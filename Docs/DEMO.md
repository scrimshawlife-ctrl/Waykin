# Demo Script — the 10-minute “Future Self” scenario

Two ways to run it: on a Mac in 30 seconds, or for real with a phone and a
pair of shoes.

## A. Scripted run (any Mac, ~30 seconds)

```bash
swift run waykin-sim
```

What you'll see, in order:

1. **Day 1 — Onboarding.** Ember the Emberfox is created. First-meeting
   greeting: *“I've never seen this world before — take me somewhere?”*
2. **Day 1 — Future Self at Shoreline Park.** A simulated 10-minute walk:
   easy start, a 40-second pause at a viewpoint (the ghost pulls ahead),
   a strong middle, a finishing surge. Ember comments as the gap changes;
   at ~09:00 you catch the ghost. 🎉
3. **Session summary.** Distance, auto-detected activity, average pace,
   outcome, bond +8, and the generated memory:
   *“We caught your future self at Shoreline Park as the sun went down — 0.9 km side by side.”*
4. **Day 2.** Reopen: *“I kept yesterday safe: …”* Walk back to the park:
   *“I remember this place.”* Three recommendations for today (yesterday's
   experience is not the top pick). Ask Ember *“Do you remember yesterday?”*
   and it answers from the stored memory.
5. Finally the exact LLM system prompt the AI layer would send is printed.

## B. Live run (iPhone, ~12 minutes)

1. `cd App && xcodegen generate && open Waykin.xcodeproj`, run on a device.
2. Create your companion (pick a species, name it).
3. On Home, choose **Future Self** from Today's adventures.
4. Tap **Start Future Self** and walk for ten minutes. The AR companion
   trots ahead of the camera; the HUD shows distance, time, pace, and the
   ghost's lead. Hold a steady pace and the gap closes; catch the ghost and
   the companion celebrates.
5. Tap **End session** — the summary sheet shows stats, bond gained, any
   relationship level-up, and the new memory.
6. Tomorrow, open the app again: the greeting references yesterday's walk.
   Return to the same spot for “I remember this place.”

## What to look for (evaluation rubric mapping)

- **Emotional** — greetings and arrival lines change across days and visits.
- **Technical** — sessions survive GPS noise (implausible fixes are dropped)
  and pauses; ending a session always produces a summary + memory.
- **Modular** — `swift run waykin-sim --experience orc-pursuit` swaps the
  entire experience with one argument; the engine code path is identical.
- **Delight** — after catching the ghost, check tomorrow's recommendations:
  the engine steers you toward something you haven't tried.
