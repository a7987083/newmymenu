#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMMachOSigner : NSObject
// Input is read-only. Output must not exist. Signature is ad-hoc, not an IPA identity signature.
+ (nullable NSDictionary *)signedCopyFromPath:(NSString *)input toPath:(NSString *)output error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
