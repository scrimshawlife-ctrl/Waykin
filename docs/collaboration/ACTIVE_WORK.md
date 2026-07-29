# Active Work Ledger

This file is a repository-readable coordination surface for humans and coding agents. GitHub issues and pull requests remain the authoritative records.

Last updated: 2026-07-29 (**FREEZE LANE** — re-baseline docs + laptop baseline on lineage `7df3a16`; no redesign until freeze merges)

> **Coordination contract:** [Issue #47](https://github.com/scrimshawlife-ctrl/Waykin/issues/47) · **Live workflow:** [Project #1](https://github.com/users/scrimshawlife-ctrl/projects/1) · [Coordination protocol](GITHUB_PROJECT_COORDINATION.md)

## Active

| Work | Owner | Status | Dependency |
|---|---|---|---|
| **Freeze: docs re-baseline + laptop receipt** | Docs / eng | **PR open** — [#249](https://github.com/scrimshawlife-ctrl/Waykin/pull/249) (`docs/current-main-rebaseline`); receipt + Prabu mesh ref; merge before build-on-top | [CONTINUATION_PLAN.md](../design/CONTINUATION_PLAN.md) · [PR #249](https://github.com/scrimshawlife-ctrl/Waykin/pull/249) |
| Indoor Ember Fox smoke | Human device | **Armed after freeze merge** — install freeze tip; fill device receipt; **visual gold standard** = Prabu IMG_2534 | [INDOOR_AR_HYBRID_SMOKE.md](../design/INDOOR_AR_HYBRID_SMOKE.md) · [DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md](../design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md) |
| Prabu device mesh reference | Prabu (historical OBSERVED) | **Authored fox on device** (not procedural spheres); strip `animated_usdz` + `anim=PLAYING` — **SHA not on photo** | [DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md](../design/receipts/DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md) · evidence PNG |
| Issue #41 — outdoor / physical validation | Human device | **Parked** until freeze tip is install target | [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md) |
| Issue #247 — TF archive hold | Product / dist | **Softened, not closed** — Prabu photo shows authored mesh on *some* build; still need OBSERVED on **exact freeze/archive SHA** before TF | [#247](https://github.com/scrimshawlife-ctrl/Waykin/issues/247) |
| Internal TestFlight RC | Human (signing / ASC) | **Blocked** — freeze + #247 + fresh validate first | [TESTFLIGHT_RC_CHECKLIST.md](../design/TESTFLIGHT_RC_CHECKLIST.md) |
| PR #245 AR redesign docs | Docs lane | **Parked behind freeze** — SUPPORTING only; recover onto freeze tip later; do **not** merge stale branch | [#245](https://github.com/scrimshawlife-ctrl/Waykin/pull/245) |
| AR session redesign PRs / Phase 0 law | — | **Not started** — build-on-top only after freeze + device honesty | Continuation plan steps 9–12 |

## Tip identity

| Field | Value |
|---|---|
| `main` tip (full) | `7df3a169ede507ce54469330318f66c4603f8c3d` |
| `main` tip (short) | `7df3a16` |
| Current companion | Packaged **Ember Fox** USDZ (`MESHY_EMBER_FOX_WALK_V1`) |
| Mesh integration authority | [PR #246](https://github.com/scrimshawlife-ctrl/Waykin/pull/246) (`b17864e`) |
| Mesh runtime | Versioned asynchronous template loading; procedural fallback; live authored replacement; scene-owned anchors explicitly removed |
| Gameplay tuning (not AR impl) | Real-walk pressure curve — [PR #248](https://github.com/scrimshawlife-ctrl/Waykin/pull/248) |
| Superseded mesh PRs | [#242](https://github.com/scrimshawlife-ctrl/Waykin/pull/242) and [#243](https://github.com/scrimshawlife-ctrl/Waykin/pull/243) **closed**; do not merge |
| Marketing / build (in tree) | **0.9.0 (2)** — **revalidate** before retaining as RC; #247 holds archive |
| Last pre-mesh Phase A receipt | `3cc8ac2` / tip `d7954ac` era — **historical**; re-run validate on current tip |
| Open implementation issues | [#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41), [#247](https://github.com/scrimshawlife-ctrl/Waykin/issues/247) (re-query at execution; do not assume “#41 only”) |
| Open PRs (non-mesh) | #245 (docs redesign, supporting), #244 (license) — treat as separate lanes |

## Recently completed (main)

| Work | Evidence |
|---|---|
| Real-walk event pressure on real distances | PR #248 · main `7df3a16` |
| Ember Fox package + load/replace/anchor/animation runtime | PR #246 · `b17864e` |
| Coordination doc sync (pre-mesh tip) | PR #240 · `d7954ac` — **historical tip pin** |
| Phase A + device/TF handoff receipts (artist-blend era) | PR #239 · `7089b5d` — **historical** |
| TF cut SHA pin (artist-blend era) | PR #238 · `3cc8ac2` — **historical** |
| Marketing 0.9.0 (2) + board + indoor scaffold | PR #237 · `2d969a0` |
| Hallmark UI polish | PR #236 · `d9d1df7` |
| Session double-End receipt/bond guard | PR #235 · `dc54694` |
| Audio cue family + lifecycle + AR presentation audio | PRs #230–#234 |
| Artist-blend / DCC mid-LOD (now superseded as runtime default) | PRs #222–#226 — **historical package**; not current runtime |
| Privacy manifest + encryption | PRs #215 / #219 |
| Persistence WP-DB1–DB5 | PRs #185–#192 |

## Operator order (human)

1. **Re-baseline validate** on tip `7df3a16` (or later main) → new Phase A / post–Ember Fox receipt.
2. **Connect iPhone** → install Debug tip `7df3a16` → indoor Ember Fox smoke (fallback → authored replace, single anchor, skeleton walk) → `evidence_class: OBSERVED` (note indoor).
3. Confirm #247 can close only with **device** evidence that the authored mesh replaced the procedural fallback.
4. **Archive Release** only after #247 hold lifts and validate PASS on archive SHA; re-check marketing/build if prior candidate was already uploaded.
5. **Daylight outdoor #41** on same tip when free; COH only with OBSERVED device rows. Mesh/runtime rows and world-event rows stay separate.

## Intake

| Work | Reason |
|---|---|
| Ember Fox indoor smoke (replace, single companion, skeleton anim) | Device lane after #246 |
| Outdoor #41 on Ember Fox tip | Mesh + world-event evidence separate |
| Recover #245 redesign docs on current main | Docs only; SUPPORTING authority |
| Phase 0 product-law AR vs audio identity | Before AR session redesign PRs |
| Smooth companion follow polish | Field-tune only after device evidence |
| WP-DB6 CloudKit evaluation ADR | Only if multi-device restore required |
| Per-state animation clips on Ember Fox skeleton | Incremental; preserve base mesh |
| Orc / FutureSelf cleanup | Migration issue + Codable tests |

## Blocked

| Work | Reason | Required resolution |
|---|---|---|
| Indoor smoke OBSERVED (post-mesh) | Needs physical iPhone on tip ≥ `b17864e` | Install tip; fill Ember Fox indoor receipt |
| #41 outdoor COH PASS | Device + daylight on post-mesh tip | Outdoor packet + COH; do not invent PASS from sim |
| TestFlight archive 0.9.0 (2) | Issue #247 hold + code moved past pre-mesh Phase A | Device mesh replacement evidence; fresh validate; revalidate version/build |

## Field-test JSON (agents)

Format samples (not device evidence): `docs/design/receipts/samples/`. Production: Settings → share latest receipt. Schema **5**.

## Parked recommendations

See [DEFERRED_RECOMMENDATIONS.md](../design/DEFERRED_RECOMMENDATIONS.md).

## Explicitly deferred (FUTURE / RC)

- Pathfinding v2, Health v2, Watch, AI Directors RC, multi-companion
- Marketplace / multiplayer
- Broad AR UX redesign until binding docs are reconciled (Phase 0)

## Merge hygiene

```text
Main tip: 7df3a16 · companion: Ember Fox (MESHY_EMBER_FOX_WALK_V1)
Ruleset: 1 write-access approving review required
Do not re-import or replace the Ember Fox mesh without an explicit asset issue
Do not merge closed PRs #242 or #243 (superseded by #246)
Do not force-merge stale branches onto main
Do not claim outdoor PASS without #41 device receipt on the tested SHA
```

## UI authority (quick)

| Need | Doc |
|---|---|
| Product surfaces | [WAYKIN_UIUX_SPEC.md](../design/WAYKIN_UIUX_SPEC.md) |
| Tokens | [UI_CANDIDATE_V02_POINTER.md](../design/UI_CANDIDATE_V02_POINTER.md) |
| Practice | [UI_ENGINEERING_PRACTICE.md](../design/UI_ENGINEERING_PRACTICE.md) |
| Continuation | [CONTINUATION_PLAN.md](../design/CONTINUATION_PLAN.md) |
| Conflicts | [DOCUMENT_AUTHORITY.md](../governance/DOCUMENT_AUTHORITY.md) |
