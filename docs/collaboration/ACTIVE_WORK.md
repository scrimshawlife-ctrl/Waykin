# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-18

## Rules

- One active owner per issue.
- One declared branch per issue.
- Declare allowed and frozen path groups before coding.
- Do not run parallel tasks that require the same file.
- Update this ledger when work starts, blocks, transfers, or completes.
- Remove completed entries after the corresponding PR merges or closes.
- Local WIP branches are preservation surfaces, not merge authority.

## Active

| Issue / PR | Owner | Branch / worktree | Allowed paths | Status | Dependency |
|---|---|---|---|---|---|
| PR #31 — reconciled AR baseline | Daniel | `agent/ar-reconciliation-main` | Reconciled AR baseline, focused tests, `project.yml`, AR docs | Merged to main at 5f42981; native build repaired and validated (PRs #31/#37/#32) | — |
| Issue #38 — preserve AR-3 work and isolate PR #31 repair | Daniel | local `wip/ar3-local-preservation` (846c42d); clean worktree `Waykin-pr31-repair` | Preservation: current mixed AR-3 set. Repair: minimum files proven by compiler diagnostic | Completed — recovery topology executed; AR-3 preserved on wip/ar3-local-preservation (do not fold into main per ownership) | — |
| PR #34 — collaborator ownership | Daniel + `prabu-openclaw` | `chore/28-collaborator-ownership` | `.github/CODEOWNERS` | Ready / awaiting Prabu review | Issue #28 |
| Issue #29 — CI and structural guards | `prabu-openclaw` for first bounded task | `chore/29-core-framework-isolation` when started | scripts, Makefile, focused tests, CI docs | Assigned / not yet evidenced | No collision with PR #31 |
| Issue #41 — physical AR validation | Prabu | Evidence-only from `main@4c645395` | Physical protocol and evidence receipt only; no code changes | Ready for physical execution | PR #40 merged |
| Issue #42 — canonical runtime AR integration | Daniel + Codex | `codex/issue-42-runtime-integration` from `main@4c645395` | App-side command mapping, existing renderer, focused app tests, directly affected collaboration docs | In progress | PR #40 merged; Issue #41 proceeds independently |

## Blocked or Pending

| Work | Reason | Required resolution |
|---|---|---|
| Issue #27 — AR reconciliation closure | Completed via PR #31 merge | — |
| Issue #28 — collaborator onboarding closure | First collaborator-authored branch and draft PR not yet supplied | Prabu reviews PR #34 and completes the Issue #29 bounded task |
| Physical AR claims | Requires direct iPhone evidence | Execute the relevant physical-device protocol and attach receipts (NOT_COMPUTABLE in simulator) |

## Handoff Note (post-Issue #38)

Recovery topology (Issue #38) complete. Issue #35 is in progress from main @ 5f41eeb176d8c4dba4f77e26cbea8399a87624f7. Preservation branch `wip/ar3-local-preservation` remains isolated per rules. All claims OBSERVED from git history + validation receipts only.

## Exclusive Ownership Boundaries

### Daniel — AR recovery

- Owns the local AR-3 preservation branch.
- Owns the clean PR #31 repair worktree.
- Must not fold the preserved AR-3 validation set into PR #31.

### `prabu-openclaw` — infrastructure onboarding task

- May work only on the Issue #29 framework-isolation guard and its declared files.
- Must not modify `App/AR/**`, `ARLab/**`, `AppTests/AR*`, `project.yml`, `ARCHITECTURE.md`, or AR validation documents while Issue #38 is active.

## Handoff Entry Template

```yaml
issue:
owner:
agent:
branch:
allowed_paths:
frozen_paths:
status:
last_validated_commit:
commands_run:
blockers:
next_action:
```
