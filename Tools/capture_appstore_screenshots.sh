#!/usr/bin/env bash
# capture_appstore_screenshots.sh — capture App Store submission screenshots
# across iPhone 6.9", iPad 13", Apple TV, Apple Watch, Mac.
#
# Each platform gets 4 distinctive prompts (so 4 screenshots), captured
# by launching the app, screenshotting, tapping/advancing, screenshotting,
# repeating. The prompts shown are real prompts from the library — the
# engine picks them with cluster avoidance, so 4 successive shots will
# span 4 different moves.

set -euo pipefail

OUT="Docs/AppStoreScreenshots"
mkdir -p "$OUT"

IPHONE="D96CD217-387F-4221-A2AA-80B3E737A710"        # iPhone 17 Pro Max (6.9")
IPAD="4FC0428B-24E2-45C1-89AF-907446C48DCD"          # iPad Pro 13-inch (M5)
TV="A6916B9B-A116-41EF-9EF9-5CA43371AA64"            # Apple TV 4K
WATCH="F5D663BA-1F5C-44EA-B832-1FC66FEE56E9"         # Apple Watch Ultra 3 49mm

iOS_BUNDLE="com.MarkFriedlander.Reflect"
TV_BUNDLE="com.MarkFriedlander.Reflect-TV"
WATCH_BUNDLE="com.MarkFriedlander.Reflect.watchkitapp"

# Build for each platform
echo "→ Building Reflect (iOS)…"
xcodebuild -project Reflect.xcodeproj -scheme Reflect -configuration Debug \
    -destination "id=$IPHONE" build 2>&1 | grep -E "BUILD" | tail -1
echo "→ Building Reflect (iPad)…"
xcodebuild -project Reflect.xcodeproj -scheme Reflect -configuration Debug \
    -destination "id=$IPAD" build 2>&1 | grep -E "BUILD" | tail -1
echo "→ Building Reflect TV…"
xcodebuild -project Reflect.xcodeproj -scheme "Reflect TV" -configuration Debug \
    -destination "id=$TV" build 2>&1 | grep -E "BUILD" | tail -1
echo "→ Building Reflect Watch…"
xcodebuild -project Reflect.xcodeproj -scheme "Reflect Watch Watch App" -configuration Debug \
    -destination "id=$WATCH" build 2>&1 | grep -E "BUILD" | tail -1

IOS_APP=$(find ~/Library/Developer/Xcode/DerivedData/Reflect-*/Build/Products/Debug-iphonesimulator -name "Reflect.app" -maxdepth 2 -type d | head -1)
TV_APP=$(find ~/Library/Developer/Xcode/DerivedData/Reflect-*/Build/Products/Debug-appletvsimulator -name "Reflect TV.app" -maxdepth 2 -type d | head -1)
WATCH_APP=$(find ~/Library/Developer/Xcode/DerivedData/Reflect-*/Build/Products/Debug-watchsimulator -name "Reflect Watch Watch App.app" -maxdepth 2 -type d | head -1)

# Helper: boot a sim (idempotent)
boot() {
    local id=$1
    xcrun simctl boot "$id" 2>/dev/null || true
    sleep 1
}

# Helper: take labelled screenshot
shot() {
    local id=$1
    local label=$2
    xcrun simctl io "$id" screenshot "$OUT/$label.png" >/dev/null 2>&1
}

# === iPhone 6.9" (4 shots) ===
echo "→ iPhone 6.9\" screenshots…"
boot "$IPHONE"
xcrun simctl install "$IPHONE" "$IOS_APP"
for i in 1 2 3 4; do
    xcrun simctl terminate "$IPHONE" "$iOS_BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$IPHONE" "$iOS_BUNDLE" >/dev/null
    sleep 2
    shot "$IPHONE" "iphone-6_9-$i"
done

# === iPad 13" (4 shots) ===
echo "→ iPad 13\" screenshots…"
boot "$IPAD"
xcrun simctl install "$IPAD" "$IOS_APP"
for i in 1 2 3 4; do
    xcrun simctl terminate "$IPAD" "$iOS_BUNDLE" 2>/dev/null || true
    xcrun simctl launch "$IPAD" "$iOS_BUNDLE" >/dev/null
    sleep 2
    shot "$IPAD" "ipad-13-$i"
done

# === Apple TV (4 shots) ===
# Use the QA env var to advance through cards quickly
echo "→ Apple TV screenshots…"
boot "$TV"
xcrun simctl install "$TV" "$TV_APP"
xcrun simctl terminate "$TV" "$TV_BUNDLE" 2>/dev/null || true
SIMCTL_CHILD_REFLECT_TV_QA_DWELL=1 xcrun simctl launch "$TV" "$TV_BUNDLE" >/dev/null
sleep 6  # let launch title fade out
for i in 1 2 3 4; do
    shot "$TV" "appletv-$i"
    # Advance via idb HID Return (Select)
    idb ui key --udid "$TV" 40 2>/dev/null || true
    sleep 5
done

# === Apple Watch (4 shots) ===
echo "→ Apple Watch screenshots…"
boot "$WATCH"
xcrun simctl install "$WATCH" "$WATCH_APP"
xcrun simctl terminate "$WATCH" "$WATCH_BUNDLE" 2>/dev/null || true
xcrun simctl launch "$WATCH" "$WATCH_BUNDLE" >/dev/null
sleep 3
for i in 1 2 3 4; do
    shot "$WATCH" "watch-$i"
    # Tap to advance
    idb ui tap --udid "$WATCH" 150 200 2>/dev/null || true
    sleep 2
done

# === Mac (4 shots) — uses the iPhone-on-Mac runtime ===
# Mac launch needs Xcode AppleScript. We use the existing mac_run.sh.
echo "→ Mac screenshots…"
pkill -f "Wrapper/Reflect.app" 2>/dev/null || true
sleep 1
./Tools/mac_run.sh run >/dev/null 2>&1
# Wait for Mac process
end=$(($(date +%s) + 45))
while [ $(date +%s) -lt $end ]; do
    if ps aux | grep "Wrapper/Reflect.app" | grep -v grep >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
sleep 3
# Bring Reflect to front and capture
osascript -e 'tell application id "com.MarkFriedlander.Reflect" to activate' 2>/dev/null || true
sleep 1
# Generate a Swift one-liner click at center to advance, capture each time
cat > /tmp/mac_click.swift <<'EOF'
import CoreGraphics
import Foundation
let loc = CGPoint(x: 415, y: 260)
let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: loc, mouseButton: .left)
let up   = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,   mouseCursorPosition: loc, mouseButton: .left)
down?.post(tap: .cghidEventTap); up?.post(tap: .cghidEventTap)
EOF
for i in 1 2 3 4; do
    osascript -e 'tell application id "com.MarkFriedlander.Reflect" to activate' 2>/dev/null || true
    sleep 1
    screencapture -x -R 122,30,586,460 "$OUT/mac-$i.png" 2>/dev/null
    swift /tmp/mac_click.swift 2>/dev/null
    sleep 2
done
pkill -f "Wrapper/Reflect.app" 2>/dev/null || true

echo
echo "Done. Output in $OUT/"
ls "$OUT/" | head -30
