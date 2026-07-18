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
