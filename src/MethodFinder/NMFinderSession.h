#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
// Private presentation state; all access belongs to the main thread.
@interface NMFinderSession : NSObject
@property(nonatomic,readonly) NSUInteger generation;
@property(nonatomic,copy,readonly) NSDictionary *snapshot;
@property(nonatomic,copy,readonly) NSDictionary *report;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *rows;
@property(nonatomic,readonly) BOOL methodMode;
@property(nonatomic,readonly) BOOL canReturnToClasses;
@property(nonatomic,readonly) double classOffset;
- (NSUInteger)beginRequestResetClasses:(BOOL)reset classOffset:(double)offset;
- (BOOL)acceptSnapshot:(nullable NSDictionary *)snapshot report:(NSDictionary *)report generation:(NSUInteger)generation;
- (BOOL)returnToClasses;
@end
NS_ASSUME_NONNULL_END
