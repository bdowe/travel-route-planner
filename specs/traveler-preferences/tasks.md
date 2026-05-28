# Tasks: Traveler Preferences

> Dependency-ordered. `[P]` = parallel-safe. Verification last.

## Schema & codegen (Go)
- [ ] Write `migrations/00004_traveler_preferences.sql` (table + trigger)
- [ ] Write `query/preferences.sql` (`GetPreferences`, `UpsertPreferences` merge)
- [ ] `make api-sqlc`; confirm `store` regenerates + compiles

## API (Go)
- [ ] Write `preferences_handler.go`: GET (empty default on no row) + PUT (validate budget/pace, trim/dedupe interests, upsert)
- [ ] Register GET/PUT `/preferences` behind `authMiddleware` in `main.go` + startup logs

## Agent (Go)
- [ ] Add `personalizedSystemPrompt` helper (pure/testable)
- [ ] In `planHandler`: resolve auth once; inject prefs + add `save_preferences` tool when authed; merge-upsert in the tool branch

## Verify backend
- [ ] `make api-fmt && make api-vet` clean
- [ ] curl: PUT/GET/partial-merge/401/400 against Postgres
- [ ] `go test` for `personalizedSystemPrompt`

## Flutter
- [ ] [P] `models/traveler_preferences.dart` (+ run `make flutter-build-models`)
- [ ] [P] `services/preferences_api_service.dart`
- [ ] `providers/preferences_provider.dart`
- [ ] `screens/preferences_screen.dart` (budget/pace select, interests chips, save)
- [ ] `screens/home_screen.dart`: account-menu "Travel profile" entry
- [ ] Complete Contract Parity table in `plan.md`

## Verify frontend
- [ ] `flutter analyze` clean; `flutter build web` succeeds
- [ ] screen loads/saves/persists across reload
