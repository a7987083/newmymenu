static ZNRuntimeMethodAction *NMAuditAction(NSUInteger arity,BOOL byRef,NSUInteger instance){
 gAuditArity=arity;gAuditByRef=byRef;gAuditLastReceiver=0;gAuditEnumerations=0;gAuditBaseCalls=0;
 ZNRuntimeMethodAction *a=[ZNRuntimeMethodAction new];a.executionKind=ZNRuntimeExecutionKindMethodCall;
 a.assembly=@"Fixture.dll";a.namespaceName=@"";a.className=@"Fixture";a.methodName=@"Call";
 a.argumentCount=arity;a.instanceIndex=instance;a.signatureAvailable=byRef;
 NSMutableArray *values=[NSMutableArray array],*types=[NSMutableArray array];
 for(NSUInteger i=0;i<arity;i++){[values addObject:@"7"];[types addObject:byRef?@"System.Int32&":@"System.Int32"];}
 a.argumentValues=values;a.parameterTypeNames=types;return a;
}
static void NMAuditIndexed(ZNIL2CPPInvokeEngine *engine,NSUInteger arity,BOOL byRef){
 ZNRuntimeMethodAction *a=NMAuditAction(arity,byRef,2);NSString *error=nil;
 NSDictionary *result=[engine executeAction:a error:&error];NMRequire(result!=nil,"indexed fixture call executes");
 BOOL bypass=arity>=2||byRef;
 NMRequire(gAuditLastReceiver==(bypass?kA:kB),"fixed source reproduces receiver routing");
 NMRequire(gAuditEnumerations==(bypass?0u:1u),"ordinal enumeration is bypassed only on M47 path");
 NMRequire(gAuditBaseCalls==(bypass?0u:1u),"M47 returns without invoking base entry");
 if(byRef){NSArray *refs=result[@"byRefResults"];NMRequire([refs.firstObject[@"value"] intValue]==99,"actual M47 passes writable ref Int32 slot");}
 printf("REPRO indexed arity=%lu byRef=%d requested=B actual=%s baseCalls=%lu enumCalls=%lu\n",(unsigned long)arity,byRef,bypass?"A":"B",(unsigned long)gAuditBaseCalls,(unsigned long)gAuditEnumerations);
}
static void NMAuditExplicit(ZNIL2CPPInvokeEngine *engine,NSUInteger arity,BOOL byRef){
 ZNRuntimeMethodAction *a=NMAuditAction(arity,byRef,0);NSString *error=nil;
 NMRequire([engine executeAction:a receiver:kB error:&error]!=nil,"explicit fixture call executes");
 BOOL bypass=arity>=2||byRef;NMRequire(gAuditLastReceiver==(bypass?kA:kB),"explicit receiver bypass reproduced");
 NMRequire(gZNExplicitReceiverOverride==0,"TLS overload restores context even when ignored");
 printf("REPRO explicit arity=%lu byRef=%d requested=B actual=%s\n",(unsigned long)arity,byRef,bypass?"A":"B");
}
int main(){@autoreleasepool{
 ZNIL2CPPInvokeEngine *engine=[ZNIL2CPPInvokeEngine new];
 Method original=class_getInstanceMethod(ZNIL2CPPInvokeEngine.class,@selector(executeAction:error:));
 Method replacement=class_getInstanceMethod(ZNIL2CPPInvokeEngine.class,@selector(znm47_executeAction:error:));
 NMRequire(strcmp(method_getTypeEncoding(original),method_getTypeEncoding(replacement))==0,"real ObjC entry ABI matches");
 IMP baseline=method_getImplementation(original);
 ZNInstallM47MultiArgInvokeDeferred();IMP installed=method_getImplementation(original);
 NMRequire(baseline!=installed,"exact M47 installer actually exchanges IMP");
 ZNInstallM47MultiArgInvokeDeferred();NMRequire(method_getImplementation(original)==installed,"dispatch_once avoids second exchange");
 for(NSUInteger arity: {0u,1u,2u,8u}){NMAuditIndexed(engine,arity,NO);NMAuditExplicit(engine,arity,NO);}
 NMAuditIndexed(engine,1,YES);NMAuditExplicit(engine,1,YES);
 ZNRuntimeMethodAction *invalid=NMAuditAction(0,NO,129);NSString *error=nil;
 NMRequire([engine executeAction:invalid error:&error]==nil && [error hasPrefix:@"FAILED_INSTANCE_INDEX"],"base rejects out-of-range ordinal");
 invalid=NMAuditAction(2,NO,129);error=nil;
 NMRequire([engine executeAction:invalid error:&error]!=nil && gAuditLastReceiver==kA,"M47 bypasses out-of-range ordinal validation");
 puts("PASS: fixed-source receiver contract defect reproduced with real Objective-C exchange; controlled IL2CPP boundary only");
 puts("NOT VERIFIED: actual game runtime, UIKit, complete outer M46/M48/M50/M52 behavior, device, production fix");
 }return 0;}
