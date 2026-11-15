#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SHA="$(git rev-parse --short=8 HEAD)"
mkdir -p build/developer-menu
BASE=(-isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -Oz -fvisibility=hidden -Wall -Wextra -Werror -Iinclude -Isrc/MethodFinder "-DNM_BUILD_SHA=\"$SHA\"")
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/MethodFinder/NMFinderSession.m -o build/developer-menu/NMFinderSession.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/MethodFinder/NMMethodPresentation.m -o build/developer-menu/NMMethodPresentation.o
xcrun --sdk iphoneos clang "${BASE[@]}" -std=c11 -fobjc-arc -fblocks -c src/DeveloperUI/NMDeveloperMenu.m -o build/developer-menu/NMDeveloperMenu.o
xcrun --sdk iphoneos clang++ -isysroot "$SDK" -arch arm64 -miphoneos-version-min=14.0 -dynamiclib -framework Foundation -framework UIKit -framework QuartzCore -framework CoreGraphics -framework UniformTypeIdentifiers -install_name @rpath/NewMyMenuDeveloper.dylib build/core/NMCore.o build/core/NMMachOAddress.o build/core/NMARM64Relocation.o build/core/NMRuntimeActionCodec.o build/core/NMMethodTranslator.o build/core/NMReceiverLease.o build/core/NMInvocationCoordinator.o build/core/NMCaptureSession.o build/core/NMIL2CPPDiscovery.o build/core/NMNamedExpression.o build/core/NMBuildManifest.o build/core/NMMachOSigner.o build/core/NMSwizzleManager.o build/core/NMConfiguration.o build/core/NMPatchImport.o build/core/NMStaticPatchPlan.o build/core/NMOfflineBuildRequest.o build/core/NMStaticCodePayload.o build/core/NMChainedFixupsPrivate.o build/core/NMStaticBinaryImage.o build/developer-menu/NMDeveloperMenu.o build/developer-menu/NMFinderSession.o build/developer-menu/NMMethodPresentation.o -o build/developer-menu/NewMyMenuDeveloper.dylib
codesign --force --sign - --timestamp=none build/developer-menu/NewMyMenuDeveloper.dylib
python3 tools/verify_core.py build/developer-menu/NewMyMenuDeveloper.dylib --developer-menu
