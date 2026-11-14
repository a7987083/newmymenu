#pragma once
#import <Foundation/Foundation.h>
#import "NMReceiverLease.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NMReceiverSelection) {
    NMReceiverSelectionNone,
    NMReceiverSelectionAutomatic,
    NMReceiverSelectionOrdinal,
    NMReceiverSelectionExplicit,
};

__attribute__((visibility("default")))
@interface NMInvocationRequest : NSObject <NSCopying>
@property(nonatomic,copy,readonly) NSUUID *identifier;
@property(nonatomic,copy,readonly) NSString *methodIdentity;
@property(nonatomic,copy,readonly) NSArray<NSString *> *parameterTypes;
@property(nonatomic,copy,readonly) NSArray<NSString *> *argumentValues;
@property(nonatomic,readonly,getter=isStatic) BOOL staticMethod;
@property(nonatomic,readonly) NMReceiverSelection receiverSelection;
@property(nonatomic,readonly) NSUInteger instanceIndex;
@property(nonatomic,strong,readonly,nullable) NMReceiverLease *explicitReceiver;
- (instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)requestForMethod:(NSString *)identity
                          parameterTypes:(NSArray<NSString *> *)types
                          argumentValues:(NSArray<NSString *> *)values
                                isStatic:(BOOL)isStatic
                               selection:(NMReceiverSelection)selection
                           instanceIndex:(NSUInteger)index
                        explicitReceiver:(nullable NMReceiverLease *)receiver
                                   error:(NSError * _Nullable * _Nullable)error;
@end

typedef NMReceiverLease * _Nullable (^NMReceiverProvider)(NMInvocationRequest *request, NSError * _Nullable * _Nullable error);
typedef NSDictionary * _Nullable (^NMInvocationBackend)(NMInvocationRequest *request, uintptr_t receiver, NSError * _Nullable * _Nullable error);

__attribute__((visibility("default")))
@interface NMInvocationCoordinator : NSObject
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithReceiverProvider:(NMReceiverProvider)provider backend:(NMInvocationBackend)backend;
- (nullable NSDictionary *)executeRequest:(NMInvocationRequest *)request error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
