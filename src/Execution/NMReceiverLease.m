#import "NMReceiverLease.h"

static NSError *NMLeaseError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"newmymenu.receiver-lease" code:code userInfo:@{NSLocalizedDescriptionKey:message}];
}

@interface NMLeaseCallState : NSObject
@property(nonatomic,strong) NSLock *lock;
@property(nonatomic,strong) NSThread *thread;
@property(nonatomic,assign) BOOL sealed;
@property(nonatomic,assign) BOOL called;
@property(nonatomic,strong,nullable) NSError *error;
@property(nonatomic,copy,nullable) NSDictionary *result;
@end
@implementation NMLeaseCallState @end

@interface NMReceiverLease () {
    @private
    id _owner;
    NMReceiverScope _scope;
}
- (instancetype)initWithOwner:(id)owner scope:(NMReceiverScope)scope;
@end

@implementation NMReceiverLease
- (instancetype)initWithOwner:(id)owner scope:(NMReceiverScope)scope {
    self=[super init];
    if (self) { _owner=owner; _scope=[scope copy]; }
    return self;
}
+ (instancetype)leaseRetainingObject:(id)object error:(NSError **)error {
    return [self leaseWithOwner:object scope:^(id owner, NMReceiverOperation operation) {
        operation((uintptr_t)(__bridge void *)owner, NULL);
    } error:error];
}
+ (instancetype)leaseWithOwner:(id)owner scope:(NMReceiverScope)scope error:(NSError **)error {
    if (!owner || !scope) {
        if (error) *error=NMLeaseError(1,@"Receiver lease requires an owned resource and scope");
        return nil;
    }
    if (error) *error=nil;
    return [[self alloc] initWithOwner:owner scope:scope];
}
- (NSDictionary *)performOperation:(NMReceiverOperation)operation error:(NSError **)error {
    if (!operation) { if (error) *error=NMLeaseError(2,@"Receiver operation is missing"); return nil; }
    NMLeaseCallState *state=[NMLeaseCallState new];
    state.lock=[NSLock new]; state.thread=NSThread.currentThread;
    // Keep the owner alive even if an invalid adapter retains the operation block.
    __attribute__((objc_precise_lifetime)) id resource=_owner;
    NMReceiverOperation guarded=^NSDictionary *(uintptr_t receiver, NSError **scopeError) {
        (void)resource;
        [state.lock lock];
        if (state.sealed || state.called || state.error || NSThread.currentThread!=state.thread || !receiver) {
            NSError *failure=NMLeaseError(3,@"Receiver scope is late, repeated, cross-thread, or null");
            if (!state.sealed) state.error=failure;
            [state.lock unlock];
            if (scopeError) *scopeError=failure;
            return nil;
        }
        state.called=YES;
        [state.lock unlock];
        NSError *failure=nil;
        NSDictionary *result=operation(receiver,&failure);
        [state.lock lock];
        if (failure) state.error=failure;
        else if (![result isKindOfClass:NSDictionary.class]) state.error=NMLeaseError(4,@"Receiver operation returned no valid result");
        else state.result=[result copy];
        NSError *publishedError=state.error;
        NSDictionary *publishedResult=publishedError?nil:state.result;
        [state.lock unlock];
        if (scopeError) *scopeError=publishedError;
        return publishedResult;
    };
    @try { _scope(resource,guarded); }
    @catch (NSException *exception) {
        [state.lock lock];
        state.error=NMLeaseError(5,[NSString stringWithFormat:@"Receiver scope exception %@: %@",exception.name,exception.reason?:@""]);
        [state.lock unlock];
    } @finally {
        [state.lock lock];
        state.sealed=YES;
        if (!state.called && !state.error) state.error=NMLeaseError(6,@"Receiver scope did not synchronously execute the operation");
        [state.lock unlock];
    }
    [state.lock lock];
    NSDictionary *result=state.error?nil:state.result;
    NSError *failure=state.error;
    [state.lock unlock];
    if (error) *error=failure;
    return result;
}
@end
