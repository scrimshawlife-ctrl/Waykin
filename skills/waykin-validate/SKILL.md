---
name: waykin-validate
description: >
  Run full Waykin engineering validation with CI parity (make validate, isolation,
  USDZ, collab, package tests, simulator). Use when /waykin-validate, validate,
  pre-PR check, or CI green check.
metadata:
  short-description: "Full Waykin validate report"
  pack: waykin-skill-pack
  version: "1.0.0"
compatibility: Requires make, swift, xcodegen; optional xcodebuild for native
---

# waykin-validate

Produce one **engineering validation report** for Waykin. Prefer existing scripts; do not invent parallel harnesses.

## 0. Preconditions

```bash
cd "$(git rev-parse --show-toplevel)"
# Read references/REPO_CONTEXT.md
git rev-parse HEAD
git status --short
```

If dirty tree is unexpected, note it; still validate unless user asked for clean-only.

## 1. Canonical pipeline (required)

Run in order; capture exit codes:

```bash
make check-core-isolation
make check-lira-usdz
make validate-collaboration   # or: python3 scripts/validate_collaboration_coordination.py
make validate                 # scripts/validate.sh — primary CI parity
git diff --check
```

`make validate` already includes isolation, usdz, collab, xcodegen, swift build/test, native best-effort.

## 2. Extended checks (when relevant)

| When | Command |
|------|---------|
| UI / presentation changed | `make validate-simulator` |
| UI screenshots needed | `WAYKIN_CAPTURE_FULL=1 ./scripts/capture_sim_screenshots.sh` |
| Demo loop | `make demo` (non-fatal if interactive) |
| Focused package tests | `swift test --filter FieldTestReceiptTests` |
| App unit tests | `xcodebuild test -scheme Waykin -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WaykinTests` |
| UI smoke | `-only-testing:WaykinUITests/WaykinSmokeTests` |

## 3. What “lint / format” means here

Waykin does **not** ship a separate SwiftLint config as the gate. Authority is:

- `make validate` + Core isolation
- Swift 6 compiler diagnostics
- `git diff --check` (whitespace)
- Architecture rules in `AGENTS.md`

Do not invent SwiftFormat runs unless the repo adds them.

## 4. Accessibility / performance in validate scope

- **Accessibility:** note if UI tests include a11y order (`WaykinSmokeTests`); physical VO = `NOT_COMPUTABLE` without device.
- **Performance:** validate does not profile Instruments. Say SKIPPED unless user also runs `/waykin-performance`.

## 5. Documentation validation

- Issue-scoped docs updated if UI/debug/persistence contracts changed.
- Cross-check `docs/governance/DOCUMENT_AUTHORITY.md` for conflicting CANONICAL claims.
- Field-test schema claims must match `FieldTestReceipt.currentSchemaVersion` (currently **5**).

## 6. Report template (always)

```markdown
## Waykin validation report
- UTC:
- SHA:
- Branch:
- Dirty files:

| Gate | Result | Notes |
|------|--------|-------|
| core isolation | PASS/FAIL | |
| lira usdz | PASS/FAIL | |
| collaboration | PASS/FAIL | |
| make validate | PASS/FAIL | |
| git diff --check | PASS/FAIL | |
| validate-simulator | PASS/FAIL/SKIPPED | |
| package test count | N | |

### Evidence
- OBSERVED:
- INFERRED:
- NOT_COMPUTABLE:

### Blocking failures
1.

### Non-blocking warnings
1.

### Ready for PR?
YES | NO — reason
```

Fail safely: if a tool is missing, mark `NOT_COMPUTABLE` and continue other gates.