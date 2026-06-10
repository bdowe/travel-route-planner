# Plan: Traveler Profile Notes

> **HOW.** See `../../CLAUDE.md` for conventions. Builds on traveler-preferences.

## Technical Approach

One new nullable `profile_notes text` column on `traveler_preferences`, flowing
through the existing COALESCE merge-upsert. Two writers, one mechanism: the
model always returns the **complete rewritten notes document** (current notes
are in its prompt; it merges + dedupes, ≤ ~15 bullet lines), and the server
does a wholesale replace — nil keeps, non-nil replaces — capped at 2000 runes
by a `normalizeNotes` helper. Live path extends the existing `save_preferences`
tool; post-trip path is a fire-and-forget goroutine (`profile_distiller.go`)
launched after `persistTrip` succeeds, making one non-streamed Claude call over
the text transcript with a forced tool. A new `profile_updated` SSE event gives
in-chat feedback for live saves only.

## Go API Changes

`src/packages/api/`:
- **Migration `migrations/00016_profile_notes.sql`:**
  `ALTER TABLE traveler_preferences ADD COLUMN profile_notes text` (+ Down drop).
- **`query/preferences.sql`:** add `profile_notes` to `UpsertPreferences`
  insert list / `sqlc.narg('profile_notes')` / `DO UPDATE … COALESCE(...)`.
  `GetPreferences` is `SELECT *` — no change. Then `make api-sqlc`
  (`store.TravelerPreference`/`UpsertPreferencesParams` gain `ProfileNotes *string`).
- **`preferences_handler.go`:** `const maxProfileNotesLen = 2000`;
  `normalizeNotes(v *string) *string` — nil→nil, trim, rune-boundary truncate;
  on the PUT path `""` stays pointer-to-empty (user clear). Add
  `ProfileNotes *string \`json:"profile_notes"\`` to response/request structs.

## Agent integration (`plan_handler.go`)

- **`save_preferences` tool:** optional `profile_notes` string; description
  demands the COMPLETE updated profile (merged + deduped), never just the new fact.
- **`personalizedSystemPrompt`:** when notes exist, append a
  "Traveler profile notes (maintained by you)" block; always (authed) append a
  standing instruction to save the full rewritten profile when learning
  something durable — no one-off trip details, no sensitive data.
- **Tool branch:** `normalizeNotes`, coerce pointer-to-empty → nil (agent can't
  wipe), upsert, then `sendSSE(w, "profile_updated", {fields, notes_preview})`
  before the existing `tool_result`.
- **After `persistTrip` succeeds** (authed, once per request):
  `go distillTravelerProfile(context.Background(), client, uid, req.Messages)` —
  request ctx dies on return; `pgxpool` is goroutine-safe.

## Distiller (`profile_distiller.go`, new)

- `distillTavelerProfile(ctx, client, uid, transcript)` — 60s timeout; load
  current prefs (ignore no-rows); one non-streamed `Messages.New`
  (claude-sonnet-4-6, MaxTokens 1024) with forced tool
  `update_traveler_profile` (same schema as `save_preferences`); normalize all
  fields through the same helpers; same upsert. All errors logged + swallowed.
- `buildDistillationTranscript(msgs, maxMsgs, maxChars)` — pure; text turns
  only, newest-biased, ~40 msgs / ~30k chars.

## Flutter Changes

`src/packages/flutter-app/lib/`:
- **`models/traveler_preferences.dart`:** `profileNotes String?`
  (`@JsonKey(name: 'profile_notes')`) + `make flutter-build-models`.
- **`services/preferences_api_service.dart` / `providers/preferences_provider.dart`:**
  thread `profileNotes` through `savePreferences`/`save()`.
- **`providers/plan_provider.dart`:** `PlanState.profileUpdateNote String?`
  (sentinel copyWith); handle `profile_updated`; clear on each `sendMessage`.
- **`screens/preferences_screen.dart`:** "Profile notes" section — caption +
  multiline `TextField` (maxLength 2000), saved via the existing Save button
  (empty text clears).
- **`screens/agent_screen.dart`:** transient "Noted" chip beside the tool
  chips when `profileUpdateNote` is set, excerpt as tooltip.

## Contract Parity
| JSON key | Go | Dart | Nullable | ✓ |
|---|---|---|---|---|
| `profile_notes` | `*string` (`preferences_handler.go`) | `String? profileNotes` | yes | [x] |
| `profile_updated.fields` | `[]string` | read loosely | no | [x] |
| `profile_updated.notes_preview` | `string` | `String?` | yes | [x] |

## Cross-cutting
- No new env vars; distiller reuses the plan handler's Anthropic client.
- Known race: live save vs distillation — last-writer-wins, acceptable since
  both send full rewrites.

## Verification
1. `make api-sqlc`; `make api-fmt && make api-vet`; `go test ./...` (table
   tests: `normalizeNotes`, `buildDistillationTranscript`,
   `personalizedSystemPrompt` with/without notes).
2. `make flutter-build-models`; `make flutter-analyze`; `make flutter-test`.
3. `make docker-dev` (API needs `up --build` for Go + migration changes):
   live save → "Noted" chip + GET shows notes; full trip → distilled notes in
   DB within ~10s; edit/clear on profile screen persists; anonymous session
   unaffected; distill failure only logs.
