# Waykin Privacy Notice

```yaml
document_id: WAYKIN-LEGAL-PRIVACY
version: 1.0
date: 2026-07-20
status: DRAFT_FOR_PRODUCT_REVIEW
```

**Last updated:** 2026-07-20

This notice describes how the **Waykin** iOS application handles information in its current solo-MVP form. It applies to the open-source project and local builds of the app. A commercial publisher may replace this with a jurisdiction-specific privacy policy before App Store release.

## Summary

| Topic | Practice |
| ----- | -------- |
| Selling personal data | **No** |
| Accounts / cloud login | **Not required** for MVP local walk |
| Precise GPS storage | **Not retained** as a durable path dump in field receipts |
| Camera frames | Used for AR only during an active AR session; **not** kept as a media library |
| Health data | **Optional**; Demo Mode never requires HealthKit |

## What we use

### Location (when you start a real walk)

- **Purpose:** measure distance, pace, and semantic path progress during an **active** movement session.
- **When:** only after you begin a real walk and grant **Location When In Use**.
- **Storage:** session presentation may show a map breadcrumb for the current walk. Field-test receipts are **privacy-filtered** and must not archive precise coordinate dumps or private map imagery.
- **Not used for:** advertising, resale, or background tracking when you are not walking in the app.

### Camera (AR)

- **Purpose:** place the companion and session presentation in the real world (ARKit / RealityKit).
- **When:** only when you open AR during a session and grant camera access.
- **Storage:** camera frames are for live AR; they are not a product feature for export or social upload.

### Health (optional)

- **Purpose:** optional soft enrichment (e.g. recent steps / walking distance band) during an active walk.
- **When:** only if you allow Health access; **Demo Mode never requires Health**.
- **Storage:** not used to build a medical record or competitive fitness profile in MVP.

### Local app data

- Companion bond and session **memories** you create on-device (SwiftData / local store).
- Appearance preference and cosmetic skin selection.
- Optional lab flags (e.g. field-test receipts) on developer builds.

### Audio

- On-device cue playback for presence language. No cloud speech transcription in MVP.

## What we do not do (MVP)

- Require a social network or multiplayer identity
- Sell or broker personal data
- Use location for advertising networks
- Claim medical, fitness coaching, or emergency services

## Your choices

- Deny location and use **Demo Mode** for offline presentation.
- Deny camera and skip AR; the walk can still run without AR.
- Deny Health; walk and demo still work.
- Clear local app data by deleting the app (standard iOS behavior).

## Children

Waykin is not directed at children under 13. Do not use the app if you are not permitted by applicable law or by a parent/guardian.

## Contact

For privacy questions about **this open-source repository**, open a GitHub issue on the project.  
Commercial operators should publish a support contact before public distribution.

## Changes

Material changes to this notice should bump `version` / `date` and be called out in release notes.
