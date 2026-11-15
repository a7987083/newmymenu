#pragma once
#include <stdint.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef enum { NMARM64RelocationOK=0,NMARM64RelocationInvalid=1,NMARM64RelocationOverflow=2,NMARM64RelocationInterior=3,NMARM64RelocationOutOfRange=4,NMARM64RelocationUnsupported=5 } NMARM64RelocationStatus;
typedef struct { uint32_t instruction; bool terminal; } NMARM64RelocationResult;
// Addresses are preferred VAs (not RVAs): ADRP must preserve actual page alignment.
// Failure never changes output. Window is half-open [start,end), all instruction PCs aligned.
__attribute__((visibility("default"))) NMARM64RelocationStatus NMARM64RelocateInstruction(uint32_t instruction,uint64_t sourceVA,uint64_t destinationVA,uint64_t windowStartVA,uint64_t windowEndVA,NMARM64RelocationResult *output);
__attribute__((visibility("default"))) bool NMARM64EncodeBranch(uint64_t fromVA,uint64_t targetVA,bool link,uint32_t *output);
__attribute__((visibility("default"))) bool NMARM64DirectBranchTarget(uint32_t instruction,uint64_t sourceVA,uint64_t *targetVA);
__attribute__((visibility("default"))) bool NMARM64EncodeADRP(uint64_t fromVA,uint64_t targetVA,uint32_t reg,uint32_t *output);
__attribute__((visibility("default"))) bool NMARM64EncodeLiteral(uint64_t fromVA,uint64_t targetVA,uint32_t opcode,uint32_t reg,uint32_t *output);
#ifdef __cplusplus
}
#endif
