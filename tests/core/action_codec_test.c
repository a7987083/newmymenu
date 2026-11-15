#include "NMRuntimeActionFormat.h"
#include "NMCore.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>
int main(void) {
    assert(NewMyMenuCoreGetAPIVersion()==21);
    const uint32_t seeds[]={0u,0xffffffffu,0x5aa55aa5u,0xa55aa55au};
    for(size_t s=0;s<sizeof(seeds)/sizeof(seeds[0]);s++)for(uint32_t i=0;i<=128;i++) {
        uint32_t encoded=0,decoded=UINT_MAX;
        assert(NMRuntimeActionTryEncodeInstanceIndex(i,seeds[s],&encoded));
        assert(NMRuntimeActionTryDecodeInstanceIndex(encoded,&decoded) && decoded==i);
        const uint32_t mask=~(NM_RUNTIME_INSTANCE_INDEX_MASK|NMRuntimeActionFlagInstanceIndex);
        assert((encoded&mask)==(seeds[s]&mask));
    }
    uint32_t output=0xdeadbeefu;
    assert(!NMRuntimeActionTryEncodeInstanceIndex(129,0,&output) && output==0xdeadbeefu);
    assert(!NMRuntimeActionTryEncodeInstanceIndex(UINT_MAX,0,&output) && output==0xdeadbeefu);
    assert(!NMRuntimeActionTryEncodeInstanceIndex(1,0,NULL));
    assert(!NMRuntimeActionTryDecodeInstanceIndex(NMRuntimeActionFlagInstanceIndex,&output) && output==0xdeadbeefu);
    assert(!NMRuntimeActionTryDecodeInstanceIndex(1u<<NM_RUNTIME_INSTANCE_INDEX_SHIFT,&output) && output==0xdeadbeefu);
    assert(!NMRuntimeActionTryDecodeInstanceIndex(NMRuntimeActionFlagInstanceIndex|(129u<<NM_RUNTIME_INSTANCE_INDEX_SHIFT),&output));
    assert(!NMRuntimeActionTryDecodeInstanceIndex(0,NULL));
    puts("PASS: C11 wire layout; 516 ordinal roundtrips/flag preservation; invalid inputs leave output unchanged");
    return 0;
}
