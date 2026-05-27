# Plan: Trip Model

> **HOW.** Translates `spec.md` into a file-level technical approach. Every
> decision traces back to an acceptance criterion. See `../../CLAUDE.md` for
> repo conventions. Depends on `data-foundation` (pgxpool, goose, sqlc, store
> package) and `user-accounts` (bearer-token auth middleware, `users` table).

## Technical Approach

Introduce the `trips` and `itinerary_items` tables via a new goose migration,
generate typed queries with sqlc, expose four REST endpoints behind the
user-accounts auth middleware in a new `trip_handler.go`, and modify
`plan_handler.go` to auto-persist a Trip when `create_itinerary` fires on an
authenticated request — emitting `trip_id` in the `done` SSE event. The
`/plan` endpoint stays auth-optional: unauthenticated calls complete normally
with no persistence, preserving the try-before-signup UX. On the Flutter side,
two new screens (My Trips list, Trip detail), a `trips_api_service.dart`
wrapper, a Riverpod provider, and a `trip.dart` / `itinerary_item.dart` model
pair round out the feature.

Key decisions:
- **Auto-persist on `create_itinerary`, not on a separate client call.** The
  server holds the canonical list of locations at that instant; a separate
  client-initiated POST would create a race and require the client to re-POST
  the full payload, duplicating the SSE stream data.
- **Auth check in `plan_handler.go` via the same bearer-token helper used by
  the trip endpoints.** A helper `userIDFromRequest(r) (uuid, bool)` attempts
  to read the token from `Authorization: Bearer <token>` and look it up in the
  `sessions` table (via sqlc). Returns `false` when absent or invalid — no
  error, no `401`; the handler proceeds without persistence.
- **Default title logic:** `summary` field from the `create_itinerary` call if
  non-empty; otherwise `"Trip to {first location name}"`. Computed in Go before
  the DB insert.
- **`itinerary_items.position` is an explicit integer.** Items are inserted in
  the order Claude returns them; position mirrors the slice index (0-based).
  The column is mutable so a future phase can reorder without a schema change.
- **`404` for both not-found and not-owned.** A single SQL query
  `WHERE id = $1 AND user_id = $2` naturally produces 0 rows for either case;
  no secondary lookup needed. (`user_id` is the trips ownership FK established by
  `data-foundation`.)
- **Date-only fields (`start_date`, `end_date`)** stored as `date` in Postgres,
  serialised as `"YYYY-MM-DD"` strings in JSON. Dart maps these to `String?`
  (no `DateTime` required for Phase 1 display-only use).

## Go API Changes

`src/packages/api/` (hand-written files stay `package main`; generated DB code
stays in `store/` — see data-foundation plan):

### Migration — `migrations/00003_trips.sql`

Flesh out the baseline `trips` skeleton from `00001_baseline.sql` and add
`itinerary_items`:

```sql
-- +goose Up
ALTER TABLE trips
  ADD COLUMN title        text        NOT NULL DEFAULT '',
  ADD COLUMN start_date   date,
  ADD COLUMN end_date     date,
  ADD COLUMN status       text        NOT NULL DEFAULT 'draft';

CREATE TABLE itinerary_items (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id    uuid        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  position   int         NOT NULL,
  name       text        NOT NULL,
  place_id   text,
  address    text,
  latitude   double precision NOT NULL,
  longitude  double precision NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ON itinerary_items(trip_id, position);
-- +goose Down
DROP TABLE itinerary_items;
ALTER TABLE trips
  DROP COLUMN title,
  DROP COLUMN start_date,
  DROP COLUMN end_date,
  DROP COLUMN status;
```

> If `00002` is claimed by `user-accounts` (for the `sessions` table), name
> this file `00003_trips.sql`. Coordinate with that feature during
> implementation.

### sqlc queries — `query/trips.sql`

New file with queries generating into `store/` (`package store`):

- `CreateTrip` — insert into `trips`, returning full row
- `CreateItineraryItem` — insert into `itinerary_items`, returning full row
- `ListTripsByOwner` — `SELECT … WHERE user_id = $1 ORDER BY created_at DESC`
- `GetTripByIDAndOwner` — trip row only; `WHERE id = $1 AND user_id = $2`
- `GetItineraryItemsByTrip` — `WHERE trip_id = $1 ORDER BY position ASC`
- `UpdateTrip` — PATCH-friendly: update `title`, `start_date`, `end_date`,
  `status`, `updated_at` where `id = $1 AND user_id = $2`; return updated row
- `DeleteTrip` — `DELETE WHERE id = $1 AND user_id = $2`; return rows affected

### New `trip_handler.go` (`package main`)

Response types (defined here):

```go
type ItineraryItemResponse struct {
    ID        string   `json:"id"`
    Position  int      `json:"position"`
    Name      string   `json:"name"`
    PlaceID   *string  `json:"place_id,omitempty"`
    Address   *string  `json:"address,omitempty"`
    Latitude  float64  `json:"latitude"`
    Longitude float64  `json:"longitude"`
}

type TripResponse struct {
    ID        string                   `json:"id"`
    Title     string                   `json:"title"`
    StartDate *string                  `json:"start_date,omitempty"`
    EndDate   *string                  `json:"end_date,omitempty"`
    Status    string                   `json:"status"`
    CreatedAt string                   `json:"created_at"`   // RFC3339
    UpdatedAt string                   `json:"updated_at"`   // RFC3339
    Items     []ItineraryItemResponse  `json:"items,omitempty"`
}

type PatchTripRequest struct {
    Title     *string `json:"title"`
    StartDate *string `json:"start_date"`
    EndDate   *string `json:"end_date"`
    Status    *string `json:"status"`
}
```

Handler functions (each uses `authMiddleware` or the `userIDFromRequest`
helper to enforce authentication; return `401` if unauthenticated, `404` if
the owner check fails):

- `listTripsHandler(w, r)` — `GET /api/v1/trips`; returns `[]TripResponse`
  (items field omitted in the list view)
- `getTripHandler(w, r)` — `GET /api/v1/trips/{id}`; returns full
  `TripResponse` including items ordered by `position`
- `patchTripHandler(w, r)` — `PATCH /api/v1/trips/{id}`; validates
  `end_date >= start_date` when both are present; returns updated
  `TripResponse` with items
- `deleteTripHandler(w, r)` — `DELETE /api/v1/trips/{id}`; `204` on success;
  `404` if no rows deleted

All four handlers must be wrapped with the `authMiddleware` introduced by
`user-accounts`; they never fall through to an unauthenticated code path.

### Modified `plan_handler.go`

Add a `userIDFromRequest(r *http.Request) (pgtype.UUID, bool)` helper (or call
the equivalent from `user-accounts`). In the `create_itinerary` branch:

1. Attempt `uid, ok := userIDFromRequest(r)`.
2. If `ok`: parse the `in.Locations` slice into typed `ItineraryItem` values,
   compute the default title, call `store.CreateTrip` then
   `store.CreateItineraryItem` for each item inside a transaction. On DB error,
   log it and fall through to the existing `done` emit without `trip_id` (do
   not return an SSE error — the conversation still completes).
3. Emit `done` with `trip_id` added when persistence succeeded; emit without
   `trip_id` when the caller is unauthenticated or DB write failed.
4. No change to the `search_places` branch or the outer loop.

### `main.go`

Register the four new routes and add startup log lines:

```go
trips := api.PathPrefix("/trips").Subrouter()
trips.Use(authMiddleware)           // all trip routes require auth
trips.HandleFunc("", listTripsHandler).Methods("GET")
trips.HandleFunc("/{id}", getTripHandler).Methods("GET")
trips.HandleFunc("/{id}", patchTripHandler).Methods("PATCH")
trips.HandleFunc("/{id}", deleteTripHandler).Methods("DELETE")
```

## Flutter Changes

`src/packages/flutter-app/lib/`:

### Models (`models/`)

**`models/trip.dart`** (hand-written; `make flutter-build-models` regenerates
`trip.g.dart`):

```dart
@JsonSerializable()
class Trip {
  final String id;
  final String title;
  @JsonKey(name: 'start_date') final String? startDate;
  @JsonKey(name: 'end_date')   final String? endDate;
  final String status;
  @JsonKey(name: 'created_at') final String createdAt;
  @JsonKey(name: 'updated_at') final String updatedAt;
  final List<ItineraryItem>? items;   // null in list view, populated in detail
  // fromJson / toJson / copyWith
}
```

**`models/itinerary_item.dart`** (hand-written; regenerates
`itinerary_item.g.dart`):

```dart
@JsonSerializable()
class ItineraryItem {
  final String id;
  final int position;
  final String name;
  @JsonKey(name: 'place_id') final String? placeId;
  final String? address;
  final double latitude;
  final double longitude;
  // fromJson / toJson
}
```

### Service (`services/trips_api_service.dart`)

Wraps the four trip endpoints using `ApiClient`. Must inject the bearer token
from the user-accounts session into the `Authorization` header on every call.
Because `user-accounts` is being designed in parallel, assume `ApiClient` will
gain a `setBearerToken(String token)` method (or accept it at construction);
during implementation, confirm the exact pattern from that feature's plan and
match it here.

Methods:
- `Future<List<Trip>> listTrips()`
- `Future<Trip> getTrip(String id)`
- `Future<Trip> patchTrip(String id, {String? title, String? startDate, String? endDate, String? status})`
- `Future<void> deleteTrip(String id)`

### Provider (`providers/trips_provider.dart`)

A `StateNotifierProvider<TripsNotifier, TripsState>`:

```
TripsState { List<Trip> trips, Trip? selectedTrip, bool loading, String? error }
```

Methods on the notifier: `loadTrips()`, `loadTrip(String id)`,
`updateTrip(String id, {...})`, `deleteTrip(String id)`.

`PlanNotifier` (in `plan_provider.dart`) gains a `String? savedTripId` field on
`PlanState`. In the `done` branch of `sendMessage`, if
`event.data['trip_id'] != null`, store it in `savedTripId`.

### Service update: `services/plan_service.dart`

`PlanService.streamPlan` currently ignores the auth token. Add an optional
`String? bearerToken` parameter (or let the caller pass custom headers). When
present, set `Authorization: Bearer <token>` on the SSE request. This is the
only way the `done` event will carry a `trip_id` for signed-in users.

> **Assumption to sanity-check:** the SSE client (`plan_service.dart`) uses
> `http.Request` which accepts arbitrary headers. Passing the bearer token as a
> header on the initial POST is straightforward. Confirm with the user-accounts
> implementation how the session token is stored on device (e.g.
> `shared_preferences` / `flutter_secure_storage`) and how `plan_provider.dart`
> reads it at call time.

### Screens

**`screens/trips_list_screen.dart`**

- `ConsumerWidget`; watches `tripsProvider`.
- On first build, calls `tripsProvider.notifier.loadTrips()`.
- Happy path: `ListView` of `TripCard` widgets (title + formatted `created_at`).
  Tap navigates to `TripDetailScreen`.
- Empty state: "No trips yet — chat with the agent to create your first trip."
- Loading state: `CircularProgressIndicator`.
- Error state: error text + "Retry" button that calls `loadTrips()` again.

**`screens/trip_detail_screen.dart`**

- Accepts a `String tripId` (navigated to by ID, not by pre-loaded object, so
  a deep link or post-finalize navigation both work).
- `ConsumerWidget`; calls `loadTrip(tripId)` on first build; watches
  `selectedTrip`.
- Happy path: displays title (editable inline), optional dates (edit via date
  pickers in a dialog), status chip, and a `ListView` of itinerary items (each
  shows `position + 1`, `name`, `address`).
- Title edit: `TextFormField` with a trailing save icon; calls `patchTrip` on
  submit.
- Date edit: "Add dates" / date-picker dialog; calls `patchTrip` with
  `start_date` + `end_date`.
- Status toggle: segmented button or dropdown for `draft` / `planned`.
- Delete: `IconButton` in the AppBar → `AlertDialog` confirmation → `deleteTrip`
  → `Navigator.pop` back to list.
- Loading / error states same pattern as list screen.

**`screens/home_screen.dart`** — add a "My Trips" navigation entry (bottom-nav
tab or drawer item) visible only to signed-in users. The signed-in state comes
from user-accounts; wire to a `currentUserProvider` or equivalent.

**`screens/agent_screen.dart`** — extend `_ItineraryBanner` (or add a sibling
widget): when `planState.savedTripId != null`, display a "View Trip" button
alongside "Load into Planner". Tapping it pushes `TripDetailScreen(tripId:
planState.savedTripId!)`. Signed-out users see the existing banner unchanged.

## Contract Parity — anti-drift gate

Rules: pointer/`omitempty` Go fields → nullable Dart fields. JSON tag on Go
side must equal the field name or `@JsonKey` name on the Dart side.

### Trip (`TripResponse` ↔ `Trip`)

| JSON key | Go type (`trip_handler.go`) | Dart type (`trip.dart`) | Nullable? | ✓ |
|---|---|---|---|---|
| `id` | `string` | `String` | no | ☐ |
| `title` | `string` | `String` | no | ☐ |
| `start_date` | `*string` (omitempty) | `String?` | yes | ☐ |
| `end_date` | `*string` (omitempty) | `String?` | yes | ☐ |
| `status` | `string` | `String` | no | ☐ |
| `created_at` | `string` (RFC3339) | `String` | no | ☐ |
| `updated_at` | `string` (RFC3339) | `String` | no | ☐ |
| `items` | `[]ItineraryItemResponse` (omitempty) | `List<ItineraryItem>?` | yes (omitted in list) | ☐ |

### Itinerary Item (`ItineraryItemResponse` ↔ `ItineraryItem`)

| JSON key | Go type (`trip_handler.go`) | Dart type (`itinerary_item.dart`) | Nullable? | ✓ |
|---|---|---|---|---|
| `id` | `string` | `String` | no | ☐ |
| `position` | `int` | `int` | no | ☐ |
| `name` | `string` | `String` | no | ☐ |
| `place_id` | `*string` (omitempty) | `String?` | yes | ☐ |
| `address` | `*string` (omitempty) | `String?` | yes | ☐ |
| `latitude` | `float64` | `double` | no | ☐ |
| `longitude` | `float64` | `double` | no | ☐ |

### `done` SSE event extension

| JSON key | Go type (`plan_handler.go` `done` payload) | Dart type (`plan_provider.dart`) | Nullable? | ✓ |
|---|---|---|---|---|
| `locations` | `[]map[string]any` | `List<Map<String,dynamic>>` | existing field | ☐ |
| `summary` | `string` | `String?` | yes (existing) | ☐ |
| `trip_id` | `*string` (omitempty) | `String?` | yes (absent when anon) | ☐ |

## Cross-cutting

- **Env vars:** no new vars; `DATABASE_URL` (data-foundation) and
  `ANTHROPIC_API_KEY` / `GOOGLE_PLACES_API_KEY` already cover all paths.
- **Gateway:** new `/api/v1/trips/*` paths are under `/api/v1/` and are
  automatically proxied through nginx. No proxy config change needed.
- **Auth middleware:** `authMiddleware` is implemented by `user-accounts`. The
  four trip routes are wrapped with it; `plan_handler.go` uses the softer
  `userIDFromRequest` helper (returns false rather than 401 when unauthenticated)
  so the SSE endpoint stays open to anonymous callers.
- **Transactions:** the `CreateTrip` + N×`CreateItineraryItem` DB writes in
  `plan_handler.go` must be wrapped in a `pgx` transaction so a partial write
  never produces an orphaned trip with missing items.
- **Empty itinerary:** if `create_itinerary` fires with zero locations, still
  create the Trip (with an empty items list) so the SSE `done` event carries a
  `trip_id`; the detail screen renders gracefully with "No places added."
- **Date validation (`PATCH`):** reject with `400` if `end_date` parses to a
  date before `start_date`; leave existing dates unchanged.

## Verification

1. `make api-fmt && make api-vet` — clean.
2. `make api-sqlc` — sqlc regenerates without error; `store/` package compiles.
3. `make api-migrate` against a fresh DB — migration `00003_trips.sql` applies
   cleanly; running twice is a no-op.
4. `make flutter-build-models` then `make flutter-analyze` — codegen and
   analysis clean.
5. Manual end-to-end via `make docker-dev` at `http://localhost:3000`:
   - Signed-out: open Agent, complete a plan; `done` event has no `trip_id`;
     no Trip is created in the DB; "View Trip" button does not appear.
   - Signed-in: complete a plan; `done` event carries `trip_id`; "View Trip"
     button appears in the banner; tapping it opens the detail screen with the
     correct ordered itinerary.
   - "My Trips" tab shows the new trip; tapping it opens the same detail view.
   - PATCH: edit the title and dates in the detail view; changes persist across
     reload.
   - DELETE: delete the trip from the detail view; it disappears from the list.
   - Accessing another user's trip ID → `404`.
   - Unauthenticated `GET /api/v1/trips` → `401`.

6. `curl` examples (through gateway, replace `TOKEN` and `TRIP_ID`):

```bash
# List trips
curl -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/trips

# Get trip detail
curl -H "Authorization: Bearer TOKEN" http://localhost:3000/api/v1/trips/TRIP_ID

# Update title
curl -X PATCH -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"title":"My Paris Trip","start_date":"2026-06-01","end_date":"2026-06-07"}' \
     http://localhost:3000/api/v1/trips/TRIP_ID

# Delete
curl -X DELETE -H "Authorization: Bearer TOKEN" \
     http://localhost:3000/api/v1/trips/TRIP_ID
```
