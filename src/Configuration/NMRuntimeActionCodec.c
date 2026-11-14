#include "NMRuntimeActionFormat.h"

bool NMRuntimeActionTryEncodeInstanceIndex(uint32_t index, uint32_t flags, uint32_t *output) {
    if (!output || index > NM_RUNTIME_INSTANCE_MAX_INDEX) return false;
    const uint32_t retained = flags & ~(NM_RUNTIME_INSTANCE_INDEX_MASK | NMRuntimeActionFlagInstanceIndex);
    *output = retained | (index ? NMRuntimeActionFlagInstanceIndex | (index << NM_RUNTIME_INSTANCE_INDEX_SHIFT) : 0u);
    return true;
}

bool NMRuntimeActionTryDecodeInstanceIndex(uint32_t flags, uint32_t *output) {
    if (!output) return false;
    const uint32_t index = (flags & NM_RUNTIME_INSTANCE_INDEX_MASK) >> NM_RUNTIME_INSTANCE_INDEX_SHIFT;
    if (flags & NMRuntimeActionFlagInstanceIndex) {
        if (!index || index > NM_RUNTIME_INSTANCE_MAX_INDEX) return false;
    } else if (index) {
        return false;
    }
    *output = index;
    return true;
}
