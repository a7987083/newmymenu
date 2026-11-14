#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/core
python3 tools/generate_dictionary.py --check
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
test "$(xcrun --sdk iphoneos --show-sdk-version)" = 18.5
xcodebuild -version > build/core/toolchain.txt
xcrun clang --version >> build/core/toolchain.txt
BASE=(-isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -Oz -fvisibility=hidden -Wall -Wextra -Werror -Iinclude)
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c src/NMCore.c -o build/core/NMCore.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c src/Configuration/NMRuntimeActionCodec.c -o build/core/NMRuntimeActionCodec.o
xcrun --sdk iphoneos clang++ "${BASE[@]}" -std=c++17 -fobjc-arc -fblocks -c src/MethodFinder/NMMethodTranslator.mm -o build/core/NMMethodTranslator.o
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -Wl,-undefined,error -framework Foundation -install_name @rpath/NewMyMenuCore.dylib build/core/NMCore.o build/core/NMRuntimeActionCodec.o build/core/NMMethodTranslator.o -o build/core/NewMyMenuCore.dylib
codesign --force --sign - --timestamp=none build/core/NewMyMenuCore.dylib
python3 tools/verify_core.py build/core/NewMyMenuCore.dylib
