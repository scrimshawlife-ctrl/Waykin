# Debug operator continuation (D5–D7)

```yaml
document_id: WAYKIN-DEBUG-OPS-CONTINUATION-001
version: 1.0
date: 2026-07-20
status: CURRENT
issue: 196
baseline_main: 62566a8
authority: SUPPORTING
depends_on:
  - docs/FIELD_TEST_PROTOCOL.md
  - ARCHITECTURE.md (FieldTestReceiptBuilder ownership)
```

## Outcome

Extend **operator/debug instrumentation** after D1–D4 (#182) so field bugs in **session map** and **local persistence** are visible in the same privacy-safe receipt + strip stack—without outdoor claims or new product chrome.

## Non-goals

- Outdoor GPS / AR / glare PASS (#41)
- Coordinates, street addresses, raw store paths, HealthKit sample IDs in receipts
- CloudKit / WP-DB6
- Permanent product UI for diagnostics

## Prior art (shipped)

| ID | Capability | Evidence |
|----|------------|----------|
| D1 | AR presentation → receipt schema 4 | `FieldTestARPresentationSummary` |
| D2 | Settings share latest JSON | Field-test receipts section |
| D3 | Operator strip (DEBUG / `-WAYKIN_OPERATOR_DEBUG`) | Path, GPS counts, audio, AR |
| D4 | `WaykinLog` categories | movement, audio, ar, path, receipt |

## Work packages

### D5 — Map presentation snapshot (privacy-safe)

**Problem:** Trace/planned route clear on end before operators can correlate “blank map” bugs with receipts.

**Deliverables**

- `FieldTestMapPresentationSummary`: `tracePointCount`, `plannedRouteStatus` (`none|searching|ready|failed`), `plannedPolylinePointCount`
- Snapshot **before** `clearSessionMapPresentation()` on end/fail
- Operator strip line: `Map: N pts · planned=<status>`
- Receipt schema **5** embeds summary (legacy decode → empty)

**Acceptance**

- Demo with synthetic breadcrumbs → non-zero `tracePointCount` in finished receipt
- JSON contains no `latitude` / `longitude` / coordinate keys from this block

### D6 — Persistence operator visibility

**Problem:** Degraded/failed open and mode string are easy to miss mid-field.

**Deliverables**

- `FieldTestPersistenceOperatorSummary`: `availability` (`PersistenceAvailability.rawValue`), `recoveryAction` (`none|degraded_fallback|emergency_failed`)
- Settings caption: mode + recovery action
- `WaykinLog.persistence` on init when not file-backed
- Strip line when operator debug on: `Persist: <mode> · <recovery>`

**Acceptance**

- In-memory test model finishes receipt with availability reflecting store
- Degraded app launch path sets recovery action (manual / unit where constructible)

### D7 — Display font soft log

**Problem:** Silent brand font miss is hard to spot.

**Deliverables**

- When `WaykinTypography.ensureRegistered()` fails, one `WaykinLog` (category `ui` or `receipt`) warning — no crash, no product banner

**Acceptance**

- Code path present; failure not required in CI

## Schema

| Version | Addition |
|---------|----------|
| 4 | `arPresentation` |
| **5** | `mapPresentation` + `persistenceOperator` on summary |

Decode: missing keys → empty defaults. Do not rewrite old files on disk.

## Evidence rules

- `OBSERVED` software-stage only
- Map counts ≠ outdoor map readability
- Persistence mode ≠ multi-device sync

## Execution order

1. Core summary types + schema 5 + builder.finish params  
2. App snapshot-before-clear + strip/Settings + logs  
3. D7 font log  
4. Tests + docs (KNOWN_LIMITATIONS, FIELD_TEST_PROTOCOL, ACTIVE_WORK)  
5. PR under issue #196  

## Done when

- `make validate` green  
- OperatorDebug + FieldTestReceipt tests cover map + persistence fields  
- Issue #196 closed via merge  
