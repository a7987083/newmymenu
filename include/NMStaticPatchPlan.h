#pragma once
#import <Foundation/Foundation.h>
#import "NMMachOAddress.h"
#import "NMStaticValues.h"
NS_ASSUME_NONNULL_BEGIN
__attribute__((visibility("default")))
@interface NMStaticPatchDefinition : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSString *identifier;
@property(nonatomic,copy,readonly) NSString *title;
@property(nonatomic,copy,readonly) NSString *group;
@property(nonatomic,copy,readonly) NSString *featureDescription;
@property(nonatomic,readonly) NMStaticControlType controlType;
@property(nonatomic,readonly) NMStaticValueType valueType;
@property(nonatomic,readonly) NMMachOAddressKind addressKind;
@property(nonatomic,readonly) uint64_t address;
@property(nonatomic,copy,readonly) NSData *expectedBytes;
@property(nonatomic,copy,readonly) NSData *replacementBytes;
// Caller-supplied evidence label, never a trust or execution authorization flag.
@property(nonatomic,copy,readonly) NSString *expectedBytesSource;
+ (nullable instancetype)definitionWithIdentifier:(NSString *)identifier title:(NSString *)title group:(NSString *)group featureDescription:(NSString *)featureDescription control:(NMStaticControlType)control valueType:(NMStaticValueType)valueType kind:(NMMachOAddressKind)kind address:(uint64_t)address expected:(NSData *)expected replacement:(NSData *)replacement evidence:(NSString *)evidence error:(NSError * _Nullable * _Nullable)error;
@end
__attribute__((visibility("default")))
@interface NMStaticPatchPlan : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,copy,readonly) NSArray<NMStaticPatchDefinition *> *definitions;
// Frozen dictionaries: rva/fileOffset/window/original/logicalIndexes/variants/logicalVariantIndexes.
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *physicalSites;
@property(nonatomic,copy,readonly) NSArray<NSNumber *> *logicalToPhysical;
@property(nonatomic,copy,readonly) NSString *sourceSHA256;
@property(nonatomic,readonly) NSUInteger sourceLength;
@property(nonatomic,readonly) uint64_t imageBase;
@property(nonatomic,readonly) BOOL requiresRelocationValidation;
+ (nullable instancetype)planForMachO:(NSData *)source definitions:(NSArray<NMStaticPatchDefinition *> *)definitions error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
