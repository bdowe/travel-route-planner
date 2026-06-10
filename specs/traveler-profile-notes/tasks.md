# Tasks: Traveler Profile Notes

> Dependency-ordered. `[P]` = parallel-safe. Verification last.

## Schema & codegen (Go)
- [x] Write `migrations/00016_profile_notes.sql` (add/drop `profile_notes`)
- [x] Extend `query/preferences.sql` `UpsertPreferences` with `profile_notes` COALESCE merge
- [x] `make api-sqlc`; confirm `store` regenerates + compiles

## API (Go)
- [x] `preferences_handler.go`: `normalizeNotes` (trim, rune-safe 2000 cap) + `profile_notes` on GET/PUT structs

## Agent (Go)
- [x] Extend `save_preferences` tool schema + description (complete-rewrite contract)
- [x] `personalizedSystemPrompt`: notes block + standing profile-keeping instruction
- [x] Tool branch: normalize, empty→nil (no agent wipe), upsert, emit `profile_updated` SSE
- [x] New `profile_distiller.go`: `buildDistillationTranscript` + `distillTravelerProfile` (forced tool, errors logged only)
- [x] Hook distiller goroutine after `persistTrip` (authed, once per request, `context.Background()`)

## Verify backend
- [x] `make api-fmt && make api-vet` clean
- [x] `go test ./...`: `normalizeNotes`, `buildDistillationTranscript`, `personalizedSystemPrompt` notes cases

## Flutter
- [x] [P] `models/traveler_preferences.dart`: `profileNotes` + `make flutter-build-models`
- [x] [P] `services/preferences_api_service.dart` + `providers/preferences_provider.dart`: thread `profileNotes`
- [x] `providers/plan_provider.dart`: `profileUpdateNote` state + `profile_updated` case
- [x] `screens/preferences_screen.dart`: Profile notes section (multiline field, clear = empty)
- [x] `screens/agent_screen.dart`: transient "Noted" chip with excerpt tooltip
- [x] Complete Contract Parity table in `plan.md`

## Verify frontend
- [x] `make flutter-analyze` clean; `make flutter-test` passes
- [x] docker-dev end-to-end: live save, distillation, edit/clear, anonymous unaffected
