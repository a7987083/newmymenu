#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
// Process-scoped owner of prepared-image pins and per-physical-site owner stacks.
__attribute__((visibility("default")))
@interface NMStaticRuntime : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)sharedRuntime;
@property(nonatomic,copy,readonly) NSDictionary *snapshot;
- (BOOL)refreshLoadedImagesWithError:(NSError * _Nullable * _Nullable)error;
// For explicit integration/testing: never loads an absent image (RTLD_NOLOAD).
- (BOOL)bindLoadedImageAtPath:(NSString *)path error:(NSError * _Nullable * _Nullable)error;
// Nil value uses the current cell. Disabled requests cannot carry a value.
- (BOOL)setFeature:(NSString *)identifier enabled:(BOOL)enabled value:(nullable NSString *)value error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
