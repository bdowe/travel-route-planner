# Tasks: Data Foundation

> Dependency-ordered. `[P]` = can run in parallel with its siblings (no shared
> files / no ordering dependency). Work top to bottom; verification is last.

## Dependencies & schema (Go)

- [ ] Add `jackc/pgx/v5` and `pressly/goose/v3` deps (`make api-deps` / `go mod tidy`)
- [ ] Write `migrations/00001_baseline.sql` (goose Up/Down): `users` + `trips`
      skeletons, UUID PKs via `gen_random_uuid()`, `created_at`/`updated_at`,
      `trips.user_id` FK → `users(id)`, `set_updated_at()` trigger + triggers
- [ ] Add `sqlc.yaml` + `query/` dir; generate the `store` package (baseline
      `User`/`Trip` models)

## Connection & wiring (Go)

- [ ] Write `db.go`: `dbPool` var, `initDB` (MaxConns 10, 5s timeout, Ping),
      `runMigrations` (embedded `embed.FS` + goose via pgx stdlib)
- [ ] Wire `main()`: read `DATABASE_URL`, degraded-start logic, run migrations,
      assign pool
- [ ] Augment `HealthResponse` (`Database` field) + `healthHandler` (Ping → `ok`
      / 503)

## Cross-cutting

- [ ] [P] Add `postgres:16-alpine` service (+ volume, `pg_isready` healthcheck) to
      `dockerize/development/docker-compose.yml` **and**
      `dockerize/deployment/docker-compose.yml`; give `api` `DATABASE_URL` +
      `depends_on` postgres healthy
- [ ] [P] Add `DATABASE_URL` to `src/packages/api/.env.sample`
- [ ] [P] Add `api-migrate` + `api-sqlc` Makefile targets
- [ ] Update `CLAUDE.md`: new `store` sub-package, `DATABASE_URL` env, health
      response change

## Verification

- [ ] `make docker-dev` brings up postgres; `GET /api/v1/health` (via :3000)
      returns 200 with `database: "ok"`
- [ ] Stop postgres → health 503; `/optimize-route`, `/places/*`, `/plan` still
      respond (degraded mode)
- [ ] Restart API against migrated DB → boots clean (idempotent); `make
      api-migrate` twice is a no-op
- [ ] `make api-sqlc` generates a compiling `store` package; `make api-fmt &&
      make api-vet` clean
- [ ] Clean checkout with no `DATABASE_URL` → degraded-mode warning, no crash
