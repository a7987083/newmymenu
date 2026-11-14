#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "NMCaptureSession.h"
#include <atomic>
#include <stdio.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL capture: %s\n",message);abort();}}
static void waitSignal(dispatch_semaphore_t sem,const char *message){check(dispatch_semaphore_wait(sem,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,message);}
static void waitState(NMCaptureSessionManager *manager,NMCaptureState state){
 for(unsigned i=0;i<300;i++){
  if(manager.state==state)return;
  dispatch_semaphore_t delay=dispatch_semaphore_create(0);dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*10),dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{dispatch_semaphore_signal(delay);});waitSignal(delay,"state delay");
 }
 check(NO,"capture state did not converge");
}
@interface NMCaptureHarness : NSObject
@property(nonatomic,strong) NSMutableDictionary *events;
@property(nonatomic,strong) NSMutableDictionary *installAcks;
@property(nonatomic,strong) NSMutableDictionary *closeAcks;
@property(nonatomic,assign) BOOL autoInstall;
@property(nonatomic,assign) BOOL autoClose;
@property(nonatomic,assign) NSUInteger closeCount;
@property(nonatomic,strong) dispatch_semaphore_t installed;
@property(nonatomic,strong) dispatch_semaphore_t closed;
@property(nonatomic,strong) dispatch_queue_t callbacks;
- (NMCaptureSessionManager *)manager;
- (NMCaptureEvent)event:(NMCaptureToken *)token;
- (NMCaptureAcknowledgement)takeInstall:(NMCaptureToken *)token;
- (void)ackClose:(NMCaptureToken *)token error:(NSError *)error;
@end
@implementation NMCaptureHarness
- (instancetype)init{self=[super init];if(self){_events=[NSMutableDictionary new];_installAcks=[NSMutableDictionary new];_closeAcks=[NSMutableDictionary new];_autoInstall=YES;_autoClose=YES;_installed=dispatch_semaphore_create(0);_closed=dispatch_semaphore_create(0);_callbacks=dispatch_queue_create("fixture.capture.callbacks",DISPATCH_QUEUE_SERIAL);}return self;}
- (NMCaptureSessionManager *)manager{
 return [[NMCaptureSessionManager alloc] initWithInstallHandler:^(NMCaptureToken *token,NMCaptureEvent event,NMCaptureAcknowledgement installed){
  BOOL autoInstall;@synchronized(self){self.events[token.identifier]=[event copy];autoInstall=self.autoInstall;if(!autoInstall)self.installAcks[token.identifier]=[installed copy];}
  if(autoInstall)installed(nil);dispatch_semaphore_signal(self.installed);
 } closeHandler:^(NMCaptureToken *token,NMCaptureAcknowledgement closed){
  BOOL autoClose;@synchronized(self){self.closeCount++;autoClose=self.autoClose;if(autoClose)[self.events removeObjectForKey:token.identifier];else self.closeAcks[token.identifier]=[closed copy];}
  if(autoClose)closed(nil);dispatch_semaphore_signal(self.closed);
 } callbackQueue:self.callbacks];
}
- (NMCaptureEvent)event:(NMCaptureToken *)token{@synchronized(self){return [self.events[token.identifier] copy];}}
- (NMCaptureAcknowledgement)takeInstall:(NMCaptureToken *)token{@synchronized(self){NMCaptureAcknowledgement ack=[self.installAcks[token.identifier] copy];[self.installAcks removeObjectForKey:token.identifier];return ack;}}
- (void)ackClose:(NMCaptureToken *)token error:(NSError *)error{
 NMCaptureAcknowledgement ack;@synchronized(self){ack=[self.closeAcks[token.identifier] copy];[self.closeAcks removeObjectForKey:token.identifier];if(!error)[self.events removeObjectForKey:token.identifier];}
 check(ack!=nil,"pending close ack exists");ack(error);
}
@end
static NMReceiverLease *objectLease(){return [NMReceiverLease leaseRetainingObject:[NSObject new] error:NULL];}
static void stale_session(){
 NMCaptureHarness *h=[NMCaptureHarness new];NMCaptureSessionManager *manager=[h manager];dispatch_semaphore_t aDone=dispatch_semaphore_create(0),bDone=dispatch_semaphore_create(0);
 NMCaptureToken *a=[manager startForTarget:@"A" timeout:0.5 completion:^(NMCaptureToken *token,NMReceiverLease *lease,NSError *error){(void)token;check(lease!=nil&&!error,"A captured");dispatch_semaphore_signal(aDone);} error:NULL];
 waitState(manager,NMCaptureStateActive);NMCaptureEvent stale=[h event:a];stale(objectLease());waitSignal(aDone,"A completion");waitState(manager,NMCaptureStateIdle);
 NMCaptureToken *b=[manager startForTarget:@"B" timeout:15 completion:^(NMCaptureToken *token,NMReceiverLease *lease,NSError *error){(void)token;check(lease==nil&&error.code==8,"B only ends by its own cancellation");dispatch_semaphore_signal(bDone);} error:NULL];
 waitState(manager,NMCaptureStateActive);stale(objectLease());[manager cancelSession:a];
 dispatch_semaphore_t pastOldDeadline=dispatch_semaphore_create(0);dispatch_after(dispatch_time(DISPATCH_TIME_NOW,800*NSEC_PER_MSEC),dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{dispatch_semaphore_signal(pastOldDeadline);});waitSignal(pastOldDeadline,"old A deadline elapsed");
 check(manager.state==NMCaptureStateActive,"B survives A stale event, cancel and deadline");
 [manager cancelSession:b];waitSignal(bDone,"B completion");waitState(manager,NMCaptureStateIdle);
 @synchronized(h){check(h.closeCount==2,"one close per actual session");}
 [manager invalidate];waitState(manager,NMCaptureStateInvalidated);
 check([manager startForTarget:@"C" timeout:1 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;(void)l;(void)e;} error:NULL]==nil,"invalidated manager rejects new session");
}
static void installing_cancel(){
 NMCaptureHarness *h=[NMCaptureHarness new];h.autoInstall=NO;NMCaptureSessionManager *manager=[h manager];dispatch_semaphore_t done=dispatch_semaphore_create(0);
 NMCaptureToken *token=[manager startForTarget:@"Installing" timeout:1 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;check(l==nil&&e.code==8,"install cancellation retained");dispatch_semaphore_signal(done);} error:NULL];
 waitSignal(h.installed,"install handler started");[manager cancelSession:token];check(manager.state==NMCaptureStateInstalling,"cannot close before install ack");
 @synchronized(h){check(h.closeCount==0,"pending install owns its resources");}
 [h event:token](objectLease());
 check([manager startForTarget:@"Other" timeout:1 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;(void)l;(void)e;} error:NULL]==nil,"pending install blocks reuse");
 NMCaptureAcknowledgement ack=[h takeInstall:token];check(ack!=nil,"take install ack");ack(nil);waitSignal(done,"cancel completes after install/close ack");waitState(manager,NMCaptureStateIdle);
 ack(nil);check(manager.state==NMCaptureStateIdle,"duplicate install ack does not revive session");
}
static void safe_close_and_retry(){
 NMCaptureHarness *h=[NMCaptureHarness new];h.autoClose=NO;NMCaptureSessionManager *manager=[h manager];dispatch_semaphore_t done=dispatch_semaphore_create(0);std::atomic<unsigned> completions(0);auto *count=&completions;
 NMCaptureToken *token=[manager startForTarget:@"Closing" timeout:1 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;check(l==nil&&e.code==7,"close failure is explicit");count->fetch_add(1);dispatch_semaphore_signal(done);} error:NULL];
 waitState(manager,NMCaptureStateActive);[h event:token](objectLease());waitSignal(h.closed,"close requested");waitState(manager,NMCaptureStateClosing);
 check(dispatch_semaphore_wait(done,DISPATCH_TIME_NOW)!=0,"no completion before close ack");
 NMCaptureCompletion unused=^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;(void)l;(void)e;};
 check([manager startForTarget:@"Blocked" timeout:1 completion:unused error:NULL]==nil,"closing blocks new install");
 [h ackClose:token error:[NSError errorWithDomain:@"fixture" code:1 userInfo:nil]];waitSignal(done,"close error delivered");waitState(manager,NMCaptureStateCloseFailed);
 check([manager startForTarget:@"Still blocked" timeout:1 completion:unused error:NULL]==nil,"failed close retains session ownership");
 @synchronized(h){h.autoClose=YES;}[manager retryCloseForSession:token];waitState(manager,NMCaptureStateIdle);dispatch_sync(h.callbacks,^{});
 check(completions.load()==1,"retry does not deliver completion twice");
}
static void install_failure_and_timeout(){
 NMCaptureHarness *h=[NMCaptureHarness new];h.autoInstall=NO;NMCaptureSessionManager *manager=[h manager];dispatch_semaphore_t done=dispatch_semaphore_create(0);
 NMCaptureToken *token=[manager startForTarget:@"Install fails" timeout:1 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;check(l==nil&&[e.domain isEqual:@"fixture-install"],"install error propagated after cleanup");dispatch_semaphore_signal(done);} error:NULL];
 waitSignal(h.installed,"failed install entered");[h takeInstall:token]([NSError errorWithDomain:@"fixture-install" code:9 userInfo:nil]);waitSignal(done,"failed install cleanup");waitState(manager,NMCaptureStateIdle);
 @synchronized(h){h.autoInstall=YES;}dispatch_semaphore_t timedOut=dispatch_semaphore_create(0);
 [manager startForTarget:@"Actual timeout" timeout:0.5 completion:^(NMCaptureToken *t,NMReceiverLease *l,NSError *e){(void)t;check(l==nil&&e.code==4,"current session own timeout");dispatch_semaphore_signal(timedOut);} error:NULL];
 waitSignal(timedOut,"timeout completes");waitState(manager,NMCaptureStateIdle);
}
int main(){@autoreleasepool{stale_session();installing_cancel();safe_close_and_retry();install_failure_and_timeout();puts("PASS: real timers isolate old sessions; install cancellation, acknowledged close, failure ownership/retry and one-shot completion");}return 0;}
