# Post–Ember Fox baseline receipt

```yaml
document_id: WAYKIN-POST-EMBER-FOX-BASELINE
date_utc: 2026-07-29T19:02:49Z
evidence_class: OBSERVED_LAPTOP
status: PASS
code_lineage_main: 7df3a169ede507ce54469330318f66c4603f8c3d
docs_branch_sha: 1378307884e10558cdc40ce33c2f93e8e214bd33
docs_branch: docs/current-main-rebaseline
companion_runtime: MESHY_EMBER_FOX_WALK_V1
mesh_authority_pr: 246
gameplay_pressure_pr: 248
freeze_intent: FREEZE_ENGINEERING_BASELINE_THEN_BUILD_ON_TOP
```

## Purpose

Immutable laptop baseline for the post–Ember Fox, post-pressure `main` lineage. This receipt freezes **engineering health** at a known SHA. It does **not** claim outdoor AR PASS, TestFlight readiness, or product-law redesign authority.

## Exact identity

| Field | Value |
| ----- | ----- |
| Parent `main` (code lineage) | `7df3a169ede507ce54469330318f66c4603f8c3d` (`7df3a16`) |
| Validated docs-branch HEAD | `1378307884e10558cdc40ce33c2f93e8e214bd33` (`1378307`) |
| Docs commit relative to main | Docs-only re-baseline on top of `7df3a16` |
| Marketing / build (in tree) | **0.9.0 (2)** — not archived; #247 holds TF |
| Dirty tree during validate | Only untracked `.worktrees/` (ignored for product paths) |

## Toolchain (OBSERVED)

| Tool | Version |
| ---- | ------- |
| Xcode | 26.5 (Build 17F42) |
| Swift | Apple Swift 6.3.2 (swiftlang-6.3.2.1.108) |
| XcodeGen | 2.46.0 |
| `usdchecker` | `/usr/bin/usdchecker` present |

## Commands executed

```bash
git rev-parse HEAD
git status --short
make check-lira-usdz
usdchecker --arkit App/Resources/Lira_AR_Base.usdz
shasum -a 256 App/Resources/Lira_AR_Base.usdz \
  App/Resources/Companion/Lira/Lira_AR_Base.usdz \
  docs/assets/companion/ar/Lira_AR_Base.usdz
make test
make validate
git diff --check
make validate-simulator
```

## Results

| Gate | Result | Notes |
| ---- | ------ | ----- |
| Core isolation | **PASS** | Via `make validate` |
| Lira USDZ integrity | **PASS** | Triple size 20362444; soft budget WARN (>12MB, <20MB hard) |
| Catalog evidence | **PASS** | `MESHY_EMBER_FOX_WALK_V1` |
| DCC sidecars | **PASS** | 6 present; animated joint curves |
| `usdchecker --arkit` | **PASS** | Success (harmless ConnectableAPI double-register noise) |
| Triple SHA-256 | **MATCH** | `3b563f1b9019cf939644b2e31a36fb6ff7c80e32446b64f14ca161d2a70dfb2f` |
| Collaboration coordination | **PASS** | |
| XcodeGen generate | **PASS** | No intentional project drift committed |
| `swift test` / package | **PASS** | **133** tests, 0 failures |
| Native `WaykinApp` build | **PASS** | Best-effort in validate |
| `make validate` OVERALL | **PASS** | package + generation |
| `git diff --check` | **PASS** | No whitespace errors on tracked changes |
| `validate-simulator` | **PASS** | App build + UI tests (see below) |
| UI tests (`WaykinUITests`) | **PASS** | 13 executed, 1 skipped, 0 failures |
| Physical indoor smoke (full I1–I14) | **NOT_COMPUTABLE** | Human device on freeze tip |
| Prabu mesh visual reference | **OBSERVED** (separate receipt) | Authored fox on device; SHA unknown — see `DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md` |
| Outdoor #41 | **NOT_COMPUTABLE** | Human daylight |
| TF archive | **HOLD** | Issue #247 until freeze-tip device confirm |

## Mesh-specific checks (package / config)

| Check | Result |
| ----- | ------ |
| Ember Fox at root / nested / docs paths | **OBSERVED** present |
| Copies byte-identical | **OBSERVED** triple SHA match |
| `project.yml` resources | **OBSERVED** root USDZ + Companion/** + six clip paths |
| Skeleton / animation present | **OBSERVED** via integrity (animated joints + catalog class) |
| Procedural fallback path still in code | **INFERRED** from #246 / loader design + prior tests; not re-traced line-by-line in this receipt |
| Live replace leaves one anchor | **NOT_COMPUTABLE** here (device / native suite); package tests on main cover loader contracts separately |
| Scale / base-transform invariants | **NOT_COMPUTABLE** as full device contract; `LiraPackagedMeshScaleTests` ship on main |

## Known limitations at freeze

1. Outdoor AR/GPS/audio/thermal remain open (#41).
2. Device confirmation that authored mesh replaces procedural fallback is still a TF hold (#247).
3. USDZ exceeds 12MB soft budget (WARN only; under 20MB hard cap).
4. Marketing **0.9.0 (2)** is in tree but **not** proven as archive candidate until fresh TF checklist on freeze SHA.
5. Simulator PASS is not outdoor or physical-device PASS.
6. Supporting AR redesign docs (#245) are **not** binding and were **not** merged into this freeze.

## Evidence classes

| Class | Content |
| ----- | ------- |
| **OBSERVED** | Validate PASS; 133 package tests; USDZ triple match; usdchecker Success; `validate-simulator` OVERALL PASS (13 UI tests, 0 failures, 1 skipped); toolchain versions above; docs-only commits on top of code `7df3a16` |
| **INFERRED** | App binary identity for product behavior matches `7df3a16` code lineage (docs commits do not change Swift/USDZ) |
| **NOT_COMPUTABLE** | Indoor device smoke; outdoor COH; TF upload; thermal/battery; human audio loudness |

## Freeze contract (build on top)

```text
FROZEN CODE LINEAGE: main 7df3a16 (+ docs re-baseline when merged)
COMPANION: Ember Fox MESHY_EMBER_FOX_WALK_V1 — do not re-import/replace
DO NOT MERGE: #242, #243
DO NOT ARCHIVE TF: until #247 cleared with device OBSERVED on this lineage
NEXT LANES ONLY AFTER FREEZE DOCS MERGE:
  1. Device indoor Ember Fox smoke (receipt)
  2. Outdoor #41 on same lineage
  3. Then optional: recover #245 as SUPPORTING docs on freeze tip
  4. Then optional: Phase 0 product-law (binding) before AR session redesign PRs
```

## Confirmation

- No intentional product source/asset file was modified during validation.
- Only untracked path observed: `.worktrees/`.
- This receipt is immutable once committed; failures after this date open **narrow defect issues**, not broad refactors.

---

**Live board:** `docs/collaboration/ACTIVE_WORK.md`  
**Continuation:** `docs/design/CONTINUATION_PLAN.md` (freeze-then-build)
