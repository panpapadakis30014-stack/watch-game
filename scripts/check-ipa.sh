#!/usr/bin/env bash
# Checks an unsigned Ringward .ipa before it is uploaded: the watch app is
# embedded where the phone expects it, it has an arm64_32 slice, it targets
# watchOS 10.0, bundle IDs / WK keys / versions are right, and nothing carries
# entitlements. Runs on macOS (needs lipo and PlistBuddy).
set -euo pipefail

IPA="${1:?usage: check-ipa.sh path/to/Ringward-unsigned.ipa}"
IOS_ID="com.panos30013.ringward"
WATCH_ID="com.panos30013.ringward.watchkitapp"
PLISTBUDDY=/usr/libexec/PlistBuddy

fail() {
  echo "::error::$*"
  exit 1
}

# Reads one key from an app's Info.plist; prints nothing if the key is missing.
plist_value() {
  "$PLISTBUDDY" -c "Print :$2" "$1/Info.plist" 2>/dev/null || true
}

expect() {
  local name="$1" got="$2" want="$3"
  [ "$got" = "$want" ] || fail "$name is '$got', expected '$want'"
  echo "$name = $got"
}

# 1. The watch binary must sit under Payload/<App>.app/Watch/<WatchApp>.app/.
# (Listing captured first: grep -q on a pipe can SIGPIPE unzip under pipefail.)
LISTING="$(unzip -l "$IPA")"
WATCH_ENTRY="$(grep -E 'Payload/[^/]+\.app/Watch/[^/]+\.app/RingwardWatch$' <<<"$LISTING" || true)"
[ -n "$WATCH_ENTRY" ] || fail "No watch binary at Payload/*.app/Watch/*.app/RingwardWatch in $IPA"
echo "$WATCH_ENTRY"

# 2. Unpack and find exactly one iOS app and one watch app.
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
unzip -q "$IPA" -d "$T"
shopt -s nullglob
IOS_APPS=("$T"/Payload/*.app)
WATCH_APPS=("$T"/Payload/*.app/Watch/*.app)
[ "${#IOS_APPS[@]}" -eq 1 ] || fail "Expected exactly one iOS app in Payload/, found ${#IOS_APPS[@]}"
[ "${#WATCH_APPS[@]}" -eq 1 ] || fail "Expected exactly one watch app in Payload/*.app/Watch/, found ${#WATCH_APPS[@]}"
A="${IOS_APPS[0]}"
W="${WATCH_APPS[0]}"

# 3. The watch binary must include the arm64_32 slice that Apple Watch SE runs.
LIPO="$(lipo -info "$W/RingwardWatch")"
echo "$LIPO"
grep -q arm64_32 <<<"$LIPO" || fail "Watch binary has no arm64_32 slice"

# 4. Info.plist values.
expect "watch MinimumOSVersion" "$(plist_value "$W" MinimumOSVersion)" "10.0"
expect "watch CFBundleIdentifier" "$(plist_value "$W" CFBundleIdentifier)" "$WATCH_ID"
expect "watch WKCompanionAppBundleIdentifier" "$(plist_value "$W" WKCompanionAppBundleIdentifier)" "$IOS_ID"
expect "watch WKApplication" "$(plist_value "$W" WKApplication)" "true"
expect "watch WKRunsIndependentlyOfCompanionApp" "$(plist_value "$W" WKRunsIndependentlyOfCompanionApp)" "true"
expect "iOS CFBundleIdentifier" "$(plist_value "$A" CFBundleIdentifier)" "$IOS_ID"

# Watch and iOS versions must match, or the phone refuses to install the watch app.
IOS_SHORT="$(plist_value "$A" CFBundleShortVersionString)"
IOS_BUILD="$(plist_value "$A" CFBundleVersion)"
[ -n "$IOS_SHORT" ] || fail "iOS CFBundleShortVersionString is missing"
[ -n "$IOS_BUILD" ] || fail "iOS CFBundleVersion is missing"
expect "watch CFBundleShortVersionString" "$(plist_value "$W" CFBundleShortVersionString)" "$IOS_SHORT"
expect "watch CFBundleVersion" "$(plist_value "$W" CFBundleVersion)" "$IOS_BUILD"

# 5. No entitlements anywhere in the package.
ENTITLEMENTS="$(find "$T" -name '*.entitlements')"
[ -z "$ENTITLEMENTS" ] || fail "Unexpected entitlements files: $ENTITLEMENTS"

echo "check-ipa: OK"
