.PHONY: core test-portable test-macos test-parity
CC ?= cc
CXX ?= c++
CORE_C = src/NMCore.c src/Configuration/NMRuntimeActionCodec.c
WARN = -Wall -Wextra -Werror
core:
	bash scripts/build_core.sh

test-portable:
	python3 tools/generate_dictionary.py --check
	python3 -m unittest discover -s tests -v
	mkdir -p build/tests
	$(CC) -std=c11 $(WARN) -Iinclude $(CORE_C) tests/core/action_codec_test.c -o build/tests/action-codec
	build/tests/action-codec

test-macos:
	mkdir -p build/tests
	xcrun clang++ -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude -framework Foundation src/MethodFinder/NMMethodTranslator.mm tests/core/translator_test.mm -o build/tests/translator
	build/tests/translator

test-parity:
	test -n "$(SOURCE_BASELINE)"
	mkdir -p build/tests
	$(CC) -std=c11 $(WARN) -Iinclude -c src/Configuration/NMRuntimeActionCodec.c -o build/tests/action-codec.o
	$(CXX) -std=c++17 $(WARN) -Iinclude -I"$(SOURCE_BASELINE)/iosruntimepatchmenu/src" build/tests/action-codec.o tests/core/action_wire_parity_test.cpp -o build/tests/action-wire-parity
	build/tests/action-wire-parity
	xcrun clang++ -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude -I"$(SOURCE_BASELINE)/iosruntimepatchmenu/src" -framework Foundation src/MethodFinder/NMMethodTranslator.mm "$(SOURCE_BASELINE)/iosruntimepatchmenu/src/ZNMethodTranslator.mm" tests/core/translator_parity_test.mm -o build/tests/translator-parity
	build/tests/translator-parity resources/MethodTranslation.zh-CN.json

.PHONY: test-execution
test-execution:
	mkdir -p build/tests
	for source in src/Execution/NMReceiverLease.m src/Execution/NMInvocationCoordinator.m src/NativeHook/NMCaptureSession.m; do xcrun clang -std=c11 $(WARN) -fobjc-arc -fblocks -Iinclude -c "$$source" -o "build/tests/$$(basename "$$source" .m).o" || exit $$?; done
	xcrun clang++ -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude -framework Foundation build/tests/NMReceiverLease.o build/tests/NMInvocationCoordinator.o build/tests/NMCaptureSession.o tests/core/execution_test.mm -o build/tests/execution
	build/tests/execution
	xcrun clang++ -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude -framework Foundation build/tests/NMReceiverLease.o build/tests/NMInvocationCoordinator.o build/tests/NMCaptureSession.o tests/core/capture_session_test.mm -o build/tests/capture-session
	build/tests/capture-session

.PHONY: test-discovery developer-menu
test-discovery:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/RuntimeDiscovery -c src/RuntimeDiscovery/NMIL2CPPDiscovery.m -o build/tests/NMIL2CPPDiscovery.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -c src/MethodFinder/NMNamedExpression.m -o build/tests/NMNamedExpression.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/RuntimeDiscovery -framework Foundation build/tests/NMNamedExpression.o build/tests/NMIL2CPPDiscovery.o tests/core/il2cpp_discovery_test.mm -o build/tests/il2cpp-discovery
	build/tests/il2cpp-discovery

developer-menu: core
	bash scripts/build_developer.sh

.PHONY: test-finder
test-finder:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Isrc/MethodFinder -framework Foundation src/MethodFinder/NMFinderSession.m tests/core/finder_session_test.m -o build/tests/finder-session
	build/tests/finder-session

.PHONY: test-presentation
test-presentation:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/MethodFinder -c src/MethodFinder/NMMethodPresentation.m -o build/tests/NMMethodPresentation.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/MethodFinder -framework Foundation build/tests/NMMethodPresentation.o src/MethodFinder/NMMethodTranslator.mm tests/core/method_presentation_test.mm -o build/tests/method-presentation
	build/tests/method-presentation

.PHONY: test-parser
test-parser:
	test -n "$(SOURCE_BASELINE)"
	mkdir -p build/tests
	python3 tools/generate_parser_parity.py "$(SOURCE_BASELINE)" build/tests/original-parser.m
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Isrc/MethodFinder -framework Foundation src/MethodFinder/NMNamedExpression.m build/tests/original-parser.m tests/core/named_expression_test.m -o build/tests/named-expression
	build/tests/named-expression

.PHONY: test-manifest
test-manifest:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -framework Foundation src/Build/NMBuildManifest.m tests/core/manifest_test.m -o build/tests/manifest
	build/tests/manifest

.PHONY: test-signer
test-signer:
	mkdir -p build/signer-fixture
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -framework Foundation src/Build/NMMachOSigner.mm tests/core/signer_driver.mm -o build/signer-fixture/signer-driver
	xcrun --sdk iphoneos clang -isysroot "$$(xcrun --sdk iphoneos --show-sdk-path)" -arch arm64 -miphoneos-version-min=14.0 -Wall -Wextra -Werror tests/core/signer_executable_fixture.c -o build/signer-fixture/executable
	python3 tools/test_signer.py build/core/NewMyMenuCore.dylib build/signer-fixture/signer-driver build/signer-fixture/executable

.PHONY: test-swizzle
test-swizzle:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -framework Foundation src/Swizzle/NMSwizzleManager.m tests/core/swizzle_test.m -o build/tests/swizzle
	build/tests/swizzle

.PHONY: test-configuration
test-configuration:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -framework Foundation src/Configuration/NMConfiguration.m tests/core/configuration_test.m -o build/tests/configuration
	build/tests/configuration

.PHONY: test-configuration-parity
test-configuration-parity:
	test -n "$(SOURCE_BASELINE)"
	mkdir -p build/tests
	python3 tools/check_configuration_source.py "$(SOURCE_BASELINE)"
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Isrc/Configuration -I"$(SOURCE_BASELINE)/iosruntimepatchmenu/src" -framework Foundation tests/core/configuration_identity_parity_test.m -o build/tests/configuration-identity-parity
	build/tests/configuration-identity-parity

.PHONY: test-patch-import-audit
test-patch-import-audit:
	test -n "$(SOURCE_BASELINE)"
	mkdir -p build/tests
	python3 tools/generate_patch_import_audit.py "$(SOURCE_BASELINE)" build/tests/original-patch-import-audit.m
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -framework Foundation build/tests/original-patch-import-audit.m -o build/tests/patch-import-audit
	build/tests/patch-import-audit

.PHONY: test-patch-import
test-patch-import:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -framework Foundation src/Configuration/NMPatchImport.m tests/core/patch_import_test.m -o build/tests/patch-import
	build/tests/patch-import

.PHONY: test-macho-address
test-macho-address:
	mkdir -p build/tests
	$(CC) -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude src/Build/NMMachOAddress.c tests/core/macho_address_test.c -o build/tests/macho-address
	build/tests/macho-address

.PHONY: test-static-plan
test-static-plan:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude -c src/Build/NMMachOAddress.c -o build/tests/plan-address.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude -c src/Build/NMARM64Relocation.c -o build/tests/plan-relocation.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude -c src/Build/NMStaticValues.c -o build/tests/plan-values.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o src/Build/NMStaticPatchPlan.m tests/core/static_plan_test.m -o build/tests/static-plan
	build/tests/static-plan

.PHONY: test-static-variant-parity
test-static-variant-parity:
	python3 tools/generate_static_variant_parity.py "$(SOURCE_BASELINE)"
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c src/Build/NMStaticPatchPlan.m -o build/tests/variant-plan.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Ibuild/tests -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/variant-plan.o tests/core/static_variant_parity_test.mm -o build/tests/static-variant-parity
	build/tests/static-variant-parity

.PHONY: test-arm64-relocation
test-arm64-relocation:
	mkdir -p build/tests
	$(CC) -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude src/Build/NMARM64Relocation.c tests/core/arm64_relocation_test.c -o build/tests/arm64-relocation
	build/tests/arm64-relocation

.PHONY: test-relocation-parity
test-relocation-parity:
	python3 tools/generate_relocation_parity.py "$(SOURCE_BASELINE)"
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude -c src/Build/NMARM64Relocation.c -o build/tests/relocation-new.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -Iinclude -Ibuild/tests -framework Foundation build/tests/relocation-new.o tests/core/relocation_parity_test.mm -o build/tests/relocation-parity
	build/tests/relocation-parity
	python3 tools/check_original_relocation_ub.py

.PHONY: test-static-code
test-static-code: test-static-plan
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c src/Build/NMStaticPatchPlan.m -o build/tests/code-plan.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c src/Build/NMBuildManifest.m -o build/tests/code-manifest.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o src/Build/NMStaticCodePayload.mm tests/core/static_code_test.mm -o build/tests/static-code
	build/tests/static-code

.PHONY: test-static-image
test-static-image: test-static-code
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o src/Build/NMStaticCodePayload.mm src/Build/NMChainedFixupsPrivate.mm src/Build/NMStaticBinaryImage.mm src/Build/NMMachOSigner.mm tests/core/static_image_test.mm -o build/tests/static-image
	build/tests/static-image build/core/NewMyMenuCore.dylib build/static-image-fixture
	codesign --verify --strict --verbose=4 build/static-image-fixture/prepared-signed.dylib
	xcrun dyld_info -validate_only build/static-image-fixture/prepared-signed.dylib > build/static-image-fixture/dyld-validation.txt 2>&1
	python3 tools/check_dyld_validation.py build/static-image-fixture/dyld-validation.txt

.PHONY: test-offline-build
test-offline-build:
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c src/Configuration/NMPatchImport.m -o build/tests/offline-import.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c src/Build/NMOfflineBuildRequest.m -o build/tests/offline-request.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -c tests/core/offline_build_test.m -o build/tests/offline-test.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o build/tests/offline-import.o build/tests/offline-request.o build/tests/offline-test.o src/Build/NMStaticCodePayload.mm src/Build/NMChainedFixupsPrivate.mm src/Build/NMStaticBinaryImage.mm src/Build/NMMachOSigner.mm -o build/tests/offline-build
	build/tests/offline-build build/core/NewMyMenuCore.dylib build/static-image-fixture
	codesign --verify --strict --verbose=4 build/static-image-fixture/offline-output/prepared-signed.macho
	xcrun dyld_info -validate_only build/static-image-fixture/offline-output/prepared-signed.macho > build/static-image-fixture/offline-output/dyld-validation.txt 2>&1
	python3 tools/check_dyld_validation.py build/static-image-fixture/offline-output/dyld-validation.txt

.PHONY: test-static-loaded-image
test-static-loaded-image:
	xcrun clang -arch arm64 -mmacosx-version-min=14.0 -O1 -dynamiclib -Wl,-headerpad,0x2000 -install_name @rpath/NMStaticSourceFixture.dylib tests/core/static_fixture_library.c -o build/tests/NMStaticSourceFixture.dylib
	codesign --force --sign - --timestamp=none build/tests/NMStaticSourceFixture.dylib
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o src/Build/NMStaticCodePayload.mm src/Build/NMChainedFixupsPrivate.mm src/Build/NMStaticBinaryImage.mm src/Build/NMMachOSigner.mm tests/core/static_loaded_image_test.mm -o build/tests/static-loaded-image
	build/tests/static-loaded-image build/tests/NMStaticSourceFixture.dylib build/static-image-fixture/host-loaded

.PHONY: test-static-values
test-static-values:
	$(CC) -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude src/Build/NMStaticValues.c tests/core/static_values_test.c -o build/tests/static-values
	build/tests/static-values
	python3 tools/generate_static_value_parity.py "$(SOURCE_BASELINE)"
	$(CC) -std=c11 $(WARN) -g -fsanitize=address,undefined -Iinclude src/Build/NMStaticValues.c build/tests/static-value-parity.c -o build/tests/static-value-parity
	build/tests/static-value-parity

.PHONY: test-static-numeric
test-static-numeric:
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -I"$(SOURCE_BASELINE)/iosruntimepatchmenu/src" -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o src/Build/NMStaticCodePayload.mm tests/core/static_numeric_test.mm -o build/tests/static-numeric
	build/tests/static-numeric

.PHONY: test-static-runtime
test-static-runtime: test-static-loaded-image
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address,undefined -fobjc-arc -fblocks -Iinclude -Isrc/Build -framework Foundation build/tests/plan-address.o build/tests/plan-relocation.o build/tests/plan-values.o build/tests/code-plan.o build/tests/code-manifest.o src/Build/NMStaticCodePayload.mm src/Build/NMChainedFixupsPrivate.mm src/Build/NMStaticBinaryImage.mm src/Build/NMMachOSigner.mm src/Build/NMStaticRuntime.mm tests/core/static_runtime_test.mm -o build/tests/static-runtime
	build/tests/static-runtime build/tests/NMStaticSourceFixture.dylib build/static-image-fixture/runtime-owned
