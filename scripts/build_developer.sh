#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SHA="$(git rev-parse --short=8 HEAD)"
mkdir -p build/developer-menu
BASE=(-isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -Oz -fvisibility=hidden -Wall -Wextra -Werror -Iinclude -Isrc/MethodFinder "-DNM_BUILD_SHA=\"$SHA\"")
source scripts/source_lists.sh
OBJECTS=()
for input in "${NM_C_SOURCES[@]}" "${NM_M_SOURCES[@]}" "${NM_MM_SOURCES[@]}"; do name=$(basename "$input");OBJECTS+=("build/core/${name%.*}.o");done
for input in "${NM_UI_SOURCES[@]}"; do object="build/developer-menu/$(basename "$input" .m).o";xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c "$input" -o "$object";OBJECTS+=("$object");done
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -framework Foundation -framework UIKit -framework QuartzCore -framework CoreGraphics -framework UniformTypeIdentifiers -install_name @rpath/NewMyMenuDeveloper.dylib "${OBJECTS[@]}" -o build/developer-menu/NewMyMenuDeveloper.dylib
codesign --force --sign - --timestamp=none build/developer-menu/NewMyMenuDeveloper.dylib
python3 tools/verify_core.py build/developer-menu/NewMyMenuDeveloper.dylib --developer-menu
