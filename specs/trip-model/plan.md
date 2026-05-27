# Plan: <Feature Name>

> **HOW.** Translates `spec.md` into a file-level technical approach. Every
> decision should trace back to an acceptance criterion. See `../../CLAUDE.md`
> for repo conventions referenced below — don't restate them, point to them.

## Technical Approach

The strategy in a few sentences. Call out key decisions and *why* (the
tradeoff or constraint behind each choice).

## Go API Changes

`src/packages/api/` (all files are `package main`):

- **Routes:** register handlers in `main.go` (`api.HandleFunc(...)`) and add a
  startup log line.
- **Handlers:** where the new handler funcs live (`main.go`, or a new
  `<feature>_handler.go`).
- **Service:** new `<feature>_service.go` for external/integration logic.
- **Types:** request/response structs and where they're defined.

Convention reminders (see CLAUDE.md → Key Constraints):
- Coordinates on `Location` are `*float64` — distinguish "not provided" from 0;
  skip validation when nil.
- SSE / streaming endpoints require `WriteTimeout: 0` and `http.Flusher`.
- `optimize_for` accepts only `distance` / `season` / `balanced` (empty →
  balanced).
- New CORS headers go in `corsMiddleware`.
- New secrets are read from env vars — document them in `.env.sample`.

## Flutter Changes

`src/packages/flutter-app/lib/`:

- **Models** (`models/`): hand-write the `.dart`, then run
  `make flutter-build-models` to regenerate the `.g.dart`. **Never hand-edit
  `.g.dart`.**
- **Service** (`services/`): wrap the new endpoint(s).
- **Provider** (`providers/`): one Riverpod provider per feature.
- **Screen / widget** (`screens/`, `widgets/`): UI, wired to the provider.

## Contract Parity  ← anti-drift gate

For each request/response pair, confirm the Go struct and its Dart
`@JsonSerializable` model agree. Fill this table; every row must match before
implementation is considered done.

| JSON key | Go type (`*_service.go` / `*.go`) | Dart type (`*.dart`) | Nullable? | ✓ |
|----------|-----------------------------------|----------------------|-----------|---|
| `example_field` | `*float64` | `double?` | yes | ☐ |

Rules: optional Go fields (pointers / `omitempty`) → nullable Dart fields;
JSON tag on the Go side must equal the `@JsonKey`/field name on the Dart side.

## Cross-cutting

- **Env vars:** new keys added to `src/packages/api/.env.sample`.
- **Gateway:** API calls are same-origin through the nginx gateway (port 3000);
  Docker builds Flutter with `--dart-define=API_BASE_URL=/api/v1`. New paths
  under `/api/v1/` need no extra proxy config.

## Verification

(Mirror into `tasks.md` as the final tasks.)

- `make api-fmt && make api-vet` — Go formatting/vet clean.
- `make flutter-build-models` then `make flutter-analyze` — codegen + analysis clean.
- `make flutter-test` / `make api-test` as applicable.
- Manual end-to-end via the gateway at `http://localhost:3000` (`make docker-dev`):
  walk each acceptance criterion from `spec.md`.
- `curl` examples for new endpoints (through the gateway).
