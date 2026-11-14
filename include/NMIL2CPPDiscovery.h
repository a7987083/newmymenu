#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMIL2CPPDiscovery : NSObject
- (instancetype)init NS_UNAVAILABLE;
// Binds only an already-loaded, unique runtime image. Does not invoke game methods.
+ (nullable instancetype)loadedRuntimeWithError:(NSError * _Nullable * _Nullable)error;
+ (NSDictionary *)loadedRuntimeCapabilities;
@property(nonatomic,copy,readonly) NSDictionary *runtimeReport;
- (nullable NSDictionary *)searchClasses:(NSString *)query limit:(NSUInteger)limit error:(NSError * _Nullable * _Nullable)error;
- (nullable NSDictionary *)searchMethodExpression:(NSString *)expression limit:(NSUInteger)limit error:(NSError * _Nullable * _Nullable)error;
- (nullable NSDictionary *)searchMethods:(NSString *)query limit:(NSUInteger)limit error:(NSError * _Nullable * _Nullable)error;
- (nullable NSDictionary *)methodsForClass:(NSDictionary *)identity limit:(NSUInteger)limit error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
