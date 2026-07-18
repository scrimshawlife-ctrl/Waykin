# Contributing to Waykin

## Workflow

1. Start from an approved GitHub issue.
2. Create a small branch: `feat/<issue>-<name>`, `fix/<issue>-<name>`, `test/<issue>-<name>`, `docs/<issue>-<name>`, or `chore/<issue>-<name>`.
3. Keep the patch within the issue's allowed systems and explicit non-goals.
4. Add or update tests and directly affected documentation.
5. Run canonical validation.
6. Open a draft pull request using the repository template.
7. Resolve review feedback and required checks before merge.

## Design and Scope

Current product authority lives in `docs/SOLO_MVP_SCOPE.md`, `WAYKIN_SPEC.md`, `README.md`, and `ARCHITECTURE.md`.

The master documentation pack includes future-state designs. Those documents preserve architectural foresight but do not authorize implementation unless promoted through the process in `docs/governance/SPEC_PROMOTION_PROCESS.md`.

## Pull Request Expectations

Every PR must state:

- The issue or milestone
- Canonical documents consulted
- What changed and what remained frozen
- Agent assistance used
- Validation evidence
- Device-evidence status
- Risk and rollback
- Parent or superseded PR when stacked

## Validation

```bash
make build
make test
make validate
git diff --check
```

Use `make validate-simulator` and physical-device protocols when relevant.

## Merge Discipline

- Do not push directly to `main`.
- Prefer small squash-mergeable PRs.
- Do not mix unrelated cleanup with feature work.
- Do not merge with unresolved required checks or review threads.
