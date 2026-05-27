# Tasks: <Feature Name>

> Dependency-ordered. `[P]` = can run in parallel with its siblings (no shared
> files / no ordering dependency). Work top to bottom; verification is last.

## API (Go)

- [ ] Define request/response types
- [ ] Implement service logic in `<feature>_service.go`
- [ ] Implement handler(s)
- [ ] Register route(s) + startup log line in `main.go`
- [ ] Add any new env var to `.env.sample`

## Models & codegen (Flutter)

- [ ] Hand-write Dart model(s) in `models/`
- [ ] Run `make flutter-build-models` to regenerate `.g.dart`
- [ ] Complete the Contract Parity table in `plan.md` (every row ✓)

## UI (Flutter)

- [ ] [P] Add service wrapper in `services/`
- [ ] [P] Add Riverpod provider in `providers/`
- [ ] Build screen / widget and wire to provider
- [ ] Handle loading / empty / error states

## Verification

- [ ] `make api-fmt && make api-vet` clean
- [ ] `make flutter-analyze` clean
- [ ] `make flutter-test` / `make api-test` pass (as applicable)
- [ ] Manual end-to-end via gateway (`make docker-dev` → `http://localhost:3000`):
      every acceptance criterion in `spec.md` checked off
