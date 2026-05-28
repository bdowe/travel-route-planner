# Plan: Traveler Preferences

> **HOW.** See `../../CLAUDE.md` for conventions. Builds on Phase-1 hooks.

## Technical Approach

A one-row-per-user `traveler_preferences` table, GET/PUT endpoints behind
`authMiddleware`, and two `plan_handler.go` integrations: read prefs into the
agent's system prompt, and a `save_preferences` tool so the agent can persist
what it learns. Both the form (PUT) and the tool funnel through one merge-upsert
query, so partial updates never clobber other fields.

## Go API Changes

`src/packages/api/`:
- **Migration `migrations/00004_traveler_preferences.sql`:** table keyed by
  `user_id uuid PK REFERENCES users(id) ON DELETE CASCADE`; `budget text` null,
  `pace text` null, `interests text[] NOT NULL DEFAULT '{}'`, `created_at`/`updated_at`
  + reuse `set_updated_at` trigger.
- **`query/preferences.sql`:** `GetPreferences :one` (`WHERE user_id=$1`);
  `UpsertPreferences :one` — `INSERT … ON CONFLICT (user_id) DO UPDATE` using
  `COALESCE(sqlc.narg(...), traveler_preferences.col)` for budget/pace/interests
  (merge; `NULL` keeps, empty array clears). Then `make api-sqlc`.
- **`preferences_handler.go` (`package main`):** `getPreferencesHandler` (load via
  `userFromContext`; `pgx.ErrNoRows` → empty `PreferencesResponse`), `putPreferencesHandler`
  (decode, validate `budget`∈{budget,mid,luxury} / `pace`∈{relaxed,balanced,packed}
  when non-nil, trim+dedupe interests, upsert). Reuse `writeJSON`/`writeJSONError`.
- **`main.go`:** `api.Handle("/preferences", authMiddleware(...)).Methods("GET")`
  and `.Methods("PUT")`; startup log lines.

## Agent integration (`plan_handler.go`)
- Resolve `uid, authed := userIDFromRequest(r)` once near the top.
- Add `personalizedSystemPrompt(base string, p *store.TravelerPreference) string`
  (pure, testable): appends a "Traveler preferences — …" line, omitting unset
  fields; returns base unchanged when `p` is nil.
- If `authed`: load prefs (ignore `ErrNoRows`), use the personalized prompt, and
  include a `save_preferences` tool (optional `budget`/`pace`/`interests`). Its
  branch calls `UpsertPreferences` (merge) for `uid` and emits the existing
  `tool_call`/`tool_result` SSE events. If not authed: base prompt, tool omitted.

## Flutter Changes
`src/packages/flutter-app/lib/`:
- **`models/traveler_preferences.dart`** (+ `.g.dart`): `budget String?`,
  `pace String?`, `interests List<String>`.
- **`services/preferences_api_service.dart`:** `getPreferences()` / `savePreferences(...)`,
  bearer token from `ApiClient` (mirror `trips_api_service.dart`).
- **`providers/preferences_provider.dart`:** `StateNotifier` `load()`/`save()`
  (mirror `trips_provider.dart`).
- **`screens/preferences_screen.dart`:** budget + pace single-select; interests
  chips with add; Save; loading/error/saved states.
- **`screens/home_screen.dart`:** add a "Travel profile" item to the account
  `PopupMenuButton`.

## Contract Parity
| JSON key | Go (`preferences_handler.go`) | Dart (`traveler_preferences.dart`) | Nullable | ✓ |
|---|---|---|---|---|
| `budget` | `*string` | `String?` | yes | [ ] |
| `pace` | `*string` | `String?` | yes | [ ] |
| `interests` | `[]string` | `List<String>` | no (empty list) | [ ] |

## Cross-cutting
- No new env vars. New `/api/v1/preferences` paths proxy through the gateway unchanged.

## Verification
1. `make api-sqlc`, `make api-fmt && make api-vet` clean; migration applies on boot.
2. curl (Postgres + API): `PUT` full profile → 200; `GET` returns it; `PUT` interests-only merges; unauth → 401; bad budget → 400.
3. `go test` for `personalizedSystemPrompt` (snippet built; unset fields omitted; nil → base).
4. `make flutter-build-models`, `flutter analyze` (0 errors), `flutter build web`; screen loads/saves/persists.
