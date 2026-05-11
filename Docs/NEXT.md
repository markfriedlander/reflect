# NEXT — Reflect: Creative Sparks

The unification work and v1.0 feature set are code-complete. Two
human-loop steps remain before shipping; everything after that is
either App Store Connect work or post-release polish.

---

## Ship Sequence (morning of release)

### 1. Bundle ID change (Xcode, ~5 min)
For Reflect TV target:
`com.MarkFriedlander.Reflect-TV` → `com.MarkFriedlander.Reflect.tv`
Walkthrough in [XCODE_WIRING.md](XCODE_WIRING.md). Required for
Universal Purchase association.

### 2. App Store Connect submission (Chrome, ~30 min)
- Paste content from [AppStore/APP_STORE_CONTENT.md](AppStore/APP_STORE_CONTENT.md).
- Enable Universal Purchase on the iOS app listing.
- Upload new iOS + tvOS builds via Xcode Organizer.
- Confirm Mac (Designed for iPhone) is enabled in App Store availability.
- Submit for review.

### 3. After unified release goes live
- Delist legacy standalone "Reflect TV" listing
  (App Store Connect → legacy listing → Pricing & Availability →
  Remove from Sale).

---

## Post-release (v1.0.x)

### 4. Sit-with sessions
Claude Code wants extended time with each surface to validate timing
choices made on intuition. Specifically:
- TV ambient at full 60–540s dwell for an hour or more.
- iPhone auto/desk mode for a workday.
- Fade durations across all surfaces (0.4s Watch / 0.6s iOS / 1.0s TV).
- Visual weight of pure-white-on-pure-black at different distances.

All these are one-line constants in the view files — single-digit
number changes if anything needs adjusting. v1.0.1 candidates.

### 5. Widget screenshots in App Store gallery
Optional metadata-only update. The widget is a marquee new feature in
"What's New" — worth showing visually.

### 6. Accent color decision
Currently no accent (pure typography). Strategic Claude proposed dim
white-blue. Five-minute change either way once decided.

### 7. AFM safety classifier tuning
The second-pass safety classifier is conservative (rejects benign
prompts like "Pause the clock" alongside genuinely problematic ones).
Behavior is correct per spec — fail-safe to curated — but if AFM
contribution to the buffer feels too thin in practice, consider
narrowing the classifier prompt or relaxing the fail-safe default.

---

## Future Scope (not v1.x)

### 8. Real-device testing on Apple TVs
Your Apple TVs are currently `unavailable` in `devicectl list devices`.
When you have time to re-pair them, install a dev build and validate
the variable-dwell rhythm in real ambient context.

### 9. Variable-dwell distribution v2
The current 24-sided roll (60–90s quick / 360–540s long / 120–300s base)
is a starting point. After weeks of real ambient use, reshape based on
what feels right.

### 10. Curated library v2
Harvest the strongest AFM-generated prompts and promote them into the
curated library. Target stays around 200 — replace weakest curated
entries with strongest generated ones.

---

## Guardrails

- Do not add any feature not on this list without discussing with Mark.
- AFM is progressive enhancement only — never required, always optional.
- The prompt is the product. If a feature would distract from the
  prompt, it doesn't belong in Reflect.
- More black, more silence, larger margins, slower fades. Less.
