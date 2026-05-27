# Spec: Data Foundation

> **Infrastructure exception:** This is an infra spec, not a feature spec.
> The "what" here is inseparable from the technology — naming PostgreSQL,
> pgx, sqlc, and goose is intentional and appropriate. This is the one
> category of spec where tech naming belongs here rather than in `plan.md`.

---

> **WHAT & WHY only** (within the infrastructure exception above). No file
> names, struct definitions, or code snippets.

## Context

The app is entirely stateless today. Every endpoint computes results on the fly
and returns them; nothing is saved between requests. This means the app cannot
remember a user, persist a trip across sessions, track booking state, or support
any personalized workflow. Every planned feature that follows — user accounts,
saved trips, itinerary building, booking history — requires a storage layer to
exist first.

This feature establishes that layer: a PostgreSQL database wired into the
development and deployment stacks, a migration system, a type-safe query layer,
and the minimal baseline schema that sibling features can build on. It also
surfaces database health in the existing health-check endpoint so problems are
visible immediately. Nothing else can be reliably built without this foundation
in place.

## User Stories

- As a **developer**, I want Postgres to start automatically when I run
  `make docker-dev` so that I never have to remember to spin up a separate
  database process.
- As a **developer**, I want schema migrations to apply automatically (either
  on API boot or via a single make target) so that the database is always in
  sync with the code without manual steps.
- As a **developer**, I want a type-safe query layer generated from plain SQL
  so that I can write ordinary SQL and get compile-time safety without an ORM.
- As a **developer running the stack**, I want the health endpoint to report
  whether the database is reachable so that I can immediately tell if the DB is
  the cause of a failure.
- As a **future feature implementer** (user-accounts, trip-model), I want a
  baseline `users` table and a skeleton `trips` table in place so that I can
  build on them without also having to set up the persistence layer from scratch.

## Acceptance Criteria

- [ ] `make docker-dev` brings up Postgres alongside Flutter, the API, and the
      gateway — no manual `docker run` step required.
- [ ] After `make docker-dev`, `GET /api/v1/health` returns HTTP 200 and the
      response body includes a `database` field with value `"ok"` when the DB is
      reachable.
- [ ] After `make docker-dev`, `GET /api/v1/health` returns HTTP 503 and the
      `database` field reflects a failure state if the database container is
      stopped or otherwise unreachable.
- [ ] Migrations run automatically on API boot **and** can also be run on demand
      via a `make api-migrate` target; applying them twice (re-run) is safe
      (idempotent).
- [ ] Running `sqlc generate` (or the equivalent make target) succeeds with no
      errors and produces type-safe Go query code that compiles cleanly.
- [ ] The database schema includes a `users` table (at minimum: surrogate primary
      key, created/updated timestamps) and a `trips` table skeleton (at minimum:
      surrogate primary key, a foreign key to `users`, created/updated
      timestamps); both tables exist after migrations run.
- [ ] `src/packages/api/.env.sample` documents all new environment variables
      required for database connectivity (URL, or host/port/user/password/dbname
      equivalents).
- [ ] The database connection is configurable via environment variable so the
      same binary can point at a local Docker Postgres, a CI Postgres, or a
      future managed/Supabase Postgres without recompilation.
- [ ] `make api-fmt && make api-vet` pass cleanly after the changes.
- [ ] The existing endpoints (`/optimize-route`, `/optimize-countries`,
      `/places/*`, `/plan`) continue to function exactly as before — this feature
      adds persistence infrastructure but does not change any existing behavior.

## API Surface

### `GET /api/v1/health`

This endpoint already exists. This feature augments its response to include
database status alongside the existing fields.

- **Purpose:** Indicates whether the API and its dependencies are healthy.
  Consumed by Docker health checks, monitoring, and developers diagnosing issues.
- **Request:** No body, no parameters.
- **Response:**
  - `status` — overall health string; `"healthy"` when all checks pass.
  - `timestamp` — the time the check was performed (existing field, unchanged).
  - `service` — service identifier string (existing field, unchanged).
  - `database` — new field; `"ok"` when the database is reachable and
    responding, or a short error string (e.g. `"unreachable"`) when it is not.
- **Errors:**
  - Returns HTTP 503 when database connectivity fails, so load balancers and
    Docker health checks can distinguish a degraded API from a healthy one.
    The response body still contains all fields; only the status code and the
    `database` value change.

*No other endpoints are added or changed by this feature.*

## Data Model

These are the baseline tables this feature establishes. The `user-accounts` and
`trip-model` sibling features will add columns and constraints on top of them —
this feature provides only the structural skeleton.

- **User** — represents a person who uses the application. Fields at baseline:
  a unique surrogate **UUID** identifier (chosen over serial integers to keep IDs
  portable and non-guessable), and created/updated timestamps. All user-identity
  fields (email, name, auth credentials) are added by the `user-accounts` feature.

- **Trip** — represents a travel plan belonging to a user. Fields at baseline:
  a unique surrogate identifier, a foreign key reference to the owning user
  (non-nullable — every trip must have an owner), and created/updated
  timestamps. All trip-content fields (name, locations, dates, status) are added
  by the `trip-model` feature.

Both tables use server-managed `created_at` and `updated_at` timestamps with
timezone; `updated_at` should be kept current automatically (via a trigger or
equivalent) so callers never have to set it manually.

The schema is intentionally minimal here. Adding columns later via additive
migrations is straightforward; getting the ownership relationship and identifier
strategy right at the start is what matters.

## UI Behavior

This feature is backend infrastructure only. There are no new screens, no new
UI states, and no changes to the Flutter app. The health-check improvement is
observable via `curl` or browser developer tools, not through the application
UI.

## Edge Cases & Error States

- **Database unreachable at API boot:** The API must still start and serve
  existing stateless endpoints. The health check should report the DB as
  unhealthy, but route-optimization, places, and plan endpoints must not be
  broken by a missing DB connection at startup.
- **Database unreachable mid-run:** If the database becomes unreachable after a
  successful boot (e.g. the Postgres container is stopped), the health endpoint
  should reflect this on the next poll. Existing stateless endpoints continue to
  function. Endpoints that require the DB (added by future features) should
  return a clear 503 rather than a confusing 500.
- **Migration failure at boot:** If migrations fail (e.g. due to a bad migration
  file or a version conflict), the failure must be logged clearly and the process
  must exit with a non-zero code — silent failure is unacceptable. The Docker
  health check will then catch the unhealthy state.
- **Re-running migrations:** Applying migrations to a database that is already
  at the latest version must be safe and produce no errors (idempotent). This
  covers the case where the API container restarts against an already-migrated
  database.
- **Connection pool exhaustion:** The connection pool has a configured maximum.
  Requests that cannot acquire a connection within a reasonable timeout should
  receive a 503, not hang indefinitely.
- **Missing environment variables:** If required database credentials are absent
  at startup, the API must log a clear error identifying which variable is
  missing and exit — not panic with an opaque nil-pointer crash.
- **Blank / development environment:** Developers who have not yet configured a
  `DATABASE_URL` (or equivalent) should get a clear log message explaining what
  is missing, matching the existing pattern for `GOOGLE_PLACES_API_KEY` and
  `ANTHROPIC_API_KEY`.

## Out of Scope

- User authentication, sessions, or JWT tokens — those belong to `user-accounts`.
- Any application logic that reads from or writes to the database — this feature
  wires up the connection and baseline schema only. The first real reads/writes
  come from sibling features.
- Adding database fields to any existing endpoint response other than
  `/api/v1/health`.
- Row-level security, multi-tenancy, or database-level auth beyond a single
  application user.
- Database backups, point-in-time recovery, or replication — operational
  concerns for a production hardening phase.
- A managed or cloud-hosted Postgres service (e.g. Supabase, RDS) — the design
  keeps portability in mind, but this feature targets local Docker only.
- Read replicas or connection pooling middleware (e.g. PgBouncer).
- Any changes to the Flutter app.

## Resolved Decisions

- **Migration tool — goose.** Go-native, supports both SQL and Go migrations,
  widely used. (golang-migrate was the alternative.)
- **When migrations run — on boot *and* on demand.** They apply automatically
  when the API starts (convenient for local dev and Docker restarts) and are also
  runnable via a `make api-migrate` target. A bad migration still surfaces via the
  boot-failure handling in Edge Cases.
- **Connection config — single `DATABASE_URL`.** One connection string (e.g.
  `postgres://user:pass@host:5432/dbname`), documented in `.env.sample`. Chosen for
  portability across local Docker, CI, and a future managed/Supabase Postgres.
- **Connection pool — max 10 connections, 5s acquire timeout** as documented
  defaults; revisit if load testing warrants.
- **Primary keys — UUID.** Portable, non-sequential, safe to expose in URLs.
