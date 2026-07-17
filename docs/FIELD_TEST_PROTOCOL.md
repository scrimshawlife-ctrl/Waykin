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

1. In Xcode, download the app container from the connected device.
2. Open `AppData/Library/Application Support/Waykin/FieldTestReceipts`.
3. Select the latest `field-test-<started-milliseconds>-<receipt-uuid>.json` file.
4. Confirm `mode` is `physical`, `outcome` is expected, persistence is recorded, and the timeline ends with completion.
5. Review the file before sharing it. Receipts omit route geometry and personal text, but timestamps reveal session timing.

Waykin never uploads receipts. At most 20 are retained; the oldest receipt is removed first. Diagnostic rotation does not affect normal session memories.

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
