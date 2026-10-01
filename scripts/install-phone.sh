#!/bin/bash
#
# Install the newest device build of Topster on the connected iPhone, and open it.
#
# Xcode's Run installs to the phone but never launches the app on this Mac;
# devicectl does both. This takes whatever Xcode built most recently for a device,
# from any copy of the repo, and says which copy and when before touching the phone,
# because installing the wrong copy's build has already cost a device test.
#
# Usage:  scripts/install-phone.sh              install and launch
#         scripts/install-phone.sh --no-launch  install only
#
set -e

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

BUNDLE="com.austinlavalley.Topster"
LAUNCH=yes
if [ "$1" = "--no-launch" ]; then LAUNCH=no; fi

# The newest device build, by when its executable was written.
APP=""
NEWEST=0
for app in "$HOME"/Library/Developer/Xcode/DerivedData/Topster-*/Build/Products/Debug-iphoneos/Topster.app; do
  [ -f "$app/Topster" ] || continue
  built=$(stat -f "%m" "$app/Topster")
  if [ "$built" -gt "$NEWEST" ]; then
    NEWEST=$built
    APP=$app
  fi
done

if [ -z "$APP" ]; then
  echo "No device build found. In Xcode, pick the iPhone as the destination and Build (cmd-B) first." >&2
  exit 1
fi

DERIVED="${APP%%/Build/Products/*}"
PROJECT=$(/usr/libexec/PlistBuddy -c "Print WorkspacePath" "$DERIVED/info.plist" 2>/dev/null || echo "unknown")
echo "build   -> $PROJECT"
echo "built   -> $(stat -f "%Sm" "$APP/Topster")"

# The first iPhone devicectl lists as connected. Matched by its identifier rather
# than by column, since device names can hold anything.
DEVICE=$(xcrun devicectl list devices 2>/dev/null | grep -w "connected" | grep -i "iphone" \
  | grep -oE "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}" | head -1)

if [ -z "$DEVICE" ]; then
  echo "No connected iPhone. Plug it in by USB, unlock it, and run this again." >&2
  exit 1
fi
echo "device  -> $DEVICE"

xcrun devicectl device install app --device "$DEVICE" "$APP"
echo "installed"

if [ "$LAUNCH" = "yes" ]; then
  xcrun devicectl device process launch --terminate-existing --device "$DEVICE" "$BUNDLE" || {
    echo "Installed, but it did not open. Unlock the phone and open Topster by hand." >&2
    exit 1
  }
  echo "launched"
fi
