#import "NMSwizzleManager.h"
#import <pthread.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#include <string.h>
static NSError *NMSWError(NSInteger code,NSString *message){return [NSError errorWithDomain:@"newmymenu.swizzle" code:code userInfo:@{NSLocalizedDescriptionKey:message}];}
static BOOL NMSWLocalMethod(Class cls,SEL selector){unsigned count=0;Method *methods=class_copyMethodList(cls,&count);BOOL local=NO;for(unsigned i=0;i<count;i++)if(method_getName(methods[i])==selector){local=YES;break;}free(methods);return local;}
static BOOL NMSWEqualTypes(Method a,Method b){
    const char *at=method_getTypeEncoding(a),*bt=method_getTypeEncoding(b);if(!at||!bt||strnlen(at,4096)==4096||strnlen(bt,4096)==4096)return NO;
    @try{NSMethodSignature *as=[NSMethodSignature signatureWithObjCTypes:at],*bs=[NSMethodSignature signatureWithObjCTypes:bt];if(!as||!bs||as.numberOfArguments<2||as.numberOfArguments!=bs.numberOfArguments||strcmp(as.methodReturnType,bs.methodReturnType))return NO;for(NSUInteger i=0;i<as.numberOfArguments;i++)if(strcmp([as getArgumentTypeAtIndex:i],[bs getArgumentTypeAtIndex:i]))return NO;return YES;}@catch(__unused NSException *e){return NO;}
}
static void *NMSWPinAddress(const void *address){
    Dl_info info={0};if(!address||!dladdr(address,&info)||!info.dli_fname)return NULL;
    if(info.dli_fbase==(const void *)_dyld_get_image_header(0))return dlopen(NULL,RTLD_NOW);
    return dlopen(info.dli_fname,RTLD_NOW|RTLD_NOLOAD);
}
@interface NMSwizzleToken () {
    void *_images[4];
}
- (BOOL)pinTarget:(Class)target replacement:(Class)replacement;
@property(nonatomic,assign) Class runtimeClass;
@property(nonatomic,assign) Class inheritedOwner;
@property(nonatomic,assign) SEL selector;
@property(nonatomic,assign) IMP originalImplementation;
@property(nonatomic,assign) IMP replacementImplementation;
@property(nonatomic,assign) BOOL createdLocalMethod;
@property(atomic,assign) NMSwizzleState state;
@property(nonatomic,copy) NSString *key;
- (instancetype)initPrivate;
@end
@implementation NMSwizzleToken
- (instancetype)initPrivate{return [super init];}
- (BOOL)pinTarget:(Class)target replacement:(Class)replacement {
    _images[0]=NMSWPinAddress((__bridge const void *)target);_images[1]=NMSWPinAddress((__bridge const void *)replacement);
    _images[2]=NMSWPinAddress((const void *)self.originalImplementation);_images[3]=NMSWPinAddress((const void *)self.replacementImplementation);
    return _images[0]&&_images[1]&&_images[2]&&_images[3];
}
- (void)dealloc {for(unsigned i=0;i<4;i++)if(_images[i])dlclose(_images[i]);}
@end
@interface NMSwizzleManager () {
    pthread_rwlock_t _gate;
    NSMutableDictionary<NSString *,NMSwizzleToken *> *_tokens;
    NSMutableArray<NSDictionary *> *_events;
}
- (instancetype)initPrivate;
@end
@implementation NMSwizzleManager
+ (instancetype)sharedManager {static NMSwizzleManager *manager;static dispatch_once_t once;dispatch_once(&once,^{manager=[[self alloc] initPrivate];});return manager;}
- (instancetype)initPrivate{self=[super init];if(self){if(pthread_rwlock_init(&_gate,NULL)!=0)return nil;_tokens=[NSMutableDictionary dictionary];_events=[NSMutableArray array];}return self;}
- (void)event:(NSString *)name key:(NSString *)key{if(_events.count>=128)[_events removeObjectAtIndex:0];[_events addObject:@{@"event":name,@"target":key}];}
- (NSArray *)diagnostics {if(pthread_rwlock_rdlock(&_gate)!=0)return @[@{@"event":@"diagnostics-unavailable",@"target":@""}];NSArray *copy=[_events copy];pthread_rwlock_unlock(&_gate);return copy;}
- (BOOL)performInvocation:(void (NS_NOESCAPE ^)(void))operation error:(NSError **)error {
    if(!operation){if(error)*error=NMSWError(1,@"Invocation scope is required");return NO;}
    int status=pthread_rwlock_rdlock(&_gate);if(status){if(error)*error=NMSWError(2,@"Cannot acquire dispatch scope");return NO;}
    NSError *failure=nil;@try{operation();}@catch(NSException *exception){failure=NMSWError(15,[NSString stringWithFormat:@"Invocation exception %@: %@",exception.name,exception.reason?:@""]);}@finally{pthread_rwlock_unlock(&_gate);}if(error)*error=failure;return failure==nil;
}
- (NMSwizzleToken *)installClass:(Class)target selector:(SEL)selector classMethod:(BOOL)classMethod replacementClass:(Class)replacementClass replacementSelector:(SEL)replacementSelector inheritance:(NMSwizzleInheritance)inheritance dispatchIsCoordinated:(BOOL)coordinated error:(NSError **)error {
    if(!target||!object_isClass(target)||class_isMetaClass(target)||!selector||!replacementClass||!object_isClass(replacementClass)||class_isMetaClass(replacementClass)||!replacementSelector||!coordinated||(inheritance!=NMSwizzleInheritanceReject&&inheritance!=NMSwizzleInheritanceLocalSnapshot)){if(error)*error=NMSWError(3,@"Valid methods and an explicit coordinated dispatch/writer contract are required");return nil;}
    if(pthread_rwlock_trywrlock(&_gate)!=0){if(error)*error=NMSWError(4,@"Active dispatch/mutation scope; installation refused");return nil;}
    NMSwizzleToken *token=nil;__attribute__((objc_precise_lifetime)) NMSwizzleToken *candidate=nil;NSError *failure=nil;
    @try{
        Class cls=classMethod?object_getClass(target):target,source=classMethod?object_getClass(replacementClass):replacementClass;
        NSString *key=[NSString stringWithFormat:@"%p/%s",(void *)cls,sel_getName(selector)];
        Method method=class_getInstanceMethod(cls,selector),replacement=class_getInstanceMethod(source,replacementSelector);
        BOOL local=method&&NMSWLocalMethod(cls,selector);
        if(_tokens[key])failure=NMSWError(5,@"Target selector already has an active owner");
        else if(_tokens.count>=128)failure=NMSWError(6,@"Active Hook limit reached");
        else if(!method||!replacement||!NMSWEqualTypes(method,replacement))failure=NMSWError(7,@"Missing method or incompatible Objective-C type signature");
        else if(!local&&inheritance==NMSwizzleInheritanceReject)failure=NMSWError(8,@"Inherited Method requires explicit local snapshot policy; its local slot cannot later be deleted");
        else {
            IMP original=method_getImplementation(method),next=method_getImplementation(replacement);
            if(!original||!next||original==next||imp_getBlock(original)||imp_getBlock(next))failure=NMSWError(9,@"Null, identical or externally owned block IMP is unsupported");
            else {
                candidate=[[NMSwizzleToken alloc] initPrivate];token=candidate;token.runtimeClass=cls;token.selector=selector;token.originalImplementation=original;token.replacementImplementation=next;token.key=key;token.createdLocalMethod=!local;
                if(![token pinTarget:target replacement:replacementClass]){failure=NMSWError(16,@"Cannot own target/replacement code images; dynamic/unmapped IMPs are unsupported");token=nil;}
                else if(!local){Class owner=class_getSuperclass(cls);while(owner&&!NMSWLocalMethod(owner,selector))owner=class_getSuperclass(owner);token.inheritedOwner=owner;
                    if(!class_addMethod(cls,selector,next,method_getTypeEncoding(method))){failure=NMSWError(10,@"Inherited local method installation conflicted");token=nil;}
                } else {method_setImplementation(method,next);}
                if(token){token.state=NMSwizzleStateActive;_tokens[key]=token;[self event:@"installed" key:key];}
            }
        }
        if(failure)[self event:@"install-refused" key:key];
    }@finally{pthread_rwlock_unlock(&_gate);}
    if(error)*error=failure;return token;
}
- (BOOL)restoreToken:(NMSwizzleToken *)token error:(NSError **)error {
    if(![token isKindOfClass:NMSwizzleToken.class]){if(error)*error=NMSWError(11,@"Restore token is invalid");return NO;}
    __attribute__((objc_precise_lifetime)) NMSwizzleToken *lifetime=token;(void)lifetime;
    if(pthread_rwlock_trywrlock(&_gate)!=0){if(error)*error=NMSWError(12,@"Active dispatch/mutation scope; restoration refused");return NO;}
    NSError *failure=nil;
    @try{
        if(token.state!=NMSwizzleStateActive||_tokens[token.key]!=token)failure=NMSWError(13,@"Token is stale or already restored");
        else {
            Method method=class_getInstanceMethod(token.runtimeClass,token.selector);
            Method parent=token.inheritedOwner?class_getInstanceMethod(token.inheritedOwner,token.selector):NULL;
            if(!method||method_getImplementation(method)!=token.replacementImplementation||(token.createdLocalMethod&&(!parent||method_getImplementation(parent)!=token.originalImplementation)))failure=NMSWError(14,@"Foreign or parent IMP changed; refusing to overwrite its chain");
            else {method_setImplementation(method,token.originalImplementation);token.state=NMSwizzleStateRestored;[_tokens removeObjectForKey:token.key];[self event:@"restored" key:token.key];}
        }
        if(failure)[self event:@"restore-refused" key:token.key?:@""];
    }@finally{pthread_rwlock_unlock(&_gate);}
    if(error)*error=failure;return failure==nil;
}
@end
