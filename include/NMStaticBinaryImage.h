#pragma once
#import "NMStaticCodePayload.h"
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMStaticBinaryImage : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSData *image;
@property(nonatomic,copy,readonly) NSDictionary *report;
// Owned __NMTEXT/__NMDATA segments only. Existing header slack required.
// Result is not signed. Publish only after independently verified signing.
+ (nullable instancetype)imageForSource:(NSData *)source plan:(NMStaticPatchPlan *)plan nonce:(uint64_t)nonce error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
