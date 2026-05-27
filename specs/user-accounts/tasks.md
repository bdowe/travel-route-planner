# Tasks: User Accounts

> Dependency-ordered. `[P]` = can run in parallel with its siblings (no shared
> files / no ordering dependency). Work top to bottom; verification is last.
> Depends on `data-foundation` being implemented first (pool, `store` package,
> migration 00001 in place).

## Database & codegen (Go)

- [ ] Write `migrations/00002_user_accounts.sql`: flesh out `users` table
      (add `email`, `password_hash`, `display_name` columns + unique/lowercase
      constraint) and create `sessions` table with `id`, `user_id`, `expires_at`,
      `created_at` (see plan for full schema).
- [ ] Write `query/users.sql`: `CreateUser`, `GetUserByEmail`, `GetUserByID`.
- [ ] Write `query/sessions.sql`: `CreateSession`, `GetSessionWithUser`,
      `DeleteSession`, `DeleteExpiredSessions`.
- [ ] Run `make api-sqlc` — confirm `store/` regenerates cleanly and compiles.

## API service & handlers (Go)

- [ ] Add `golang.org/x/crypto` to `go.mod` via `go mod tidy` / `make api-deps`.
- [ ] Write `auth_service.go` (`package main`): `hashPassword`, `checkPassword`,
      `generateSessionToken`, `issueSession`, `validateEmail`,
      `defaultDisplayName`.
- [ ] Write `auth_handler.go` (`package main`): define `RegisterRequest`,
      `LoginRequest`, `AuthResponse`, `UserResponse` structs; implement
      `registerHandler`, `loginHandler`, `logoutHandler`, `meHandler`.
- [ ] Add `authMiddleware` and `userFromContext` helper to `main.go` (alongside
      existing middleware). Verify `Authorization` is in `corsMiddleware` allowed
      headers — add if missing.
- [ ] Register the four auth routes in `main.go` and add startup log line.

## Models & codegen (Flutter)

- [ ] Add `flutter_secure_storage: ^9.x` to `pubspec.yaml`; run `flutter pub get`.
- [ ] [P] Hand-write `models/user.dart`: `UserModel` and `AuthResponse` with
      correct `@JsonKey` annotations (`display_name`, `created_at`).
- [ ] [P] Write `services/auth_storage.dart`: thin `FlutterSecureStorage` wrapper
      (`saveToken`, `loadToken`, `clearToken`).
- [ ] Run `make flutter-build-models` to regenerate `models/user.g.dart`.
- [ ] Complete the Contract Parity table in `plan.md` (every row ✓).

## UI (Flutter)

- [ ] [P] Write `services/auth_service.dart`: wrap `register`, `login`, `logout`,
      `me` using the existing `ApiClient`.
- [ ] [P] Update `services/api_client.dart`: attach `Authorization: Bearer <token>`
      when a token is stored; on 401 response clear token and signal auth provider.
- [ ] Write `providers/auth_provider.dart`: `AuthNotifier extends AsyncNotifier<UserModel?>`;
      on init load token → call `me` (or clear on 401); expose `login`, `register`,
      `logout` methods.
- [ ] Write `screens/auth_screen.dart`: tab/toggle Sign Up / Log In; email +
      password + optional display name fields; spinner on in-flight; inline field
      errors; server error banner; on success navigate to home (or deep-link target).
- [ ] Update `screens/home_screen.dart`: show display name / email in app bar;
      add "Sign out" icon button wired to `authNotifier.logout()`.
- [ ] Add protected-route guard in router/`main.dart`: redirect unauthenticated
      navigations to `/auth`; store `redirectTo` in auth provider state; after
      login navigate to `redirectTo` or home.
- [ ] Handle all auth error states in UI: blank fields (client-side 422), malformed
      email, password too short, duplicate email (409), wrong credentials (401),
      expired session mid-use (401 from `ApiClient`), network failure.

## Verification

- [ ] `make api-fmt && make api-vet` clean.
- [ ] `make api-sqlc` succeeds; generated `store/` package compiles.
- [ ] `make flutter-build-models` then `make flutter-analyze` clean.
- [ ] `curl` end-to-end against `http://localhost:3000` (see plan Verification
      section for the full command sequence): register → 201, duplicate → 409,
      login → 200 + token, `me` with token → 200, `me` without → 401, logout → 204,
      `me` after logout → 401.
- [ ] Flutter UI smoke test: unauthenticated open → Auth screen; register flow →
      home with display name in app bar; sign out → Auth screen; reopen tab →
      Auth screen (token cleared).
- [ ] Session persistence smoke test: sign in → close/reopen tab → still signed in.
- [ ] Regression: existing public endpoints (`/optimize-route`, `/places/search`,
      `/plan`) respond correctly without `Authorization` header.
