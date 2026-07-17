# Known Limitations (MPOC scope)

## Companion & AI
- The live voice is `RuleBasedProvider` — deterministic templates, not a
  hosted LLM. `PromptBuilder` produces the full Phase-7 system prompt, but no
  network provider (Anthropic/OpenAI) is wired in yet, and there is no
  streaming chat UI in the app.
- Memory text is template-generated. It's reliable and offline, but every
  “sunset at the park” reads the same until the AI provider rewrites them.
- No long-term memory summarization; memories accumulate as a flat list.

## AR
- The companion is a placeholder creature (two spheres) with procedural
  motion — follow, bob, celebrate-spin — not a rigged, animated model. It
  proves presence, not art direction.
- Anchoring is camera-relative with plane detection enabled but unused for
  occlusion or ground snapping; the companion can float over uneven terrain.
- AR requires a physical device. The simulator (and onboarding/home screens
  everywhere) use a 2D animated avatar fallback.
- 60 FPS holds with this scene complexity, but no formal battery or thermal
  profiling was done.

## Movement & health
- Activity auto-detection is GPS-speed-based only; CoreMotion/HealthKit are
  not integrated (no step counts, heart rate, or indoor tracking).
- Background tracking is disabled (`allowsBackgroundLocationUpdates = false`);
  lock the phone and the session pauses. Enabling it needs the background
  location entitlement and App Store justification.
- Reverse geocoding picks the first point of interest/street name; it can be
  generic (“Somewhere new”) if geocoding fails or is offline.

## Backend & sync
- No Supabase: everything persists locally in SwiftData. No auth, no cloud
  sync, no cross-device continuity. `MemoryStore` is the seam where a synced
  store would plug in.
- Weather is hardcoded to `clear` in the app (the engines accept real
  weather; no WeatherKit call yet).

## App
- Audio is system sounds + haptics, not designed sound; “heartbeat” is an
  impact haptic. `AudioService` is the swap point.
- No Apple Watch app, no route map rendering on the summary screen, and the
  session screen was verified on simulator with simulated GPS — a real-world
  outdoor field test is still to be done.
- Experience progress does not survive force-quitting mid-session; the
  session is simply lost (no crash, no partial memory).

## Out of scope by design
Multiplayer, marketplace, breeding, battles, commerce, subscriptions, social
feed, inventory, PvP — see the MPOC brief.
