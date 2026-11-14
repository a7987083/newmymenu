#import "NMInvocationCoordinator.h"
#import "NMRuntimeActionFormat.h"

static NSError *NMInvocationError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:@"newmymenu.invocation" code:code userInfo:@{NSLocalizedDescriptionKey:message}];
}
static NSArray<NSString *> *NMCopyStrings(NSArray *values) {
    if (![values isKindOfClass:NSArray.class]) return nil;
    NSMutableArray *result=[NSMutableArray arrayWithCapacity:values.count];
    for (id value in values) {
        if (![value isKindOfClass:NSString.class]) return nil;
        [result addObject:[value copy]];
    }
    return [result copy];
}
@interface NMInvocationRequest ()
- (instancetype)initPrivate;
@end
@implementation NMInvocationRequest
+ (instancetype)requestForMethod:(NSString *)identity parameterTypes:(NSArray<NSString *> *)types argumentValues:(NSArray<NSString *> *)values isStatic:(BOOL)isStatic selection:(NMReceiverSelection)selection instanceIndex:(NSUInteger)index explicitReceiver:(NMReceiverLease *)receiver error:(NSError **)error {
    NSArray *typeCopy=NMCopyStrings(types),*valueCopy=NMCopyStrings(values);
    BOOL valid=[identity isKindOfClass:NSString.class] && identity.length && typeCopy && valueCopy && typeCopy.count==valueCopy.count && typeCopy.count<=NM_RUNTIME_ACTION_MAX_ARGUMENTS;
    for (NSString *type in typeCopy) if (!type.length) valid=NO;
    if (isStatic) valid=valid && selection==NMReceiverSelectionNone && index==0 && receiver==nil;
    else switch (selection) {
        case NMReceiverSelectionAutomatic: valid=valid && index==0 && receiver==nil; break;
        case NMReceiverSelectionOrdinal: valid=valid && index>=1 && index<=NM_RUNTIME_INSTANCE_MAX_INDEX && receiver==nil; break;
        case NMReceiverSelectionExplicit: valid=valid && index==0 && [receiver isKindOfClass:NMReceiverLease.class]; break;
        default: valid=NO; break;
    }
    if (!valid) { if (error) *error=NMInvocationError(1,@"Invalid method signature, arguments, or receiver selection"); return nil; }
    NMInvocationRequest *request=[[self alloc] initPrivate];
    request->_identifier=[NSUUID UUID]; request->_methodIdentity=[identity copy];
    request->_parameterTypes=typeCopy; request->_argumentValues=valueCopy; request->_staticMethod=isStatic;
    request->_receiverSelection=selection; request->_instanceIndex=index; request->_explicitReceiver=receiver;
    if (error) *error=nil;
    return request;
}
- (instancetype)initPrivate { return [super init]; }
- (id)copyWithZone:(NSZone *)zone { (void)zone; return self; }
@end

@interface NMInvocationCoordinator () {
    @private
    NMReceiverProvider _provider;
    NMInvocationBackend _backend;
}
@end
@implementation NMInvocationCoordinator
- (instancetype)initWithReceiverProvider:(NMReceiverProvider)provider backend:(NMInvocationBackend)backend {
    if (!provider || !backend) return nil;
    self=[super init]; if (self) { _provider=[provider copy]; _backend=[backend copy]; } return self;
}
- (NSDictionary *)executeRequest:(NMInvocationRequest *)request error:(NSError **)error {
    if (![request isKindOfClass:NMInvocationRequest.class]) { if (error) *error=NMInvocationError(2,@"Invocation request is missing"); return nil; }
    NSError *failure=nil; NSDictionary *result=nil;
    @try {
        if (request.isStatic) {
            result=_backend(request,0,&failure);
        } else {
            NMReceiverLease *lease=request.receiverSelection==NMReceiverSelectionExplicit?request.explicitReceiver:_provider(request,&failure);
            if (failure) { if (error) *error=failure; return nil; }
            if (![lease isKindOfClass:NMReceiverLease.class]) { if (error) *error=NMInvocationError(3,@"Receiver provider returned no owned lease"); return nil; }
            result=[lease performOperation:^NSDictionary *(uintptr_t receiver, NSError **innerError) {
                return self->_backend(request,receiver,innerError);
            } error:&failure];
        }
        if (!failure && ![result isKindOfClass:NSDictionary.class]) failure=NMInvocationError(4,@"Invocation backend returned no valid result");
    } @catch (NSException *exception) {
        failure=NMInvocationError(5,[NSString stringWithFormat:@"Invocation exception %@: %@",exception.name,exception.reason?:@""]);
    }
    if (error) *error=failure;
    return failure?nil:result;
}
@end
