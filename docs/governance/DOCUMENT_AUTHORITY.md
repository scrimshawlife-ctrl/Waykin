# Waykin Document Authority

## Precedence

When sources conflict, apply this order:

1. `docs/SOLO_MVP_SCOPE.md`
2. `WAYKIN_SPEC.md`
3. `README.md`
4. `ARCHITECTURE.md`
5. Accepted ADRs under `docs/decisions/`
6. `AGENTS.md`
7. Approved issue acceptance criteria
8. `CONTRIBUTING.md`
9. Current/supporting master-pack documents
10. Future/reference master-pack documents
11. PR descriptions
12. Agent prompts or chat instructions

A lower-authority source cannot silently override a higher-authority source.

## Maturity Classes

- `CURRENT`: approved present-tense contract.
- `NEAR_TERM`: approved direction requiring milestone scope.
- `FUTURE`: architectural foresight only.
- `ARCHIVED`: retained history with no active authority.

## Authority Classes

- `BINDING`: must be followed.
- `SUPPORTING`: informs implementation but yields to binding sources.
- `REFERENCE_ONLY`: does not authorize work.

## Conflict Resolution

When a conflict is found:

1. Preserve the narrower current scope.
2. Record the conflict in the issue or PR.
3. Add an ADR when ownership, dependencies, persistence, determinism, or approved scope changes.
4. Do not implement the broader interpretation until promotion is approved.

## Design and UI documentation (supporting)

Design docs under `docs/design/` are **SUPPORTING** or **DESIGN_REFERENCE** unless an accepted ADR or binding product doc elevates a specific contract.

When UI sources disagree:

1. Apply the precedence list above first (`SOLO_MVP_SCOPE`, product spec, architecture, ADRs).
2. For **product surfaces** (screens, Demo vs Real, AR modality, companion state meaning), prefer [`docs/design/WAYKIN_UIUX_SPEC.md`](../design/WAYKIN_UIUX_SPEC.md).
3. For **tokens/chrome package** integration, prefer [`docs/design/UI_CANDIDATE_V02_POINTER.md`](../design/UI_CANDIDATE_V02_POINTER.md) when it diverges from older in-repo mockups.
4. For **SwiftUI practice, DoD, and PR evidence process**, use [`docs/design/UI_ENGINEERING_PRACTICE.md`](../design/UI_ENGINEERING_PRACTICE.md) and [`docs/design/UI_CHANGE_VALIDATION_RECEIPT.md`](../design/UI_CHANGE_VALIDATION_RECEIPT.md)—they must not expand activity scope or invent product claims.
5. Outdoor / physical claims require field or outdoor protocols and receipts, not design prose alone.

Do not introduce a parallel “canonical UI law” tree that bypasses this document.
