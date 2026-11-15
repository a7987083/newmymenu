#pragma once
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
#define NM_MACHO_MAX_SEGMENTS 128
#define NM_MACHO_MAX_INSTRUCTION_RANGES 512
typedef struct { uint64_t rva,fileoff,length; } NMMachOInstructionRegion;
// Value snapshot: no pointers into the input, no process/runtime addresses.
typedef struct { uint64_t vmaddr,vmsize,fileoff,filesize; uint32_t protection; char name[17]; } NMMachOSegment;
typedef struct { uint64_t imageBase,fileSize,commandEnd; size_t count; NMMachOSegment segments[NM_MACHO_MAX_SEGMENTS]; size_t instructionCount; NMMachOInstructionRegion instructions[NM_MACHO_MAX_INSTRUCTION_RANGES]; } NMMachOLayout;
typedef enum { NMMachOAddressRVA=1,NMMachOAddressPreferredVA=2,NMMachOAddressFileOffset=3 } NMMachOAddressKind;
// Failure leaves output unchanged. Only thin little-endian ARM64 executable/dylib/bundle.
__attribute__((visibility("default"))) bool NMMachOReadLayout(const void *bytes,size_t length,NMMachOLayout *output);
// Entire nonempty range must fit one unambiguous file-backed segment.
__attribute__((visibility("default"))) bool NMMachOResolveRange(const NMMachOLayout *layout,NMMachOAddressKind kind,uint64_t address,uint64_t length,uint64_t *fileOffset,uint64_t *rva);
// Proves file/VM consistency within an aligned executable instruction section only.
__attribute__((visibility("default"))) bool NMMachOIsInstructionRange(const NMMachOLayout *layout,uint64_t rva,uint64_t length);
#ifdef __cplusplus
}
#endif
