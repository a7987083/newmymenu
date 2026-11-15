#pragma once
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef enum {NMStaticValueAuto=0,NMStaticValueI32=1,NMStaticValueU32=2,NMStaticValueI64=3,NMStaticValueU64=4,NMStaticValueF32=5,NMStaticValueF64=6} NMStaticValueType;
typedef enum {NMStaticControlSwitch=0,NMStaticControlSlider=1,NMStaticControlButton=2,NMStaticControlNumber=3} NMStaticControlType;
typedef struct { uint64_t bits; uint32_t reg,consumedInstructions; NMStaticValueType type; } NMStaticImmediate;
// Fixed original MOVZ(+MOVK)/scalar FMOV algorithms; no file or process writes.
__attribute__((visibility("default"))) bool NMStaticDecodeImmediate(const void *instructions,size_t length,NMStaticValueType requested,NMStaticImmediate *result);
#ifdef __cplusplus
}
#endif
