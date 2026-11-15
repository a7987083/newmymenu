# Shared explicit source inventory. No discovery by filename/glob at build time.
NM_C_SOURCES=(src/NMCore.c src/Configuration/NMRuntimeActionCodec.c src/Build/NMMachOAddress.c src/Build/NMARM64Relocation.c)
NM_M_SOURCES=(src/Execution/NMReceiverLease.m src/Execution/NMInvocationCoordinator.m src/NativeHook/NMCaptureSession.m src/RuntimeDiscovery/NMIL2CPPDiscovery.m src/MethodFinder/NMNamedExpression.m src/Build/NMBuildManifest.m src/Swizzle/NMSwizzleManager.m src/Configuration/NMConfiguration.m src/Configuration/NMPatchImport.m src/Build/NMStaticPatchPlan.m src/Build/NMOfflineBuildRequest.m)
NM_MM_SOURCES=(src/MethodFinder/NMMethodTranslator.mm src/Build/NMMachOSigner.mm src/Build/NMStaticCodePayload.mm src/Build/NMChainedFixupsPrivate.mm src/Build/NMStaticBinaryImage.mm)
NM_UI_SOURCES=(src/MethodFinder/NMFinderSession.m src/MethodFinder/NMMethodPresentation.m src/DeveloperUI/NMDeveloperMenu.m)
