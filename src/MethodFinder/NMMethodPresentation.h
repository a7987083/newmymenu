#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
// Display-only fields. Raw values are the only clipboard source; no metadata pointers.
@interface NMMethodPresentation : NSObject
+ (NSArray<NSDictionary *> *)fieldsForMethod:(NSDictionary *)method;
+ (NSString *)subtitleForMethod:(NSDictionary *)method;
@end
NS_ASSUME_NONNULL_END
