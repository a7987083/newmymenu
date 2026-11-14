#import <Foundation/Foundation.h>
#import "NMSwizzleManager.h"
#import <dispatch/dispatch.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
static void check(BOOL ok,const char *text){if(!ok){fprintf(stderr,"FAIL swizzle: %s\n",text);abort();}}
static NMSwizzleToken *instanceToken,*classToken;
static _Atomic(unsigned) released;
typedef struct {double value;NSInteger count;} NMSWPair;
@interface NMSWParent : NSObject
- (NSInteger)value:(NSInteger)x;
+ (double)classValue:(double)x;
- (NMSWPair)pair:(double)x count:(NSInteger)n;
@end
@implementation NMSWParent
- (NSInteger)value:(NSInteger)x{return x+1;}
+ (double)classValue:(double)x{return x+0.5;}
- (NMSWPair)pair:(double)x count:(NSInteger)n{return (NMSWPair){x+1,n+2};}
- (void)dealloc{atomic_fetch_add(&released,1);}
@end
@interface NMSWChild : NMSWParent @end
@implementation NMSWChild @end
@interface NMSWReplacement : NSObject
- (NSInteger)replacementValue:(NSInteger)x;
- (NSInteger)badValue:(double)x;
+ (double)replacementClassValue:(double)x;
- (NMSWPair)replacementPair:(double)x count:(NSInteger)n;
@end
@implementation NMSWReplacement
- (NSInteger)replacementValue:(NSInteger)x{NSInteger(*original)(id,SEL,NSInteger)=(NSInteger(*)(id,SEL,NSInteger))instanceToken.originalImplementation;return original(self,@selector(value:),x)+10;}
- (NSInteger)badValue:(double)x{return (NSInteger)x;}
+ (double)replacementClassValue:(double)x{double(*original)(id,SEL,double)=(double(*)(id,SEL,double))classToken.originalImplementation;return original(self,@selector(classValue:),x)+2;}
- (NMSWPair)replacementPair:(double)x count:(NSInteger)n{return (NMSWPair){x+3,n+4};}
@end
static NSInteger foreignValue(id obj,SEL sel,NSInteger x){(void)obj;(void)sel;return x+90;}
static NMSwizzleToken *install(NMSwizzleManager *m,Class cls,SEL sel,BOOL meta,SEL replacement,NMSwizzleInheritance inheritance,NSError **error){return [m installClass:cls selector:sel classMethod:meta replacementClass:NMSWReplacement.class replacementSelector:replacement inheritance:inheritance dispatchIsCoordinated:YES error:error];}
int main(void){@autoreleasepool{
 NMSwizzleManager *manager=NMSwizzleManager.sharedManager;check(manager!=nil,"singleton gate initialized");NSError *error=nil;
 IMP baseline=method_getImplementation(class_getInstanceMethod(NMSWParent.class,@selector(value:)));
 check([manager installClass:NMSWParent.class selector:@selector(value:) classMethod:NO replacementClass:NMSWReplacement.class replacementSelector:@selector(replacementValue:) inheritance:0 dispatchIsCoordinated:NO error:&error]==nil&&error.code==3,"uncoordinated external dispatch is rejected");
 check(install(manager,NMSWParent.class,@selector(value:),NO,@selector(badValue:),0,&error)==nil&&error.code==7,"wrong argument ABI rejected");
 check(install(manager,NMSWChild.class,@selector(value:),NO,@selector(replacementValue:),0,&error)==nil&&error.code==8,"inherited method rejected by default without parent mutation");
 check(method_getImplementation(class_getInstanceMethod(NMSWParent.class,@selector(value:)))==baseline,"failed install leaves original IMP untouched");
 instanceToken=install(manager,NMSWParent.class,@selector(value:),NO,@selector(replacementValue:),0,&error);check(instanceToken&&!error&&instanceToken.originalImplementation==baseline,"first install saves exact original IMP");
 check(install(manager,NMSWParent.class,@selector(value:),NO,@selector(replacementValue:),0,&error)==nil&&error.code==5,"duplicate selector owner rejected");
 __weak NMSWParent *weak=nil;unsigned before=atomic_load(&released);
 @autoreleasepool{NMSWParent *object=[NMSWParent new];weak=object;check([manager performInvocation:^{check([object value:2]==13,"replacement calls original with correct argument/return");} error:&error],"coordinated dispatch succeeds");}
 check(weak==nil&&atomic_load(&released)==before+1,"Hook manager does not retain receiver objects");
 __block NSInteger reentrant=0;check([manager performInvocation:^{NSError *inner=nil;check(![manager restoreToken:instanceToken error:&inner],"reentrant restore refused");reentrant=inner.code;} error:&error]&&reentrant==12,"restore cannot deadlock waiting on its own active call");
 dispatch_semaphore_t entered=dispatch_semaphore_create(0),resume=dispatch_semaphore_create(0),done=dispatch_semaphore_create(0);
 dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^{[manager performInvocation:^{dispatch_semaphore_signal(entered);dispatch_semaphore_wait(resume,DISPATCH_TIME_FOREVER);} error:NULL];dispatch_semaphore_signal(done);});
 check(dispatch_semaphore_wait(entered,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"worker entered dispatch gate");
 check(![manager restoreToken:instanceToken error:&error]&&error.code==12,"concurrent active call refuses restore");
 check(install(manager,NMSWParent.class,@selector(pair:count:),NO,@selector(replacementPair:count:),0,&error)==nil&&error.code==4,"concurrent active call refuses install");
 dispatch_semaphore_signal(resume);check(dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC))==0,"worker exits scope");
 dispatch_apply(1000,dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^(size_t n){@autoreleasepool{[manager performInvocation:^{NMSWParent *obj=[NMSWParent new];check([obj value:(NSInteger)n]==(NSInteger)n+11,"parallel original chain stays intact");} error:NULL];}});
 Method active=class_getInstanceMethod(NMSWParent.class,@selector(value:));method_setImplementation(active,(IMP)foreignValue);
 check(![manager restoreToken:instanceToken error:&error]&&error.code==14&&method_getImplementation(active)==(IMP)foreignValue,"foreign IMP conflict is identified without overwriting it");
 method_setImplementation(active,instanceToken.replacementImplementation);check([manager restoreToken:instanceToken error:&error]&&!error&&instanceToken.state==NMSwizzleStateRestored,"restore after explicit conflict resolution");
 check(![manager restoreToken:instanceToken error:&error]&&error.code==13,"stale restore rejected");instanceToken=nil;
 instanceToken=install(manager,NMSWChild.class,@selector(value:),NO,@selector(replacementValue:),NMSwizzleInheritanceLocalSnapshot,&error);check(instanceToken.createdLocalMethod,"explicit inherited local override created");
 [manager performInvocation:^{check([[NMSWParent new] value:1]==2&&[[NMSWChild new] value:1]==12,"inherited override never pollutes parent");} error:NULL];
 method_setImplementation(class_getInstanceMethod(NMSWParent.class,@selector(value:)),(IMP)foreignValue);check(![manager restoreToken:instanceToken error:&error]&&error.code==14,"changed parent prevents stale inherited snapshot restore");method_setImplementation(class_getInstanceMethod(NMSWParent.class,@selector(value:)),baseline);
 check([manager restoreToken:instanceToken error:&error],"restore explicit local snapshot");check(class_getInstanceMethod(NMSWChild.class,@selector(value:))!=class_getInstanceMethod(NMSWParent.class,@selector(value:)),"documented local slot remains after snapshot restore");instanceToken=nil;
 classToken=install(manager,NMSWChild.class,@selector(classValue:),YES,@selector(replacementClassValue:),NMSwizzleInheritanceLocalSnapshot,&error);check(classToken!=nil,"class method uses metaclass");
 [manager performInvocation:^{check([NMSWParent classValue:1]==1.5&&[NMSWChild classValue:1]==3.5,"class-method double ABI and inheritance isolation");} error:NULL];check([manager restoreToken:classToken error:&error],"class method restored");classToken=nil;
 NMSwizzleToken *pair=install(manager,NMSWParent.class,@selector(pair:count:),NO,@selector(replacementPair:count:),0,&error);check(pair!=nil,"multiargument aggregate signature accepted");
 [manager performInvocation:^{NMSWPair result=[[NMSWParent new] pair:2.5 count:7];check(result.value==5.5&&result.count==11,"real ObjC aggregate return ABI");} error:NULL];check([manager restoreToken:pair error:&error],"aggregate method restored");
 check(![manager performInvocation:^{[NSException raise:@"Fixture" format:@"dispatch failure"];} error:&error]&&error.code==15,"exception reports failure and releases dispatch scope");
 NMSwizzleToken *again=install(manager,NMSWParent.class,@selector(pair:count:),NO,@selector(replacementPair:count:),0,&error);check(again&&[manager restoreToken:again error:&error],"gate remains usable after exception");
 check(manager.diagnostics.count>0&&manager.diagnostics.count<=128,"diagnostics are bounded and observable");
 puts("PASS: actual ObjC instance/class/aggregate ABI, original IMP, duplicate/type/foreign conflicts, inheritance policy, concurrent/reentrant refusal, restore and object release");
 }return 0;}
