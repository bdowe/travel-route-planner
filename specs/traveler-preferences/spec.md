# Spec: Traveler Preferences

> **WHAT & WHY only.** No tech choices, file names, libraries, or code.

## Context

The AI agent treats every traveler the same — it has no memory of what kind of
trips you like, so it can't personalize. This feature gives each user a **global
preference profile** (budget, pace, interests) that the agent reads to tailor its
suggestions and can update as it learns about you, and that you can edit directly
in a form. It's the "gets to know you" pillar of the vision and feeds the ranking
in later phases (accommodations, activities, dining). Depends on user accounts
(identity) and the persistence layer.

## User Stories

- As a **traveler**, I want to set my budget level, trip pace, and interests so
  the agent suggests trips that fit me.
- As a **traveler**, I want the agent to remember preferences I mention in
  conversation so I don't have to repeat myself.
- As a **traveler**, I want to view and edit my saved preferences at any time.

## Acceptance Criteria

- [ ] A signed-in user can view their preferences; before they set anything, the
      profile is empty (no budget/pace, no interests).
- [ ] A signed-in user can set/update budget, pace, and interests and have them
      persist across sessions.
- [ ] When a signed-in user plans with the agent, the agent's suggestions reflect
      their saved preferences (e.g. a "luxury / relaxed / food" profile yields
      different suggestions than "budget / packed / museums").
- [ ] When the agent learns a preference mid-conversation, it saves it; the change
      is visible afterward in the preferences form.
- [ ] Updating only some fields leaves the others unchanged (partial updates merge).
- [ ] Preference endpoints require authentication; unauthenticated requests are rejected.
- [ ] Anonymous agent use still works and simply isn't personalized.

## API Surface

All endpoints require authentication.

### `GET /api/v1/preferences`
- **Purpose:** return the signed-in user's preference profile.
- **Response:** `budget` (string or null), `pace` (string or null), `interests`
  (list of strings, empty if none). Returns empty defaults if never set.

### `PUT /api/v1/preferences`
- **Purpose:** create or update the profile.
- **Request:** any of `budget`, `pace`, `interests`. Omitted fields are left
  unchanged (partial/merge). Sending an empty `interests` list clears interests.
- **Response:** the updated profile (same shape as GET).
- **Errors:** `400` if `budget`/`pace` is outside its allowed set; `401` if unauthenticated.

## Data Model

- **Traveler Preferences** — one profile per user (1:1). Fields:
  - *Budget* — overall spending level; one of a small fixed set (budget / mid /
    luxury); optional/unset.
  - *Pace* — how packed the days should be; one of a small fixed set (relaxed /
    balanced / packed); optional/unset.
  - *Interests* — a list of free-form theme tags (e.g. museums, food, nightlife,
    nature); may be empty.

## UI Behavior

- **Travel profile screen:** reached from the account menu. Budget and pace shown
  as single-select controls; interests as selectable/add-able chips. A Save action
  persists changes. Loading and error states handled; the form pre-fills with the
  current profile.
- **In the agent:** no new screen — personalization is implicit. When the agent
  saves a preference it learned, it surfaces the same activity indicator used for
  its other tools.

## Edge Cases & Error States

- No profile yet → GET returns empty defaults (not an error).
- Partial update must not wipe untouched fields.
- Invalid budget/pace value → `400` with a clear message.
- Unauthenticated request to preferences → `401`.
- Anonymous agent session → no personalization, no save; the conversation works as before.
- Duplicate/whitespace interest tags are trimmed/de-duplicated.

## Out of Scope

- Dietary/accessibility and travel-party fields (cut from this phase).
- Per-trip preference overrides (global profile only).
- Using preferences to *rank* accommodations/activities/dining — that's later
  phases; here preferences only feed the agent's context and are stored.

## Resolved Decisions

- **Capture:** both a form (explicit edit) and agent read/write (the agent can
  save preferences it learns).
- **Scope:** one global profile per user; no per-trip overrides.
- **Fields:** budget, pace, interests only.
- **Merge semantics:** partial updates merge (omitted = unchanged; empty interests
  list = clear).
