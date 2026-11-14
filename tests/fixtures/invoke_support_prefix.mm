// Controlled IL2CPP boundary; numeric tokens are never dereferenced as objects.
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <stdint.h>
#include <initializer_list>
#include <stdio.h>
#include <string.h>
static uintptr_t const kA=0xA000, kB=0xB000;
static NSUInteger gAuditArity;
static BOOL gAuditByRef;
static uintptr_t gAuditLastReceiver;
static NSUInteger gAuditEnumerations;
static NSUInteger gAuditBaseCalls;
static void NMRequire(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL %s\n",message);abort();}}

@interface ZNRuntimeLogger : NSObject
+ (instancetype)sharedLogger;
- (void)log:(NSString *)text;
@end
@implementation ZNRuntimeLogger
+ (instancetype)sharedLogger {static id logger;static dispatch_once_t once;dispatch_once(&once,^{logger=[self new];});return logger;}
- (void)log:(NSString *)text {(void)text;}
@end

@implementation ZNRuntimeMethodAction
- (NSString *)canonicalIdentity {return @"Fixture::Call";}
- (NSString *)legacyCanonicalIdentity {return @"Fixture::Call";}
- (id)copyWithZone:(NSZone *)zone {
 ZNRuntimeMethodAction *a=[[[self class] allocWithZone:zone] init];
 a.argumentCount=self.argumentCount;a.argumentValues=self.argumentValues;a.parameterTypeNames=self.parameterTypeNames;
 a.signatureAvailable=self.signatureAvailable;a.instanceIndex=self.instanceIndex;a.executionKind=self.executionKind;
 a.assembly=self.assembly;a.namespaceName=self.namespaceName;a.className=self.className;a.methodName=self.methodName;return a;
}
@end

@interface ZNIL2CPPResolver : NSObject
+ (instancetype)sharedResolver;
@property(nonatomic,readonly,getter=isAvailable) BOOL available;
@property(nonatomic,readonly) NSString *unityPath;
@property(nonatomic,readonly) NSString *lastError;
- (void)refresh;
- (NSDictionary *)resolveMethodAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m argumentCount:(NSInteger)count;
@end
@implementation ZNIL2CPPResolver
+ (instancetype)sharedResolver {static id resolver;static dispatch_once_t once;dispatch_once(&once,^{resolver=[self new];});return resolver;}
- (BOOL)isAvailable{return YES;}
- (NSString *)unityPath{return @"";}
- (NSString *)lastError{return @"";}
- (void)refresh{}
- (NSDictionary *)resolveMethodAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m argumentCount:(NSInteger)count {
 (void)a;(void)n;(void)c;(void)m;(void)count;return @{@"methodInfo":@0x1111};
}
@end
@interface ZNIL2CPPFullSignatureResolver : NSObject
+ (instancetype)sharedResolver;
- (NSDictionary *)resolveAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m parameterTypeNames:(NSArray *)types error:(NSString **)error;
@end
@implementation ZNIL2CPPFullSignatureResolver
+ (instancetype)sharedResolver {static id resolver;static dispatch_once_t once;dispatch_once(&once,^{resolver=[self new];});return resolver;}
- (NSDictionary *)resolveAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m parameterTypeNames:(NSArray *)types error:(NSString **)error {
 (void)a;(void)n;(void)c;(void)m;(void)types;(void)error;return @{@"methodInfo":@0x1111};
}
@end
@interface ZNIL2CPPInstanceResolver : NSObject
+ (instancetype)sharedResolver;
- (uintptr_t)znm44_selectedInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c;
- (BOOL)znm44_validateInstanceAddress:(uintptr_t)p assembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c error:(NSString **)error;
- (void)znm44_clearSelectedInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c;
- (void *)resolveUniqueInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c diagnostics:(NSString **)d error:(NSString **)error;
- (NSArray *)candidateAddressesForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c limit:(NSUInteger)limit diagnostics:(NSString **)d error:(NSString **)error;
@end
@implementation ZNIL2CPPInstanceResolver
+ (instancetype)sharedResolver {static id resolver;static dispatch_once_t once;dispatch_once(&once,^{resolver=[self new];});return resolver;}
- (uintptr_t)znm44_selectedInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c{(void)a;(void)n;(void)c;return kA;}
- (BOOL)znm44_validateInstanceAddress:(uintptr_t)p assembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c error:(NSString **)error{(void)a;(void)n;(void)c;(void)error;return p==kA||p==kB;}
- (void)znm44_clearSelectedInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c{(void)a;(void)n;(void)c;}
- (void *)resolveUniqueInstanceForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c diagnostics:(NSString **)d error:(NSString **)error{(void)a;(void)n;(void)c;(void)d;(void)error;return (void *)kA;}
- (NSArray *)candidateAddressesForAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c limit:(NSUInteger)limit diagnostics:(NSString **)d error:(NSString **)error {
 (void)a;(void)n;(void)c;(void)limit;(void)d;(void)error;gAuditEnumerations++;return @[@(kA),@(kB)];
}
@end

NSDictionary<NSString *,id> *ZNIL2CPPDescribeMethodABI(NSDictionary<NSString *,id> *candidate){
 (void)candidate;NSMutableArray *params=[NSMutableArray array];
 for(NSUInteger i=0;i<gAuditArity;i++)[params addObject:@{@"name":gAuditByRef?@"System.Int32&":@"System.Int32",@"kind":@(ZNIL2CPPABIValueKindSigned32),@"byRef":@(gAuditByRef)}];
 return @{@"available":@YES,@"parameters":params,@"genericStatusKnown":@YES,@"generic":@NO};
}
@implementation ZNRuntimeArgumentMarshaller
+ (void)registerValueType:(NSString *)type encoder:(ZNRuntimeValueTypeEncoder)encoder{(void)type;(void)encoder;}
+ (NSMutableData *)encodeValueTypeParameterForMethod:(uintptr_t)m index:(NSUInteger)i type:(NSString *)t input:(NSString *)s imagePath:(NSString *)p error:(NSString **)e{
 (void)m;(void)i;(void)t;(void)s;(void)p;(void)e;NMRequire(NO,"unexpected struct marshaller in primitive fixture");return nil;
}
+ (NSMutableData *)zeroInitializedByRefValueTypeForMethod:(uintptr_t)m index:(NSUInteger)i imagePath:(NSString *)p error:(NSString **)e{
 (void)m;(void)i;(void)p;(void)e;NMRequire(NO,"unexpected out struct in fixture");return nil;
}
@end
// Export real C symbols for the unchanged M47 dlsym calls.
extern "C" void *il2cpp_runtime_invoke(const void *method,void *object,void **params,void **exception){
 (void)method;*exception=nullptr;gAuditLastReceiver=(uintptr_t)object;if(gAuditByRef)*((int32_t *)params[0])=99;return nullptr;
}
extern "C" uint32_t il2cpp_method_get_flags(const void *m,uint32_t *flags){(void)m;*flags=0;return 0;}
extern "C" const void *il2cpp_method_get_param(const void *m,uint32_t i){(void)m;(void)i;return (void *)0x2222;}
extern "C" void *il2cpp_class_from_type(const void *t){(void)t;return (void *)0x3333;}
extern "C" bool il2cpp_class_is_valuetype(void *c){(void)c;return true;}
extern "C" uint32_t il2cpp_type_get_attrs(const void *t){(void)t;return 0;}

@interface ZNIL2CPPInvokeEngine : NSObject
- (NSDictionary<NSString *,id> *)executeAction:(ZNRuntimeMethodAction *)action error:(NSString **)error;
- (NSDictionary<NSString *,id> *)executeAction:(ZNRuntimeMethodAction *)action receiver:(uintptr_t)receiver error:(NSString **)error;
@end
@interface ZNIL2CPPInvokeEngine (FixtureBoundary)
- (NSDictionary<NSString *,id> *)capabilities;
- (NSDictionary<NSString *,id> *)executeAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m argumentCount:(NSUInteger)count argumentValues:(NSArray *)values error:(NSString **)error;
@end
@implementation ZNIL2CPPInvokeEngine (FixtureBoundary)
- (NSDictionary<NSString *,id> *)capabilities {return @{@"resolver":@YES,@"runtimeInvoke":@YES,@"methodGetFlags":@YES,@"instanceResolver":@YES};}
- (NSDictionary<NSString *,id> *)executeAssembly:(NSString *)a namespace:(NSString *)n className:(NSString *)c method:(NSString *)m argumentCount:(NSUInteger)count argumentValues:(NSArray *)values error:(NSString **)error {
 (void)a;(void)n;(void)c;(void)m;(void)count;(void)values;(void)error;
 gAuditBaseCalls++;gAuditLastReceiver=gZNExplicitReceiverOverride?:kA;return @{@"instance":@(gAuditLastReceiver)};
}
@end
