# Spec: Activities & Dining

> **WHAT & WHY only.**

## Context

The agent already personalizes recommendations (Phase 2) and saves them as
itinerary items on a trip (Phase 1) — but every item looks the same in the UI,
and dining tends to get crowded out by sightseeing in the agent's responses.
This feature tags each itinerary item as **attraction** or **restaurant** so
travelers can see at a glance what the trip mixes in, filter the list, and trust
that dining gets equal billing. It fulfills both `activity-recommendations` and
`dining-recommendations` from the vision roadmap in a single, infrastructure-shared
feature. Depends on trips + traveler preferences.

## User Stories

- As a **traveler**, I want the agent to suggest a mix of activities and dining
  shaped by my interests, budget, and pace.
- As a **traveler**, I want to see at a glance whether an itinerary item is a
  place to go or a place to eat.
- As a **traveler**, I want to filter my trip to just attractions or just
  restaurants.

## Acceptance Criteria

- [ ] When the agent finalizes an itinerary for a signed-in user, each saved
      item is tagged `attraction` or `restaurant` where applicable; tags
      survive reloads.
- [ ] The trip detail screen shows a different icon per category and a leading
      number for un-tagged items (existing behavior preserved).
- [ ] A filter row on the trip detail narrows the list to All / Attractions /
      Restaurants without re-fetching.
- [ ] The agent's responses (in a typical planning session) include both kinds
      of places.

## API Surface

No new endpoints. `GET /api/v1/trips/{id}` returns each item's `category`
(string, nullable) alongside existing fields; omitted when null. The agent's
`create_itinerary` tool gains a per-location optional `category` enum
(`attraction` | `restaurant`).

## Data Model

- **Itinerary Item** gains an optional **category**:
  - `attraction` — places to visit (museums, parks, viewpoints, …)
  - `restaurant` — places to eat
  - unset/null — generic, treated as "un-tagged" in the UI

The allowed set is enforced by the application, not the database, so adding
categories later doesn't require a migration.

## UI Behavior

- **Trip detail items:**
  - leading icon: `restaurant` → restaurant icon, `attraction` → attractions
    icon, null → existing numbered avatar.
  - a single-row filter chip set above the items: **All** (default), **Attractions**,
    **Restaurants**. Selecting one filters client-side.
- **Agent:** no new screen; behavior changes are implicit (better mix, tagged
  outputs, surfaced as the existing tool-call/done events).

## Edge Cases & Error States

- Pre-Phase-4 items have `category = null` — they render with the existing
  numbered avatar and appear under **All** only.
- The agent sends an unrecognized category value → server normalizes (lowercase,
  trim) and drops if not in the allowed set; the item still saves, just without
  a category.
- Filter narrows to zero items → list shows an "no items match this filter" note.

## Out of Scope

- More categories (cafe / nightlife / outdoor / shopping); free-form tags.
- Manual "Add a place" UI; itinerary item hand-editing.
- Time-of-day slots for dining; day-by-day scheduling.
- Explicit ranking metrics — personalization remains via the agent's prompt.

## Resolved Decisions

- **Categories:** minimal — `attraction` and `restaurant` only.
- **Capture:** agent-only this phase (matches the trip-model deferral of
  itinerary hand-editing).
- **Enforcement:** application-level, not a DB check constraint.
