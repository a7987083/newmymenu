#pragma once
#import "NMStaticBinaryImage.h"
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMOfflineBuildRequest : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,strong,readonly) NMStaticPatchPlan *plan;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *reviewRows;
@property(nonatomic,copy,readonly) NSArray<NSString *> *warnings;
+ (nullable instancetype)requestWithSource:(NSData *)source name:(NSString *)name patchJSON:(NSData *)patchJSON kind:(NMMachOAddressKind)kind error:(NSError * _Nullable * _Nullable)error;
// New unique directory only; source never opened writable. Remove all private files on failure.
- (nullable NSDictionary *)generateInNewDirectory:(NSString *)directory reviewAcknowledged:(BOOL)review nonce:(uint64_t)nonce progress:(nullable NSProgress *)progress error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
