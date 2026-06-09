# Spec: Flights & Transport

> **WHAT & WHY only.**

## Context

After Phase 3 a trip has stays and after Phase 4 the itinerary is tagged by
category, but the app says nothing about **how the traveler gets there or
between destinations**. This feature adds **travel segments** attached to a
trip — flights and ground transport (trains, buses, cars, ferries) — surfaced as
deep-link handoffs to Google Flights, Kayak, and Rome2Rio. The traveler browses
real options on those sites and saves the chosen segments to the trip; the
provider-agnostic interface keeps the door open for a real flight API
(Duffel/Amadeus) in Phase 6 when booking matters. Depends on trips + accounts.

## User Stories

- As a **traveler**, I want to open Google Flights / Kayak pre-filled with my
  origin, destination, and dates so I can browse real flight options.
- As a **traveler**, I want Rome2Rio links between destinations for trains,
  buses, and other ground transport.
- As a **traveler**, I want to save the flights and other segments I've chosen
  to my trip, including for multi-leg journeys.
- As a **traveler**, I want to remove a saved segment.

## Acceptance Criteria

- [ ] For a (mode, origin, destination, dates) input, the app returns the right
      deep links per mode: flight → Google Flights + Kayak; ground → Rome2Rio.
- [ ] A signed-in user can add one or more segments to their own trip; they
      appear in the trip detail.
- [ ] A user can delete a saved segment.
- [ ] A user cannot modify segments on another user's trip.
- [ ] The agent can surface the same browse links during planning.

## API Surface

- `GET /api/v1/transport-links?mode=flight|ground&origin=&destination=&depart_date=&return_date=&passengers=`
  → list of `{provider, mode, url}`. No auth required.
- `POST /api/v1/trips/{id}/segments` (auth, owner) → add; returns it.
- `DELETE /api/v1/trips/{id}/segments/{segmentId}` (auth, owner) → 204.
- `GET /api/v1/trips/{id}` (existing) now also returns a `segments` list.

## Data Model

- **Travel Segment** — belongs to a trip (many per trip). Fields: mode
  (flight/train/bus/car/ferry/other); origin / destination (city or airport
  names); depart date / arrive date (optional); provider (free text — airline,
  rail operator); url (optional); price note; notes.

## UI Behavior

- **Trip detail → Travel section** (between Stays and Itinerary): lists saved
  segments chronologically by depart_date with mode-aware icons; **Find flights**
  and **Find ground transport** actions open dialogs that ask for origin (text
  input — destination/dates pre-filled from the trip), fetch links, and launch
  the provider; **Add a segment** for manual entry; delete per segment.
- **Agent:** when discussing how to get there, surfaces "Browse on Google
  Flights / Kayak / Rome2Rio" links (no in-app prices).

## Edge Cases & Error States

- Missing required query params on the links endpoint → 400.
- Adding/deleting on a trip you don't own → 404 (existence not leaked).
- Unauthenticated trip-scoped calls → 401.
- An invalid `arrive_date` before `depart_date` → 400 on add.
- Empty segments list → trip detail renders a "no travel added yet" state.

## Out of Scope

- Real-time flight pricing/availability, in-app booking (Duffel/Amadeus
  integration deferred to Phase 6).
- Time-of-day on segments (dates only this phase).
- Auto-ordering itinerary by segment dates; route optimization.
- A home-airport preference on the traveler profile (worth a follow-up).
- Notifications / calendar sync.

## Resolved Decisions

- **Source:** Google Flights + Kayak for flights, Rome2Rio for ground transport,
  all via **deep-link handoff**; provider-agnostic interface so a listing
  API can slot in later.
- **Multiple** segments per trip; unified `trip_segments` table tagged by `mode`.
- **No times** this phase — dates only.
