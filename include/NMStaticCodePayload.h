#pragma once
#import "NMStaticPatchPlan.h"
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMStaticCodePayload : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSData *code;
@property(nonatomic,copy,readonly) NSData *metadata;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *sitePatches;
@property(nonatomic,copy,readonly) NSString *sourceSHA256;
@property(nonatomic,readonly) uint64_t codeVA;
@property(nonatomic,readonly) uint64_t metadataVA;
// Generates into private immutable buffers; no process memory or files modified.
+ (nullable instancetype)payloadForPlan:(NMStaticPatchPlan *)plan codeVA:(uint64_t)codeVA metadataVA:(uint64_t)metadataVA nonce:(uint64_t)nonce error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
