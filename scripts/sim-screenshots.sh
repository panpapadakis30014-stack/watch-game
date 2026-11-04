#!/usr/bin/env bash
# Builds the watch app for the simulator and saves real screenshots of
# Ringward (start, mid-game), the game picker and Lanternfall (start,
# mid-game, level-up) on Apple Watch SE 40mm and 44mm (2nd generation), all
# from seeded demo states. A missing runtime or device type is logged and
# skipped; build, install and launch failures fail the step.
set -euo pipefail

BUNDLE_ID="com.panos30013.ringward.watchkitapp"

SDKVER="$(xcrun --sdk watchsimulator --show-sdk-version)"
RUNTIME="$(xcrun simctl list runtimes -j | jq -r --arg v "$SDKVER" \
  '[.runtimes[] | select(.platform=="watchOS" and .isAvailable and (.version|startswith($v)))][0].identifier // empty')"
if [ -z "$RUNTIME" ]; then
  echo "::warning::No watchOS $SDKVER simulator runtime; skipping screenshots"
  exit 0
fi
echo "Using runtime $RUNTIME"

xcodebuild build \
  -project Ringward.xcodeproj \
  -scheme RingwardWatch \
  -configuration Debug \
  -destination 'generic/platform=watchOS Simulator' \
  -derivedDataPath build/sim \
  CODE_SIGNING_ALLOWED=NO
APP="build/sim/Build/Products/Debug-watchsimulator/RingwardWatch.app"
# Ad-hoc signature so arm64 simulators accept the app.
codesign --force --sign - --timestamp=none "$APP"

mkdir -p shots
for entry in "se40|Apple Watch SE (40mm) (2nd generation)" "se44|Apple Watch SE (44mm) (2nd generation)"; do
  slug="${entry%%|*}"
  name="${entry#*|}"

  TYPE="$(xcrun simctl list devicetypes -j | jq -r --arg n "$name" '.devicetypes[] | select(.name==$n) | .identifier')"
  if [ -z "$TYPE" ]; then
    echo "::warning::Device type \"$name\" not available; skipping"
    continue
  fi
  if ! UDID="$(xcrun simctl create "Ringward $slug" "$TYPE" "$RUNTIME")"; then
    echo "::warning::Could not create a \"$name\" simulator on $RUNTIME; skipping"
    continue
  fi

  xcrun simctl bootstatus "$UDID" -b
  xcrun simctl install "$UDID" "$APP"
  for mode in start midgame; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -RingwardDemo "$mode"
    sleep 8
    xcrun simctl io "$UDID" screenshot "shots/$slug-$mode.png"
  done
  for mode in picker start midgame levelup; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" || true
    xcrun simctl launch "$UDID" "$BUNDLE_ID" -LanternfallDemo "$mode"
    sleep 8
    if [ "$mode" = picker ]; then out="shots/$slug-picker.png"; else out="shots/$slug-lanternfall-$mode.png"; fi
    xcrun simctl io "$UDID" screenshot "$out"
  done
  xcrun simctl shutdown "$UDID"
  xcrun simctl delete "$UDID"
done

ls -l shots
