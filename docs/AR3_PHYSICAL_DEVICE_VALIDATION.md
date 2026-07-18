# AR-3 Physical-Device Validation

## Evidence

- Date: 2026-07-17
- Runtime repair revision: `344ded6147d5919642a1ecd4a4e488240d38acc1`
- Device: iPhone 17 Pro
- Build: signed Debug build of `WaykinARLab`
- Installed bundle: `com.waykin.arlab`
- Installed executable SHA-256: `3af1ab7dd0372eda60e3fd045ae212c43eb954028c2c80308eefa0e00af7ac11`
- Final automated baseline: 60 Swift package tests, 133 native tests, and 9 UI tests passed
- Focused lifecycle/runtime subset: 21 tests passed

## Observations

| Check | Result | Evidence |
| --- | --- | --- |
| Start Arc places procedural Lira | PASS | Confirmed during the indoor device run. |
| Direct idle, follow, investigate, alert, and celebrate states render | PASS | Confirmed during the indoor device run. |
| Seven-event canonical sequence advances in order | PASS | Confirmed through the final Bond moment. |
| Threat appears and intensifies without changing identity or anchor | PASS | Threat appearance and in-place intensification were confirmed. |
| Threat disappears when pursuit fades | PASS | Removal was confirmed during the canonical sequence. |
| Final celebration ends the demo session | PASS | Final state and normal session closure were confirmed. |
| Manual Discovery places its engineering placeholder | PASS | Confirmed during the indoor device run. |
| Clear removes rendered entities | PASS | Confirmed during the indoor device run. |
| Background and foreground recovery | PASS | The repaired build cleared the prior run and rendered entities, resumed tracking, and placed Lira from a fresh Start Arc after reopen. |
| Tracking interruption recovery | NOT_COMPUTABLE | Backgrounding does not exercise an ARKit interruption callback. |
| Battery and thermal behavior | NOT_COMPUTABLE | The indoor validation run did not characterize either behavior. |
| Outdoor placement and calibration | NOT_COMPUTABLE | This was an indoor deterministic session. |
| Frame pacing under the milestone performance target | NOT_COMPUTABLE | No frame-time measurement was recorded during the device run. |
| Allocation behavior under the milestone performance target | NOT_COMPUTABLE | No allocation measurement was recorded during the device run. |

## Decision

M2 companion embodiment and the M3 deterministic indoor runtime-integration gate are validated on the tested device. The master milestone ladder's outdoor-device and measured performance gates remain open, so M2/M3 are not yet merge-ready and M4 must not begin.

The validation is limited to the isolated AR Lab. It does not validate M4 locomotion or eye contact, M5 discovery gameplay, M6 threat gameplay, a complete AR Companion Walk, or outdoor-alpha behavior.
