# Spec: Traveler Profile Notes (knowledge that refines over time)

> **WHAT & WHY only.** No tech choices, file names, libraries, or code.

## Context

The agent's knowledge of a traveler is limited to four structured fields
(budget, pace, interests, home airport). Everything else it learns while
planning — travel companions, dietary needs, accommodation style, dislikes —
evaporates when the session ends. This feature adds a **free-text profile**
the agent maintains and refines across trips: it records durable facts the
moment the traveler reveals them, and after each trip is planned it distills
the whole conversation for anything it missed. The traveler can always see
and edit what's been learned. Builds on traveler-preferences (profile storage
and agent read/write) and user accounts.

## User Stories

- As a **traveler**, when I mention something durable about myself mid-chat
  ("I'm vegetarian", "we travel with two kids"), I want the agent to remember
  it for every future trip without me repeating it.
- As a **traveler**, I want the system to learn from the *whole* planning
  conversation — including things the agent didn't think to note at the time —
  so its picture of me improves with every trip I plan.
- As a **traveler**, I want to see everything the AI has noted about me and
  edit or clear it, so wrong inferences never stick.
- As a **traveler**, I want subtle in-chat feedback when the agent notes
  something, so I know it's learning (and what).

## Acceptance Criteria

- [ ] The profile gains a free-text **notes** section alongside the existing
      structured fields; notes persist across sessions and feed the agent's
      context on every authenticated chat.
- [ ] When a signed-in user reveals a durable fact mid-conversation, the agent
      saves it into the notes and the chat shows a brief "noted" indicator.
- [ ] After a signed-in user's itinerary is created, the system distills the
      conversation and merges what it learned (notes, and structured fields
      only when clearly established) into the profile — without delaying or
      ever failing the itinerary.
- [ ] Notes are merged and de-duplicated over time, not appended forever; they
      stay within a fixed size cap (2000 characters).
- [ ] The Travel profile screen shows the notes; the user can edit or clear
      them, and edits persist.
- [ ] The agent can never wipe the notes wholesale; only the user can clear them.
- [ ] Anonymous sessions: no notes are read, written, or distilled; planning
      works as before.

## API Surface

### `GET /api/v1/preferences` (existing, extended)
- **Response:** adds `profile_notes` (string or null).

### `PUT /api/v1/preferences` (existing, extended)
- **Request:** adds optional `profile_notes`. Omitted = unchanged; empty
  string = clear. Over-long values are truncated to the cap.
- **Response:** the updated profile including `profile_notes`.

### `POST /api/v1/plan` (existing, extended)
- New SSE event **`profile_updated`** emitted when the agent saves profile
  learnings live: `fields` (list of field names that changed) and
  `notes_preview` (short excerpt of the saved notes, may be empty).
- Post-trip distillation produces **no** SSE event (it runs after the
  response completes); its results appear on the next profile load/session.

## Data Model

- **Traveler Preferences** (existing, extended) — adds *Profile notes*: a
  short free-text document (bullet-style lines) maintained primarily by the
  AI; optional/unset; capped at 2000 characters. Each write replaces the
  whole document with a merged, de-duplicated rewrite.

## UI Behavior

- **Travel profile screen:** a "Profile notes" section with a multiline text
  field pre-filled with current notes, a caption explaining the AI maintains
  it, and the existing Save action (clearing the field clears the notes).
- **Agent chat:** when the agent saves learnings live, a small transient
  "Noted" indicator appears alongside the existing tool-activity chips, with
  the notes excerpt available on hover/long-press. No indicator for post-trip
  distillation.

## Edge Cases & Error States

- Distillation failure (model error, timeout, missing key) → logged only; the
  trip and the chat response are unaffected.
- Agent sends empty/whitespace notes → treated as "no change", never a wipe.
- User PUT with empty string → clears notes (distinct from omitting the key).
- Notes over the cap (any writer) → truncated safely (no broken characters).
- Concurrent live save and distillation → last write wins; acceptable because
  every write is a full merged rewrite built from recent state.
- Older/other clients that don't know `profile_updated` ignore it.

## Out of Scope

- Periodic/background re-analysis across all past trips (no job infra yet).
- Per-trip notes or trip-scoped overrides (global profile only).
- Structured expansion of the schema (dietary/companions as typed columns) —
  the notes field is deliberately free-form.
- Surfacing distillation results in the same chat session.

## Resolved Decisions

- **Representation:** hybrid — keep structured fields, add one free-text
  notes document (not a separate notes-per-fact table, not more columns).
- **Learning timing:** both live (agent tool during chat) and post-trip
  distillation (one extra model pass over the transcript after the itinerary
  is created). No periodic background jobs.
- **Visibility:** fully visible and editable by the user, with live in-chat
  feedback on saves.
- **Merge mechanism:** the model always rewrites the complete notes document
  (merge + dedupe, ≤ ~15 short lines); storage does wholesale replace with a
  hard size cap. No server-side diffing.
- **Distillation runs asynchronously** after the itinerary persists, so it can
  never delay or fail trip creation; in exchange it gets no in-chat feedback.
