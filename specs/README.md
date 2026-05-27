# Specs — Spec-Driven Development

Every non-trivial feature starts as a spec, reviewed before any code is written.
This is a lightweight, dependency-free adaptation of the spec → plan → tasks
discipline (inspired by GitHub Spec Kit, without its tooling or constitution).

## The loop

1. **Spec** (`spec.md`) — *what & why*. User stories, acceptance criteria, the
   API contract and data model described behaviorally. The user reviews this
   first.
2. **Plan** (`plan.md`) — *how*. The file-level technical approach, mapped to
   this repo's conventions, including the contract-parity check.
3. **Tasks** (`tasks.md`) — ordered, checkable work items.
4. **Implement** — write the code, checking off tasks and acceptance criteria.

## The one rule: what vs. how

- **Spec = what & why.** No tech choices, file names, libraries, or code.
- **Plan = how.** Files, types, rationale.

If a sentence in the spec names a file or a package, it belongs in the plan.

## Starting a feature

```bash
cp -r specs/_template specs/<feature-name>   # kebab-case, e.g. trip-budget-tracker
```

Then fill in `spec.md` first. No numeric prefixes, no branch coupling — features
are named directories that live alongside the code on `main`.

## How Claude uses these

- Before editing code for a feature, Claude reads that feature's `spec.md` and
  `plan.md`.
- **Acceptance criteria are the definition of done.**
- Any unresolved `[NEEDS CLARIFICATION]` in the spec is surfaced to the user
  before implementation starts.

## Why the contract-parity gate

This stack's most common bug is **Go ↔ Flutter drift**: a field added to a Go
response struct that the Dart `@JsonSerializable` model never picks up (or the
reverse). `plan.md` includes a parity table that must be filled — JSON key, Go
type, Dart type, nullability — so the contract is verified, not assumed.
