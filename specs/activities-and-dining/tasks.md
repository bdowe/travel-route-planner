# Tasks: Activities & Dining

> Dependency-ordered. `[P]` = parallel-safe. Verification last.

## Schema & codegen (Go)
- [ ] `migrations/00006_itinerary_categories.sql` (ALTER ADD COLUMN category)
- [ ] `make api-sqlc`; `store` regenerates + compiles

## Backend wiring (Go)
- [ ] `plan_handler.go`: add `category` to `create_itinerary` schema; update `basePrompt`
- [ ] `trip_handler.go`: `persistTrip` reads + normalizes `category`; `ItineraryItemResponse` + `toTripResponse` pass it through
- [ ] `api-fmt`/`api-vet` clean

## Verify backend
- [ ] Throwaway `persistTrip` test with mixed categories (incl. unset) round-trips
- [ ] curl: psql-seeded items return `category`; null items omit it

## Flutter
- [ ] [P] `models/itinerary_item.dart`: add `category String?`; `make flutter-build-models`
- [ ] `screens/trip_detail_screen.dart`: category-aware leading icon + filter chip row + filtered iteration
- [ ] Complete Contract Parity table in `plan.md`

## Verify frontend
- [ ] `flutter analyze` clean; `flutter build web` succeeds
- [ ] Category icons render; filter chips narrow the list
