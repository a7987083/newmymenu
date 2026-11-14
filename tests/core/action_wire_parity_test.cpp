#include "NMRuntimeActionFormat.h"
#include "ZNRuntimeActionFormat.h" // Fixed-source checkout is a test-only baseline.
#include <cassert>
#include <cstring>
#include <cstdio>
static_assert(sizeof(NMRuntimeActionHeader)==sizeof(ZNRuntimeActionHeader));
static_assert(sizeof(NMRuntimeMethodCallEntry)==sizeof(ZNRuntimeMethodCallEntry));
#define FIELD(type, oldtype, field) static_assert(offsetof(type,field)==offsetof(oldtype,field))
FIELD(NMRuntimeMethodCallEntry,ZNRuntimeMethodCallEntry,flags);
FIELD(NMRuntimeMethodCallEntry,ZNRuntimeMethodCallEntry,titleOffset);
FIELD(NMRuntimeMethodCallEntry,ZNRuntimeMethodCallEntry,reserved);
FIELD(NMRuntimeActionHeader,ZNRuntimeActionHeader,stringPoolOffset);
int main(){
 assert(NM_RUNTIME_ACTION_MAGIC==ZN_RUNTIME_ACTION_MAGIC && NM_RUNTIME_ACTION_VERSION==ZN_RUNTIME_ACTION_VERSION);
 assert(static_cast<uint32_t>(NMRuntimeActionKindIL2CPPMethodCall)==static_cast<uint32_t>(ZNRuntimeActionKindIL2CPPMethodCall));
 assert(static_cast<uint32_t>(NMRuntimeActionKindIL2CPPNativeHook)==static_cast<uint32_t>(ZNRuntimeActionKindIL2CPPNativeHook));
 assert(static_cast<uint32_t>(NMRuntimeActionKindDirectNativeCall)==static_cast<uint32_t>(ZNRuntimeActionKindDirectNativeCall));
 for(uint32_t index=0;index<=128;index++){
  uint32_t encoded=0;assert(NMRuntimeActionTryEncodeInstanceIndex(index,0,&encoded));
  assert(encoded==ZNRuntimeActionEncodeInstanceIndex(index));
  assert(ZNRuntimeActionDecodeInstanceIndex(encoded)==index);
  NMRuntimeMethodCallEntry fresh={};ZNRuntimeMethodCallEntry old={};
  fresh.actionID=old.actionID=3;fresh.kind=old.kind=1;fresh.flags=old.flags=encoded;fresh.argumentCount=old.argumentCount=2;
  fresh.titleOffset=old.titleOffset=64;fresh.reserved[5]=old.reserved[5]=100;
  assert(std::memcmp(&fresh,&old,sizeof(fresh))==0);
 }
 puts("PASS: original/new action ABI and 129 encoded entries match byte-for-byte");
}
