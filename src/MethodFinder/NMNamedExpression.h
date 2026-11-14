#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface NMNamedExpression : NSObject
+ (nullable NSDictionary *)parse:(NSString *)expression error:(NSString * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
