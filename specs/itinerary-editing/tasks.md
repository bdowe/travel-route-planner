# Tasks: Itinerary Editing — Manual Add & In-Place AI Section Refinement

> Dependency-ordered. `[P]` = can run in parallel with its siblings (no shared
> files / no ordering dependency). Work top to bottom; verification is last.

## API (Go)

- [ ] Add `ShiftItineraryItemPositions`, `DeleteItineraryItemsByTrip`,
      `TouchTrip` to `query/trips.sql`; run `make api-sqlc`
- [ ] `itinerary_item_handler.go`: `AddItineraryItemRequest`,
      `insertPositionForDay`, `addItineraryItemHandler` (tx: shift → insert →
      touch; 201 with full `TripResponse`)
- [ ] Register `POST /trips/{id}/items` + startup log line in `main.go`
- [ ] `itinerary_section.go`: `sectionSelector`, `hubOfItem`,
      `spliceSection`, `itemParamsFromLocation` (+ refactor `persistTrip` to
      use it), `replaceTripSection`
- [ ] `plan_handler.go`: `PlanRequest.TripID`, ownership bind (SSE error on
      failure), tool swap (`update_itinerary_section` replaces
      `create_itinerary` when bound), shared `itineraryLocationSchema`,
      dispatch case + `trip_updated` SSE event, system-prompt addendum
- [ ] `itinerary_section_test.go`: table tests for `insertPositionForDay`,
      `spliceSection` (all scopes, disambiguation, miss errors, tag
      preservation), `hubOfItem`

## Models & codegen (Flutter)

- [ ] No model changes needed (verify `ItineraryItem`/`Trip` parity)
- [ ] Complete the Contract Parity table in `plan.md` (every row ✓)

## UI (Flutter)

- [ ] [P] `trips_api_service.dart`: `addItineraryItem`
- [ ] [P] `plan_service.dart`: `trip_id` in `streamPlan` body
- [ ] `plan_provider.dart`: `tripUpdateCount`, `'trip_updated'` case,
      `tripId` ctor param, `beginSectionRefinement`, `tripRefineProvider`
      autoDispose family with keepAlive
- [ ] `widgets/chat_panel.dart`: extract from `agent_screen.dart`; rewrite
      AgentScreen as thin shell (behavior unchanged — verify before
      continuing)
- [ ] `widgets/trip_refine_panel.dart`: `RefineTarget`, `TripRefinePanel`,
      `tripUpdateCount` listener
- [ ] `trip_detail_screen.dart`: adaptive layout (right dock ≥900px /
      bottom sheet), `_openRefine` + `_buildSectionSeed`, refine icons on
      trip/day/city headers ("Other places" disabled), remove AgentScreen
      push + `_refining`
- [ ] `widgets/add_itinerary_item_dialog.dart`: autocomplete + manual
      fallback + day/time/category pickers; "Add place" header button;
      `_computeTravelTimes` null-coord fix
- [ ] Handle loading / empty / error states (dialog spinner + inline errors;
      panel error banner; empty-trip add flow)

## Verification

- [ ] `make api-fmt && make api-vet` clean
- [ ] `make api-test` passes (incl. `itinerary_section_test.go`)
- [ ] `make flutter-analyze` clean
- [ ] `make flutter-test` passes
- [ ] Manual end-to-end via gateway (`make docker-dev` → `http://localhost:3000`):
      every acceptance criterion in `spec.md` checked off (incl. flat version
      count, untouched out-of-section items, AgentScreen regression,
      narrow-window bottom sheet + keyboard)
