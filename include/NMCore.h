#pragma once
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
// Foundation core only. API 1 does not imply menu/Invoke/Hook/Build availability.
__attribute__((visibility("default"))) uint32_t NewMyMenuCoreGetAPIVersion(void);
#ifdef __cplusplus
}
#endif
