#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/core
python3 tools/generate_dictionary.py --check
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
test "$(xcrun --sdk iphoneos --show-sdk-version)" = 18.5
xcodebuild -version > build/core/toolchain.txt
python3 - <<'PYCODE'
from pathlib import Path
if Path('build/core/toolchain.txt').read_text().splitlines() != ['Xcode 16.4', 'Build version 16F6']:
    raise SystemExit('Unexpected Xcode version/build')
PYCODE
xcrun clang --version >> build/core/toolchain.txt
BASE=(-isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -Oz -fvisibility=hidden -Wall -Wextra -Werror -Iinclude)
source scripts/source_lists.sh
OBJECTS=()
for input in "${NM_C_SOURCES[@]}"; do object="build/core/$(basename "$input" .c).o";xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c "$input" -o "$object";OBJECTS+=("$object");done
for input in "${NM_M_SOURCES[@]}"; do object="build/core/$(basename "$input" .m).o";xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c "$input" -o "$object";OBJECTS+=("$object");done
for input in "${NM_MM_SOURCES[@]}"; do object="build/core/$(basename "$input" .mm).o";xcrun --sdk iphoneos clang++ "${BASE[@]}" -std=c++17 -fobjc-arc -fblocks -Isrc/Build -c "$input" -o "$object";OBJECTS+=("$object");done
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -framework Foundation -install_name @rpath/NewMyMenuCore.dylib "${OBJECTS[@]}" -o build/core/NewMyMenuCore.dylib
codesign --force --sign - --timestamp=none build/core/NewMyMenuCore.dylib
python3 tools/verify_core.py build/core/NewMyMenuCore.dylib
