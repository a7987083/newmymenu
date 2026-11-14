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

.PHONY: test-discovery device-probe
test-discovery:
	mkdir -p build/tests
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/RuntimeDiscovery -c src/RuntimeDiscovery/NMIL2CPPDiscovery.m -o build/tests/NMIL2CPPDiscovery.o
	xcrun clang -std=c11 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -c src/MethodFinder/NMNamedExpression.m -o build/tests/NMNamedExpression.o
	xcrun clang++ -std=c++17 $(WARN) -g -fsanitize=address -fobjc-arc -fblocks -Iinclude -Isrc/RuntimeDiscovery -framework Foundation build/tests/NMNamedExpression.o build/tests/NMIL2CPPDiscovery.o tests/core/il2cpp_discovery_test.mm -o build/tests/il2cpp-discovery
	build/tests/il2cpp-discovery

device-probe: core
	bash scripts/build_device_probe.sh

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
	xcrun --sdk iphoneos clang++ -isysroot "$$(xcrun --sdk iphoneos --show-sdk-path)" -arch arm64 -miphoneos-version-min=14.0 -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude -c src/Build/NMMachOSigner.mm -o build/signer-fixture/signer-arm64.o
	xcrun clang++ --analyze -std=c++17 $(WARN) -fobjc-arc -fblocks -Iinclude src/Build/NMMachOSigner.mm -o build/signer-fixture/signer-analysis.plist
	python3 tools/check_analysis.py build/signer-fixture/signer-analysis.plist
