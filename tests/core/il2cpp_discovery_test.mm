#import <Foundation/Foundation.h>
#import "NMIL2CPPDiscovery+Internal.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL discovery: %s\n",message);abort();}}
struct NMFixtureType {const char *name;};struct NMFixtureMethod {const char *name;NMFixtureType *ret;NMFixtureType *params[2];uint32_t count,flags;};struct NMFixtureClass {const char *name,*ns;NMFixtureType *type;NMFixtureMethod *method;};
static NMFixtureType clsType={"Game.CheatController"},playerType={"Game.Player"},intType={"System.Int32"},refType={"System.Int32&"},voidType={"System.Void"};
static NMFixtureMethod methods[]={ {"GetValue",&intType,{nullptr,nullptr},0,0x10},{"SetValue",&voidType,{&refType,nullptr},1,0} };
static NMFixtureClass classes[]={{"CheatController","Game",&clsType,methods},{"Player","Game",&playerType,methods},{"CheatController","Game",&clsType,methods}};
static unsigned attached,detached,allocated,freed;static bool currentThread,notReady,changed,throwMetadata,ambiguous,attachFailure,changeDuringScan;
static void *domainGet(){if(notReady)return nullptr;return (void *)(uintptr_t)(changed?0x2000:0x1000);}
static const void **assemblies(const void *domain,size_t *count){(void)domain;static const void *values[]={(void *)0x3000};*count=1;return values;}
static const void *image(const void *assembly){(void)assembly;return (void *)0x4000;}
static const char *imageName(const void *p){(void)p;return "Assembly-CSharp.dll";}
static size_t classCount(const void *p){(void)p;return ambiguous?3:2;}
static void *getClass(const void *p,size_t i){(void)p;return &classes[i];}
static const char *className(void *c){if(throwMetadata)[NSException raise:@"Fixture" format:@"metadata"];if(changeDuringScan)changed=true;return ((NMFixtureClass *)c)->name;}
static const char *classNS(void *c){return ((NMFixtureClass *)c)->ns;}
static const void *classType(void *c){return ((NMFixtureClass *)c)->type;}
static const void *classMethods(void *c,void **iter){(void)c;uintptr_t i=(uintptr_t)*iter;if(i==2)return nullptr;*iter=(void *)(i+1);return &methods[i];}
static const char *methodName(const void *m){return ((NMFixtureMethod *)m)->name;}
static uint32_t paramCount(const void *m){return ((NMFixtureMethod *)m)->count;}
static const void *param(const void *m,uint32_t i){return ((NMFixtureMethod *)m)->params[i];}
static const void *returnType(const void *m){return ((NMFixtureMethod *)m)->ret;}
static uint32_t flags(const void *m,uint32_t *impl){*impl=0;return ((NMFixtureMethod *)m)->flags;}
static char *typeName(const void *t){allocated++;return strdup(((NMFixtureType *)t)->name);}
static void freeMemory(void *p){freed++;free(p);}
static void *threadCurrent(){return currentThread?(void *)0x5000:nullptr;}
static void *threadAttach(void *d){(void)d;if(attachFailure)return nullptr;attached++;return (void *)0x5000;}
static void threadDetach(void *t){check(t==(void *)0x5000,"detach exact owned thread");detached++;}
static NMIL2CPPAPI api(){return {domainGet,assemblies,image,imageName,classCount,getClass,className,classNS,classType,classMethods,methodName,paramCount,param,returnType,flags,typeName,freeMemory,threadCurrent,threadAttach,threadDetach};}
int main(){@autoreleasepool{
 NMIL2CPPDiscovery *service=[[NMIL2CPPDiscovery alloc] initWithAPI:api() report:@{@"runtimeIdentifier":@"fixture"} ownedHandle:nullptr];check(service!=nil,"complete API accepted");
 NSError *error=nil;NSDictionary *found=[service searchClasses:@"cheat" limit:10 error:&error];check(!error&&[found[@"count"] intValue]==1,"case-insensitive class search");check(attached==1&&detached==1&&allocated==freed,"thread scope and typename free");
 NSDictionary *descriptor=[found[@"results"] firstObject];NSDictionary *listed=[service methodsForClass:descriptor limit:10 error:&error];NSArray *rows=listed[@"results"];
 check(!error&&rows.count==2&&[rows[0][@"static"] boolValue]&&[rows[1][@"parameterTypes"][0] isEqual:@"System.Int32&"],"method signatures and flags copied");
 NSDictionary *global=[service searchMethods:@"vALuE" limit:10 error:&error];NSArray *globalRows=global[@"results"];
 check(!error&&globalRows.count==4&&[global[@"methodsScanned"] intValue]==4,@"global method substring search scans both classes".UTF8String);
 check([globalRows[0][@"classIdentity"][@"fullType"] isEqual:@"Game.CheatController"],"global result preserves copied owner identity");
 NSDictionary *methodLimit=[service searchMethods:@"Value" limit:1 error:&error];check([methodLimit[@"count"] intValue]==1&&[methodLimit[@"truncated"] boolValue],"method search result limit is explicit");
 NSDictionary *noMethod=[service searchMethods:@"absent" limit:10 error:&error];check(!error&&[noMethod[@"count"] intValue]==0,"method no-match is empty snapshot");
 NSDictionary *qualified=[service searchMethodExpression:@"assembly-csharp!Game.CheatController::setvalue/1" limit:10 error:&error];check(!error&&[qualified[@"count"] intValue]==1,"qualified assembly/namespace/class/method/arity filter");
 NSDictionary *wrongArity=[service searchMethodExpression:@"Game.CheatController::SetValue/0" limit:10 error:&error];check(!error&&[wrongArity[@"count"] intValue]==0,"arity does not select a different overload");
 NSDictionary *wrongOwner=[service searchMethodExpression:@"Other.CheatController::SetValue/1" limit:10 error:&error];check(!error&&[wrongOwner[@"count"] intValue]==0,"namespace qualifier is enforced");
 unsigned preDelta=attached;check([service searchMethodExpression:@"SetValue+4" limit:10 error:&error]==nil&&error.code==20&&attached==preDelta,"nonzero delta rejected before VM calls");
 currentThread=true;unsigned before=attached;[service searchClasses:@"Player" limit:10 error:&error];check(attached==before&&detached==before,"existing VM thread is not detached");currentThread=false;
 throwMetadata=true;check([service searchClasses:@"cheat" limit:10 error:&error]==nil&&error,"exception becomes error");check(attached==detached,"exception still detaches owned thread");throwMetadata=false;
 attachFailure=true;before=detached;check([service searchClasses:@"cheat" limit:10 error:&error]==nil&&error&&detached==before,"failed attach is not detached");attachFailure=false;
 notReady=true;check([service searchClasses:@"cheat" limit:10 error:&error]==nil&&error,"not ready rejected");notReady=false;
 NSDictionary *limited=[service searchClasses:@"Game" limit:1 error:&error];check([limited[@"count"] intValue]==1&&[limited[@"truncated"] boolValue],"bounds are visible");
 NSMutableDictionary *wrong=[descriptor mutableCopy];wrong[@"runtimeIdentifier"]=@"other";before=attached;check([service methodsForClass:wrong limit:10 error:&error]==nil&&error&&before==attached,"stale binding rejected before VM entry");
 NMIL2CPPAPI missing=api();missing.freeMemory=nullptr;check([[NMIL2CPPDiscovery alloc] initWithAPI:missing report:@{@"runtimeIdentifier":@"x"} ownedHandle:nullptr]==nil,"allocator pair required");
 ambiguous=true;check([service methodsForClass:descriptor limit:10 error:&error]==nil&&error.code==16,"ambiguous class is not first-match selected");ambiguous=false;
 changeDuringScan=true;check([service searchClasses:@"cheat" limit:10 error:&error]==nil&&error.code==7,"domain replacement rejected");changeDuringScan=false;changed=false;
 check(attached==detached,"all owned threads detached");
 check(allocated==freed,"all allocated type names freed");puts("PASS: controlled native metadata API search/signatures, thread ownership/finally, allocator pairing, bounds and stale descriptors");
 }return 0;}
