#import <Foundation/Foundation.h>
#import "NMConfiguration.h"
#import <dispatch/dispatch.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL configuration: %s\n",message);abort();}}
static NSData *encode(id root){return [NSJSONSerialization dataWithJSONObject:root options:NSJSONWritingSortedKeys error:nil];}
static NSMutableDictionary *method(NSString *title,NSString *value){return [@{@"title":title,@"description":@"fixture",@"group":@"Runtime Methods",@"executionKind":@1,@"assembly":@"Assembly-CSharp.dll",@"namespace":@"Game",@"class":@"Player",@"method":@"SetValue",@"argumentCount":@1,@"parameterTypeNames":@[@"System.Int32&"],@"signatureAvailable":@YES,@"argumentValues":@[value],@"argumentControlConfigs":@[@{@"enabled":@YES,@"type":@"number",@"valueType":@"I32",@"min":@0,@"max":@100,@"default":@1,@"step":@1}],@"immediateChain":@{}} mutableCopy];}
static NSMutableDictionary *hook(NSNumber *identifier,NSNumber *kind){return [@{@"actionID":identifier,@"title":@"Native",@"assembly":@"Assembly-CSharp.dll",@"namespace":@"Game",@"class":@"Player",@"method":@"SetValue",@"argumentCount":@1,@"parameterTypeNames":@[@"System.Int32"],@"signatureAvailable":@YES,@"templateKind":kind,@"argumentIndex":@0,@"min":@1,@"max":@100,@"default":@1} mutableCopy];}
static NSDictionary *root(NSArray *methods,NSArray *hooks){return @{@"format":@"zonoe-authoring",@"schemaVersion":@1,@"runtimeMethods":methods,@"nativeHooks":hooks};}
static NMConfigurationDocument *doc(NSArray *methods,NSArray *hooks){NSError *error=nil;NMConfigurationDocument *d=[NMConfigurationDocument documentFromJSONData:encode(root(methods,hooks)) error:&error];check(d&&!error,"valid fixture document");return d;}
int main(void){@autoreleasepool{
 NSError *error=nil;NSMutableDictionary *record=method(@"One",@"10");record[@"preparedRVA"]=@4096;record[@"methodInfo"]=@8192;record[@"instanceIndex"]=@2;
 NMConfigurationDocument *d=doc(@[record],@[hook(@1,@1)]);check(d.requiresTargetValidation&&d.warnings.count==2,"offline schema validation never claims Runtime validation");check(!d.runtimeMethods[0][@"methodInfo"]&&!d.runtimeMethods[0][@"preparedRVA"],"binary-specific caches removed");
 record[@"argumentValues"]=@[@"changed"];check([d.runtimeMethods[0][@"argumentValues"][0] isEqual:@"10"],"document owns immutable values");
 NSData *saved=[d JSONDataWithError:&error];NMConfigurationDocument *again=[NMConfigurationDocument documentFromJSONData:saved error:&error];check(again&&!error&&[[again JSONDataWithError:&error] isEqual:saved]&&[again.runtimeMethods[0][@"instanceIndex"] intValue]==2,"new format roundtrip preserves receiver ordinal");
 check([d legacyAuthoringJSONDataWithError:&error]==nil&&error.code==12,"legacy export cannot silently drop instanceIndex");
 NMConfigurationDocument *legacy=doc(@[method(@"Legacy",@"2")],@[]);NSData *old=[legacy legacyAuthoringJSONDataWithError:&error];check(old&&!error&&[NMConfigurationDocument documentFromJSONData:old error:&error],"old authoring format still imports/exports");
 NMConfigurationDocument *different=doc(@[method(@"One",@"1"),method(@"Two",@"2"),method(@"One",@"3")],@[]);check(different.runtimeMethods.count==3,"same target can back distinct value/title features");
 check([NMConfigurationDocument documentFromJSONData:encode(root(@[method(@"One",@"1"),method(@"One",@"1")],@[])) error:&error]==nil&&error.code==8,"exact duplicate feature rejected");
 NSMutableDictionary *overloadA=method(@"Overload",@"1"),*overloadB=method(@"Overload",@"1");
 for(NSMutableDictionary *r in @[overloadA,overloadB]){r[@"argumentCount"]=@2;r[@"argumentValues"]=@[@"1",@"2"];r[@"argumentControlConfigs"]=@[@{@"type":@"fixed"},@{@"type":@"fixed"}];}
 overloadA[@"parameterTypeNames"]=@[@"A,B",@"C"];overloadB[@"parameterTypeNames"]=@[@"A",@"B,C"];
 check(doc(@[overloadA,overloadB],@[]).runtimeMethods.count==2,"structured target identity avoids comma-delimited signature collisions");
 NSMutableDictionary *space=method(@"One",@"1");space[@"class"]=@" Player ";
 check(![NMConfigurationDocument documentFromJSONData:encode(root(@[method(@"One",@"1"),space],@[])) error:&error]&&error.code==8,"lookup whitespace normalization does not create duplicate features");
 NSMutableDictionary *invalid=method(@"Bad",@"3");invalid[@"argumentCount"]=@YES;check([NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error]==nil&&error.code==5,"bool cannot masquerade as arity");invalid[@"argumentCount"]=@1.5;check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"fractional arity rejected");
 invalid=method(@"Bad",@"3");invalid[@"instanceIndex"]=[NSDecimalNumber decimalNumberWithString:@"18446744073709551616"];check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"unsigned overflow cannot wrap into valid ordinal");
 invalid=method(@"Bad",@"3");invalid[@"parameterTypeNames"]=@[];check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"missing exact parameter types rejected");
 invalid=method(@"Bad",@"3");invalid[@"executionKind"]=@2;check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"unknown execution kind rejected");
 invalid=method(@"Bad",@"3");invalid[@"argumentControlConfigs"]=@[@{@"type":@"slider",@"min":@2,@"max":@1}];check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"invalid control range rejected before store mutation");
 invalid=method(@"Bad",@"3");invalid[@"immediateChain"]=@{@"class":@"Player",@"method":@"Other",@"argumentCount":@1,@"argumentValues":@[]};check(![NMConfigurationDocument documentFromJSONData:encode(root(@[invalid],@[])) error:&error],"chain argument shape is checked offline");
 NSMutableDictionary *h=hook(@1,@2);h[@"callbackArgumentIndex"]=@0;h[@"skipOriginal"]=@YES;check(doc(@[],@[h]).nativeHooks.count==1,"callback template portable shape");h[@"skipOriginal"]=@NO;check(![NMConfigurationDocument documentFromJSONData:encode(root(@[],@[h])) error:&error],"callback template requires short circuit");
 h=hook(@1,@3);check(doc(@[],@[h]).nativeHooks.count==1,"return bool template portable shape");
 h=hook(@1,@4);h[@"fieldArgumentIndex"]=@0;h[@"fieldArgumentMode"]=@"indirect-pointer";h[@"fieldCodec"]=@"secure-long-accessor";h[@"codecClass"]=@"SecureLong";h[@"codecGetterMethod"]=@"Get";h[@"codecSetterMethod"]=@"Set";check(doc(@[],@[h]).nativeHooks.count==1,"legacy field codec descriptor preserved without execution");
 h=hook(@1,@5);h[@"fieldArgumentIndex"]=@0;h[@"fieldArgumentMode"]=@"indirect-pointer";h[@"fieldCodec"]=@"codestage-obscured-int";h[@"codecClass"]=@"CodeStage.AntiCheat.ObscuredTypes.ObscuredInt&";h[@"fieldOffset"]=@0;check(doc(@[],@[h]).nativeHooks.count==1,"complex codec portable type mapping");h[@"fieldOffset"]=@4;check(![NMConfigurationDocument documentFromJSONData:encode(root(@[],@[h])) error:&error],"whole-struct descriptor cannot import nonzero field offset");
 NMConfigurationDocument *ids=doc(@[],@[hook(@1,@1),hook(@1,@3)]);check([ids.nativeHooks[1][@"actionID"] intValue]==2,"generated Native ID collision remapped deterministically");
 check(![NMConfigurationDocument documentFromJSONData:encode(root(@[],@[])) error:&error]&&[NMConfigurationDocument.emptyDocument JSONDataWithError:&error]==nil,"empty import/export cannot accidentally clear workspace");
 NSMutableDictionary *badRoot=[root(@[method(@"A",@"1")],@[]) mutableCopy];badRoot[@"schemaVersion"]=@YES;check(![NMConfigurationDocument documentFromJSONData:encode(badRoot) error:&error],"bool schema version rejected");
 NMConfigurationStore *store=[NMConfigurationStore new];check(store.snapshot.revision==0&&!store.snapshot.document.requiresTargetValidation,"empty workspace initialized");
 check([store commitDocument:legacy mode:NMConfigurationImportReplace expectedRevision:0 error:&error]&&store.snapshot.revision==1,"single document commit");
 NMConfigurationSnapshot *before=store.snapshot;invalid=method(@"LastInvalid",@"2");invalid[@"argumentValues"]=@[];
 check(![store importJSONData:encode(root(@[method(@"ValidFirst",@"1"),invalid],@[hook(@8,@1)])) mode:NMConfigurationImportMerge expectedRevision:1 error:&error]&&store.snapshot==before,"late invalid record leaves entire Runtime/Native workspace unchanged");
 check(![store commitDocument:legacy mode:NMConfigurationImportMerge expectedRevision:1 error:&error]&&error.code==8&&store.snapshot==before,"duplicate merge is atomic failure");
 check([store commitDocument:doc(@[method(@"Next",@"3")],@[hook(@8,@1)]) mode:NMConfigurationImportMerge expectedRevision:1 error:&error]&&store.snapshot.revision==2&&store.snapshot.document.runtimeMethods.count==2&&store.snapshot.document.nativeHooks.count==1,"one commit exposes both domains together");
 before=store.snapshot;check(![store commitDocument:legacy mode:NMConfigurationImportReplace expectedRevision:1 error:&error]&&error.code==100&&store.snapshot==before,"stale revision cannot overwrite newer edits");
 _Atomic(unsigned) wins=0;_Atomic(unsigned) *successes=&wins;NMConfigurationDocument *shared=legacy;
 dispatch_apply(100,dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^(size_t i){@autoreleasepool{(void)i;NSError *e=nil;BOOL ok=[store commitDocument:shared mode:NMConfigurationImportReplace expectedRevision:2 error:&e];if(ok)atomic_fetch_add(successes,1);else check(e.code==100,"parallel loser reports revision conflict");}});
 check(atomic_load(&wins)==1&&store.snapshot.revision==3,"exactly one of 100 concurrent commits wins, no lost update");
 check([store commitDocument:NMConfigurationDocument.emptyDocument mode:NMConfigurationImportReplace expectedRevision:3 error:&error]&&!store.snapshot.document.requiresTargetValidation,"explicit empty replacement remains available");
 puts("PASS: legacy/new authoring schema, raw signature/control/chain descriptors, cache stripping, Native templates/IDs and atomic revisioned Runtime+Native import");
 }return 0;}
