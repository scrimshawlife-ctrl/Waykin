# Waykin Demo Script

## Terminal Demo (Fastest)

```bash
cd /path/to/Waykin
swift run WaykinDemo
```

Expected output shows:
- Companion created
- Night recommendations
- Orc Pursuit simulation with threat increasing when stopped
- Memory generated
- Bond increase
- Next-day different recommendations

## Full iOS Flow (in Xcode)

1. `make generate`
2. Open the generated `Waykin.xcodeproj`
3. Select the Waykin scheme and an iPhone Simulator
4. Run the application
5. Use Demo Scenarios or the real-walk entry point

The project already wires:
- MovementEngine
- Experience Packs
- SwiftData for Companion + Memories (file-backed in UI tests)
- MapKit for active session
- RealLocationProvider path (physical device required for live GPS)

## Permission Handling

The core never assumes location is granted. Demo works without any permissions.

## Day / Night

Pass "day" or "night" to RecommendationEngine and ExperienceContext.

This is sufficient to prove the thesis.