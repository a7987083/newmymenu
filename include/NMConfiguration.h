#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMConfigurationDocument : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *runtimeMethods;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *nativeHooks;
@property(nonatomic,copy,readonly) NSArray<NSString *> *warnings;
@property(nonatomic,readonly) BOOL requiresTargetValidation;
+ (instancetype)emptyDocument;
+ (nullable instancetype)documentFromJSONData:(NSData *)data error:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *)JSONDataWithError:(NSError * _Nullable * _Nullable)error;
- (nullable NSData *)legacyAuthoringJSONDataWithError:(NSError * _Nullable * _Nullable)error;
@end
__attribute__((visibility("default")))
@interface NMConfigurationSnapshot : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,strong,readonly) NMConfigurationDocument *document;
@property(nonatomic,readonly) uint64_t revision;
@end
typedef NS_ENUM(NSUInteger,NMConfigurationImportMode){NMConfigurationImportMerge=1,NMConfigurationImportReplace=2};
__attribute__((visibility("default")))
@interface NMConfigurationStore : NSObject
- (instancetype)init;
@property(nonatomic,strong,readonly) NMConfigurationSnapshot *snapshot;
- (BOOL)importJSONData:(NSData *)data mode:(NMConfigurationImportMode)mode expectedRevision:(uint64_t)revision error:(NSError * _Nullable * _Nullable)error;
// The only commit entry. Empty replacement is explicit, never an accidental bad import.
- (BOOL)commitDocument:(NMConfigurationDocument *)document mode:(NMConfigurationImportMode)mode expectedRevision:(uint64_t)revision error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
