# Xcode Wiring — Superseded

The original step-by-step guide in this file became obsolete on
2026-05-10 when Claude Code wired the project directly via
`Tools/wire_xcode.rb` (Ruby xcodeproj gem) instead of asking Mark
to do it by hand in Xcode.

## What was actually done

Discovered the project uses **Xcode 16 synchronized folder groups**
(`PBXFileSystemSynchronizedRootGroup`). That means file membership in
targets is determined by which folders are in each target's
`fileSystemSynchronizedGroups` array — not by individual file references
in build phases.

So instead of dragging files in Xcode, the wiring needed was:
1. Add `Shared/`, `iOS/`, `tvOS/`, `Watch/` as synchronized groups.
2. Link `Shared/` to all three app targets.
3. Link `iOS/` → Reflect, `tvOS/` → Reflect TV, `Watch/` → Reflect Watch.
4. Bump Watch deployment target 9.6 → 11.0.
5. Remove the obsolete `PBXFileSystemSynchronizedBuildFileExceptionSet`
   entries that used to share `Reflect/Prompts.swift` across targets.

`Tools/wire_xcode.rb` is idempotent. If you ever need to re-wire from
a fresh checkout, run `ruby Tools/wire_xcode.rb`.

## One open item — still needs Mark

The **Reflect TV target's bundle ID** is currently
`com.MarkFriedlander.Reflect-TV` (legacy standalone format). For
App Store Connect Universal Purchase to associate the tvOS build with
the iOS app record, this must change to a child of the iOS bundle ID:
`com.MarkFriedlander.Reflect.tv`.

Left for Mark because the change cascades:
- New provisioning profile needed.
- Coordinate with the legacy TV app delisting.
- App Store Connect record needs to be updated.

Make this change in Xcode → Reflect TV target → Signing & Capabilities,
not via the script.
