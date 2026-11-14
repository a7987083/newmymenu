#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define NM_RUNTIME_ACTION_MAGIC UINT64_C(0x00314E5443414E5A) /* "ZNACTN1" */
#define NM_RUNTIME_ACTION_VERSION 1u
#define NM_RUNTIME_ACTION_MAX_ENTRIES 128u
#define NM_RUNTIME_ACTION_MAX_ARGUMENTS 8u

typedef uint32_t NMRuntimeActionKind;
enum {
    NMRuntimeActionKindInvalid = 0,
    NMRuntimeActionKindIL2CPPMethodCall = 1,
    NMRuntimeActionKindIL2CPPNativeHook = 2,
    NMRuntimeActionKindDirectNativeCall = 3,
};

typedef uint32_t NMRuntimeActionFlags;
enum {
    NMRuntimeActionFlagNone = 0,
    NMRuntimeActionFlagArgument0Text = 1u << 0,
    NMRuntimeActionFlagParameterSignature = 1u << 1,
    NMRuntimeActionFlagArgumentVectorText = 1u << 2,
    // M5.1 reserved[3] -> UTF-8 JSON per-argument runtime control config.
    NMRuntimeActionFlagArgumentControls = 1u << 3,
    // M5.1 reserved[4] -> UTF-8 JSON Immediate Chain target descriptor.
    NMRuntimeActionFlagImmediateChain = 1u << 4,
    // M6.3 reserved[5] -> UTF-8 feature description.
    NMRuntimeActionFlagFeatureDescription = 1u << 5,
    // M6.4 Native Hook config JSON. For NativeHook entries reserved[0] points to it.
    NMRuntimeActionFlagNativeHookConfig = 1u << 6,
    // P2: index 1..128 in flags bits 16..23; 0 means legacy automatic resolution.
    // Does not change NMRuntimeMethodCallEntry ABI or consume reserved[] offsets.
    NMRuntimeActionFlagInstanceIndex = 1u << 7,
};

// Instance ordinal is an enumeration index, not a stable object identity.
#define NM_RUNTIME_INSTANCE_MAX_INDEX 128u
#define NM_RUNTIME_INSTANCE_INDEX_SHIFT 16u
#define NM_RUNTIME_INSTANCE_INDEX_MASK (UINT32_C(0xff) << NM_RUNTIME_INSTANCE_INDEX_SHIFT)

typedef struct {
    uint64_t magic;
    uint32_t version;
    uint32_t count;
    uint32_t entrySize;
    uint32_t totalSize;
    uint32_t stringPoolOffset;
    uint32_t stringPoolSize;
    uint32_t flags;
    uint32_t reserved32;
    uint64_t reserved[3];
} NMRuntimeActionHeader;

typedef struct {
    uint32_t actionID;
    uint32_t kind;
    uint32_t flags;
    uint32_t argumentCount;
    uint32_t titleOffset;
    uint32_t groupOffset;
    uint32_t assemblyOffset;
    uint32_t namespaceOffset;
    uint32_t classOffset;
    uint32_t methodOffset;
    // reserved[0] argument0 text (legacy /1)
    // reserved[1] full parameter signature
    // reserved[2] argument vector JSON
    // reserved[3] M5.1 argument control JSON
    // reserved[4] M5.1 Immediate Chain JSON
    // reserved[5] M6.3 feature description UTF-8
    uint32_t reserved[6];
} NMRuntimeMethodCallEntry;

#if defined(__cplusplus)
static_assert(sizeof(NMRuntimeActionHeader) == 64, "NMRuntimeActionHeader ABI");
static_assert(sizeof(NMRuntimeMethodCallEntry) == 64, "NMRuntimeMethodCallEntry ABI");
static_assert(offsetof(NMRuntimeMethodCallEntry, titleOffset) == 16, "NMRuntimeMethodCallEntry string offsets ABI");
static_assert(offsetof(NMRuntimeMethodCallEntry, reserved) == 40, "NMRuntimeMethodCallEntry reserved ABI");
#endif

#ifdef __cplusplus
extern "C" {
#endif
// Ordinal is 0 (automatic) or 1..128. It is not an object identity.
// On failure, output is unchanged; unrelated flag bits are preserved.
__attribute__((visibility("default")))
bool NMRuntimeActionTryEncodeInstanceIndex(uint32_t index, uint32_t flags, uint32_t *output);
__attribute__((visibility("default")))
bool NMRuntimeActionTryDecodeInstanceIndex(uint32_t flags, uint32_t *output);
#ifdef __cplusplus
}
#else
_Static_assert(sizeof(NMRuntimeActionHeader) == 64, "NMRuntimeActionHeader ABI");
_Static_assert(sizeof(NMRuntimeMethodCallEntry) == 64, "NMRuntimeMethodCallEntry ABI");
_Static_assert(offsetof(NMRuntimeMethodCallEntry, titleOffset) == 16, "string offsets ABI");
_Static_assert(offsetof(NMRuntimeMethodCallEntry, reserved) == 40, "reserved ABI");
#endif
