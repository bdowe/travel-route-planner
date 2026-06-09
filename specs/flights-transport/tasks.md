# Tasks: Flights & Transport

> Dependency-ordered. `[P]` = parallel-safe. Verification last.

## Schema & codegen (Go)
- [ ] `migrations/00007_trip_segments.sql` (table + trigger + index)
- [ ] `query/segments.sql` (Create / ListByTrip / Delete)
- [ ] `make api-sqlc`; store compiles

## Providers & API (Go)
- [ ] `transport_service.go`: provider interface + Google Flights / Kayak / Rome2Rio `SearchURL` + `transportLinks`
- [ ] `segment_handler.go`: links / add / delete (ownership via `ownedTrip`)
- [ ] Extend `TripResponse` + `getTripHandler` with `segments`
- [ ] `suggest_transport` agent tool in `plan_handler.go`
- [ ] Register routes in `main.go`; startup logs

## Verify backend
- [ ] `api-fmt`/`api-vet` clean
- [ ] `go test` for `SearchURL` builders
- [ ] curl: links / add / list-in-trip / delete / 404 / 401

## Flutter
- [ ] [P] `models/trip_segment.dart` (+ build-models); extend `trip.dart`
- [ ] [P] `services/transport_api_service.dart`
- [ ] `providers/transport_provider.dart`
- [ ] `trip_detail_screen.dart`: Travel section (list/delete, Find flights/ground dialogs, Add segment)
- [ ] Complete Contract Parity table in `plan.md`

## Verify frontend
- [ ] `flutter analyze` clean; `flutter build web`
- [ ] Travel section lists/deletes; Find dialogs open links; Add saves
