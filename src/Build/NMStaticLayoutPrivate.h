#pragma once

#include <stdint.h>
#include <stddef.h>

// Protection V2 is a build-time polymorphic layout layer. It is deliberately
// not presented as cryptography: the CPU must still execute the generated
// instructions. The goal is to prevent a whole ON/OFF variant from being
// stored as one predictable contiguous instruction sequence.
#define NMLayout_PAYLOAD_SLOT_SIZE UINT64_C(16)
#define NMLayout_PAYLOAD_VARIANT_PAD UINT64_C(64)
#define NMLayout_PAYLOAD_THUNK_STRIDE UINT64_C(48)

static inline uint64_t NMLayoutMix64(uint64_t x) {
    x ^= x >> 30;
    x *= UINT64_C(0xBF58476D1CE4E5B9);
    x ^= x >> 27;
    x *= UINT64_C(0x94D049BB133111EB);
    x ^= x >> 31;
    return x;
}

static inline uint64_t NMLayoutDeriveLayoutState(uint64_t nonce,
                                              uint64_t siteRVA,
                                              uint32_t variantOrdinal) {
    uint64_t x = nonce ^ NMLayoutMix64(siteRVA + UINT64_C(0x9E3779B97F4A7C15));
    x ^= NMLayoutMix64(((uint64_t)variantOrdinal << 32) | (uint64_t)(variantOrdinal ^ 0xA5A55A5Au));
    x = NMLayoutMix64(x);
    return x ? x : UINT64_C(0xD1B54A32D192ED03);
}

static inline uint64_t NMLayoutNextLayoutWord(uint64_t *state) {
    uint64_t x = state ? *state : 0;
    if (!x) x = UINT64_C(0xD1B54A32D192ED03);
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    if (state) *state = x;
    return x * UINT64_C(0x2545F4914F6CDD1D);
}

static inline uint64_t NMLayoutVariantReservedBytes(uint64_t sourceLength) {
    if (!sourceLength || (sourceLength & UINT64_C(3))) return 0;
    return (sourceLength / UINT64_C(4)) * NMLayout_PAYLOAD_SLOT_SIZE;
}

static inline uint64_t NMLayoutVariantStrideBytes(uint64_t sourceLength) {
    uint64_t payload = NMLayoutVariantReservedBytes(sourceLength);
    return payload ? payload + NMLayout_PAYLOAD_VARIANT_PAD : 0;
}

static inline void NMLayoutShuffleU32(uint32_t *values, size_t count, uint64_t state) {
    if (!values || count < 2) return;
    for (size_t i = count - 1; i > 0; --i) {
        uint64_t r = NMLayoutNextLayoutWord(&state);
        size_t j = (size_t)(r % (uint64_t)(i + 1));
        uint32_t tmp = values[i];
        values[i] = values[j];
        values[j] = tmp;
    }
}

