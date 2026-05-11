#!/usr/bin/env bash
# mac_run.sh — Build + launch Reflect as a Mac (Designed for iPad) app.
#
# Why this script exists: the iOS-on-Mac runtime is gated through Xcode's
# run action. xcodebuild alone can build, but only Xcode's run can produce
# the system-managed wrapper that LaunchServices will accept. We drive
# Xcode programmatically via osascript — no GUI clicks needed.
#
# Use: ./Tools/mac_run.sh           — build + launch
#      ./Tools/mac_run.sh build     — build only (fast, no launch)
#      ./Tools/mac_run.sh stop      — terminate the running Mac instance
#
# Note: the launch path needs Xcode to be open. If it's closed, the
# osascript step will open it for you (visible).

set -euo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)/Reflect.xcodeproj"
SCHEME="Reflect"
MAC_UDID="00008112-0010193C3A88C01E"   # `xcodebuild -showdestinations` → name=My Mac

cmd="${1:-run}"

case "$cmd" in
    build|run)
        echo "→ Building for Mac (Designed for iPad)…"
        xcodebuild build \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "id=$MAC_UDID" \
            -configuration Debug \
            2>&1 | grep -E "error:|warning:|BUILD SUCCEEDED|BUILD FAILED" || true
        ;;
esac

case "$cmd" in
    run)
        echo "→ Launching via Xcode…"
        osascript <<'EOF'
tell application "Xcode"
    stop active workspace document
    delay 2
    run active workspace document
end tell
EOF
        echo "→ Launched. Process: $(ps aux | grep "Wrapper/Reflect.app" | grep -v grep | awk '{print $2}' | head -1)"
        ;;
    stop)
        echo "→ Stopping…"
        osascript -e 'tell application "Xcode" to stop active workspace document' >/dev/null 2>&1 || true
        pkill -f "Wrapper/Reflect.app" 2>/dev/null || true
        echo "→ Stopped."
        ;;
esac
