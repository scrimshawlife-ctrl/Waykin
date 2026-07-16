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

1. Create new iOS App project
2. Drag Sources/WaykinCore into the project
3. Implement SwiftUI views using the provided stubs in App/
4. Use MovementEngine in a @ObservableObject
5. Wire experiences as plugins
6. Use SwiftData for Companion + Memories
7. Add MapKit for PHONE_MAP presentation
8. RealityKit for PHONE_AR (stub provided)

## Permission Handling

The core never assumes location is granted. Demo works without any permissions.

## Day / Night

Pass "day" or "night" to RecommendationEngine and ExperienceContext.

This is sufficient to prove the thesis.