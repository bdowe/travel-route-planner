# Spec: User Accounts

> **WHAT & WHY only.** No tech choices, file names, libraries, or code. If a
> sentence names a file or a package, it belongs in `plan.md`, not here.

## Context

The app is currently fully stateless — every session is anonymous and nothing
is remembered between visits. Turning it into a "travel agent" product requires
identity: saved trips, travel preferences, and (later) bookings all need an
owner. This feature introduces user accounts and authentication as the identity
foundation for every subsequent personalization feature. It depends on the
`data-foundation` feature, which supplies the relational database and the
baseline `users` table.

## User Stories

- As a **new visitor**, I want to create an account with my email and a password
  so that my trips and preferences are saved to me.
- As a **returning user**, I want to sign in with my email and password so that
  I can access my saved data.
- As a **signed-in user**, I want to sign out so that my account is not
  accessible on a shared device.
- As a **signed-in user**, I want the app to remember my session across
  page refreshes and app restarts so that I am not forced to log in every time.
- As a **developer or downstream feature**, I want a way to retrieve the
  currently authenticated user's profile so that other features can display and
  personalize content for them.
- As a **signed-out user** who tries to access a protected screen, I want to be
  redirected to sign in so that the experience is clear and not broken.

## Acceptance Criteria

The definition of done — observable, testable outcomes.

**Registration**
- [ ] A user can register by providing a valid email address and a password that
      meets minimum length requirements; on success, the user is signed in
      immediately.
- [ ] Registration fails with a clear error message if the email address is
      already associated with an existing account.
- [ ] Registration fails with a clear error message if the email is malformed.
- [ ] Registration fails with a clear error message if the password does not
      meet minimum requirements.

**Login**
- [ ] A registered user can sign in with their correct email and password; on
      success, they are taken to the main app screen.
- [ ] Login fails with a clear, non-specific error message when the email or
      password is incorrect (no hint as to which is wrong).
- [ ] Login fails with a clear error message if either field is blank.

**Session persistence**
- [ ] After signing in, the user remains signed in across page refreshes and
      full app restarts without re-entering credentials.
- [ ] A session lasts **30 days** from issuance; once expired, the next request
      that requires authentication returns a session-expired error and the user is
      prompted to sign in again.

**Logout**
- [ ] A signed-in user can sign out; after signing out they cannot access
      protected screens and any stored session credential on the device is
      cleared.

**Current user**
- [ ] The API exposes an endpoint that returns the authenticated user's profile
      (id, email, display name, account creation date) when called with a valid
      session; it rejects the request with an authentication error when called
      without one.

**Protected endpoints**
- [ ] Any API endpoint marked as requiring authentication returns an
      authentication-required error (distinct from a generic server error) when
      called without a valid session.
- [ ] The Flutter app does not surface account-only screens or actions to a
      signed-out user; navigating to a protected route redirects to the
      login/signup screen instead.

## API Surface

### `POST /api/v1/auth/register`
- **Purpose:** Create a new user account and establish an authenticated session.
- **Request:** `email` (string, required) — the user's email address; `password`
  (string, required) — the chosen password; `display_name` (string, optional) —
  a human-readable name to show in the UI, defaults to the email local part if
  omitted.
- **Response:** The created user's `id`, `email`, `display_name`, and
  `created_at` date, plus a session credential the client must present on
  subsequent authenticated requests.
- **Errors:** `409 Conflict` when the email is already registered; `422
  Unprocessable Entity` when input validation fails (malformed email, password
  too short), with a message describing which field failed.

---

### `POST /api/v1/auth/login`
- **Purpose:** Authenticate an existing user and establish a session.
- **Request:** `email` (string, required); `password` (string, required).
- **Response:** The user's `id`, `email`, `display_name`, and `created_at`, plus
  a session credential.
- **Errors:** `401 Unauthorized` when credentials are invalid (message must not
  reveal whether the email or the password was wrong); `422 Unprocessable
  Entity` when either field is blank.

---

### `POST /api/v1/auth/logout`
- **Purpose:** Invalidate the current session so the credential can no longer be
  used.
- **Auth required:** Yes.
- **Request:** No body; the session credential is presented through the standard
  authenticated request mechanism.
- **Response:** Empty success response.
- **Errors:** `401 Unauthorized` if no valid session is present (idempotent from
  the user's perspective — the app treats any non-success as "already logged
  out").

---

### `GET /api/v1/auth/me`
- **Purpose:** Return the currently authenticated user's profile.
- **Auth required:** Yes.
- **Request:** No body; authentication credential in the request.
- **Response:** `id`, `email`, `display_name`, `created_at`.
- **Errors:** `401 Unauthorized` when the session is absent, invalid, or
  expired.

## Data Model

- **User** — represents a person with a registered account. Key fields:
  - `id` — unique, system-assigned identifier; never changes.
  - `email` — the user's login email address; unique across all users;
    normalized to lowercase.
  - `password_credential` — a securely stored representation of the user's
    password (the plain-text password is never stored or logged).
  - `display_name` — the name shown in the UI; may be updated by the user later;
    optional at creation.
  - `created_at` — when the account was created; set once, never updated.

- **Session** — represents an active authenticated session tied to a User. Key
  fields:
  - `id` — the credential presented by the client on every authenticated request.
  - `user_id` — the User this session belongs to.
  - `expires_at` — the point in time after which the session is no longer valid
    (30 days after issuance).
  - `created_at` — when the session was issued.

  Sessions are invalidated explicitly on logout and implicitly once `expires_at`
  is passed.

## UI Behavior

### Login / Signup Screen
- **Where:** A standalone screen that is the entry point for unauthenticated
  users. The app opens here when no valid session exists on the device.
- **Layout:** Tabs or toggle to switch between "Sign up" and "Log in" modes; both
  show email and password fields. Sign up additionally shows an optional display
  name field.
- **Happy path (sign up):** User fills in email, password, and optionally a
  display name → taps "Create account" → spinner while the request is in flight
  → on success, navigates to the main app screen as a signed-in user.
- **Happy path (log in):** User fills in email and password → taps "Sign in" →
  spinner → on success, navigates to the main app screen.
- **Error states:** Inline validation messages appear beneath the relevant field
  (blank field, malformed email, password too short). Server errors (wrong
  credentials, email taken) appear as a visible error message near the submit
  button. The form remains editable so the user can correct and retry.

### Main App (signed-in state)
- **Session indicator:** The app bar or navigation area shows the user's display
  name (or email) and a "Sign out" affordance (e.g. account menu or icon button).
- **Sign out flow:** Tapping "Sign out" → confirmation if desired → calls logout
  → clears local session storage → returns user to the Login/Signup screen.

### Protected Routes
- Any screen that requires authentication (trip history, preferences, etc.)
  is not reachable while signed out. Attempting to navigate there redirects
  to the Login/Signup screen. After a successful sign-in the user is forwarded
  to the screen they originally tried to reach.

### Session Expiry
- If the stored session is expired when the app launches, the user is taken
  directly to the Login/Signup screen with an informational message that their
  session has expired.
- If a session expires mid-use (i.e., an API call returns an auth error), the
  app presents the Login/Signup screen. After re-authenticating, the user
  returns to where they were.

## Edge Cases & Error States

- **Duplicate email on signup:** Server returns a conflict error; the UI displays
  a message such as "An account with this email already exists" and offers a
  direct link or button to the login form.
- **Wrong credentials on login:** Server returns a generic "invalid credentials"
  error; the UI must not distinguish between a wrong email and a wrong password
  (prevents account enumeration).
- **Blank fields submitted:** Client-side validation catches blank email or
  password before the request is sent and shows a field-level message.
- **Expired session:** Calling any authenticated endpoint with an expired session
  returns `401`; the app treats this identically to being logged out.
- **Tampered or invalid session credential:** Returns `401`; client clears the
  stored credential and redirects to Login/Signup.
- **Network failure during login/signup:** The UI shows a generic "something went
  wrong, please try again" error and leaves the form intact; no session is stored.
- **Logout with already-invalid session:** The server returns `401`; the client
  treats this as a successful logout (clears local credential and navigates to
  Login/Signup) since the intended end-state is the same.
- **Concurrent sessions:** Not addressed in this feature; no limit on the number
  of simultaneous sessions per user.

## Out of Scope

- Password reset / forgot-password flow (email delivery not yet available).
- Email verification after signup.
- Social / OAuth login (Google, Apple, etc.).
- Account deletion or data export.
- Profile editing (changing email, display name, or password) — identity only,
  no settings UI.
- Role-based access control or admin accounts.
- Rate limiting on login attempts (security hardening — deferred).
- Multi-factor authentication.

## Resolved Decisions

- **Password reset — deferred.** Needs email-delivery infrastructure we don't
  have yet; out of scope for Phase 1.
- **Email verification — deferred.** Accounts are usable immediately on signup;
  verification comes in a later phase (also needs email delivery).
- **Session lifetime — 30 days absolute** from issuance, then re-authenticate.
- **Social login — out of scope** for Phase 1 (email + password only).
- **Display name — optional** at signup; defaults to the email local part when
  omitted.
- **Post-login redirect — return to the originally requested route** on the web
  build (deep-link friendly); otherwise land on the home screen.
