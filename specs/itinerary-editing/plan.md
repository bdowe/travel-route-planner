# Plan: Itinerary Editing — Manual Add & In-Place AI Section Refinement

> **HOW.** Translates `spec.md` into a file-level technical approach. Every
> decision should trace back to an acceptance criterion. See `../../CLAUDE.md`
> for repo conventions referenced below — don't restate them, point to them.

## Technical Approach

Two independent writers for `itinerary_items`, sharing one coercion helper so
they can't drift:

1. **Manual add** — a small REST sub-resource handler
   (`POST /trips/{id}/items`) following the accommodations pattern: ownership
   guard, validation against the existing category/time-of-day allow-lists,
   position computed server-side (end of the chosen day), positions shifted in
   a transaction.
2. **Section refinement** — the existing `/plan` SSE agent, bound to a trip by
   a new `trip_id` request field. When bound, the `create_itinerary` tool is
   **replaced** by `update_itinerary_section` (deterministically prevents new
   version rows). The tool replaces one section's items in place via a
   delete-all + reinsert rewrite (keeps `position` dense; item ids aren't
   referenced externally; the `(trip_id, position)` index is non-unique so
   shifts are safe). The replacement section is run through the existing
   `reorderItineraryByDistance` before persisting. A new `trip_updated` SSE
   event tells the client to refresh — distinct from `done` so the fresh-plan
   completion banner path is untouched.

On the Flutter side, the chat UI is extracted from `AgentScreen` into a
reusable `ChatPanel`, driven by a **scoped** provider
(`tripRefineProvider(tripId)`) so panel sessions never clobber the global
agent-tab conversation. The trip detail page hosts the panel adaptively:
docked right column ≥900px, `DraggableScrollableSheet` below.

## Go API Changes

`src/packages/api/` (all files are `package main`):

- **Queries** (`query/trips.sql`, then `make api-sqlc`):
  `ShiftItineraryItemPositions` (position+1 from an index),
  `DeleteItineraryItemsByTrip`, `TouchTrip` (bump `updated_at` — item writes
  don't touch the trips row otherwise).
- **Routes** (`main.go`, next to accommodations):
  `POST /trips/{id}/items` behind `authMiddleware`, plus startup log line.
- **Handlers:** new `itinerary_item_handler.go` — `addItineraryItemHandler`
  (uses `ownedTrip` guard from accommodation_handler.go; pure helper
  `insertPositionForDay`; tx: shift → insert → touch; responds 201 with full
  `TripResponse`). Nil coords stored as `0,0` (columns NOT NULL; Flutter map
  already excludes `(0,0)`).
- **Section logic:** new `itinerary_section.go` — `sectionSelector`
  (scope day|city|trip, day, city), `hubOfItem` (mirrors Flutter `_hubOf`:
  `day_trip_from ?? city`, case-insensitive), `spliceSection` (pure; errors
  with valid days/hubs on selector miss so the model self-corrects),
  `itemParamsFromLocation` (extracted from `persistTrip`'s coercion loop and
  reused by it), `replaceTripSection` (tx rewrite).
- **Plan handler** (`plan_handler.go`): `PlanRequest.TripID`; ownership check
  via `GetTripByIDAndOwner` right after user resolution — failure emits SSE
  `error` and aborts (never silently falls back to version-creating mode);
  tool list swap + system-prompt addendum when bound; dispatch case runs
  `reorderItineraryByDistance` then `replaceTripSection`, emits
  `trip_updated`. Shared `itineraryLocationSchema` var feeds both tools'
  `items`/`locations` schemas.
- **Types:** `AddItineraryItemRequest` in the new handler file; tool input
  decoded inline in the dispatch case (matches existing tool cases).

Convention reminders: request coords are `*float64` (nil = not provided); SSE
already runs with `WriteTimeout: 0`; no new env vars; no CORS changes.

## Flutter Changes

`src/packages/flutter-app/lib/`:

- **Models:** none — `ItineraryItem`/`Trip` already match the responses. No
  codegen run needed.
- **Service:** `services/trips_api_service.dart` → `addItineraryItem(tripId,
  body)` (POST, expects 201 → `Trip`); `services/plan_service.dart` →
  `streamPlan(..., tripId)` adds `trip_id` to the body.
- **Provider:** `providers/plan_provider.dart` — `PlanState.tripUpdateCount`
  (monotonic counter; listen-friendly for repeated patches),
  `'trip_updated'` event case, `PlanNotifier.tripId` ctor param,
  `beginSectionRefinement(seed)` (no server chat-id round trip), and
  `tripRefineProvider` = `StateNotifierProvider.autoDispose.family` keyed by
  trip id with `keepAlive` so the conversation survives panel close/reopen.
- **Widgets:**
  - `widgets/chat_panel.dart` — `ChatPanel(state, notifier, inputHint,
    emptyState?, footerBuilder?)` extracted from `agent_screen.dart`
    (bubbles, input bar, tool chips + `update_itinerary_section` label,
    flight cards, error display, autoscroll). `agent_screen.dart` becomes a
    thin shell; behavior unchanged.
  - `widgets/trip_refine_panel.dart` — `RefineTarget{scope, day?, city?}` +
    `TripRefinePanel{tripId, target, onClose, onTripUpdated}`; listens to
    `tripUpdateCount` → `onTripUpdated`.
  - `widgets/add_itinerary_item_dialog.dart` — debounced Places autocomplete
    (via existing `placesApiServiceProvider`), details fetch on select,
    manual-name fallback, day/time-of-day/category pickers.
- **Screen:** `screens/trip_detail_screen.dart` — adaptive layout
  (`LayoutBuilder`: ≥900px Row + 400px panel; else Stack +
  `DraggableScrollableSheet` .15/.45/.92 with keyboard inset padding);
  `_openRefine` + `_buildSectionSeed` replace the AgentScreen push; refine
  icons on trip header / day sub-headers / city group headers ("Other places"
  disabled); "Add place" button on the Itinerary header; `_computeTravelTimes`
  sends null coords for `(0,0)` items.

## Contract Parity  ← anti-drift gate

| JSON key | Go type | Dart type | Nullable? | ✓ |
|----------|---------|-----------|-----------|---|
| `name` (add-item req) | `string` | `String` | no | ✓ |
| `place_id` | `*string` | `String?` (key omitted when unset) | yes | ✓ |
| `address` | `*string` | `String?` (key omitted when unset) | yes | ✓ |
| `latitude` / `longitude` | `*float64` | `double` (keys omitted when no Places match) | yes (omitted → no location) | ✓ |
| `category` | `*string` | `String?` (key omitted when unset) | yes | ✓ |
| `time_of_day` | `*string` | `String?` (key omitted when unset) | yes | ✓ |
| `city` | `*string` | not sent (server stores NULL; UI groups by address) | yes | ✓ |
| `day` | `*int` | `int?` (key omitted when unset) | yes | ✓ |
| add-item 201 body | `TripResponse` | `Trip` (existing model, field-for-field) | — | ✓ |
| `trip_id` (PlanRequest) | `string` | `String?` (key omitted when null) | yes | ✓ |
| `trip_updated.data.trip_id` | `string` | unread (event arrival alone triggers reload) | no | ✓ |

Rules: optional Go fields (pointers / `omitempty`) → nullable Dart fields;
JSON tag on the Go side must equal the `@JsonKey`/field name on the Dart side.

## Cross-cutting

- **Env vars:** none added.
- **Gateway:** new path is under `/api/v1/` — no proxy config changes.
- **In-flight work:** builds on the uncommitted `itinerary_optimizer.go`,
  `plan_handler.go` reorder call, and the trip-detail sliver refactor.
- **Deprecation flag:** `POST /trips/{id}/refine` and the admin versions view
  become unused by the UI for refinement; kept, cleanup later.

## Verification

(Mirror into `tasks.md` as the final tasks.)

- `make api-fmt && make api-vet` — Go formatting/vet clean.
- `make api-test` — includes new `itinerary_section_test.go` pure-function
  tests (`insertPositionForDay`, `spliceSection`, `hubOfItem`).
- `make flutter-analyze` && `make flutter-test` — clean (no codegen needed).
- Manual end-to-end via the gateway at `http://localhost:3000`
  (`make docker-dev`; API container needs `up --build` after Go changes;
  Flutter container restart + browser hard refresh): walk each acceptance
  criterion from `spec.md`, including: version count flat after refinements,
  items outside a refined section byte-identical, AgentScreen regression.
- `curl` examples:
  - `curl -X POST :3000/api/v1/trips/{id}/items -H 'Authorization: Bearer …' -d '{"name":"Café X","day":2,"time_of_day":"morning","category":"restaurant"}'` → 201
  - same without auth → 401; `"category":"bar"` → 400.
