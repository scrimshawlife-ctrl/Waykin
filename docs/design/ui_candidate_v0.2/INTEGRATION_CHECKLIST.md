# Waykin Visual — Integration Checklist

```yaml
asset_id: WK_REVIEW_IntegrationChecklist_v0.1
version: 0.2
status: PHASE_4_READY
for: manual_integration_after_human_approval
```

Use this checklist when selectively importing candidates into the Waykin application.  
**Do not** treat Stage 8 completion as permission to auto-merge.

---

## A. Pre-integration gates

- [x] Human accepted or modified **REC-001** (Echo brand) in `DESIGN_DECISIONS.md`  
- [x] Human accepted or modified **REC-002** (Living Familiar)  
- [x] Human accepted MVP skins Dawn / Veil / Rupture (or listed exceptions)  
- [x] Confirmed no product-scope changes required beyond listed handoffs  
- [x] Confirmed isolation: design package paths known; app repo separate  

## B. Design tokens

- [ ] Copy `WK_TOKENS_v0.2.json` or map YAML → app theme  
- [ ] Day appearance implements foundation/surface/text/semantic colors  
- [ ] Night appearance is **not** a simple invert  
- [ ] Contrast checked on device outdoors (day) and low light (night)  
- [ ] Disabled opacity 0.35 applied consistently  
- [ ] Focus ring colors applied for keyboard/accessibility where relevant  
- [ ] Reduced-motion preference wired to motion tokens  

## C. Typography

- [ ] Primary font licensed for app (DM Sans OFL or substitute Source Sans 3 / system)  
- [ ] Fallback stack present  
- [ ] Display / title / body / caption / numeric styles mapped  
- [ ] Dynamic Type / system text scaling tested  
- [ ] Uppercase limited to short state/mode chips  

## D. Brand

- [ ] Primary logo SVG (Bond Filament B) refined if needed  
- [ ] App icon produced at required store sizes from approved concept  
- [ ] Wordmark “Waykin” spacing verified at small sizes  
- [ ] Monochrome / single-color reductions tested  

## E. Companion

- [ ] Production mesh/puppet or 2D rig created from Living Familiar direction  
- [ ] Anchors A1–A3 verified in all shipped states  
- [ ] States: dormant, manifesting, guide, rival, hunter, sanctuary, bond update  
- [ ] Hunter uses echo/distortion language; gore review passed  
- [ ] LODs or simplified mid-session representation defined  
- [ ] Reduced-motion static poses available  

## F. Skins

- [ ] Dawn default skin materials  
- [ ] Veil materials + echo intensity  
- [ ] Rupture materials + fracture FX caps  
- [ ] Unlock does not require marketplace MVP  
- [ ] Avatars/portraits generated from production rig (not only exploration gens)  

## G. UI screens (minimum path)

- [ ] Launch  
- [ ] Home (companion, bond, begin)  
- [ ] Session selection (Trail / Race / Hunt)  
- [ ] Preparation  
- [ ] Active session (state, relation, pause)  
- [ ] Pause (non-punitive)  
- [ ] Safety pause (protective)  
- [ ] Sanctuary  
- [ ] Summary (relationship-first)  
- [ ] Bond update (non-XP hero)  
- [ ] Minimal settings (audio, haptics, appearance, reduced motion)  

Optional but recommended:

- [ ] Onboarding intro  
- [ ] Permissions  
- [ ] Safety brief  
- [ ] Companion overview  

## H. State binding

- [ ] App state enum covers guide / rival / hunter / sanctuary / pause / safety / caution / tracking_loss  
- [ ] UI binds color + icon + text for each critical state  
- [ ] Companion relation: ahead / near / behind / pressure  
- [ ] Tracking loss and route uncertainty overlays do not remove End/Pause  

## I. Icons

- [ ] Production icon set per packet §12 inventory  
- [ ] 24px grid, ~1.75 stroke, round caps  
- [ ] Active / disabled / caution states  
- [ ] Outdoor legibility at 16–24 pt  

## J. Safety & accessibility

- [ ] Pause and end always available mid-session  
- [ ] Stopping never styled as failure  
- [ ] Color-vision safe (shape+text redundancy)  
- [ ] One-handed primary targets ≥ 48pt  
- [ ] Audio-off still leaves state legible  
- [ ] Safety copy reviewed (Hunt controlled pressure)  

## K. Audio relationship (no files required here)

- [ ] Guide / rival / hunter / bond / sanctuary motifs planned against visual states  
- [ ] Visual pulse not competing with audio narrative  

## L. Engineering handoffs closed or deferred

For each `HO-*` in `ENGINEERING_HANDOFF.md`:

- [ ] HO-001 Day/night theme — done / deferred / accepted risk  
- [ ] HO-002 Reduced motion — done / deferred / accepted risk  
- [ ] HO-003 Dynamic type — done / deferred / accepted risk  
- [ ] HO-004 Semantic state enum — done / deferred / accepted risk  
- [ ] HO-005 Navigation graph — done / deferred / accepted risk  

## M. Manifest hygiene

- [ ] Each imported asset updated to `EXPORTED` then `INTEGRATED` **by human**  
- [ ] Rejected assets marked `REJECTED` with note  
- [ ] Version bumps if files change post-import  

## N. Post-integration smoke test

- [ ] Cold launch → home  
- [ ] Trail session glanceability  
- [ ] Race session relation readability  
- [ ] Hunt pressure without panic UI  
- [ ] Pause / resume / end  
- [ ] Safety pause tone  
- [ ] Bond update presentation  
- [ ] Day/night switch  
- [ ] Reduced motion on  

## O. Sign-off

```yaml
reviewer:
date:
rec_001: accepted | modified | rejected
rec_002: accepted | modified | rejected
skins: accepted | modified | rejected
tokens_imported: true | false
notes: |
  ...
```

---

**Reminder:** Completing this checklist is a human/engineering process outside the isolated visual workstream’s authority.
