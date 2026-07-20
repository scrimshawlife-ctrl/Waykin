# Waykin Field-Test Protocol

This protocol is the first physical Companion Walk evidence gate. Receipts are local engineering artifacts; creating one does not validate GPS, audio, battery, safety, or emotional effectiveness.

## Minimum Initial Evidence

- 5 completed physical walks.
- At least 3 distinct routes.
- At least 2 daylight contexts.
- No critical session failure.
- No repeated cue-spam defect.
- Bond and one memory persist after each completed walk.
- A receipt is created successfully for every completed session.

## After Each Walk

Record these ratings manually outside the app:

```text
Return intent: 1-5
Audio usefulness: 1-5
Audio intrusiveness: 1-5
World responsiveness: 1-5
Attention burden: 1-5
Notes: optional
```

Do not put these ratings into analytics infrastructure. The core product question is:

> Did the walk feel more alive without demanding too much attention?

## Receipt Review

### On device (preferred for solo operators)

1. Open **Settings → Field-test receipts**.
2. Confirm status is **Written** after a completed session; use **Refresh from disk** if needed.
3. Optionally **Share latest receipt JSON** (AirDrop / Files). Receipts are privacy-filtered but timestamps reveal session timing — review before sharing outside the project.
4. Check `summary.arPresentation` when AR was opened: LOD label, mesh evidence class, continuity note, deferred/replant counts (schema 4+). These are software presentation labels, not outdoor quality PASS.
5. Check `summary.mapPresentation` (schema 5): trace point count and planned-route status only — not outdoor map readability.
6. Check `summary.persistenceOperator` (schema 5): availability + recovery action — local store health only, not cloud sync.

### Via Xcode container

1. Download the app container from the connected device.
2. Open `AppData/Library/Application Support/Waykin/FieldTestReceipts`.
3. Select the latest `field-test-<started-milliseconds>-<receipt-uuid>.json` file.
4. Confirm `mode` is `physical`, `outcome` is expected, persistence is recorded, and the timeline ends with completion.
5. Review the file before sharing it. Receipts omit route geometry and personal text, but timestamps reveal session timing.
6. Treat audio fields as software-stage evidence only:
   semantic cue requests, planner outcomes, asset lookup, session setup, player activity, interruptions, and coarse route categories can show where playback stopped progressing, but they do not prove that a human heard sound. Receipt stop and fade counts represent adapter requests; a delayed fade completion may not be present after the session receipt is finalized.
7. Treat AR fields the same way: they record whether AR opened and final presentation labels/counts, not physical tracking quality.

Waykin never uploads receipts. At most 20 are retained; the oldest receipt is removed first. Diagnostic rotation does not affect normal session memories.

## Operator strip (engineering)

DEBUG builds (or launch arg `-WAYKIN_OPERATOR_DEBUG`) show a compact **Operator** strip on the active session: path relation, accept/reject, last audio cue, AR LOD if opened. Filter Console.app by subsystem `life.scrimshaw.waykin` (categories: `movement`, `audio`, `ar`, `path`, `receipt`).

## Stop Conditions

Stop feature expansion and repair the observed failure before further testing if:

- The session loses significant distance.
- Pause or resume adds false distance.
- Audio fails to stop.
- Cues repeat excessively.
- Permission failure creates a fake session.
- Memory or Bond duplicates.
- A receipt contains precise location data.
- The app becomes unsafe or distracting to operate while walking.
