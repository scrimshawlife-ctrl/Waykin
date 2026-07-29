# Device lane handoff (post freeze #249)

```yaml
document_id: WAYKIN-DEVICE-LANE-HANDOFF
date: 2026-07-29
freeze_merge: d8c062013fea4e0e0fc7fe661b050f12135d9163
code_lineage: 7df3a169ede507ce54469330318f66c4603f8c3d
status: HUMAN_DEVICE_NEXT
```

## Agent readiness (OBSERVED laptop)

| Item | Status |
| ---- | ------ |
| Freeze docs #249 on main | Merged |
| Laptop baseline receipt | PASS (package + validate + simulator) |
| Indoor protocol v2 (Ember Fox) | On main |
| Indoor scaffold | `INDOOR_AR_HYBRID_SMOKE_20260729T191500Z_7df3a16_PENDING.md` (regen with prep script on install tip) |
| Outdoor scaffold | `OUTDOOR_QA_RECEIPT_20260729T191500Z_7df3a16_PENDING.md` |
| Prabu visual gold standard | `DEVICE_MESH_REFERENCE_PRABU_IMG_2534.md` |
| Physical device (this machine) | **NOT_COMPUTABLE** — iPhone listed offline/unavailable |

## Human install steps

```bash
cd /path/to/Waykin
git checkout main && git pull --ff-only
SHA=$(git rev-parse HEAD)
echo "install_sha=$SHA"   # must be ≥ d8c0620
make check-lira-usdz
make validate             # optional if already green on tip
# Prefer regenerating tip-bound receipt:
bash scripts/indoor_ar_smoke_prep.sh
# Install Debug to phone (Xcode / xcodebuild -destination id=…)
```

## Indoor smoke (must fill)

1. Protocol: `docs/design/INDOOR_AR_HYBRID_SMOKE.md` (I1–I14)
2. Visual: match Prabu fox still — not procedural spheres
3. Receipt: tip-bound PENDING → fill with `evidence_class: OBSERVED` (note indoor)
4. Share field-test JSON schema ≥ 5

## After indoor

- Close or re-scope **#247** only with tip-bound OBSERVED authored mesh
- Outdoor **#41** daylight on same install SHA
- No AR redesign PRs until product-law Phase 0 after device honesty

## Explicit non-claims

- This handoff is not outdoor PASS
- This handoff is not TF archive approval
