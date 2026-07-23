# Field-test receipt JSON samples

**Authority:** format examples only. Not outdoor PASS, not #41 COH, not #217 device verification.

| File | What it is | Evidence class |
| ---- | ---------- | -------------- |
| `SIMULATOR_field-test_schema4_demo_no_ar.json` | Real sim export (schema **4**), demo walk, **AR never opened** | **SIMULATOR** only |
| `FORMAT_schema5_field-test_EXAMPLE.json` | **Synthetic** schema **5** shape for agents (Claude/Codex). `arPresentation.finalLODDescription` shows the `#217` `clips=N` / `animated_usdz` pattern | **EXAMPLE** — not OBSERVED on device |

## How production receipts are produced

1. Install a named tip SHA on **physical device** (or sim for non-AR format checks).
2. Complete a walk; open AR if testing LOD/placement.
3. Settings → share latest field-test receipt.
4. On disk: `Application Support/Waykin/FieldTestReceipts/field-test-<ms>-<uuid>.json`
5. Schema source: `Sources/WaykinCore/Diagnostics/FieldTestReceipt.swift` (`currentSchemaVersion = 5`).

## #217 fields to read

Under `summary.arPresentation`:

- `finalLODDescription` — look for `clips=N` (`clips=0` = import lost anim; `clips≥1` = clips imported)
- Prefer `animated_usdz` / `usdz_active_animated_skelanim` for skinned walk package
- `meshEvidenceClass`, `companionPlaced`, `continuityReplantCount`, `entityReplacementCount`

## Privacy

Samples must not contain coordinates, raw HealthKit samples, absolute paths, or device names. Do not commit device dumps that violate receipt privacy law.
