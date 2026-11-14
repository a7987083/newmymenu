#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger,NMBuildItemDomain){NMBuildItemDomainStatic=1,NMBuildItemDomainRuntime=2};
__attribute__((visibility("default")))
@interface NMBuildItem : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSString *providerIdentifier;
@property(nonatomic,copy,readonly) NSString *kind;
@property(nonatomic,copy,readonly) NSString *identifier;
@property(nonatomic,readonly) NMBuildItemDomain domain;
@property(nonatomic,copy,readonly) NSDictionary *metadata;
+ (nullable instancetype)itemWithProvider:(NSString *)provider kind:(NSString *)kind identifier:(NSString *)identifier domain:(NMBuildItemDomain)domain metadata:(NSDictionary *)metadata error:(NSError * _Nullable * _Nullable)error;
@end
// All input data must come from the frozen configuration. Error is held before inner pools drain.
typedef NSArray<NMBuildItem *> * _Nullable (^NMBuildCollector)(NSDictionary *configuration,NSError * _Nullable __strong * _Nonnull error);
__attribute__((visibility("default")))
@interface NMBuildProvider : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSString *identifier;
+ (nullable instancetype)providerWithIdentifier:(NSString *)identifier collector:(NMBuildCollector)collector;
@end
__attribute__((visibility("default")))
@interface NMBuildManifest : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSArray<NMBuildItem *> *items;
@property(nonatomic,copy,readonly) NSArray<NSString *> *activeProviderIdentifiers;
@property(nonatomic,readonly) NSUInteger staticItemCount;
@property(nonatomic,readonly) NSUInteger runtimeItemCount;
+ (nullable instancetype)collectProviders:(NSArray<NMBuildProvider *> *)providers configuration:(NSDictionary *)configuration error:(NSError * _Nullable * _Nullable)error;
+ (nullable instancetype)manifestFromJSONData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *)JSONDataWithError:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
