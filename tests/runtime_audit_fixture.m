// Real Objective-C Runtime audit experiments, not the production menu.
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
static void require(BOOL ok, const char *message) { if (!ok) { fprintf(stderr,"FAIL: %s\n",message); abort(); } }
static _Atomic(unsigned) deallocations;
@interface NMAuditParent : NSObject
- (NSInteger)value:(NSInteger)x;
+ (NSInteger)classValue:(NSInteger)x;
@end
@implementation NMAuditParent
- (NSInteger)value:(NSInteger)x { return x+1; }
+ (NSInteger)classValue:(NSInteger)x { return x+2; }
@end
@interface NMAuditChild : NMAuditParent
- (NSInteger)replacement:(NSInteger)x;
@end
@implementation NMAuditChild
- (NSInteger)replacement:(NSInteger)x { return x+10; }
@end
@interface NMAuditLifetime : NSObject
@end
@implementation NMAuditLifetime
- (void)dealloc { atomic_fetch_add(&deallocations,1); }
@end
static NSInteger localReplacement(id object, SEL selector, NSInteger x) { (void)object;(void)selector;return x+20; }
static NSInteger classReplacement(id object, SEL selector, NSInteger x) { (void)object;(void)selector;return x+30; }
__attribute__((visibility("default"))) int NewMyMenuRuntimeAuditFixture(void) {
 @autoreleasepool {
    NMAuditParent *parent=[NMAuditParent new]; NMAuditChild *child=[NMAuditChild new];
    Method inherited=class_getInstanceMethod(NMAuditChild.class,@selector(value:));
    Method base=class_getInstanceMethod(NMAuditParent.class,@selector(value:));
    Method replacement=class_getInstanceMethod(NMAuditChild.class,@selector(replacement:));
    require(inherited==base,"inherited Method aliases parent Method");
    require(strcmp(method_getTypeEncoding(base),method_getTypeEncoding(replacement))==0,"fixture ABI agrees");
    IMP original=method_getImplementation(base);
    method_exchangeImplementations(inherited,replacement);
    require([parent value:1]==11,"unsafe inherited exchange changes parent behavior");
    method_exchangeImplementations(inherited,replacement);
    require([parent value:1]==2,"restore experiment baseline");
    require(class_addMethod(NMAuditChild.class,@selector(value:),(IMP)localReplacement,method_getTypeEncoding(base)),"localize inherited method");
    require([parent value:1]==2 && [child value:1]==21,"localized override leaves parent untouched");
    Method local=class_getInstanceMethod(NMAuditChild.class,@selector(value:));
    require(method_setImplementation(local,original)==(IMP)localReplacement,"save previous IMP");
    require([child value:1]==2,"restore original behavior (local override remains)");
    Class meta=object_getClass(NMAuditChild.class);
    Method classBase=class_getClassMethod(NMAuditChild.class,@selector(classValue:));
    require(class_addMethod(meta,@selector(classValue:),(IMP)classReplacement,method_getTypeEncoding(classBase)),"class methods target metaclass");
    require([NMAuditParent classValue:1]==3 && [NMAuditChild classValue:1]==31,"class inheritance isolation");
    Method met=class_getInstanceMethod(meta,@selector(classValue:));
    method_setImplementation(met,method_getImplementation(classBase));
    _Atomic(unsigned) *count=calloc(1,sizeof(*count)); require(count!=NULL,"allocate concurrent counter");
    dispatch_apply(1000,dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^(size_t i){
        @autoreleasepool { require([child value:(NSInteger)i]==(NSInteger)i+1,"concurrent stable dispatch"); atomic_fetch_add(count,1); }
    });
    require(atomic_load(count)==1000,"all concurrent stable calls ran");free(count);
    __weak NMAuditLifetime *weak=nil;
    @autoreleasepool { NMAuditLifetime *object=[NMAuditLifetime new]; weak=object; require(weak!=nil,"weak alive in scope"); }
    require(weak==nil && atomic_load(&deallocations)==1,"object lifetime fixture");
    // A block-backed IMP must stay alive while any runtime Method can call it.
    IMP block=imp_implementationWithBlock(^NSInteger(id obj,NSInteger x){(void)obj;return x+40;});
    method_setImplementation(local,block);
    require([child value:1]==41,"block IMP ABI and return");
    method_setImplementation(local,original);
    require(imp_removeBlock(block),"release block after controlled synchronous restore");
    puts("PASS: inheritance hazard, localized instance/class override, original IMP, stable concurrent calls, object lifetime, block IMP");
    puts("NOT TESTED: target menu, concurrent installation/restoration, arbitrary third-party hooks, IL2CPP, UIKit, device");
 }
 return 0;
}
#ifndef NM_AUDIT_DYLIB
int main(void) { return NewMyMenuRuntimeAuditFixture(); }
#endif
