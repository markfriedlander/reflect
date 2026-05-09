# NEXT — Reflect: Creative Sparks

## Immediate (Mark, this week)

### 1. Xcode wiring
Follow [XCODE_WIRING.md](XCODE_WIRING.md) to bring the new file structure
into `Reflect.xcodeproj`. ~15–25 min. The Swift is done; this is just
project-file plumbing.

### 2. Build verification
Build all three schemes against simulators. Zero warnings, zero errors
target. Anything that fails: screenshot for the next Claude Code session.

### 3. Accent color decision
See [VISUAL_NOTES.md](VISUAL_NOTES.md). Either:
- (a) No accent — pure typography, current state.
- (b) The dim white-blue Strategic Claude proposed.
If (b): tell Claude Code in a follow-up and it gets wired into the toast
text and possibly the TV launch title. Body prompts stay pure white
either way.

### 4. App icon
Strategic Claude is producing the spec separately. When ready, wire
into Assets.xcassets and verify all three target sizes.

---

## Near-term (this release)

### 5. First device tests
- iPhone (any iOS 18+ device): tap behavior, long-press auto mode.
- iPad: same as iPhone, verify generous-margin layout works at iPad size.
- Mac: launch via "iPhone & iPad Apps on Mac", verify full-screen toggle.
- Apple TV: variable dwell rhythm feels right, remote click responds
  cleanly.
- Apple Watch: tap + haptic, no accidental advances.

### 6. AFM verification (capable iPhone only)
On an iPhone 15 Pro / 16 Pro with Apple Intelligence enabled:
- Verify the buffer fills silently in the background.
- Verify generated prompts feel indistinguishable from curated.
- If any generated prompt sounds motivational/coachy, tighten the
  banned-vocab list.

---

## Release

### 7. Universal Purchase setup
App Store Connect: associate the tvOS build with the existing iOS app
record. Confirm the listing pulls metadata correctly.

### 8. Delist legacy TV app
Only AFTER the unified release ships and is downloadable. Pricing &
Availability → Remove from Sale on the standalone "Reflect TV" listing.

### 9. App Store metadata refresh
- Display name (Springboard): "Reflect"
- Full name (App Store): "Reflect: Creative Sparks"
- Description: emphasize ambient mode (the new thing) without naming
  AFM (the user shouldn't think about which prompts came from where).

---

## Post-release / Future

### 10. Watch complication
The single most Eno-native surface for Reflect, per Claude Code's
analysis. Rectangular complication families on modular and infograph
faces. One short prompt, refreshing on the OS's widget budget (a few
times an hour at most). Glance down for the time, get a card.

### 11. Variable-dwell tuning
After a few weeks of use, revisit the TV dwell distribution. The
current 24-sided roll is a starting point; we can re-shape based on
what feels right in real ambient use.

### 12. Curation pass v2
After AFM has been generating in the wild for a while, harvest the
best generated prompts and promote them into the curated library.
Targets stay around 200 — replace the weakest curated entries with
the strongest generated ones.

---

## Guardrails

- Do not add any feature not on this list without discussing with Mark.
- AFM is progressive enhancement only — never required, always optional.
- The prompt is the product. If a feature would distract from the prompt,
  it doesn't belong in Reflect.
- More black, more silence, larger margins, slower fades. Less.
