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
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c src/NMCore.c -o build/core/NMCore.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c src/Configuration/NMRuntimeActionCodec.c -o build/core/NMRuntimeActionCodec.o
xcrun --sdk iphoneos clang++ "${BASE[@]}" -std=c++17 -fobjc-arc -fblocks -c src/MethodFinder/NMMethodTranslator.mm -o build/core/NMMethodTranslator.o
xcrun --sdk iphoneos clang++ "${BASE[@]}" -std=c++17 -fobjc-arc -fblocks -c src/Build/NMMachOSigner.mm -o build/core/NMMachOSigner.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -c src/Build/NMMachOAddress.c -o build/core/NMMachOAddress.o
for source in src/Execution/NMReceiverLease.m src/Execution/NMInvocationCoordinator.m src/NativeHook/NMCaptureSession.m src/RuntimeDiscovery/NMIL2CPPDiscovery.m src/MethodFinder/NMNamedExpression.m src/Build/NMBuildManifest.m src/Swizzle/NMSwizzleManager.m src/Configuration/NMConfiguration.m src/Configuration/NMPatchImport.m src/Build/NMStaticPatchPlan.m; do
    xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c "$source" -o "build/core/$(basename "$source" .m).o"
done
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -framework Foundation -install_name @rpath/NewMyMenuCore.dylib build/core/NMCore.o build/core/NMMachOAddress.o build/core/NMRuntimeActionCodec.o build/core/NMMethodTranslator.o build/core/NMReceiverLease.o build/core/NMInvocationCoordinator.o build/core/NMCaptureSession.o build/core/NMIL2CPPDiscovery.o build/core/NMNamedExpression.o build/core/NMBuildManifest.o build/core/NMMachOSigner.o build/core/NMSwizzleManager.o build/core/NMConfiguration.o build/core/NMPatchImport.o build/core/NMStaticPatchPlan.o -o build/core/NewMyMenuCore.dylib
codesign --force --sign - --timestamp=none build/core/NewMyMenuCore.dylib
python3 tools/verify_core.py build/core/NewMyMenuCore.dylib
