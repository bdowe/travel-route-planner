# Spec: <Feature Name>

> **WHAT & WHY only.** No tech choices, file names, libraries, or code. If a
> sentence names a file or a package, it belongs in `plan.md`, not here.

## Context

What problem does this solve? Why now? What's the intended outcome? One short
paragraph — the motivation a reviewer needs to judge whether the feature is
worth building.

## User Stories

- As a **<role>**, I want **<capability>** so that **<benefit>**.
- As a …

## Acceptance Criteria

The definition of done — observable, testable outcomes. A reviewer should be
able to check each one by using the app, with no knowledge of the code.

- [ ] …
- [ ] …

## API Surface

The contract, described behaviorally (not as Go/Dart code). For each endpoint:

### `<METHOD> /api/v1/<path>`
- **Purpose:** …
- **Request:** the fields the caller sends and what they mean. Note which are
  optional and what happens when omitted.
- **Response:** the fields returned and what they mean.
- **Errors:** which conditions produce which error responses.

## Data Model

The entities this feature introduces or changes, described by meaning — not as
struct/class definitions.

- **<Entity>** — what it represents; key fields and their meaning; which fields
  are optional and why.

## UI Behavior

- **Screen / surface:** where this lives and how the user reaches it.
- **Happy path:** the main flow, step by step.
- **States:** loading, empty, success, error — what the user sees in each.

## Edge Cases & Error States

- What happens when input is missing/invalid?
- What happens when an upstream service (Places, Anthropic, Airbnb, network)
  fails or times out?
- Limits and boundaries (e.g. maximum counts).

## Out of Scope

- Explicitly list what this feature does **not** cover, to prevent scope creep.

## Open Questions

Unresolved decisions. Mark each `[NEEDS CLARIFICATION]` and resolve them before
implementation begins.

- [NEEDS CLARIFICATION] …
