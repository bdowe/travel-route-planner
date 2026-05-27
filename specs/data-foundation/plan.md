# Plan: Data Foundation

> **HOW.** Translates `spec.md` into a file-level technical approach. See
> `../../CLAUDE.md` for repo conventions. The locked decisions live in the spec's
> **Resolved Decisions** section (goose, single `DATABASE_URL`, pool 10/5s, UUID
> PKs, migrate-on-boot + `make api-migrate`).

## Technical Approach

Introduce a Postgres persistence layer the rest of Phase 1 builds on, with the
smallest possible surface: a connection pool, an embedded migration that creates
the baseline schema, code generation wired up, and a DB-aware health check. No
business reads/writes yet — those come with `user-accounts` and `trip-model`.

- **Driver/pool:** `pgx/v5` + `pgxpool`. One shared pool created at startup.
- **Migrations:** `goose/v3`, SQL migrations embedded in the binary via `embed.FS`
  (so the container needs no migration files on disk). Run on boot *and* via
  `make api-migrate`.
- **Codegen:** `sqlc` generates type-safe Go models/queries from the schema.
- **Degraded-start reconciliation** (resolves the tension between the spec's
  "missing env → exit" and "API must still serve stateless endpoints" edge cases):
  - `DATABASE_URL` **missing/empty** → log a clear warning (same pattern as
    `GOOGLE_PLACES_API_KEY`/`ANTHROPIC_API_KEY`) and start in **degraded mode**
    (no pool); stateless endpoints keep working; health reports DB down (503).
  - `DATABASE_URL` set but **DB unreachable** at boot → same degraded start,
    health 503.
  - Migrations **fail** against a configured, reachable DB → log and **exit
    non-zero** (a real deployment error, not a degraded condition).

## Go API Changes

`src/packages/api/` (handlers stay `package main`; generated DB code is the first
deliberate sub-package — see note):

- **New `db.go`** (`package main`): package-level `var dbPool *pgxpool.Pool`;
  `initDB(ctx, url)` parses config, sets `MaxConns=10` and a 5s acquire timeout,
  connects, and `Ping`s; `runMigrations(url)` opens a `database/sql` handle via
  `pgx/v5/stdlib`, calls `goose.SetBaseFS(embeddedMigrations)` + `goose.Up`.
- **New `migrations/00001_baseline.sql`** (goose `-- +goose Up`/`Down`): create
  `users` and `trips` skeletons with **UUID** PKs (`gen_random_uuid()`, built into
  PG >=13 — no `pgcrypto` extension needed), `created_at`/`updated_at timestamptz`,
  `trips.user_id` FK -> `users(id)` (NOT NULL), plus a `set_updated_at()` trigger
  function and triggers on both tables. Embedded via `//go:embed migrations/*.sql`.
- **New `sqlc.yaml`** + **`query/`** dir: engine `postgresql`, schema = the
  migrations, output to a `store` package (see note). `query/` starts minimal —
  sqlc generates the baseline `User`/`Trip` models from the schema; real queries
  arrive with the sibling features.
- **`main.go`:** in `main()`, read `DATABASE_URL`, apply the degraded-start logic
  above, run migrations, assign `dbPool`. Augment `healthHandler` to `Ping` the
  pool and add a `database` field; add `Database string` (json:"database") to
  `HealthResponse`; return **503** when the pool is nil or the ping fails.
- **`go.mod`/`go.sum`:** add `jackc/pgx/v5` and `pressly/goose/v3` via
  `make api-deps` (`go mod tidy`).

> **Note — first non-`main` package.** sqlc output lives in
> `src/packages/api/store/` (`package store`), a deliberate exception to the
> "all files `package main`" convention for *generated* persistence code.
> Hand-written API/handler files stay `package main`. Update `CLAUDE.md` to record
> this when implementing.

## Flutter Changes

**None.** This is backend infrastructure. The only response change is `/health`
gaining a `database` field, which is consumed by curl/Docker health checks, not a
typed Dart model (confirm no health model exists during implementation; if one
does, add the field).

## Contract Parity

Minimal — no new request/response models cross Go<->Dart. The single changed
response:

| JSON key | Go type (`main.go` `HealthResponse`) | Dart type | Nullable? | ✓ |
|----------|--------------------------------------|-----------|-----------|---|
| `database` | `string` | (no typed model — untyped health check) | n/a | [ ] |

## Cross-cutting

- **Env:** add `DATABASE_URL=postgres://travel:travel@localhost:5432/travel_planner?sslmode=disable`
  to `src/packages/api/.env.sample` (in Docker the host is the `postgres` service name).
- **Docker:** add a `postgres` service (`postgres:16-alpine`, `POSTGRES_USER/PASSWORD/DB`,
  named volume, `pg_isready` healthcheck) on `travel-planner-network` in **both**
  `dockerize/development/docker-compose.yml` and `dockerize/deployment/docker-compose.yml`.
  Give the `api` service `DATABASE_URL` (pointing at `postgres:5432`) and
  `depends_on: postgres: { condition: service_healthy }`.
- **Makefile:** add `api-migrate` (run goose up) and `api-sqlc` (`sqlc generate`)
  targets; note sqlc/goose as dev tools.
- **Gateway:** no change — `/api/v1/*` already proxied.

## Verification

(Mirrors the spec's verification; mirror into `tasks.md` when starting.)

1. `make docker-dev` brings up `postgres` alongside chrome/api/flutter/gateway;
   migrations apply on boot; `GET http://localhost:3000/api/v1/health` returns 200
   with `database: "ok"`.
2. Stop the `postgres` container -> health returns **503** with a DB failure value;
   `/optimize-route`, `/places/*`, `/plan` still respond (degraded mode).
3. Restart API against an already-migrated DB -> boot succeeds (migrations
   idempotent). `make api-migrate` run twice is a no-op the second time.
4. `make api-sqlc` (sqlc generate) succeeds and the generated `store` package
   compiles; `make api-fmt && make api-vet` clean.
5. `.env.sample` documents `DATABASE_URL`; a clean checkout with no `DATABASE_URL`
   starts in degraded mode with a clear warning (not a crash).
