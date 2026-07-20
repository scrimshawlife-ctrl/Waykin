---
name: waykin-pr-review
description: >
  Review Waykin pull requests against AGENTS.md, architecture isolation, tests,
  evidence rules, and UI practice. Verdict: PASS, PASS WITH COMMENTS, or
  REQUEST CHANGES. Use when /waykin-pr-review, review PR, or code review Waykin.
metadata:
  short-description: "Waykin PR review verdict"
  pack: waykin-skill-pack
  version: "1.0.0"
---

# waykin-pr-review

## 0. Load context

```bash
cd "$(git rev-parse --show-toplevel)"
# PR number from user or gh pr view
gh pr view <N> --json title,body,baseRefName,headRefName,files,commits,statusCheckRollup
gh pr diff <N>
```

Read: `AGENTS.md`, `ARCHITECTURE.md`, relevant design docs for touched paths.

## 1. Mandatory gates

| Gate | Fail → |
|------|--------|
| WaykinCore isolation (no new platform frameworks) | REQUEST CHANGES |
| Expands MVP scope (run/cycle, multiplayer, cloud) without docs | REQUEST CHANGES |
| Claims outdoor/device PASS without evidence | REQUEST CHANGES |
| Breaks Begin Walk primary / Demo labeling / AR cover modality | REQUEST CHANGES |
| Missing tests for Core logic changes | REQUEST CHANGES or strong comment |
| CI red | REQUEST CHANGES |
| Secrets / coordinates in receipts/logs | REQUEST CHANGES |
| Force unwraps in new code without justification | REQUEST CHANGES |

## 2. Review dimensions

1. **Architecture** — ownership, dependency direction, presentation vs truth  
2. **Correctness** — edge cases, session clear, persistence recovery  
3. **Style** — match local file style; no drive-by refactors  
4. **Performance** — snapshots, caps, MainActor  
5. **Testing** — package + App tests; UI tests only if navigation/CTA  
6. **Docs** — KNOWN_LIMITATIONS / design docs if contracts change  
7. **API stability** — schema decode defaults for receipts  
8. **Maintenance** — smallest coherent patch  

## 3. Verdict definition

- **PASS** — merge-ready; nits only optional  
- **PASS WITH COMMENTS** — non-blocking improvements; CI green; architecture OK  
- **REQUEST CHANGES** — blocking defect, isolation, scope, privacy, or red CI  

## 4. Output format

```markdown
## Waykin PR review — #<N>
**Verdict:** PASS | PASS WITH COMMENTS | REQUEST CHANGES

### Summary
(1–3 sentences)

### Blocking
- path:line — issue — required fix

### Non-blocking
- ...

### Architecture
- Core isolation:
- Presentation vs truth:

### Tests / CI
- Status:
- Gaps:

### Evidence / claims
- Over-claims found: none|list

### Rationale for verdict
```

Do not rubber-stamp. Do not demand unrelated refactors.