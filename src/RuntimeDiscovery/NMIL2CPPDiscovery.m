#import "NMIL2CPPDiscovery+Internal.h"
#import "../MethodFinder/NMNamedExpression.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <dlfcn.h>
#include <string.h>
#include <time.h>

static NSError *NMDLError(NSInteger code,NSString *text) { return [NSError errorWithDomain:@"newmymenu.il2cpp-discovery" code:code userInfo:@{NSLocalizedDescriptionKey:text}]; }
static NSString *NMDLString(const char *text) { return text?([NSString stringWithUTF8String:text]?:@""):@""; }
static double NMDLTime(void) { struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return t.tv_sec+t.tv_nsec/1e9; }
static BOOL NMDLAPIComplete(NMIL2CPPAPI api) {
#define NM_CHECK(field,name) if(!api.field)return NO;
    NM_IL2CPP_API_FIELDS(NM_CHECK)
#undef NM_CHECK
    return YES;
}
static NSString *NMDLTypeName(NMIL2CPPAPI api,const void *type) {
    if(!type)return @"?";
    char *raw=api.typeGetName(type); if(!raw)return @"?";
    NSString *value;
    @try { value=[NMDLString(raw) copy]; } @finally { api.freeMemory(raw); }
    return value.length?value:@"?";
}
// Shared by class expansion and global method search: one metadata copying path.
static NSDictionary *NMDLCopyMethod(NMIL2CPPAPI api,const void *method,NSDictionary *identity,NSError *__strong *failure) {
    uint32_t params=api.methodGetParamCount(method);
    if(params>128){if(failure)*failure=NMDLError(18,@"Invalid method parameter count");return nil;}
    NSMutableArray *types=[NSMutableArray arrayWithCapacity:params];
    for(uint32_t i=0;i<params;i++)[types addObject:NMDLTypeName(api,api.methodGetParam(method,i))];
    uint32_t implementation=0;uint32_t flags=api.methodGetFlags(method,&implementation);
    NSString *name=NMDLString(api.methodGetName(method)),*ret=NMDLTypeName(api,api.methodGetReturnType(method));
    return @{@"method":name,@"parameterTypes":[types copy],@"returnType":ret,@"static":@((flags&0x10u)!=0),@"classIdentity":identity,@"signature":[NSString stringWithFormat:@"%@ %@(%@)",ret,name,[types componentsJoinedByString:@", "]]};
}
static NSInteger NMDLClassRank(NSString *name,NSString *query) {
    if([name caseInsensitiveCompare:query]==NSOrderedSame)return 0;
    NSString *n=name.lowercaseString,*q=query.lowercaseString;
    if([n hasPrefix:q])return 1;if([n hasSuffix:q])return 2;
    return [n containsString:q]?3:NSIntegerMax;
}
static NSComparisonResult NMDLCompareClasses(NSDictionary *a,NSDictionary *b) {
    NSInteger ar=[a[@"rank"] integerValue],br=[b[@"rank"] integerValue];
    if(ar!=br)return ar<br?NSOrderedAscending:NSOrderedDescending;
    NSComparisonResult order=[a[@"fullType"] localizedCaseInsensitiveCompare:b[@"fullType"]];
    return order==NSOrderedSame?[a[@"assembly"] compare:b[@"assembly"]]:order;
}
static NSString *NMDLImageUUID(const struct mach_header *header) {
    if(!header || header->magic!=MH_MAGIC_64 || header->sizeofcmds>16*1024*1024)return @"";
    const uint8_t *cursor=(const uint8_t *)header+sizeof(struct mach_header_64),*end=cursor+header->sizeofcmds;
    for(uint32_t i=0;i<header->ncmds;i++){
        if((size_t)(end-cursor)<sizeof(struct load_command))return @"";
        const struct load_command *command=(const void *)cursor;
        if(command->cmdsize<sizeof(*command)||command->cmdsize>(size_t)(end-cursor))return @"";
        if(command->cmd==LC_UUID&&command->cmdsize>=sizeof(struct uuid_command))return [[[NSUUID alloc] initWithUUIDBytes:((const struct uuid_command *)command)->uuid] UUIDString];
        cursor+=command->cmdsize;
    }
    return @"";
}

@interface NMIL2CPPDiscovery () {
    @private
    NMIL2CPPAPI _api;
    void *_ownedHandle;
    NSDictionary *_runtimeReport;
}
- (nullable NSDictionary *)scanQuery:(NSString *)query methods:(BOOL)methods filter:(nullable NSDictionary *)filter limit:(NSUInteger)limit error:(NSError **)error;
- (nullable NSDictionary *)withMetadata:(NSDictionary * _Nullable (^)(NMIL2CPPAPI api,void *domain,NSError *__strong *error))operation error:(NSError **)error;
@end

@implementation NMIL2CPPDiscovery
+ (NSDictionary *)loadedRuntimeCapabilities {
    NSMutableArray *images=[NSMutableArray array];
    uint32_t count=_dyld_image_count();
    for(uint32_t i=0;i<count;i++){
        const struct mach_header *header=_dyld_get_image_header(i);
        NSString *path=NMDLString(_dyld_get_image_name(i));
        if(!path.length || [path hasPrefix:@"/System/"] || [path hasPrefix:@"/usr/lib/"])continue;
        void *handle=i==0?dlopen(NULL,RTLD_NOW):dlopen(path.fileSystemRepresentation,RTLD_NOW|RTLD_NOLOAD);
        if(!handle)continue;
        void *domain=dlsym(handle,"il2cpp_domain_get");Dl_info info={0};
        if(domain && dladdr(domain,&info) && info.dli_fbase==(void *)header){
            NSMutableArray *present=[NSMutableArray array],*missing=[NSMutableArray array];
#define NM_REPORT(field,name) {void *p=dlsym(handle,name);Dl_info owner={0};if(p&&dladdr(p,&owner)&&owner.dli_fbase==info.dli_fbase)[present addObject:@name];else [missing addObject:@name];}
            NM_IL2CPP_API_FIELDS(NM_REPORT)
#undef NM_REPORT
            NSMutableArray *gc=[NSMutableArray array];
            for(NSString *name in @[@"il2cpp_gchandle_new",@"il2cpp_gchandle_get_target",@"il2cpp_gchandle_free",@"il2cpp_runtime_invoke"]){
                void *p=dlsym(handle,name.UTF8String);Dl_info owner={0};if(p&&dladdr(p,&owner)&&owner.dli_fbase==info.dli_fbase)[gc addObject:name];
            }
            [images addObject:@{@"path":path,@"uuid":NMDLImageUUID(header),@"availableSymbols":[present copy],@"missingSymbols":[missing copy],@"invocationSymbolsNotCalled":[gc copy]}];
        }
        dlclose(handle);
    }
    return @{@"runtimeImages":[images copy],@"metadataBindingAvailable":@(images.count==1 && [images.firstObject[@"missingSymbols"] count]==0),@"policy":@"Read-only metadata; GCHandle and runtime_invoke are not called"};
}
+ (instancetype)loadedRuntimeWithError:(NSError **)error {
    NSDictionary *capabilities=[self loadedRuntimeCapabilities];NSArray *images=capabilities[@"runtimeImages"];
    if(images.count!=1){if(error)*error=NMDLError(1,images.count?@"Multiple IL2CPP runtime owners; refusing ambiguous binding":@"No loaded IL2CPP runtime exports; enter the game and retry");return nil;}
    NSDictionary *image=images.firstObject;
    if([image[@"missingSymbols"] count]){if(error)*error=NMDLError(2,[NSString stringWithFormat:@"Missing or foreign metadata symbols: %@",[image[@"missingSymbols"] componentsJoinedByString:@", "]]);return nil;}
    NSString *path=image[@"path"];
    void *handle=dlopen(path.fileSystemRepresentation,RTLD_NOW|RTLD_NOLOAD);
    if(!handle && [path isEqual:NMDLString(_dyld_get_image_name(0))])handle=dlopen(NULL,RTLD_NOW);
    NMIL2CPPAPI api={0};void *domain=handle?dlsym(handle,"il2cpp_domain_get"):NULL;Dl_info runtime={0};
    if(!domain||!dladdr(domain,&runtime)||![NMDLString(runtime.dli_fname) isEqualToString:path]){if(handle)dlclose(handle);if(error)*error=NMDLError(3,@"Runtime image changed during binding");return nil;}
#define NM_BIND(field,name) {void *p=dlsym(handle,name);Dl_info owner={0};if(p&&dladdr(p,&owner)&&owner.dli_fbase==runtime.dli_fbase)memcpy(&api.field,&p,sizeof(p));}
    NM_IL2CPP_API_FIELDS(NM_BIND)
#undef NM_BIND
    NSMutableDictionary *report=[image mutableCopy];report[@"runtimeIdentifier"]=NSUUID.UUID.UUIDString;
    NMIL2CPPDiscovery *discovery=[[self alloc] initWithAPI:api report:report ownedHandle:handle];
    if(!discovery){if(handle)dlclose(handle);if(error)*error=NMDLError(4,@"Incomplete metadata API table");return nil;}
    if(error)*error=nil;return discovery;
}
- (instancetype)initWithAPI:(NMIL2CPPAPI)api report:(NSDictionary *)report ownedHandle:(void *)handle {
    if(!NMDLAPIComplete(api)||![report[@"runtimeIdentifier"] isKindOfClass:NSString.class])return nil;
    self=[super init];if(self){_api=api;_runtimeReport=[report copy];_ownedHandle=handle;}return self;
}
- (void)dealloc { if(_ownedHandle)dlclose(_ownedHandle); }
- (NSDictionary *)runtimeReport { return _runtimeReport; }
- (NSDictionary *)withMetadata:(NSDictionary *(^)(NMIL2CPPAPI,void *,NSError *__strong *))operation error:(NSError **)error {
    NMIL2CPPAPI api=_api;void *domain=api.domainGet();
    if(!domain){if(error)*error=NMDLError(5,@"IL2CPP Domain is not ready; enter gameplay and retry");return nil;}
    void *thread=api.threadCurrent();BOOL attached=NO;
    if(!thread){thread=api.threadAttach(domain);attached=thread!=NULL;}
    if(!thread){if(error)*error=NMDLError(6,@"IL2CPP thread_attach returned null");return nil;}
    // The internal callback owns its error strongly before nested autorelease pools drain.
    // Public NSError** writeback happens only after the operation has returned.
    NSError *failure=nil;NSDictionary *result=nil;
    @try {
        result=operation(api,domain,&failure);
        if(api.domainGet()!=domain){failure=NMDLError(7,@"IL2CPP Domain changed during metadata operation");result=nil;}
    } @catch(NSException *exception) {
        failure=NMDLError(8,[NSString stringWithFormat:@"Metadata exception %@: %@",exception.name,exception.reason?:@""]);
    } @finally { if(attached)api.threadDetach(thread); }
    if(!result&&!failure)failure=NMDLError(9,@"Metadata operation produced no result");
    if(error)*error=failure;return failure?nil:result;
}
- (NSDictionary *)searchClasses:(NSString *)query limit:(NSUInteger)limit error:(NSError **)error {return [self scanQuery:query methods:NO filter:nil limit:limit error:error];}
- (NSDictionary *)searchMethods:(NSString *)query limit:(NSUInteger)limit error:(NSError **)error {return [self scanQuery:query methods:YES filter:nil limit:limit error:error];}
- (NSDictionary *)searchMethodExpression:(NSString *)expression limit:(NSUInteger)limit error:(NSError **)error {
    NSString *parseError=nil;NSDictionary *filter=[NMNamedExpression parse:expression error:&parseError];
    if(!filter){if(error)*error=NMDLError(19,parseError?:@"Invalid method expression");return nil;}
    if([filter[@"delta"] longLongValue]!=0){if(error)*error=NMDLError(20,@"Nonzero delta requires the address resolver; metadata search does not reinterpret an interior address as a method");return nil;}
    return [self scanQuery:expression methods:YES filter:filter limit:limit error:error];
}
- (NSDictionary *)scanQuery:(NSString *)query methods:(BOOL)methodSearch filter:(NSDictionary *)filter limit:(NSUInteger)limit error:(NSError **)error {
    NSString *text=[query isKindOfClass:NSString.class]?[[query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] copy]:nil;
    if(!text.length || !limit || limit>1024){if(error)*error=NMDLError(10,@"Enter a keyword and limit within 1..1024");return nil;}
    return [self withMetadata:^NSDictionary *(NMIL2CPPAPI api,void *domain,NSError *__strong *failure){
        size_t count=0;const void **assemblies=api.domainGetAssemblies(domain,&count);
        if(!assemblies||!count||count>4096){if(failure)*failure=NMDLError(11,@"No assemblies yet or invalid assembly count");return nil;}
        NSMutableArray *ordered=[NSMutableArray array];
        for(size_t i=0;i<count;i++){const void *image=api.assemblyGetImage(assemblies[i]);if(image)[ordered addObject:@{@"pointer":@((uintptr_t)image),@"assembly":NMDLString(api.imageGetName(image))}];}
        [ordered sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){BOOL ac=[a[@"assembly"] hasPrefix:@"Assembly-CSharp"],bc=[b[@"assembly"] hasPrefix:@"Assembly-CSharp"];if(ac!=bc)return ac?NSOrderedAscending:NSOrderedDescending;return [a[@"assembly"] compare:b[@"assembly"]];}];
        NSMutableArray *results=[NSMutableArray array];NSUInteger scanned=0,methodsScanned=0,totalMatches=0,capacity=MIN((NSUInteger)4096,MAX(limit*4,(NSUInteger)64));BOOL truncated=NO;double deadline=NMDLTime()+2.0;
        for(NSDictionary *entry in ordered){
            const void *image=(const void *)(uintptr_t)[entry[@"pointer"] unsignedLongLongValue];size_t classes=api.imageGetClassCount(image);
            if(classes>2000000){if(failure)*failure=NMDLError(12,@"Invalid class count");return nil;}
            for(size_t i=0;i<classes;i++){ @autoreleasepool {
                if((methodSearch&&results.count>=limit)||scanned>=200000||NMDLTime()>deadline){truncated=YES;break;}
                scanned++;void *klass=api.imageGetClass(image,i);if(!klass)continue;
                NSString *name=NMDLString(api.classGetName(klass)),*ns=NMDLString(api.classGetNamespace(klass));
                if(filter){
                    NSString *actual=[entry[@"assembly"] lowercaseString],*wanted=[filter[@"assembly"] lowercaseString];
                    if([actual hasSuffix:@".dll"])actual=[actual substringToIndex:actual.length-4];
                    if([wanted hasSuffix:@".dll"])wanted=[wanted substringToIndex:wanted.length-4];
                    if(wanted.length&&![actual isEqual:wanted])continue;
                    if([filter[@"class"] length]&&[name caseInsensitiveCompare:filter[@"class"]]!=NSOrderedSame)continue;
                    if([filter[@"namespaceSpecified"] boolValue]&&[ns caseInsensitiveCompare:filter[@"namespace"]]!=NSOrderedSame)continue;
                }
                NSString *full=NMDLTypeName(api,api.classGetType(klass));
                NSDictionary *identity=@{@"assembly":entry[@"assembly"],@"namespace":ns,@"class":name,@"fullType":full,@"runtimeIdentifier":self->_runtimeReport[@"runtimeIdentifier"]};
                if(!methodSearch){
                    NSString *search=[NSString stringWithFormat:@"%@ %@ %@",name,ns,full];
                    NSInteger rank=NMDLClassRank(name,text);
                    if(rank==NSIntegerMax&&[search rangeOfString:text options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location!=NSNotFound)rank=4;
                    if(rank!=NSIntegerMax){
                        totalMatches++;NSMutableDictionary *ranked=[identity mutableCopy];ranked[@"rank"]=@(rank);[results addObject:[ranked copy]];
                        if(results.count>capacity){[results sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return NMDLCompareClasses(a,b);}];[results removeObjectsInRange:NSMakeRange(capacity,results.count-capacity)];}
                    }
                } else {
                    void *iterator=NULL;const void *method=NULL;
                    while((method=api.classGetMethods(klass,&iterator))){ @autoreleasepool {
                        if(results.count>=limit||methodsScanned>=500000||NMDLTime()>deadline){truncated=YES;break;}
                        methodsScanned++;
                        NSString *methodName=NMDLString(api.methodGetName(method));
                        if(filter){
                            if([methodName caseInsensitiveCompare:filter[@"method"]]!=NSOrderedSame)continue;
                            if([filter[@"argumentSpecified"] boolValue]&&api.methodGetParamCount(method)!=[filter[@"argumentCount"] unsignedIntegerValue])continue;
                        } else if([methodName rangeOfString:text options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch].location==NSNotFound)continue;
                        NSDictionary *row=NMDLCopyMethod(api,method,identity,failure);if(!row)return nil;[results addObject:row];
                    }}
                }
                if(truncated)break;
            }}
            if(truncated)break;
        }
        if(!methodSearch){
            [results sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return NMDLCompareClasses(a,b);}];
            if(results.count>limit)[results removeObjectsInRange:NSMakeRange(limit,results.count-limit)];
            truncated=truncated||totalMatches>limit;
        }
        return @{@"kind":methodSearch?@"methods":@"classes",@"query":text,@"results":[results copy],@"count":@(results.count),@"scanned":@(scanned),@"methodsScanned":@(methodsScanned),@"matchesWithinScan":@(methodSearch?results.count:totalMatches),@"truncated":@(truncated)};
    } error:error];
}
- (NSDictionary *)methodsForClass:(NSDictionary *)identity limit:(NSUInteger)limit error:(NSError **)error {
    if(![identity isKindOfClass:NSDictionary.class]){if(error)*error=NMDLError(13,@"Class descriptor must be a dictionary");return nil;}
    for(NSString *key in @[@"assembly",@"namespace",@"class",@"fullType",@"runtimeIdentifier"]){if(![identity[key] isKindOfClass:NSString.class]){if(error)*error=NMDLError(13,@"Invalid class descriptor");return nil;}}
    if(!limit||limit>1024||![identity[@"runtimeIdentifier"] isEqual:_runtimeReport[@"runtimeIdentifier"]]){if(error)*error=NMDLError(14,@"Runtime changed or invalid method limit; search classes again");return nil;}
    NSMutableDictionary *frozen=[NSMutableDictionary dictionary];for(NSString *key in @[@"assembly",@"namespace",@"class",@"fullType",@"runtimeIdentifier"])frozen[key]=[identity[key] copy];
    NSDictionary *descriptor=[frozen copy];
    return [self withMetadata:^NSDictionary *(NMIL2CPPAPI api,void *domain,NSError *__strong *failure){
        size_t count=0;const void **assemblies=api.domainGetAssemblies(domain,&count);if(!assemblies||!count||count>4096){if(failure)*failure=NMDLError(11,@"Invalid assembly list");return nil;}
        void *matched=NULL;double deadline=NMDLTime()+2.0;
        for(size_t a=0;a<count;a++){
            const void *image=api.assemblyGetImage(assemblies[a]);if(!image||![NMDLString(api.imageGetName(image)) isEqual:descriptor[@"assembly"]])continue;
            size_t classes=api.imageGetClassCount(image);if(classes>2000000){if(failure)*failure=NMDLError(12,@"Invalid class count");return nil;}
            for(size_t c=0;c<classes;c++){ @autoreleasepool {
                if(c>=200000||NMDLTime()>deadline){if(failure)*failure=NMDLError(15,@"Class identity lookup exceeded bounds; narrow the query");return nil;}
                void *klass=api.imageGetClass(image,c);if(!klass)continue;
                if(![NMDLString(api.classGetName(klass)) isEqual:descriptor[@"class"]]||![NMDLString(api.classGetNamespace(klass)) isEqual:descriptor[@"namespace"]])continue;
                if(![NMDLTypeName(api,api.classGetType(klass)) isEqual:descriptor[@"fullType"]])continue;
                if(matched&&matched!=klass){if(failure)*failure=NMDLError(16,@"Ambiguous class identity; refusing first-match selection");return nil;}matched=klass;
            }}
        }
        if(!matched){if(failure)*failure=NMDLError(17,@"Class is no longer available; search again");return nil;}
        NSMutableArray *results=[NSMutableArray array];void *iterator=NULL;const void *method=NULL;BOOL truncated=NO;NSUInteger scanned=0;
        while((method=api.classGetMethods(matched,&iterator))){ @autoreleasepool {
            if(results.count>=limit||scanned++>=20000||NMDLTime()>deadline){truncated=YES;break;}
            NSDictionary *row=NMDLCopyMethod(api,method,descriptor,failure);if(!row)return nil;[results addObject:row];
        }}
        return @{@"kind":@"methods",@"class":descriptor,@"results":[results copy],@"count":@(results.count),@"truncated":@(truncated)};
    } error:error];
}
@end
