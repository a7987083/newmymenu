#pragma once
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary * _Nullable (^NMReceiverOperation)(uintptr_t receiver, NSError * _Nullable * _Nullable error);
// Must synchronously call operation exactly once on the calling thread.
// owner must guarantee receiver lifetime AND address validity for the entire operation.
typedef void (^NMReceiverScope)(id owner, NMReceiverOperation operation);

__attribute__((visibility("default")))
@interface NMReceiverLease : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)leaseRetainingObject:(id)object error:(NSError * _Nullable * _Nullable)error;
+ (nullable instancetype)leaseWithOwner:(id)owner scope:(NMReceiverScope)scope error:(NSError * _Nullable * _Nullable)error;
- (nullable NSDictionary *)performOperation:(NMReceiverOperation)operation error:(NSError * _Nullable * _Nullable)error;
@end
NS_ASSUME_NONNULL_END
