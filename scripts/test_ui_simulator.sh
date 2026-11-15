#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/source_lists.sh
mkdir -p build/developer-menu/ui-fixture build/ui-simulator
xcrun simctl list runtimes -j > build/ui-simulator/runtimes.json
RUNTIME=$(python3 - <<'PY'
import json
r=[x['identifier'] for x in json.load(open('build/ui-simulator/runtimes.json'))['runtimes'] if x.get('isAvailable') and x.get('version')=='18.5' and 'iOS' in x['identifier']]
print(r[0] if r else '')
PY
)
if [[ -z "$RUNTIME" ]]; then
  python3 - <<'PY'
import json
json.dump({'executed':False,'reason':'Pinned iOS 18.5 Simulator runtime is not installed; SDK availability does not imply a runnable Simulator','physicalDeviceVerified':False},open('build/developer-menu/ui-fixture/unavailable.json','w'),indent=2)
PY
  exit 0
fi
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
test "$(xcrun --sdk iphonesimulator --show-sdk-version)" = 18.5
APP=build/ui-simulator/NewMyMenuUIFixture.app
mkdir -p "$APP"
FLAGS=(-isysroot "$SDK" -target arm64-apple-ios14.0-simulator -O1 -g -fvisibility=hidden -Wall -Wextra -Werror -Iinclude -Isrc/Build -Isrc/MethodFinder "-DNM_BUILD_SHA=\"$(git rev-parse --short=8 HEAD)\"")
OBJECTS=()
for input in "${NM_C_SOURCES[@]}"; do out="build/ui-simulator/$(basename "$input" .c).o";xcrun clang "${FLAGS[@]}" -std=c11 -c "$input" -o "$out";OBJECTS+=("$out");done
for input in "${NM_M_SOURCES[@]}" "${NM_UI_SOURCES[@]}" tests/ui/main.m; do out="build/ui-simulator/$(basename "$input" .m).o";xcrun clang "${FLAGS[@]}" -std=c11 -fobjc-arc -fblocks -c "$input" -o "$out";OBJECTS+=("$out");done
for input in "${NM_MM_SOURCES[@]}"; do out="build/ui-simulator/$(basename "$input" .mm).o";xcrun clang++ "${FLAGS[@]}" -std=c++17 -fobjc-arc -fblocks -c "$input" -o "$out";OBJECTS+=("$out");done
xcrun clang++ "${FLAGS[@]}" -framework Foundation -framework UIKit -framework QuartzCore -framework CoreGraphics -framework UniformTypeIdentifiers "${OBJECTS[@]}" -o "$APP/NewMyMenuUIFixture"
python3 - <<'PY'
import plistlib
plistlib.dump({'CFBundleIdentifier':'io.newmymenu.UIFixture','CFBundleExecutable':'NewMyMenuUIFixture','CFBundleName':'NewMyMenuUIFixture','CFBundlePackageType':'APPL','CFBundleVersion':'1','CFBundleShortVersionString':'1.0','MinimumOSVersion':'14.0','UIDeviceFamily':[1,2],'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight']},open('build/ui-simulator/NewMyMenuUIFixture.app/Info.plist','wb'))
PY
cp build/core/NewMyMenuCore.dylib "$APP/StaticFixture.bin"
codesign --force --sign - --timestamp=none "$APP"
DEVICE=$(xcrun simctl create NewMyMenu-UI-Fixture com.apple.CoreSimulator.SimDeviceType.iPhone-16 "$RUNTIME")
CONTAINER=""
cleanup_ui(){
  status=$?
  if [[ -n "$CONTAINER" && -d "$CONTAINER/Documents/ui-fixture" ]]; then cp "$CONTAINER/Documents/ui-fixture/"* build/developer-menu/ui-fixture/ 2>/dev/null || true;fi
  if [[ "$status" != 0 ]]; then xcrun simctl io "$DEVICE" screenshot build/developer-menu/ui-fixture/failure.png >/dev/null 2>&1 || true;fi
  xcrun simctl shutdown "$DEVICE" >/dev/null 2>&1 || true
  xcrun simctl delete "$DEVICE" >/dev/null 2>&1 || true
  trap - EXIT
  exit "$status"
}
trap cleanup_ui EXIT
xcrun simctl boot "$DEVICE"
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl install "$DEVICE" "$APP"
xcrun simctl launch --console --terminate-running-process "$DEVICE" io.newmymenu.UIFixture > build/developer-menu/ui-fixture/launch.log 2>&1 &
LAUNCH=$!
CONTAINER=$(xcrun simctl get_app_container "$DEVICE" io.newmymenu.UIFixture data)
for iteration in $(seq 1 180); do
  for phase in build keyboard; do
    if [[ -f "$CONTAINER/Documents/ui-fixture/$phase-ready" && ! -f "$CONTAINER/Documents/ui-fixture/$phase-captured" ]]; then
      python3 tools/capture_simulator.py "$DEVICE" "build/developer-menu/ui-fixture/$phase-system.png"
      touch "$CONTAINER/Documents/ui-fixture/$phase-captured"
    fi
  done
  if [[ -f "$CONTAINER/Documents/ui-fixture/result.json" ]]; then cp "$CONTAINER/Documents/ui-fixture/"* build/developer-menu/ui-fixture/;wait "$LAUNCH";exit 0;fi
  if ! kill -0 "$LAUNCH" 2>/dev/null; then cat build/developer-menu/ui-fixture/launch.log;wait "$LAUNCH";exit 1;fi
  sleep 1
done
cat build/developer-menu/ui-fixture/launch.log
exit 1
