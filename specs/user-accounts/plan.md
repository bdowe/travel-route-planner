# Plan: User Accounts

> **HOW.** Translates `spec.md` into a file-level technical approach. See
> `../../CLAUDE.md` for repo conventions and `../data-foundation/plan.md` for the
> persistence layer this feature builds on. Every decision traces to an
> acceptance criterion.

## Technical Approach

Implement email/password authentication using DB-backed opaque session tokens
(not JWT). The `data-foundation` feature provides the pool, migrations, and
`store` package; this feature adds a second migration that fleshes out `users`
and creates `sessions`, new sqlc queries, and two new `package main` files
(`auth_handler.go`, `auth_service.go`) plus an auth middleware wired into
`main.go`.

Key decisions:

- **Opaque tokens over JWT.** Logout and expiry are trivially correct: deleting
  the row makes the token immediately invalid, no clock skew possible. The spec's
  `Session` data model maps 1:1 to this approach.
- **bcrypt for password hashing.** Industry standard in `golang.org/x/crypto`;
  never store or log plaintext (satisfies the spec's `password_credential`
  requirement).
- **Bearer token transport.** Client sends `Authorization: Bearer <token>` on
  every authenticated request; the middleware resolves it to a `*store.User`
  injected into the request context.
- **Selective route protection.** Existing optimizer/places/plan endpoints stay
  public; `/auth/logout` and `/auth/me` require auth via the middleware. Future
  trip endpoints will reuse the same middleware.
- **`flutter_secure_storage` for on-device token persistence.** Encrypted
  key-value store backed by Keychain (iOS/macOS) and Keystore (Android); falls
  back gracefully on web (localStorage with obfuscation). Survives app restarts,
  satisfying the session-persistence acceptance criterion.

## Go API Changes

`src/packages/api/` (all hand-written files remain `package main`):

### Migration — `migrations/00002_user_accounts.sql`

- Alter `users` table (created by `data-foundation`): add `email TEXT NOT NULL UNIQUE`
  (check constraint lowercases on insert/update via `LOWER(email)`),
  `password_hash TEXT NOT NULL`, `display_name TEXT` (nullable). The baseline
  migration already provides `id UUID PK`, `created_at`, `updated_at`, and the
  `set_updated_at` trigger.
- Create `sessions` table: `id TEXT PRIMARY KEY` (the opaque token — a
  `crypto/rand` hex string generated in Go, not a DB UUID), `user_id UUID NOT
  NULL REFERENCES users(id) ON DELETE CASCADE`, `expires_at TIMESTAMPTZ NOT
  NULL`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`. Index on `user_id` for
  logout-all-sessions queries later.

### sqlc queries

- **`query/users.sql`:** `CreateUser`, `GetUserByEmail`, `GetUserByID`.
- **`query/sessions.sql`:** `CreateSession`, `GetSessionWithUser` (JOIN returning
  both session and user fields — used by auth middleware), `DeleteSession`
  (logout), `DeleteExpiredSessions` (cleanup, called opportunistically).

Run `make api-sqlc` to regenerate `store/` after modifying queries.

### `auth_service.go` (`package main`)

- `hashPassword(plain string) (string, error)` — wraps `bcrypt.GenerateFromPassword`
  (cost 12).
- `checkPassword(hash, plain string) bool` — wraps `bcrypt.CompareHashAndPassword`.
- `generateSessionToken() (string, error)` — 32 random bytes from `crypto/rand`,
  hex-encoded → 64-char string.
- `issueSession(ctx, queries, userID uuid.UUID) (store.Session, error)` — calls
  `generateSessionToken`, sets `expires_at = now + 30 days`, calls
  `queries.CreateSession`.
- `validateEmail(email string) bool` — basic format check (stdlib `net/mail`).
- `defaultDisplayName(email string) string` — returns the local part before `@`.

### `auth_handler.go` (`package main`)

Structs (defined in this file):

```
RegisterRequest  { Email, Password, DisplayName *string }
LoginRequest     { Email, Password string }
AuthResponse     { User UserResponse; Token string }
UserResponse     { ID, Email, DisplayName string; CreatedAt time.Time }
```

Handlers:

- `registerHandler(w, r)` — decode `RegisterRequest`; validate email format and
  password length (min 8 chars); lowercase email; check for duplicate via
  `GetUserByEmail` (return 409 on conflict); hash password; `CreateUser`; call
  `issueSession`; return 201 + `AuthResponse`.
- `loginHandler(w, r)` — decode `LoginRequest`; blank-field check (422);
  `GetUserByEmail` + `checkPassword`; on any mismatch return generic 401 "invalid
  credentials"; call `issueSession`; return 200 + `AuthResponse`.
- `logoutHandler(w, r)` — extract token from context (set by middleware); call
  `DeleteSession`; return 204.
- `meHandler(w, r)` — extract `*store.User` from context; return 200 +
  `UserResponse`.

### Auth middleware — `main.go`

`authMiddleware(next http.Handler) http.Handler` (alongside `corsMiddleware` /
`loggingMiddleware`):

1. Read `Authorization` header; if missing/malformed return 401.
2. Call `queries.GetSessionWithUser(token)`; if not found or `expires_at` past
   return 401.
3. Call `queries.DeleteExpiredSessions` opportunistically (best-effort, no error
   propagation).
4. Inject `*store.User` into `context.WithValue`; call `next`.

A helper `userFromContext(ctx) *store.User` is added for use by handlers.

### Routes — `main.go`

Register under the existing `api` subrouter:

```
api.HandleFunc("/auth/register", registerHandler).Methods("POST")
api.HandleFunc("/auth/login",    loginHandler).Methods("POST")
api.HandleFunc("/auth/logout",   authMiddleware(http.HandlerFunc(logoutHandler)).ServeHTTP).Methods("POST")
api.HandleFunc("/auth/me",       authMiddleware(http.HandlerFunc(meHandler)).ServeHTTP).Methods("GET")
```

Add startup log line: `log.Println("Auth routes: POST /auth/register, /auth/login, /auth/logout  GET /auth/me")`.

### `go.mod` / `go.sum`

Add `golang.org/x/crypto` (for bcrypt) via `go mod tidy` / `make api-deps`.
`pgx/v5` and `goose` are already added by `data-foundation`.

## Flutter Changes

`src/packages/flutter-app/lib/`:

### Models — `models/user.dart` (hand-written; `.g.dart` generated)

```dart
@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  @JsonKey(name: 'display_name')
  final String displayName;       // never null in responses; server fills in default
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  ...
}

@JsonSerializable()
class AuthResponse {
  final UserModel user;
  final String token;
  ...
}
```

Run `make flutter-build-models` after writing/editing these files.

### Service — `services/auth_service.dart`

Wrap the four auth endpoints using the existing `ApiClient`. Methods:
`register(email, password, {displayName})` → `AuthResponse`,
`login(email, password)` → `AuthResponse`,
`logout()` → `void`,
`me()` → `UserModel`.

### Token storage — `services/auth_storage.dart`

Thin wrapper around `flutter_secure_storage` (`FlutterSecureStorage()`).
Methods: `saveToken(String token)`, `loadToken() Future<String?>`,
`clearToken()`. Key: `session_token`.

Add `flutter_secure_storage: ^9.x` to `pubspec.yaml`.

### Update `services/api_client.dart`

- `ApiClient` reads the stored token via `AuthStorage` and attaches
  `Authorization: Bearer <token>` on every request when a token is present.
- Expose `login`, `register`, `logout`, `me` methods (delegate to
  `AuthService`), or keep them in `AuthService` and inject `ApiClient` — choose
  the pattern that matches the existing service style (currently `ApiClient` is
  injected into other services; keep that: `AuthService` takes an `ApiClient`).
- On any 401 response, `ApiClient` clears the stored token and notifies the
  auth provider (via a callback/stream) so the app can redirect to login.

### Provider — `providers/auth_provider.dart`

`AuthNotifier extends AsyncNotifier<UserModel?>`:

- On init: `loadToken()` → if present, call `me()`; if 401 (expired), clear
  token and emit `null`.
- `login(email, password)` → call service, persist token, emit `UserModel`.
- `register(email, password, displayName)` → same pattern.
- `logout()` → call service (swallow 401), clear token, emit `null`.
- Expose `authState` as `AsyncValue<UserModel?>`.

`authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(...)`.

### Screens

- **`screens/auth_screen.dart`:** Standalone screen with tab/toggle for Sign Up
  / Log In. Sign Up: email, password, optional display name fields + "Create
  account" button. Log In: email, password + "Sign in" button. Spinner on
  in-flight requests. Inline field errors (blank, malformed email, short
  password). Server error banner near submit button. On success, `context.go()`
  to home (or the deep-link redirect target stored in provider state).
- **`screens/home_screen.dart` (modify existing):** Add display name / email in
  the app bar and a "Sign out" icon button that calls `authNotifier.logout()`.
- **Protected route gating:** In `main.dart` (or the router), wrap
  account-only routes with a guard: if `authState` is `null` (and not loading),
  redirect to `/auth` and store the attempted route as `redirectTo` in the auth
  provider state. After successful login/register, navigate to `redirectTo` or
  home.

## Contract Parity  ← anti-drift gate

Rules: optional Go fields (pointer / `omitempty`) → nullable Dart fields; JSON
tag on Go side must equal the `@JsonKey`/field name on Dart side.

### `POST /api/v1/auth/register` and `POST /api/v1/auth/login` — request bodies

| JSON key | Go type (`auth_handler.go`) | Dart type (`auth_service.dart`) | Nullable? | ✓ |
|----------|-----------------------------|---------------------------------|-----------|---|
| `email` | `string` | `String` | no | ☐ |
| `password` | `string` | `String` | no | ☐ |
| `display_name` | `*string` (register only) | `String?` (register only) | yes | ☐ |

### `AuthResponse` — shared response for register and login

| JSON key | Go type (`auth_handler.go`) | Dart type (`models/user.dart`) | Nullable? | ✓ |
|----------|-----------------------------|---------------------------------|-----------|---|
| `user` | `UserResponse` (struct) | `UserModel` | no | ☐ |
| `token` | `string` | `String` | no | ☐ |

### `UserResponse` / `UserModel` — embedded in `AuthResponse` and returned by `GET /auth/me`

| JSON key | Go type (`auth_handler.go`) | Dart type (`models/user.dart`) | Nullable? | ✓ |
|----------|-----------------------------|---------------------------------|-----------|---|
| `id` | `string` (UUID rendered as string) | `String` | no | ☐ |
| `email` | `string` | `String` | no | ☐ |
| `display_name` | `string` (never omitted — server fills default) | `String` | no | ☐ |
| `created_at` | `time.Time` (RFC 3339) | `DateTime` | no | ☐ |

> `display_name` is nullable at the DB level and optional in the request, but the
> server always resolves the default before writing and always includes it in
> responses — so the Dart side treats it as non-nullable `String`.

## Cross-cutting

- **Env vars:** no new env vars. `DATABASE_URL` (already in `.env.sample` from
  `data-foundation`) is the only dependency; `ANTHROPIC_API_KEY` and
  `GOOGLE_PLACES_API_KEY` are unchanged.
- **Gateway:** all four routes are under `/api/v1/auth/`; the nginx proxy rule
  `/api/v1/` already covers them — no proxy config change needed.
- **CORS:** `Authorization` header must be in the `Access-Control-Allow-Headers`
  list in `corsMiddleware` in `main.go`. Verify it is present; add if missing.
- **`make api-sqlc`:** must be run after adding `query/users.sql` and
  `query/sessions.sql`. The `store` package (already established by
  `data-foundation`) gains new generated files; no package-level changes needed.
- **`pubspec.yaml`:** add `flutter_secure_storage: ^9.x`. Run `flutter pub get`.

## Verification

(Mirrored into `tasks.md` as the final task group.)

1. `make api-fmt && make api-vet` — Go formatting and vet clean.
2. `make api-sqlc` — sqlc generation succeeds; `store/` package compiles.
3. `make flutter-build-models` then `make flutter-analyze` — codegen + analysis
   clean.
4. Manual end-to-end via `make docker-dev` → `http://localhost:3000`:

   ```bash
   # Register — expect 201 + token
   curl -s -X POST http://localhost:3000/api/v1/auth/register \
     -H 'Content-Type: application/json' \
     -d '{"email":"alice@example.com","password":"hunter22","display_name":"Alice"}' | jq .

   # Duplicate email — expect 409
   curl -s -X POST http://localhost:3000/api/v1/auth/register \
     -H 'Content-Type: application/json' \
     -d '{"email":"alice@example.com","password":"hunter22"}' | jq .

   # Login — expect 200 + token
   TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
     -H 'Content-Type: application/json' \
     -d '{"email":"alice@example.com","password":"hunter22"}' | jq -r .token)

   # Me — expect 200 + user profile
   curl -s http://localhost:3000/api/v1/auth/me \
     -H "Authorization: Bearer $TOKEN" | jq .

   # Me without token — expect 401
   curl -s http://localhost:3000/api/v1/auth/me | jq .

   # Logout — expect 204
   curl -s -X POST http://localhost:3000/api/v1/auth/logout \
     -H "Authorization: Bearer $TOKEN" -o /dev/null -w '%{http_code}'

   # Me after logout — expect 401
   curl -s http://localhost:3000/api/v1/auth/me \
     -H "Authorization: Bearer $TOKEN" | jq .
   ```

5. Flutter UI: open `http://localhost:3000`; verify Login/Signup screen appears
   when unauthenticated; complete register flow; confirm display name appears in
   app bar; sign out returns to Login/Signup screen; re-open tab — Login/Signup
   screen shown (token cleared, not persisted from a prior signed-in state after
   explicit logout).
6. Session persistence: sign in → close and reopen tab → confirm still signed in
   (token loaded from secure storage, `me` call succeeds on boot).
7. Existing endpoints (`/api/v1/optimize-route`, `/api/v1/places/search`,
   `/api/v1/plan`) return correct responses without an `Authorization` header
   (confirm no regression from middleware).
