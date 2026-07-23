# Waykin TestFlight / RC checklist

```yaml
document_id: WAYKIN-TESTFLIGHT-RC-001
version: 1.0
date: 2026-07-22
status: SUPPORTING
authority: SUPPORTING
baseline_sha: 8beec340311287b015e46b824d0ede2b94d7b0e4
baseline_short: 8beec34
validate_observed: PASS_2026-07-22
outdoor_gate: ISSUE_41_OPEN
```

**Purpose:** Prepare an internal TestFlight release candidate without claiming outdoor AR/GPS PASS or App Store public launch readiness.

**Authority:** Supporting engineering checklist. Does not override `docs/SOLO_MVP_SCOPE.md`, `KNOWN_LIMITATIONS.md`, or issue #41 evidence rules.

**Note (2026-07-23):** Checklist content can land via docs PR without the #216 Info.plist-only commit. After #217 merges, re-pin `baseline_sha` and re-run section 2 gates before archive.

**Who:** Human with Apple Developer Program access for signing, App Store Connect, and upload. Agent can run automated gates and fill OBSERVED/NOT_COMPUTABLE rows.

---

## 0. Precondition snapshot (fill at cut)

| Field | Value at cut |
| ----- | ------------ |
| Cut `git_sha` (full) | `8beec340311287b015e46b824d0ede2b94d7b0e4` (refresh if main moves) |
| Cut date (UTC) | 2026-07-22 |
| Branch | `main` (or RC branch named below) |
| `make validate` | **PASS** (OBSERVED on baseline; re-run on cut) |
| Open product blockers | #41 outdoor COH still open — ship only as **internal** TF with known limitations |
| Dirty tree | Only intentional RC commits |

If tip moves after this doc’s baseline, re-run section 2 and rewrite the SHA rows.

---

## 1. Version & identity

| Item | Current (baseline) | RC action |
| ---- | ------------------ | --------- |
| Display name | Waykin | Keep |
| Bundle ID (app) | `com.waykin.WaykinApp` | Confirm team ownership in Apple Developer |
| AR Lab bundle | `com.waykin.arlab` | **Do not** upload Lab as consumer TF unless intentional |
| Marketing version | `1.0` (`CFBundleShortVersionString`) | Set explicit RC (e.g. `0.9.0` internal or `1.0.0` if product accepts) in `project.yml` **and** regenerate |
| Build number | `1` (`CFBundleVersion`) | **Must bump** per TF upload (monotone integer) |
| Deployment target | iOS 17.0 | Confirm tester devices ≥ 17 |
| App icon | `AppIcon` full set present (incl. 1024) | Spot-check on device home screen |
| Display font | `WaykinDisplay-Regular.ttf` in `UIAppFonts` | Splash only; no DM Sans claim |
| Encryption | `ITSAppUsesNonExemptEncryption` = false | Shipped in project.yml (#215); Info.plist sync PR recommended |
| Privacy manifest | `App/Resources/PrivacyInfo.xcprivacy` | Present; tracking false; UserDefaults CA92.1 |

### Recommended pre-upload version edit (when product picks numbers)

In `project.yml` under `WaykinApp` `info.properties` / settings, set marketing + build explicitly, then:

```bash
xcodegen generate
# Confirm App/Info.plist CFBundleShortVersionString / CFBundleVersion
git add project.yml App/Info.plist
```

Do **not** upload build `1` repeatedly after the first TF binary.

---

## 2. Automated engineering gates

Run from repo root on the **exact** cut SHA:

```bash
git checkout main && git pull --ff-only
git rev-parse HEAD
make check-core-isolation
make check-lira-usdz
make validate-collaboration
make validate
git diff --check
# Optional for UI-heavy RC:
# make validate-simulator
```

| Gate | Required | Result (fill) |
| ---- | -------- | ------------- |
| core isolation | PASS | |
| lira usdz (Meshy ≤ soft budget) | PASS | |
| collaboration coordination | PASS | |
| make validate (package + native best-effort) | PASS | |
| git diff --check | PASS | |
| validate-simulator | Recommended if UI changed since last TF | |
| CI on cut commit (GitHub Actions) | PASS | |

**Baseline OBSERVED (2026-07-22 on `8beec34`):** isolation PASS, usdz PASS (`MESHY_TEXTURED_STATIC_V1`, ~10.0 MB), collab PASS, validate PASS (126 package tests + WaykinApp native build).

---

## 3. Legal / privacy / entitlements

| Artifact | Status | RC note |
| -------- | ------ | ------- |
| `docs/legal/PRIVACY.md` | Present; status **DRAFT_FOR_PRODUCT_REVIEW** | Product must approve or replace before **public** App Store; internal TF can use draft if testers are informed |
| `docs/legal/TERMS.md` | Present | Same review gate for public store |
| `docs/legal/SAFETY.md` | Present | Walking safety expectations |
| `docs/legal/NOTICES.md` | Present | Third-party / Apple frameworks |
| `LICENSE` | Apache-2.0 | OSS; App Store listing is separate |
| Location When-In-Use usage string | In Info.plist | Foreground walk only |
| Camera usage string | In Info.plist | AR session only |
| Health share usage string | In Info.plist | Optional enrichment; Demo never requires |
| `App/Waykin.entitlements` | HealthKit **share** (read path) | No Health write; no background location |
| Background location | **Not** entitled | Correct for MVP |
| App Tracking Transparency | Not used | Privacy manifest `NSPrivacyTracking` false |
| Encryption export | Exempt declaration | `ITSAppUsesNonExemptEncryption` false |

**Human legal actions remaining**

- [ ] Product review of PRIVACY/TERMS (or jurisdiction-specific store policy URL)
- [ ] App Store Connect privacy questionnaire aligned with local-first + no analytics
- [ ] Support contact if TF is external (not only internal team)

---

## 4. Product readiness matrix

| Area | Gate for **internal** TF | Outdoor/public claim |
| ---- | ------------------------ | -------------------- |
| Demo walk | Completes; summary/memory; no location required | N/A |
| Real walk | Permission honesty; pause when inactive/background | GPS quality still #41 |
| AR | Plants/clears; freeze compliance; Meshy package loads or soft fallback | Outdoor COH #41 |
| Continuity | Indoor hybrid smoke preferred before TF wave | Outdoor re-walk after mitigations |
| Path / map | Presentation-only; clears on end/fail | Outdoor map readability NOT_COMPUTABLE |
| HealthKit | Optional; deny path still walks | Device auth/lifecycle evidence open |
| Audio | Bundled cues present; soft silence on failure | Outdoor audibility open |
| Persistence | Bond + memories; degraded state visible | Multi-device CloudKit deferred |
| Field receipts | Schema **5**; share privacy-filtered JSON | Engineering only, not analytics |
| Accessibility | UI smoke / a11y order in tests | Physical VO optional residual |
| Glasses glance | Flag default off | Physical glasses NOT_COMPUTABLE |

### Strongly recommended before first external tester wave

1. Indoor AR hybrid smoke on cut SHA — fill `docs/design/receipts/INDOOR_AR_HYBRID_SMOKE_*_PENDING.md`
2. At least one Demo walk + one short real walk on a named iPhone
3. Confirm Settings → field-test receipt share works and JSON has no coordinates

### Not required to block **internal** TF

- Full outdoor #41 COH PASS (document as known limitation)
- AI Directors, Watch, CloudKit, Path v2, Health write

---

## 5. Assets & size

| Asset | Check |
| ----- | ----- |
| `Lira_AR_Base.usdz` / Companion Lira package | `make check-lira-usdz` PASS; soft budget ≤ 12 MB |
| Session stills / skins | Dawn/Veil/Rupture present as shipped |
| Audio WAVs under `App/Resources/Audio/` | Present for catalog kinds |
| App icon 1024 | Present for store/TF marketing |
| No debug-only secrets in Release | Operator debug behind DEBUG / flag only |

---

## 6. Signing & App Store Connect (human)

| Step | Owner | Status |
| ---- | ----- | ------ |
| Apple Developer team selected | Human | NOT_COMPUTABLE for agent-only sessions |
| Distribution certificate + App Store/TF profile | Human | |
| App record in App Store Connect (`com.waykin.WaykinApp`) | Human | |
| Internal testing group created | Human | |
| Export compliance (encryption) matches plist | Human | |
| Content rights / age rating questionnaire | Human | Walking / AR; no UGC marketplace |
| TestFlight “What to Test” notes pasted (section 8) | Human | |

### Archive commands (run only when human confirms signing)

```bash
# Prefer Xcode Organizer for first RC.
# CLI sketch (adjust team/signing as needed):
xcodegen generate
xcodebuild -scheme Waykin -destination 'generic/platform=iOS' \
  -configuration Release archive -archivePath /tmp/Waykin.xcarchive
```

Tag only after a successful archive of the intended SHA:

```bash
git tag -a v0.9.0-tf1 -m "Waykin internal TestFlight cut $(git rev-parse --short HEAD)"
# git push origin v0.9.0-tf1   # only when human requests
```

---

## 7. Smoke on TestFlight build (device)

Install the **TF binary** (not a local Debug mix). Record device model + iOS.

| ID | Check | Result |
| -- | ----- | ------ |
| TF1 | Cold launch → splash → Home | |
| TF2 | Demo Begin Walk → pause/end → summary | |
| TF3 | Real walk permission path; deny still allows Demo | |
| TF4 | Optional: short real walk distance ticks | |
| TF5 | Open AR; plant; leave clean; re-open single Lira | |
| TF6 | Reduce Motion readable | |
| TF7 | Background during walk pauses safely | |
| TF8 | Health deny does not brick walk | |
| TF9 | Field receipt share (if enabled in that build) | |
| TF10 | No crash on first-run onboarding/legal | |

Mark PASS / FAIL / NOT_COMPUTABLE. Open **separate** defect issues for FAILs.

---

## 8. Release notes templates

### TestFlight “What to Test”

```text
Waykin internal RC — companion walk loop (Demo + real walk).

Please try:
1) Demo Walk end-to-end (no location needed)
2) Real walk permission + short outdoor or indoor walk
3) AR plant / leave / re-open (table or floor is fine indoors)
4) Pause, End, background briefly during a walk
5) Optional: deny Health and confirm walk still works

Known limitations (do not file as “missing cloud”):
- Outdoor AR/GPS quality still under issue #41 (not claimed PASS)
- No accounts, multiplayer, Watch app, or cloud sync
- Field-test receipts are privacy-filtered engineering exports only

Build SHA: <paste full SHA>
```

### GitHub / internal changelog

```markdown
## Waykin <version> (<build>)
### User-facing
- Companion Walk loop (Demo + real walk), Lira presence, Bond, semantic audio
- Session map presentation (not navigation-grade)
- Optional HealthKit step/distance enrichment
- AR presentation with packaged Meshy Lira mid-LOD (freeze maintenance path)

### Engineering / known limitations
- Outdoor AR/GPS/audio quality: issue #41 — NOT_COMPUTABLE until daylight COH on this tip
- Privacy notice still DRAFT_FOR_PRODUCT_REVIEW for public store
- Local-first persistence only (no CloudKit)

### SHA
<code>
```

---

## 9. Store blockers vs internal TF

| Item | Blocks **public** App Store? | Blocks **internal** TF? |
| ---- | ---------------------------- | ----------------------- |
| #41 outdoor COH incomplete | Soft (honesty in notes); not a binary reject by itself | **No** if documented |
| PRIVACY.md draft status | **Yes** for public listing trust | Prefer fix; soft for closed TF |
| Missing build number bump | Upload may replace poorly | **Yes** — bump build |
| Signing / ASC app record | **Yes** | **Yes** |
| PrivacyInfo.xcprivacy | **Yes** (submission) | Should be present (#215) |
| Encryption declaration | **Yes** | Should be present |
| AI / Watch / multiplayer missing | No (out of scope) | No |

---

## 10. RC decision

| Verdict | Criteria |
| ------- | -------- |
| **READY for internal TestFlight** | Section 2 green on cut SHA; section 3 usage strings + privacy manifest + encryption present; section 6 signing ready; known limitations listed in TF notes |
| **BLOCKED** | Validate red; missing PrivacyInfo; wrong entitlements (e.g. background location added accidentally); no signing; critical crash on TF1–TF2 |
| **NOT READY for public App Store** | Until product-reviewed legal URLs/policy, outdoor honesty narrative, and product sign-off beyond internal TF |

### Baseline verdict (2026-07-22, `8beec34`)

| Dimension | Verdict |
| --------- | ------- |
| Engineering package/native validate | **READY** (re-confirm on cut) |
| Privacy manifest + encryption | **READY** (Info.plist tracked sync PR optional hygiene) |
| Legal product review | **OPEN** (draft privacy) |
| Outdoor evidence | **Residual** (#41) |
| TestFlight readiness | **READY for internal TF** once human signing + build number bump |
| App Store public | **BLOCKED** pending legal review + product outdoor honesty + release decision |

---

## 11. Human actions remaining (checklist)

- [ ] Merge Info.plist encryption sync if still open
- [ ] Choose marketing version + bump build number
- [ ] Re-run `make validate` on final cut SHA
- [ ] (Recommended) Indoor smoke I1–I12 on that SHA
- [ ] Archive Release with correct team signing
- [ ] Upload to App Store Connect → Internal Testing
- [ ] Paste “What to Test” with SHA
- [ ] Run TF1–TF10 on at least one physical iPhone
- [ ] File defects as new issues (do not expand #41 into implementation)
- [ ] Schedule daylight #41 when weather/time allows (parallel track)

---

## Related

- [`KNOWN_LIMITATIONS.md`](../../KNOWN_LIMITATIONS.md)
- [`INDOOR_AR_HYBRID_SMOKE.md`](INDOOR_AR_HYBRID_SMOKE.md)
- [`docs/legal/PRIVACY.md`](../legal/PRIVACY.md)
- [`AR_MVP_FREEZE.md`](AR_MVP_FREEZE.md)
- Issue [#41](https://github.com/scrimshawlife-ctrl/Waykin/issues/41)
- Skill: `/waykin-release`
