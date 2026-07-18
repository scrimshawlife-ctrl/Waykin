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

## Active

| Issue / PR | Owner | Branch | Allowed paths | Status | Dependency |
|---|---|---|---|---|---|
| PR #19 — AR-1 integration | Daniel | `agent/ar1-realitykit-session-shell` | `App/AR/**`, AR tests and docs | Review / integration | Current main |
| PR #24 — AR-3 runtime integration | Unassigned pending reconciliation | `ar3-runtime-integration` | AR adapter, AR tests and docs | Draft / blocked | PR #19 integration chain |
| Remote collaboration hardening | Daniel | `agent/remote-collaboration-hardening` | Collaboration docs and GitHub ownership | Implementation | Current main |

## Blocked or Pending

| Work | Reason | Required resolution |
|---|---|---|
| Friend CODEOWNERS assignment | GitHub username not recorded in repository context | Add collaborator username and update `.github/CODEOWNERS` |
| AR-3 retarget to `main` | AR-1/AR-2 integration chain is not yet reconciled into `main` | Merge or reconstruct current AR baseline, then rebase AR-3 |
| Physical AR claims | Requires direct iPhone evidence | Execute the relevant physical-device protocol |

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
