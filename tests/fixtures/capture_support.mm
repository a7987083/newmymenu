#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
static unsigned gAuditInstalls,gAuditDestroys;
static ZNM47DobbyInstrumentCallback gAuditHandler;
static void *gAuditHookAddress;
static void NMRequire(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL %s\n",message);abort();}}
static double NMSeconds(){struct timespec ts;clock_gettime(CLOCK_MONOTONIC,&ts);return ts.tv_sec+ts.tv_nsec/1e9;}
@interface ZNRuntimeLogger : NSObject
+ (instancetype)sharedLogger;
- (void)log:(NSString *)text;
@end
@implementation ZNRuntimeLogger
+ (instancetype)sharedLogger{static id logger;static dispatch_once_t once;dispatch_once(&once,^{logger=[self new];});return logger;}
- (void)log:(NSString *)text{(void)text;}
@end
extern "C" int DobbyInstrument(void *address,ZNM47DobbyInstrumentCallback callback){gAuditInstalls++;gAuditHandler=callback;gAuditHookAddress=address;return 0;}
extern "C" int DobbyDestroy(void *address){NMRequire(address==gAuditHookAddress,"destroy matches active boundary address");gAuditDestroys++;return 0;}
// INSERT EXACT SOURCE HERE
int main(){@autoreleasepool{
#if !defined(__arm64__) && !defined(__aarch64__)
 fprintf(stderr,"This exact callback fixture requires real arm64\n");return 1;
#endif
 dispatch_async(dispatch_get_main_queue(),^{
  NSString *error=nil;
  BOOL started=ZNM47StartReceiverCapture(@{@"methodPointer":@0x1000,@"method":@"A"},0.5,^(uintptr_t receiver,NSString *captureError){
   NMRequire(receiver==0xA000 && captureError==nil,"A completes by actual capture callback");
   double startedB=NMSeconds();NSString *nextError=nil;
   BOOL next=ZNM47StartReceiverCapture(@{@"methodPointer":@0x2000,@"method":@"B"},15.0,^(uintptr_t nextReceiver,NSString *nextCaptureError){
    double elapsed=NMSeconds()-startedB;
    NMRequire(nextReceiver==0 && [nextCaptureError containsString:@"捕获窗口结束"],"B was wrongly timed out");
    NMRequire(elapsed<10.0,"B terminated before its 15 second deadline");
    NMRequire(gAuditInstalls==2 && gAuditDestroys==2 && !ZNM47ReceiverCaptureBusy(),"stale timeout destroyed B session");
    printf("REPRO session A=0.5s completed; session B=15s wrongly ended by A stale timeout after %.3fs\n",elapsed);
    puts("PASS: exact fixed-source cross-session timeout defect reproduced with real libdispatch");
    puts("NOT VERIFIED: real Dobby patching, target process, iOS device or production fix");fflush(stdout);exit(0);
   },&nextError);
   NMRequire(next && nextError==nil,"B starts after A completion");
  },&error);
  NMRequire(started && error==nil,"A starts");
  ZNM47DobbyRegisterContextPrefix context={};context.general.regs.x0=0xA000;
  gAuditHandler((void *)0x1000,&context);
 });
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC),dispatch_get_main_queue(),^{NMRequire(NO,"expected stale timeout was not observed within watchdog");});
 dispatch_main();
 }return 0;}
