#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "NMInvocationCoordinator.h"
#include <atomic>
#include <initializer_list>
#include <stdio.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL execution: %s\n",message);abort();}}
@interface NMTestReceiver : NSObject
@property(nonatomic,assign) NSInteger value;
@property(nonatomic,assign) std::atomic<unsigned> *deallocations;
@end
@implementation NMTestReceiver
- (void)dealloc { if(_deallocations)_deallocations->fetch_add(1); }
@end
static NMInvocationRequest *request(NSUInteger arity,BOOL byRef,NMReceiverSelection selection,NSUInteger ordinal,NMReceiverLease *lease,BOOL isStatic){
 NSMutableArray *types=[NSMutableArray array],*values=[NSMutableArray array];
 for(NSUInteger i=0;i<arity;i++){[types addObject:byRef?@"System.Int32&":@"System.Int32"];[values addObject:@"7"];}
 NSError *error=nil;NMInvocationRequest *r=[NMInvocationRequest requestForMethod:@"Fixture::Call" parameterTypes:types argumentValues:values isStatic:isStatic selection:selection instanceIndex:ordinal explicitReceiver:lease error:&error];
 check(r!=nil&&error==nil,"request creation");return r;
}
static void receiver_contract(){
 NMTestReceiver *a=[NMTestReceiver new],*b=[NMTestReceiver new];a.value=1;b.value=2;
 NMReceiverLease *leaseA=[NMReceiverLease leaseRetainingObject:a error:NULL],*leaseB=[NMReceiverLease leaseRetainingObject:b error:NULL];
 std::atomic<unsigned> backendCalls(0),providerCalls(0);auto *calls=&backendCalls;auto *providers=&providerCalls;
 NMInvocationCoordinator *engine=[[NMInvocationCoordinator alloc] initWithReceiverProvider:^NMReceiverLease *(NMInvocationRequest *r,NSError **error){
  (void)error;providers->fetch_add(1);return r.receiverSelection==NMReceiverSelectionOrdinal&&r.instanceIndex==2?leaseB:leaseA;
 } backend:^NSDictionary *(NMInvocationRequest *r,uintptr_t receiver,NSError **error){
  (void)error;calls->fetch_add(1);if(r.isStatic){check(receiver==0,"static receiver");return @{@"value":@0};}
  NMTestReceiver *target=(__bridge NMTestReceiver *)(void *)receiver;
  return @{@"value":@(target.value),@"arity":@(r.argumentValues.count)};
 }];
 for(NSUInteger arity: {0u,1u,2u,8u})for(NSNumber *ref in @[@NO,@YES]){
  if(ref.boolValue && arity!=1)continue;
  for(NSNumber *mode in @[@(NMReceiverSelectionOrdinal),@(NMReceiverSelectionExplicit)]){
   NMReceiverSelection kind=(NMReceiverSelection)mode.unsignedIntegerValue;
   NMInvocationRequest *r=request(arity,ref.boolValue,kind,kind==NMReceiverSelectionOrdinal?2:0,kind==NMReceiverSelectionExplicit?leaseB:nil,NO);
   NSError *error=nil;NSDictionary *result=[engine executeRequest:r error:&error];
   check([result[@"value"] intValue]==2&&!error,"all arities/ByRef use requested B, never selected A");
  }
 }
 check(providerCalls.load()==5,"explicit leases never call selection provider");
 NMInvocationRequest *parallel=request(2,NO,NMReceiverSelectionExplicit,0,leaseB,NO);
 dispatch_apply(1000,dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^(size_t index){@autoreleasepool{
  (void)index;NSError *error=nil;check([[[engine executeRequest:parallel error:&error] objectForKey:@"value"] intValue]==2&&!error,"concurrent explicit receiver isolation");
 }});
 check(backendCalls.load()==1010,"one backend call per request");
 check([[[engine executeRequest:request(0,NO,NMReceiverSelectionNone,0,nil,YES) error:NULL] objectForKey:@"value"] intValue]==0,"static request path");
 NSMutableString *type=[@"System.Int32" mutableCopy],*value=[@"1" mutableCopy],*identity=[@"Fixture" mutableCopy];
 NMInvocationRequest *frozen=[NMInvocationRequest requestForMethod:identity parameterTypes:@[type] argumentValues:@[value] isStatic:NO selection:NMReceiverSelectionExplicit instanceIndex:0 explicitReceiver:leaseB error:NULL];
 [type setString:@"bad"];[value setString:@"bad"];[identity setString:@"bad"];
 check([frozen.methodIdentity isEqual:@"Fixture"]&&[frozen.parameterTypes[0] isEqual:@"System.Int32"]&&[frozen.argumentValues[0] isEqual:@"1"],"request deep copies input strings");
 NSError *error=nil;
 check([NMInvocationRequest requestForMethod:@"x" parameterTypes:@[] argumentValues:@[] isStatic:NO selection:NMReceiverSelectionOrdinal instanceIndex:129 explicitReceiver:nil error:&error]==nil&&error,"invalid ordinal rejected before backend");
 check([NMInvocationRequest requestForMethod:@"x" parameterTypes:@[] argumentValues:@[] isStatic:NO selection:NMReceiverSelectionExplicit instanceIndex:2 explicitReceiver:leaseB error:&error]==nil,"mixed receiver intent rejected");
}
static void lease_scope_contract(){
 NSObject *owner=[NSObject new];__block unsigned calls=0;NSError *error=nil;
 NMReceiverOperation operation=^NSDictionary *(uintptr_t receiver,NSError **failure){(void)receiver;(void)failure;calls++;return @{};};
 NMReceiverLease *twice=[NMReceiverLease leaseWithOwner:owner scope:^(id resource,NMReceiverOperation op){op((uintptr_t)(__bridge void*)resource,NULL);op((uintptr_t)(__bridge void*)resource,NULL);} error:NULL];
 check([twice performOperation:operation error:&error]==nil&&error&&calls==1,"double scope cannot execute backend twice");
 __block NMReceiverOperation late=nil;
 NMReceiverLease *asynchronous=[NMReceiverLease leaseWithOwner:owner scope:^(id resource,NMReceiverOperation op){(void)resource;late=[op copy];} error:NULL];
 error=nil;check([asynchronous performOperation:operation error:&error]==nil&&error,"scope must be synchronous");
 check(late((uintptr_t)(__bridge void*)owner,NULL)==nil&&calls==1,"late operation cannot execute");late=nil;
 NMReceiverLease *cross=[NMReceiverLease leaseWithOwner:owner scope:^(id resource,NMReceiverOperation op){
  dispatch_semaphore_t done=dispatch_semaphore_create(0);
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{op((uintptr_t)(__bridge void*)resource,NULL);dispatch_semaphore_signal(done);});
  check(dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"cross-thread callback finishes");
 } error:NULL];
 error=nil;check([cross performOperation:operation error:&error]==nil&&error&&calls==1,"cross-thread scope rejected");
 NMReceiverLease *nullReceiver=[NMReceiverLease leaseWithOwner:owner scope:^(id resource,NMReceiverOperation op){(void)resource;op(0,NULL);} error:NULL];
 check([nullReceiver performOperation:operation error:&error]==nil&&error&&calls==1,"null receiver rejected");
 NMReceiverLease *lease=[NMReceiverLease leaseRetainingObject:owner error:NULL];
 NMInvocationCoordinator *throws=[[NMInvocationCoordinator alloc] initWithReceiverProvider:^NMReceiverLease *(NMInvocationRequest *r,NSError **e){(void)r;(void)e;return lease;} backend:^NSDictionary *(NMInvocationRequest *r,uintptr_t p,NSError **e){(void)r;(void)p;(void)e;[NSException raise:@"FixtureFailure" format:@"expected"];return nil;}];
 error=nil;check([throws executeRequest:request(2,NO,NMReceiverSelectionExplicit,0,lease,NO) error:&error]==nil&&error,"backend exception becomes explicit failure");
}
static void owner_lifetime(){
 std::atomic<unsigned> deallocations(0);auto *count=&deallocations;__weak NMTestReceiver *weak=nil;
 dispatch_semaphore_t entered=dispatch_semaphore_create(0),release=dispatch_semaphore_create(0),finished=dispatch_semaphore_create(0);
 dispatch_queue_t worker=dispatch_queue_create("fixture.invocation",DISPATCH_QUEUE_SERIAL);
 NMInvocationCoordinator *engine=[[NMInvocationCoordinator alloc] initWithReceiverProvider:^NMReceiverLease *(NMInvocationRequest *r,NSError **e){(void)r;(void)e;return nil;} backend:^NSDictionary *(NMInvocationRequest *r,uintptr_t pointer,NSError **e){
  (void)r;(void)e;dispatch_semaphore_signal(entered);check(dispatch_semaphore_wait(release,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"release invocation");
  NMTestReceiver *object=(__bridge NMTestReceiver *)(void *)pointer;return @{@"value":@(object.value)};
 }];
 @autoreleasepool{
  NMTestReceiver *object=[NMTestReceiver new];object.value=7;object.deallocations=count;weak=object;
  NMReceiverLease *lease=[NMReceiverLease leaseRetainingObject:object error:NULL];NMInvocationRequest *r=request(1,NO,NMReceiverSelectionExplicit,0,lease,NO);
  dispatch_async(worker,^{@autoreleasepool{check([[[engine executeRequest:r error:NULL] objectForKey:@"value"] intValue]==7,"leased object usable throughout call");}dispatch_semaphore_signal(finished);});
 }
 check(dispatch_semaphore_wait(entered,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"backend entered");
 check(weak!=nil&&deallocations.load()==0,"external refs released but lease owner alive");
 dispatch_semaphore_signal(release);check(dispatch_semaphore_wait(finished,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"backend finished");dispatch_sync(worker,^{});
 check(weak==nil&&deallocations.load()==1,"lease resource released exactly once after call");
}
int main(){@autoreleasepool{receiver_contract();lease_scope_contract();owner_lifetime();puts("PASS: explicit/ordinal receiver across arity/ByRef, 1000 parallel calls, immutable requests, invalid scopes, errors and real ObjC resource lifetime");}return 0;}
