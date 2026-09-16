#!/bin/bash
#
# Build Topster and install it to every booted simulator.
#
# Installing to only one simulator is how a stale build ends up in front of someone
# while a fix sits unused on another device. Twice was enough. This always installs
# everywhere, and prints the build timestamp so drift is visible at a glance.
#
# Usage:  scripts/build-install.sh            build and install
#         scripts/build-install.sh --test     also run the UI tests
#
set -e

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED="/tmp/topster-dd"
BUNDLE="com.austinlavalley.Topster"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Topster.app"

cd "$PROJECT_DIR"

booted() {
  xcrun simctl list devices | grep -i booted \
    | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}"
}

DEVICES=$(booted)
if [ -z "$DEVICES" ]; then
  echo "No booted simulators. Start one and try again." >&2
  exit 1
fi

# Build against whichever simulator happens to be booted first.
DEST=$(echo "$DEVICES" | head -1)

xcodebuild build-for-testing \
  -scheme Topster -project Topster.xcodeproj \
  -destination "platform=iOS Simulator,id=$DEST" \
  -derivedDataPath "$DERIVED" 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

for id in $DEVICES; do
  name=$(xcrun simctl list devices | grep "$id" | cut -d"(" -f1 | xargs)
  xcrun simctl terminate "$id" "$BUNDLE" 2>/dev/null || true
  xcrun simctl install "$id" "$APP"
  echo "installed -> $name  ($(stat -f "%Sm" "$APP/Topster"))"
done

if [ "$1" = "--test" ]; then
  xcodebuild test-without-building \
    -scheme Topster -project Topster.xcodeproj \
    -destination "platform=iOS Simulator,id=$DEST" \
    -derivedDataPath "$DERIVED" 2>&1 | grep -E "passed|failed|error:"
fi
