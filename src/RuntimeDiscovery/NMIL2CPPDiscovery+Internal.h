#pragma once
#import "NMIL2CPPDiscovery.h"
#import "NMIL2CPPAPI.h"
// Dependency-injection seam for controlled native API fixtures; not installed in public include/.
@interface NMIL2CPPDiscovery (Internal)
- (nullable instancetype)initWithAPI:(NMIL2CPPAPI)api report:(NSDictionary *)report ownedHandle:(nullable void *)handle;
@end
