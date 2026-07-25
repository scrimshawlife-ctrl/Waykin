# Phase A pre-device gates receipt

```yaml
document_id: WAYKIN_PHASE_A_PREDEVICE
date_utc: 2026-07-25T19:45:22Z
main_tip_sha: 3cc8ac21a3bbe286486c551b04630b5531ec928c
main_tip_short: 3cc8ac2
environment: laptop + Xcode 26.5
toolchain: Swift 6.3.2
marketing_version: "0.9.0"
build_number: "2"
not: outdoor_#41
not: indoor_physical_device
not: TestFlight_upload
```

Re-run after Hallmark #236 + TF version #237 + cut pin #238. Local `make validate` on tip.

| Gate | Result |
|------|--------|
| `make check-lira-usdz` | **PASS** (5301358 bytes; 6 DCC sidecars; animated joints; ARTIST_BLEND_HERO_DCC_MID_LOD) |
| `make validate` | **PASS** (isolation + collab + xcodegen + 130 package tests + WaykinApp build) |
| `git diff --check` | **PASS** |
| Outdoor #41 | **NOT_COMPUTABLE** |
| Indoor device smoke | **NOT_COMPUTABLE** (iPhone listed offline) |
| TestFlight upload | **NOT_COMPUTABLE** (human signing / ASC) |

## Device inventory (laptop)

| Device | Status |
|--------|--------|
| iPhone (26.3.1) `00008150-000A6C120CB8401C` | **Offline** — connect USB/trust to install |
| iOS Simulator iPhone 17 | Available |

## Archive identity

| Field | Value |
|-------|-------|
| Recommended archive tip | `3cc8ac21a3bbe286486c551b04630b5531ec928c` |
| Marketing / build | **0.9.0 (2)** |
| Bundle | `com.waykin.WaykinApp` |

## Human next (ordered)

1. **Connect iPhone** → Debug install tip → fill indoor smoke receipt  
   `docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_20260725T194535Z_3cc8ac2_PENDING.md`
2. **Xcode Organizer** → Release archive tip → Internal Testing  
   See `docs/design/TESTFLIGHT_RC_CHECKLIST.md`
3. **Daylight outdoor #41** when free  
   `docs/design/receipts/OUTDOOR_QA_RECEIPT_20260725T194535Z_3cc8ac2_PENDING.md`

## Explicit non-claims

No outdoor AR quality, GPS, physical audio, battery, or HealthKit device lifecycle claims from this receipt.
