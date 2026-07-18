# Contributing to Waykin

## Workflow

1. Start from an approved GitHub issue.
2. Create a small branch from current `main`: `feat/<issue>-<name>`, `fix/<issue>-<name>`, `test/<issue>-<name>`, `docs/<issue>-<name>`, or `chore/<issue>-<name>`.
3. Keep the patch within the issue's allowed systems and explicit non-goals.
4. Add or update tests and directly affected documentation.
5. Run canonical validation.
6. Open a draft pull request using the repository template.
7. Resolve review feedback and required checks before merge.

## Design and Scope

Current product authority lives in `docs/SOLO_MVP_SCOPE.md`, `WAYKIN_SPEC.md`, `README.md`, and `ARCHITECTURE.md`.

The master documentation pack includes future-state designs. Those documents preserve architectural foresight but do not authorize implementation unless promoted through the process in `docs/governance/SPEC_PROMOTION_PROCESS.md`.

## Remote and Agent-Assisted Work

Remote collaborators must read [`docs/collaboration/REMOTE_COLLABORATOR_GUIDE.md`](docs/collaboration/REMOTE_COLLABORATOR_GUIDE.md) before beginning implementation.

Every agent-assisted task should begin with a completed [`docs/collaboration/AGENT_TASK_PACKET_TEMPLATE.md`](docs/collaboration/AGENT_TASK_PACKET_TEMPLATE.md). Use [`docs/collaboration/ACTIVE_WORK.md`](docs/collaboration/ACTIVE_WORK.md) to prevent overlapping file ownership and record active handoffs.

Ordinary branches must start from current `main`. Stacked branches require an explicit issue dependency and must be reconciled or retargeted after the parent work merges.

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
- Do not run parallel tasks that require the same file.
- Rebase or reconstruct stacked follow-on work onto current `main` after its parent merges.
