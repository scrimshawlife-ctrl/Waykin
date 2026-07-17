# WAYKIN Physical Device Walk Validation Receipt

**Device model:** [fill at test time]
**iOS version:** [fill]
**App commit:** [HEAD]
**Date:** [YYYY-MM-DD]
**Environment:** Outdoor pedestrian area, clear sky view preferred
**Permission state at start:** [NOT_DETERMINED / AUTHORIZED / DENIED]
**Session duration (wall):** 
**Active time:** 
**Distance (m):** 
**Average pace (min/km):** 
**Accepted samples:** 
**Rejected samples:** 
**Pause behavior:** [OBSERVED / INFERRED]
**Resume behavior:** [OBSERVED / INFERRED]
**Summary visible:** 
**Memory created:** 
**Memory persists after relaunch:** 
**Location denial test result:** 

## Observed Defects
- 

## Notes
- Used COMPANION_WALK only.
- No background, no watch, no AR.
- All simulator regressions remained green.
## Preflight Checklist
- [ ] Physical iPhone attached
- [ ] Device trusted in Xcode
- [ ] Developer Mode enabled (iOS 16+)
- [ ] Automatic signing resolved locally
- [ ] Waykin.app installed on device
- [ ] Location permission known or reset in Settings
- [ ] Safe outdoor pedestrian route (5-10 min)
- [ ] Demo Mode regression verified green before physical test
- [ ] No exact route coordinates will be committed

## 5-10 Minute Protocol
1. Launch app, start "Start Real Walk (COMPANION_WALK)"
2. Grant When-In-Use when prompted
3. Wait for first fix (liveSignal = active)
4. Walk 2+ minutes
5. Confirm accepted samples and distance increase without abrupt jumps
6. Pause 20-30s, confirm stable
7. Resume, confirm no spike
8. Walk 2+ more minutes
9. End session
10. Verify summary + memory created
11. Terminate app
12. Relaunch, confirm memory persists
