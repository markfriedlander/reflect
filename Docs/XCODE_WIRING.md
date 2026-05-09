# Xcode Wiring Guide — Reflect Unification

These are the steps to wire the new file structure into the existing
`Reflect.xcodeproj`. Claude Code wrote all the Swift; you do the
project-file work in Xcode itself so nothing gets corrupted.

Estimated time: 15–25 minutes. Take it slow, save often.

---

## Before you start

Quit Xcode, then make a backup just in case:

```sh
cd ~/Desktop/Fun
cp -R Reflect Reflect-backup-$(date +%Y%m%d)
```

Then reopen `Reflect.xcodeproj` in Xcode.

---

## Step 1 — Add the four new folder groups

In the Project Navigator (left pane), the project root currently has:
- Reflect (group, contains old iOS files)
- Reflect TV (group, contains old TV files)
- Reflect Watch Watch App (group, contains old Watch files)

You'll **add four new groups at the project root**, each pointing to the
corresponding folder on disk.

For each of `Shared`, `iOS`, `tvOS`, `Watch`:

1. Right-click the project root in the Navigator → **Add Files to "Reflect"…**
2. Navigate to the folder on disk (`Reflect/Shared`, etc.)
3. **Important checkboxes in the dialog:**
   - ☑ Create groups (NOT "Create folder references")
   - ☐ Copy items if needed (leave UNCHECKED — files are already in place)
   - **Add to targets: see table below.**

| Folder   | Target memberships                      |
|----------|------------------------------------------|
| Shared   | ☑ Reflect  ☑ Reflect TV  ☑ Reflect Watch Watch App |
| iOS      | ☑ Reflect (only)                         |
| tvOS     | ☑ Reflect TV (only)                      |
| Watch    | ☑ Reflect Watch Watch App (only)         |

**Special case for `iOS/WatchContentView.swift`:** after adding the iOS
group, click that one file in the Navigator and in the right-side File
Inspector (⌥⌘1), set its target membership to **only** "Reflect Watch Watch App"
— uncheck "Reflect". The file lives in the iOS folder for organizational
reasons but belongs to the Watch target.

---

## Step 2 — Remove the legacy files

The old per-target files are now superseded. Remove them all in one pass:

1. In the Navigator, select these files (Cmd-click to multi-select):
   - `Reflect/ContentView.swift`
   - `Reflect/Prompts.swift`
   - `Reflect/ReflectApp.swift`
   - `Reflect TV/ContentView.swift`
   - `Reflect TV/Reflect_TVApp.swift`
   - `Reflect Watch Watch App/ContentView.swift`
   - `Reflect Watch Watch App/Reflect_WatchApp.swift`

2. Right-click → **Delete** → choose **Move to Trash** (not "Remove References").

This step is required — if you skip it, you'll get duplicate `@main`
errors because both the old and new `ReflectApp` structs will exist.

The empty parent groups (`Reflect`, `Reflect TV`, `Reflect Watch Watch App`)
can stay if they still hold Assets.xcassets, Info.plist, etc. — only the
`.swift` files above need to go.

---

## Step 3 — Verify deployment targets

Click the project (top of Navigator) → select each target in turn → **General** tab.

| Target                       | Minimum Deployment |
|------------------------------|--------------------|
| Reflect (iOS)                | iOS 18.0           |
| Reflect TV (tvOS)            | tvOS 18.0          |
| Reflect Watch Watch App      | watchOS 11.0       |

Mac support: ensure under "Supported Destinations" for the iOS target,
**"Mac (Designed for iPhone)"** is enabled. This is the iPhone-binary-on-Mac
path. Do NOT add Mac Catalyst.

---

## Step 4 — Verify bundle IDs (CRITICAL for App Store update path)

The unified app must update the existing iOS App Store listing in place.
That means the **iOS target's bundle ID must match the existing iOS app's
bundle ID exactly.**

1. Select the **Reflect** target → **Signing & Capabilities** → check
   the Bundle Identifier matches what's currently live on the App Store
   for the iOS Reflect listing.
2. The **Reflect TV** target's bundle ID should be a child of the iOS
   bundle ID (e.g. `com.yourname.Reflect.TV`) — App Store Connect requires
   this for Universal Purchase.
3. The **Watch** target's bundle ID should likewise be a child
   (e.g. `com.yourname.Reflect.watchkitapp`).

If the iOS target's bundle ID does NOT match the live listing, **stop and
ask before proceeding** — changing it later is messier than fixing it now.

---

## Step 5 — FoundationModels framework

The shared `AFMPromptGenerator.swift` uses `import FoundationModels`,
gated behind `#if canImport(FoundationModels)`. This means:

- On the iOS target: builds against the FoundationModels framework
  automatically (it's a system framework on iOS 18+).
- On the tvOS / Watch targets: `canImport` returns false, AFM stays inert,
  the engine falls back to the curated library. No additional setup.

If iOS build fails with "no such module 'FoundationModels'", verify the
iOS target's deployment is iOS 18+ and the Xcode version supports it.
No manual framework linking should be needed.

---

## Step 6 — Universal Purchase setup (App Store Connect, later)

This isn't an Xcode step but flagging it for the release pass:

1. The new unified iOS app updates the existing iOS listing in place
   (because bundle ID matches).
2. The tvOS target needs to be added to the same App Store Connect record
   as the iOS app — under the iOS app's "App Information" → enable
   "Universal Purchase" if not already, and the tvOS build will associate
   with the same listing.
3. The legacy standalone "Reflect TV" App Store listing gets **delisted**
   (Pricing & Availability → Remove from Sale) only AFTER the unified
   release ships, so existing TV users have a path to the new version.

Don't delist the old TV app before the new one is live and downloadable.

---

## Step 7 — First build

1. Select the **Reflect** scheme, target an iPhone simulator, ⌘B.
2. Select the **Reflect TV** scheme, target an Apple TV simulator, ⌘B.
3. Select the **Reflect Watch Watch App** scheme, target a Watch simulator
   in conjunction with an iPhone, ⌘B.

Expected result: zero warnings, zero errors. Per the CLAUDE.md zero-warnings
rule, anything that pops up gets fixed (or explicitly justified) before
shipping.

If a build fails, screenshot the error and Claude Code can debug it next
session.

---

## Step 8 — Run

- iOS: tap to advance, long-press to toggle auto mode (30s cadence).
- tvOS: ambient cycling with variable dwell time, remote-click to advance.
- Watch: tap to advance with click haptic.

Black background, white text. No chrome.
