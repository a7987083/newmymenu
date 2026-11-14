#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SHA="$(git rev-parse --short=8 HEAD)"
mkdir -p build/device-probe
BASE=(-isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -Oz -fvisibility=hidden -Wall -Wextra -Werror -Iinclude -Isrc/MethodFinder "-DNM_BUILD_SHA=\"$SHA\"")
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/MethodFinder/NMFinderSession.m -o build/device-probe/NMFinderSession.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/MethodFinder/NMMethodPresentation.m -o build/device-probe/NMMethodPresentation.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/DeviceProbe/NMDeviceProbe.m -o build/device-probe/NMDeviceProbe.o
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -framework Foundation -framework UIKit -framework QuartzCore -framework CoreGraphics -install_name @rpath/NewMyMenuDeviceProbe.dylib build/core/NMCore.o build/core/NMRuntimeActionCodec.o build/core/NMMethodTranslator.o build/core/NMReceiverLease.o build/core/NMInvocationCoordinator.o build/core/NMCaptureSession.o build/core/NMIL2CPPDiscovery.o build/device-probe/NMDeviceProbe.o build/device-probe/NMFinderSession.o build/device-probe/NMMethodPresentation.o -o build/device-probe/NewMyMenuDeviceProbe.dylib
codesign --force --sign - --timestamp=none build/device-probe/NewMyMenuDeviceProbe.dylib
python3 tools/verify_core.py build/device-probe/NewMyMenuDeviceProbe.dylib --device-probe
