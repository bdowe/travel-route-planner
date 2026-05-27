# Tasks: Trip Model

> Dependency-ordered. `[P]` = can run in parallel with its siblings (no shared
> files / no ordering dependency). Work top to bottom; verification is last.
> Prerequisite features must be implemented first: `data-foundation` (DB pool,
> goose, sqlc, store package) and `user-accounts` (auth middleware, sessions
> table, bearer-token helper).

## Database

- [ ] Write `migrations/00003_trips.sql` — flesh out `trips` columns
      (`title`, `start_date`, `end_date`, `status`) and create
      `itinerary_items` table with `position` index (see plan.md schema).
      Coordinate migration number with `user-accounts` (`00002` for sessions).
- [ ] Write `query/trips.sql` — seven sqlc queries:
      `CreateTrip`, `CreateItineraryItem`, `ListTripsByOwner`,
      `GetTripByIDAndOwner`, `GetItineraryItemsByTrip`, `UpdateTrip`,
      `DeleteTrip` (see plan.md for signatures).
- [ ] Run `make api-sqlc` to generate `store/` types; verify compilation.
- [ ] Run `make api-migrate` against dev DB; confirm migration applies and is
      idempotent on second run.

## API (Go)

- [ ] Define `ItineraryItemResponse`, `TripResponse`, and `PatchTripRequest`
      structs in `trip_handler.go` (`package main`).
- [ ] Implement `listTripsHandler` — `GET /api/v1/trips`; list only, no items
      array.
- [ ] [P] Implement `getTripHandler` — `GET /api/v1/trips/{id}`; full detail
      with items ordered by `position`.
- [ ] [P] Implement `patchTripHandler` — `PATCH /api/v1/trips/{id}`; validate
      `end_date >= start_date`; return full detail.
- [ ] [P] Implement `deleteTripHandler` — `DELETE /api/v1/trips/{id}`; `204`
      on success, `404` when 0 rows deleted.
- [ ] Register the four routes on a `trips` subrouter wrapped with
      `authMiddleware` in `main.go`; add startup log lines (see plan.md route
      block).
- [ ] Implement `userIDFromRequest(r) (uuid, bool)` helper (reads
      `Authorization: Bearer` header, validates against the sessions table via
      sqlc — coordinate exact implementation with `user-accounts`).
- [ ] Modify `plan_handler.go` `create_itinerary` branch:
      - Call `userIDFromRequest`; if authenticated, wrap `CreateTrip` +
        `CreateItineraryItem`×N in a pgx transaction.
      - Compute default title (`summary` → `"Trip to {first location name}"`).
      - Emit `done` with `trip_id` on success; emit without `trip_id` on
        unauthenticated or DB error (log DB error; do not propagate as SSE
        error).
- [ ] `make api-fmt && make api-vet` clean.

## Models & codegen (Flutter)

- [ ] [P] Hand-write `models/itinerary_item.dart` (`@JsonSerializable`,
      `place_id` / `address` nullable, `latitude` / `longitude` required
      `double`).
- [ ] [P] Hand-write `models/trip.dart` (`@JsonSerializable`, `start_date` /
      `end_date` nullable `String?`, `items` nullable `List<ItineraryItem>?`).
- [ ] Run `make flutter-build-models` to regenerate `itinerary_item.g.dart`
      and `trip.g.dart`.
- [ ] Complete every row in the Contract Parity table in `plan.md` (mark ✓).

## Services & providers (Flutter)

- [ ] [P] Write `services/trips_api_service.dart` — four methods wrapping the
      trip endpoints; inject bearer token into `Authorization` header (confirm
      token-storage pattern from `user-accounts`).
- [ ] [P] Update `services/plan_service.dart` — add optional `bearerToken`
      parameter to `streamPlan`; set `Authorization: Bearer` header when
      present.
- [ ] Write `providers/trips_provider.dart` — `TripsNotifier` /
      `TripsState` with `loadTrips`, `loadTrip`, `updateTrip`, `deleteTrip`
      methods.
- [ ] Extend `PlanState` in `plan_provider.dart` with `String? savedTripId`;
      populate it in the `done` branch when `event.data['trip_id'] != null`;
      thread the bearer token from the session into `PlanService.streamPlan`.

## UI (Flutter)

- [ ] Write `screens/trips_list_screen.dart` — list of `TripCard` widgets;
      loading / empty / error states (see plan.md for copy).
- [ ] Write `screens/trip_detail_screen.dart` — full detail with inline title
      edit, date-picker dialog, status toggle, itinerary list, and delete
      confirmation dialog; loading / error states.
- [ ] Update `screens/agent_screen.dart` (`_ItineraryBanner`): when
      `planState.savedTripId != null`, add "View Trip" button that navigates to
      `TripDetailScreen(tripId: planState.savedTripId!)`.
- [ ] Update `screens/home_screen.dart`: add "My Trips" navigation entry
      (bottom-nav tab or drawer) visible only when signed in; navigates to
      `TripsListScreen`. Wire signed-in check to the `currentUser` provider from
      `user-accounts`.
- [ ] `make flutter-build-models` (re-run after any model change) then
      `make flutter-analyze` clean.

## Verification

- [ ] `make api-fmt && make api-vet` clean.
- [ ] `make api-sqlc` succeeds; generated `store/` package compiles.
- [ ] `make api-migrate` applies `00003_trips.sql` cleanly; idempotent on
      second run.
- [ ] `make flutter-build-models` then `make flutter-analyze` clean.
- [ ] `make flutter-test` / `make api-test` pass (extend test script with
      trip endpoint smoke tests).
- [ ] Manual end-to-end via gateway (`make docker-dev` →
      `http://localhost:3000`): every acceptance criterion in `spec.md`
      checked off, including:
      - [ ] Signed-out agent run → no `trip_id` in `done`; no Trip in DB; no
              "View Trip" button.
      - [ ] Signed-in agent run → `trip_id` in `done`; "View Trip" button
              navigates to detail; itinerary matches exactly.
      - [ ] My Trips list shows the new trip; tapping opens detail.
      - [ ] Title and date edits persist across reload.
      - [ ] Delete removes trip from list.
      - [ ] Other user's trip ID returns `404`.
      - [ ] Unauthenticated `GET /api/v1/trips` returns `401`.
      - [ ] Empty itinerary (`create_itinerary` with zero locations) creates a
              Trip; detail screen renders "No places added." without crashing.
