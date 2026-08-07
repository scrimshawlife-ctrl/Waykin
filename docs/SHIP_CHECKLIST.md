# Ship Checklist

Pre–TestFlight / App Store checklist for **Waykin** (Zero State / Zero State LLC).

Detailed RC engineering checklist: [design/TESTFLIGHT_RC_CHECKLIST.md](design/TESTFLIGHT_RC_CHECKLIST.md).  
Version policy: [VERSIONING.md](VERSIONING.md). Validation: [TESTING.md](TESTING.md).

Owner actions that need Apple Developer / vendor accounts are marked **(owner)**.

---

## 0. Version and repo hygiene

- [ ] `python3 Tools/version.py show` matches intended cut
- [ ] `python3 Tools/version.py check` passes
- [ ] `CHANGELOG.md` has a dated section for this version
- [ ] Git tag `vMAJOR.MINOR.PATCH` after merge to `main`
- [ ] CI green on release commit (validate + package + native-ios)
- [ ] No secrets, signing certs, or private field receipts in the tree
- [ ] LICENSE remains proprietary Zero State terms

**1.0.0** = first public soft-launch / App Store candidate. `0.9.x` = internal TestFlight evidence cuts.

---

## 1. Product completeness (MVP)

- [ ] Walking session loop: home → real/demo walk → summary → memory
- [ ] Lira companion runtime + Bond progression local persistence
- [ ] Semantic audio path with safe silence
- [ ] AR presentation path frozen MVP (or explicitly documented exceptions)
- [ ] Walk remains safe/completable when AR denied, unavailable, or degraded
- [ ] Demo Mode parity with canonical loop (no location required)
- [ ] Pause / stop always available; pursuit never coerces through distress

---

## 2. App Store Connect **(owner)**

- [ ] App record + bundle id reserved
- [ ] Display name **Waykin**
- [ ] Age rating questionnaire complete
- [ ] Privacy Nutrition Labels match real HealthKit / Location / Camera usage
- [ ] Privacy policy URL live ([docs/legal/PRIVACY.md](legal/PRIVACY.md) source)
- [ ] Support / marketing URLs as needed
- [ ] Encryption export compliance (`ITSAppUsesNonExemptEncryption` = false if still accurate)
- [ ] Pricing / availability for soft-launch geos agreed

---

## 3. Entitlements and permissions

- [ ] Location When-In-Use usage string accurate
- [ ] Camera usage string accurate (AR)
- [ ] HealthKit share usage string accurate; Demo never requires Health
- [ ] Background audio mode only as required for pocket-safe cues
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) present and reviewed

---

## 4. Store listing assets

- [ ] App icon final
- [ ] Screenshots (iPhone; iPad if offered)
- [ ] Optional preview video
- [ ] Description, keywords, what’s new
- [ ] Marketing claims do **not** overstate outdoor AR/GPS evidence

---

## 5. Evidence gates (do not skip)

- [ ] Indoor smoke on named build SHA
- [ ] Outdoor walk receipts per [PHYSICAL_DEVICE_WALK_VALIDATION.md](PHYSICAL_DEVICE_WALK_VALIDATION.md) for any GPS/AR outdoor claim
- [ ] Audio interruption / route-change smoke on device
- [ ] #41 (or successor) status recorded honestly (`PARTIAL` / open / closed)

---

## 6. TestFlight

- [ ] Internal TF build installed on owner device
- [ ] Crash-free Demo + short real walk
- [ ] Legal/onboarding acknowledgment path works
- [ ] External group only after indoor+basic outdoor smoke

---

## 7. Release day

- [ ] Version bumped; changelog finalized
- [ ] Submit with complete review notes (no login if none)
- [ ] Monitor crashes 48h; rollback plan known
- [ ] Tag release; update ROADMAP status if milestone crossed

---

## Related

- [ROADMAP.md](../ROADMAP.md)
- [KNOWN_LIMITATIONS.md](../KNOWN_LIMITATIONS.md)
- [SECURITY.md](../SECURITY.md)
- [waykin-release skill](../skills/waykin-release/SKILL.md)
