#import "NMConfiguration.h"
#import "NMRuntimeActionFormat.h"
#import "NMAuthoringFeatureIdentity.h"
#import <CoreFoundation/CoreFoundation.h>
#include <math.h>
#include <errno.h>
#include <stdlib.h>
static NSError *NMCError(NSInteger code,NSString *message){return [NSError errorWithDomain:@"newmymenu.configuration" code:code userInfo:@{NSLocalizedDescriptionKey:message}];}
static BOOL NMCString(id value,BOOL required){return [value isKindOfClass:NSString.class]&&[value length]<=16384&&(!required||[[value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] length]>0);}
static BOOL NMCInteger(id value,uint64_t maximum){
    if(![value isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())return NO;
    NSString *string=[value stringValue];if(!string.length||[string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location!=NSNotFound)return NO;
    const char *text=string.UTF8String;char *end=NULL;errno=0;unsigned long long number=strtoull(text,&end,10);return !errno&&end!=text&&end&&!*end&&number<=maximum;
}
static BOOL NMCSignedInteger(id value){
    if(![value isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID())return NO;
    const char *text=[[value stringValue] UTF8String];char *end=NULL;errno=0;(void)strtoll(text,&end,10);return !errno&&end!=text&&end&&!*end;
}
static BOOL NMCBoolean(id value){return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID();}
static NSData *NMCEncode(id object,NSError **error){NSData *data=[NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingSortedKeys error:error];if(data.length>4*1024*1024){if(error)*error=NMCError(1,@"Configuration exceeds 4 MiB");return nil;}if(data&&error)*error=nil;return data;}
static NSArray *NMCBinaryKeys(void){return @[@"methodInfo",@"methodPointer",@"rva",@"rvaText",@"imageBase",@"preparedDescriptor",@"preparedRVA",@"preparedUUID",@"preparedStaticKnown",@"preparedIsStatic",@"preparedCodecGetterRVA",@"preparedCodecSetterRVA",@"staticPrepatch",@"staticHookSlotRVA",@"staticTrampolineRVA",@"staticCodeCaveRVA",@"staticDisplacedInstruction",@"fallbackRVA",@"fallbackUUID"];}
static id NMCSanitize(id value,NSMutableSet *warnings){
    if([value isKindOfClass:NSDictionary.class]){NSMutableDictionary *out=[NSMutableDictionary dictionary];for(NSString *key in value){if([NMCBinaryKeys() containsObject:key]){[warnings addObject:[@"Discarded binary-specific cache: " stringByAppendingString:key]];continue;}out[key]=NMCSanitize(value[key],warnings);}return [out copy];}
    if([value isKindOfClass:NSArray.class]){NSMutableArray *out=[NSMutableArray array];for(id child in value)[out addObject:NMCSanitize(child,warnings)];return [out copy];}return value;
}
static BOOL NMCOwner(NSDictionary *record){return NMCString(record[@"assembly"],YES)&&NMCString(record[@"namespace"],NO)&&NMCString(record[@"class"],YES)&&NMCString(record[@"method"],YES)&&NMCInteger(record[@"argumentCount"],NM_RUNTIME_ACTION_MAX_ARGUMENTS)&&NMCBoolean(record[@"signatureAvailable"])&&[record[@"signatureAvailable"] boolValue]&&[record[@"parameterTypeNames"] isKindOfClass:NSArray.class]&&[record[@"parameterTypeNames"] count]==[record[@"argumentCount"] unsignedIntegerValue];}
static NSArray *NMCMethodKey(NSDictionary *record){NSMutableArray *key=[NSMutableArray array];for(NSString *field in @[@"assembly",@"namespace",@"class",@"method"])[key addObject:[record[field] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];NSMutableArray *types=[NSMutableArray array];for(NSString *type in record[@"parameterTypeNames"])[types addObject:[type stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]];[key addObject:[types copy]];return [key copy];}
static id NMCFeatureKey(NSDictionary *record){NSData *key=NMCEncode(NMCMethodKey(record),NULL);NSString *identity=[[NSString alloc] initWithData:key encoding:NSUTF8StringEncoding];NSMutableDictionary *result=[NMAuthoringRuntimeFeatureIdentity(record,identity) mutableCopy];result[@"instanceIndex"]=record[@"instanceIndex"]?:@0;return [result copy];}
static NSArray *NMCHookKey(NSDictionary *record){return @[NMCMethodKey(record),record[@"templateKind"],record[@"argumentIndex"]?:@0,record[@"fieldArgumentIndex"]?:@(UINT64_MAX)];}
static BOOL NMCControls(NSArray *controls){
    for(id raw in controls){if(![raw isKindOfClass:NSDictionary.class]||![@[@"fixed",@"switch",@"button",@"number",@"slider"] containsObject:raw[@"type"]])return NO;
        if(raw[@"enabled"]&&!NMCBoolean(raw[@"enabled"]))return NO;
        if(raw[@"valueType"]&&(!NMCString(raw[@"valueType"],YES)||![@[@"AUTO",@"I32",@"U32",@"I64",@"U64",@"F32",@"F64"] containsObject:[raw[@"valueType"] uppercaseString]]))return NO;
        for(NSString *key in @[@"min",@"max",@"step",@"default"]){id value=raw[key];if(value&&(![value isKindOfClass:NSNumber.class]||NMCBoolean(value)||!isfinite([value doubleValue])))return NO;}
        if(raw[@"min"]&&raw[@"max"]&&[raw[@"min"] compare:raw[@"max"]]==NSOrderedDescending)return NO;
        if(raw[@"step"]&&[raw[@"step"] doubleValue]<=0)return NO;
        if(raw[@"default"]&&((raw[@"min"]&&[raw[@"default"] compare:raw[@"min"]]==NSOrderedAscending)||(raw[@"max"]&&[raw[@"default"] compare:raw[@"max"]]==NSOrderedDescending)))return NO;
    }return YES;
}
static BOOL NMCChain(NSDictionary *chain){
    if(![chain isKindOfClass:NSDictionary.class])return NO;if(!chain.count)return YES;
    if(!NMCString(chain[@"class"],YES)||!NMCString(chain[@"method"],YES)||!NMCInteger(chain[@"argumentCount"],NM_RUNTIME_ACTION_MAX_ARGUMENTS))return NO;
    if(chain[@"instanceIndex"]&&!NMCInteger(chain[@"instanceIndex"],NM_RUNTIME_INSTANCE_MAX_INDEX))return NO;
    if(chain[@"signatureAvailable"]&&!NMCBoolean(chain[@"signatureAvailable"]))return NO;
    if([chain[@"signatureAvailable"] boolValue]&&![chain[@"parameterTypeNames"] isKindOfClass:NSArray.class])return NO;
    for(NSString *key in @[@"assembly",@"namespace"])if(chain[key]&&!NMCString(chain[key],NO))return NO;
    for(NSString *key in @[@"parameterTypeNames",@"argumentValues"]){id values=chain[key];if(values){if(![values isKindOfClass:NSArray.class]||[values count]!=[chain[@"argumentCount"] unsignedIntegerValue])return NO;for(id value in values)if(!NMCString(value,[key isEqual:@"parameterTypeNames"]))return NO;}}
    return YES;
}
static BOOL NMCTemplate(NSDictionary *r){
    if(!NMCInteger(r[@"actionID"],UINT32_MAX)||![r[@"actionID"] unsignedIntValue]||!NMCInteger(r[@"templateKind"],5)||![r[@"templateKind"] unsignedIntValue])return NO;
    NSUInteger argc=[r[@"argumentCount"] unsignedIntegerValue],kind=[r[@"templateKind"] unsignedIntegerValue];
    for(NSString *key in @[@"argumentIndex",@"callbackArgumentIndex",@"fieldArgumentIndex",@"fieldOffset",@"codecGetterArgumentCount",@"codecSetterArgumentCount"])if(r[key]&&!NMCInteger(r[key],UINT64_MAX))return NO;
    for(NSString *key in @[@"callbackValue",@"skipOriginal",@"returnBoolValue"])if(r[key]&&!NMCBoolean(r[key]))return NO;
    for(NSString *key in @[@"min",@"max",@"default"]){id value=r[key];if(value&&!NMCSignedInteger(value))return NO;}
    if(r[@"min"]&&r[@"max"]&&[r[@"min"] compare:r[@"max"]]==NSOrderedDescending)return NO;
    if(r[@"default"]&&((r[@"min"]&&[r[@"default"] compare:r[@"min"]]==NSOrderedAscending)||(r[@"max"]&&[r[@"default"] compare:r[@"max"]]==NSOrderedDescending)))return NO;
    if(kind==1)return r[@"argumentIndex"]&&[r[@"argumentIndex"] unsignedIntegerValue]<argc;
    if(kind==2)return r[@"callbackArgumentIndex"]&&[r[@"callbackArgumentIndex"] unsignedLongLongValue]<argc&&(!r[@"skipOriginal"]||[r[@"skipOriginal"] boolValue]);
    if(kind==3)return YES;
    if(!r[@"fieldArgumentIndex"]||[r[@"fieldArgumentIndex"] unsignedLongLongValue]>=argc||![r[@"fieldArgumentMode"] isEqual:@"indirect-pointer"])return NO;
    if(kind==4)return [r[@"fieldCodec"] isEqual:@"secure-long-accessor"]&&NMCString(r[@"codecClass"],YES)&&NMCString(r[@"codecGetterMethod"],YES)&&NMCString(r[@"codecSetterMethod"],YES);
    NSString *type=r[@"codecClass"];if(!NMCString(type,YES)||[r[@"fieldOffset"] unsignedLongLongValue]!=0)return NO;
    type=[type stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];while([type hasSuffix:@"&"]||[type hasSuffix:@"*"])type=[[type substringToIndex:type.length-1] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *expected=[type isEqual:@"CodeStage.AntiCheat.ObscuredTypes.ObscuredInt"]?@"codestage-obscured-int":(([@[@"Percent.Scripting.Stdlib.SecureValue.SecureLong",@"SecureLong"] containsObject:type])?@"secure-long-whole-accessor":nil);
    return expected&&[r[@"fieldCodec"] isEqual:expected];
}
@interface NMConfigurationDocument ()
- (instancetype)initRoot:(NSDictionary *)root warnings:(NSArray *)warnings;
+ (nullable instancetype)normalizeRoot:(NSDictionary *)root warnings:(NSMutableSet *)warnings error:(NSError **)error;
@end
@implementation NMConfigurationDocument
- (instancetype)initRoot:(NSDictionary *)root warnings:(NSArray *)warnings{self=[super init];if(self){_runtimeMethods=root[@"runtimeMethods"];_nativeHooks=root[@"nativeHooks"];_warnings=[warnings copy];}return self;}
+ (instancetype)emptyDocument{return [[self alloc] initRoot:@{@"runtimeMethods":@[],@"nativeHooks":@[]} warnings:@[]];}
- (BOOL)requiresTargetValidation{return _runtimeMethods.count+_nativeHooks.count>0;}
+ (instancetype)normalizeRoot:(NSDictionary *)root warnings:(NSMutableSet *)warnings error:(NSError **)error {
    NSArray *methods=root[@"runtimeMethods"]?:@[],*hooks=root[@"nativeHooks"]?:@[];
    if(![methods isKindOfClass:NSArray.class]||![hooks isKindOfClass:NSArray.class]||methods.count>256||hooks.count>256){if(error)*error=NMCError(3,@"Configuration lists must contain at most 256 records each");return nil;}
    NSMutableArray *cleanMethods=[NSMutableArray array],*cleanHooks=[NSMutableArray array];NSMutableSet *features=[NSMutableSet set],*nativeKeys=[NSMutableSet set],*nativeIDs=[NSMutableSet set];
    for(NSUInteger domain=0;domain<2;domain++)for(id input in (domain?hooks:methods)){
        if(![input isKindOfClass:NSDictionary.class]){if(error)*error=NMCError(4,@"Authoring record is not a dictionary");return nil;}
        NSMutableDictionary *r=[NMCSanitize(input,warnings) mutableCopy];
        if(!r[@"assembly"])r[@"assembly"]=@"Assembly-CSharp.dll";if(!r[@"namespace"])r[@"namespace"]=@"";if(!r[@"title"])r[@"title"]=@"";if(!r[@"description"])r[@"description"]=@"";if(!r[@"group"])r[@"group"]=domain?@"Native Hooks":@"Runtime Methods";
        if(!NMCOwner(r)){if(error)*error=NMCError(5,@"Invalid owner, arity or complete parameter signature");return nil;}
        for(id type in r[@"parameterTypeNames"])if(!NMCString(type,YES)){if(error)*error=NMCError(5,@"Parameter type must be a nonempty string");return nil;}
        for(NSString *key in @[@"title",@"description",@"group"])if(!NMCString(r[key],NO)){if(error)*error=NMCError(6,@"Invalid display field");return nil;}
        if(!domain){
            if(!r[@"executionKind"])r[@"executionKind"]=@1;if(!r[@"instanceIndex"])r[@"instanceIndex"]=@0;if(!r[@"immediateChain"])r[@"immediateChain"]=@{};
            if(!NMCInteger(r[@"executionKind"],3)||![@[@1,@3] containsObject:r[@"executionKind"]]||!NMCInteger(r[@"instanceIndex"],NM_RUNTIME_INSTANCE_MAX_INDEX)||![r[@"argumentValues"] isKindOfClass:NSArray.class]||[r[@"argumentValues"] count]!=[r[@"argumentCount"] unsignedIntegerValue]||![r[@"argumentControlConfigs"] isKindOfClass:NSArray.class]||[r[@"argumentControlConfigs"] count]!=[r[@"argumentCount"] unsignedIntegerValue]||!NMCControls(r[@"argumentControlConfigs"])||!NMCChain(r[@"immediateChain"])){if(error)*error=NMCError(7,@"Invalid Runtime arguments, controls, receiver or chain");return nil;}
            for(id value in r[@"argumentValues"])if(!NMCString(value,NO)){if(error)*error=NMCError(7,@"Argument values must be strings");return nil;}
            id key=NMCFeatureKey(r);if([features containsObject:key]){if(error)*error=NMCError(8,@"Duplicate Runtime feature configuration");return nil;}[features addObject:key];[cleanMethods addObject:[r copy]];
        }else{
            if(!NMCTemplate(r)){if(error)*error=NMCError(9,@"Invalid Native template or parameter fields");return nil;}
            id key=NMCHookKey(r);if([nativeKeys containsObject:key]){if(error)*error=NMCError(10,@"Duplicate Native target/template configuration");return nil;}[nativeKeys addObject:key];
            uint32_t action=[r[@"actionID"] unsignedIntValue];while([nativeIDs containsObject:@(action)])action=action==UINT32_MAX?1:action+1;r[@"actionID"]=@(action);[nativeIDs addObject:@(action)];[cleanHooks addObject:[r copy]];
        }
    }
    NSDictionary *payload=@{@"runtimeMethods":cleanMethods,@"nativeHooks":cleanHooks};NSData *data=NMCEncode(payload,error);if(!data)return nil;
    NSDictionary *frozen=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];if(!frozen)return nil;if(error)*error=nil;
    return [[self alloc] initRoot:frozen warnings:[[warnings allObjects] sortedArrayUsingSelector:@selector(compare:)]];
}
+ (instancetype)documentFromJSONData:(NSData *)data error:(NSError **)error {
    if(![data isKindOfClass:NSData.class]||!data.length||data.length>4*1024*1024){if(error)*error=NMCError(1,@"Configuration must be nonempty JSON within 4 MiB");return nil;}
    @try{id root=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];if(!root)return nil;
        if(![root isKindOfClass:NSDictionary.class]||![@[@"zonoe-authoring",@"newmymenu.authoring"] containsObject:root[@"format"]]||!NMCInteger(root[@"schemaVersion"],1)||![root[@"schemaVersion"] isEqual:@1]){if(error)*error=NMCError(2,@"Unsupported authoring format/schema");return nil;}
        for(NSString *key in root)if(![@[@"format",@"schemaVersion",@"runtimeMethods",@"nativeHooks"] containsObject:key]){if(error)*error=NMCError(2,@"Unknown root field; no silent schema downgrade");return nil;}
        NMConfigurationDocument *document=[self normalizeRoot:root warnings:[NSMutableSet set] error:error];if(document&&!document.requiresTargetValidation){if(error)*error=NMCError(3,@"Import cannot silently clear the workspace with an empty list");return nil;}return document;
    }@catch(NSException *exception){if(error)*error=NMCError(11,exception.reason?:exception.name);return nil;}
}
- (NSData *)JSONDataWithError:(NSError **)error{if(!self.requiresTargetValidation){if(error)*error=NMCError(3,@"No authoring features to export");return nil;}return NMCEncode(@{@"format":@"newmymenu.authoring",@"schemaVersion":@1,@"runtimeMethods":_runtimeMethods,@"nativeHooks":_nativeHooks},error);}
- (NSData *)legacyAuthoringJSONDataWithError:(NSError **)error {
    if(!self.requiresTargetValidation){if(error)*error=NMCError(3,@"No authoring features to export");return nil;}
    for(NSDictionary *r in _runtimeMethods)if([r[@"instanceIndex"] unsignedIntegerValue]!=0){if(error)*error=NMCError(12,@"Legacy authoring cannot preserve instanceIndex; use newmymenu format");return nil;}
    NSMutableArray *methods=[NSMutableArray array];for(NSDictionary *r in _runtimeMethods){NSMutableDictionary *copy=[r mutableCopy];[copy removeObjectForKey:@"instanceIndex"];[methods addObject:copy];}
    return NMCEncode(@{@"format":@"zonoe-authoring",@"schemaVersion":@1,@"runtimeMethods":methods,@"nativeHooks":_nativeHooks},error);
}
@end
@interface NMConfigurationSnapshot ()
- (instancetype)initDocument:(NMConfigurationDocument *)document revision:(uint64_t)revision;
@end
@implementation NMConfigurationSnapshot
- (instancetype)initDocument:(NMConfigurationDocument *)document revision:(uint64_t)revision{self=[super init];if(self){_document=document;_revision=revision;}return self;}
@end
@implementation NMConfigurationStore {NSLock *_lock;NMConfigurationSnapshot *_snapshot;}
- (instancetype)init{self=[super init];if(self){_lock=[NSLock new];_snapshot=[[NMConfigurationSnapshot alloc] initDocument:NMConfigurationDocument.emptyDocument revision:0];}return self;}
- (NMConfigurationSnapshot *)snapshot{[_lock lock];NMConfigurationSnapshot *value=_snapshot;[_lock unlock];return value;}
- (BOOL)importJSONData:(NSData *)data mode:(NMConfigurationImportMode)mode expectedRevision:(uint64_t)revision error:(NSError **)error {NMConfigurationDocument *document=[NMConfigurationDocument documentFromJSONData:data error:error];return document?[self commitDocument:document mode:mode expectedRevision:revision error:error]:NO;}
- (BOOL)commitDocument:(NMConfigurationDocument *)document mode:(NMConfigurationImportMode)mode expectedRevision:(uint64_t)revision error:(NSError **)error {
    if(![document isKindOfClass:NMConfigurationDocument.class]||(mode!=NMConfigurationImportMerge&&mode!=NMConfigurationImportReplace)){if(error)*error=NMCError(13,@"Invalid document or import mode");return NO;}
    NMConfigurationSnapshot *base=self.snapshot;if(base.revision!=revision||revision==UINT64_MAX){if(error)*error=NMCError(100,@"Stale or exhausted revision; reload workspace");return NO;}
    NMConfigurationDocument *candidate=document;
    if(mode==NMConfigurationImportMerge){NSMutableSet *warnings=[NSMutableSet setWithArray:base.document.warnings];[warnings addObjectsFromArray:document.warnings];candidate=[NMConfigurationDocument normalizeRoot:@{@"runtimeMethods":[base.document.runtimeMethods arrayByAddingObjectsFromArray:document.runtimeMethods],@"nativeHooks":[base.document.nativeHooks arrayByAddingObjectsFromArray:document.nativeHooks]} warnings:warnings error:error];if(!candidate)return NO;}
    NMConfigurationSnapshot *next=[[NMConfigurationSnapshot alloc] initDocument:candidate revision:revision+1];
    [_lock lock];if(_snapshot.revision!=revision){[_lock unlock];if(error)*error=NMCError(100,@"Concurrent configuration changed; nothing imported");return NO;}_snapshot=next;[_lock unlock];if(error)*error=nil;return YES;
}
@end
