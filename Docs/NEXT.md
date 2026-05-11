# NEXT — Reflect: Creative Sparks

The unification work is done in code. What remains is human-loop work —
device testing, App Store Connect, App Store metadata, and one bundle ID
change that needs Mark's hands.

## Immediate (Mark, this week)

### 1. Change Reflect TV bundle ID
For Universal Purchase, change in Xcode:
`com.MarkFriedlander.Reflect-TV` → `com.MarkFriedlander.Reflect.tv`
in the **Reflect TV** target's Signing & Capabilities. Will require
generating new provisioning profile.

### 2. Real-device test pass
- iPhone 16 Plus AFM — **verified** during QA pass (see QA_REPORT.md).
  No further action needed unless you want to re-test after any AFM
  prompt or validator changes.
- Mac runtime — **verified** via `./Tools/mac_run.sh run`. Full-screen
  toggle and longer-session feel are still worth a real sit-with.
- iPad — verify identical iPhone behavior at iPad layout.
- Apple TV — sit with ambient mode for an hour on real hardware. Does
  the variable dwell feel right? Adjust constants in
  `tvOS/TVContentView.swift#nextDwellSeconds()` if not.
- Apple Watch — tap behavior + haptic on real wrist (sim verified the
  call fires; only your wrist tells you if it feels right).

### 3. Accent color decision
Currently no accent (pure typography). Strategic Claude proposed a dim
white-blue or none at all. If white-blue is wanted, tell Claude Code —
gets wired into the toast text and possibly the TV launch title.

---

## Release

### 4. Universal Purchase setup
App Store Connect: associate the tvOS build with the existing iOS app
record. Confirm metadata pulls correctly.

### 5. Delist legacy TV app
Only AFTER the unified release ships and is downloadable.

### 6. App Store metadata refresh
- Display name (Springboard): "Reflect"
- Full name (App Store): "Reflect: Creative Sparks"
- Description: emphasize ambient mode (the new thing) without naming AFM.

---

## Post-release

### 7. Watch complication
The single most Eno-native surface. Rectangular complication family,
~1 short prompt refreshing on the OS widget budget (a few times an hour).

### 8. Variable-dwell tuning
After a few weeks of real use, revisit the TV dwell distribution.

### 9. Curation pass v2
Harvest the strongest AFM-generated prompts and promote them into the
curated library.

---

## Guardrails

- Do not add any feature not on this list without discussing with Mark.
- AFM is progressive enhancement only — never required, always optional.
- The prompt is the product. If a feature would distract from the prompt,
  it doesn't belong in Reflect.
- More black, more silence, larger margins, slower fades. Less.
