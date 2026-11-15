#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMPatchImportDocument : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *candidates;
@property(nonatomic,copy,readonly) NSArray<NSString *> *warnings;
@property(nonatomic,readonly) BOOL requiresBinaryValidation;
+ (nullable instancetype)documentFromJSONData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *)JSONDataWithError:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
