#import "NMBuildManifest.h"
#import <CoreFoundation/CoreFoundation.h>
static NSError *NMBError(NSInteger code,NSString *text){return [NSError errorWithDomain:@"newmymenu.manifest" code:code userInfo:@{NSLocalizedDescriptionKey:text}];}
static BOOL NMBName(id name){return [name isKindOfClass:NSString.class]&&[name length]>0&&[name length]<=1024;}
static NSDictionary *NMBFreeze(id input,NSError **error){
    if(![input isKindOfClass:NSDictionary.class]||![NSJSONSerialization isValidJSONObject:input]){if(error)*error=NMBError(1,@"Manifest input must be a JSON dictionary");return nil;}
    NSError *failure=nil;NSData *data=[NSJSONSerialization dataWithJSONObject:input options:NSJSONWritingSortedKeys error:&failure];
    if(!data||data.length>4*1024*1024){if(error)*error=failure?:NMBError(2,@"Manifest JSON exceeds 4 MiB");return nil;}
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}
static BOOL NMBKeys(NSDictionary *object,NSArray *keys){return [[NSSet setWithArray:object.allKeys] isEqualToSet:[NSSet setWithArray:keys]];}
@interface NMBuildItem ()
- (instancetype)initPrivate;
@end
@implementation NMBuildItem
- (instancetype)initPrivate{return [super init];}
+ (instancetype)itemWithProvider:(NSString *)provider kind:(NSString *)kind identifier:(NSString *)identifier domain:(NMBuildItemDomain)domain metadata:(NSDictionary *)metadata error:(NSError **)error {
    if(!NMBName(provider)||!NMBName(kind)||!NMBName(identifier)||(domain!=NMBuildItemDomainStatic&&domain!=NMBuildItemDomainRuntime)){if(error)*error=NMBError(3,@"Invalid BuildItem identity or domain");return nil;}
    NSDictionary *frozen=NMBFreeze(metadata,error);if(!frozen)return nil;
    NMBuildItem *item=[[self alloc] initPrivate];item->_providerIdentifier=[provider copy];item->_kind=[kind copy];item->_identifier=[identifier copy];item->_domain=domain;item->_metadata=frozen;if(error)*error=nil;return item;
}
@end
@interface NMBuildProvider ()
@property(nonatomic,copy) NMBuildCollector collector;
- (instancetype)initPrivate;
@end
@implementation NMBuildProvider
- (instancetype)initPrivate{return [super init];}
+ (instancetype)providerWithIdentifier:(NSString *)identifier collector:(NMBuildCollector)collector {
    if(!NMBName(identifier)||!collector)return nil;
    NMBuildProvider *provider=[[self alloc] initPrivate];provider->_identifier=[identifier copy];provider->_collector=[collector copy];return provider;
}
@end
@interface NMBuildManifest ()
- (instancetype)initWithItems:(NSArray<NMBuildItem *> *)items;
@end
@implementation NMBuildManifest
- (instancetype)initWithItems:(NSArray<NMBuildItem *> *)items {
    self=[super init];if(self){_items=[items copy];NSMutableSet *active=[NSMutableSet set];for(NMBuildItem *item in items)[active addObject:item.providerIdentifier];_activeProviderIdentifiers=[[active allObjects] sortedArrayUsingSelector:@selector(compare:)];}return self;
}
- (NSUInteger)staticItemCount {NSUInteger count=0;for(NMBuildItem *item in _items)if(item.domain==NMBuildItemDomainStatic)count++;return count;}
- (NSUInteger)runtimeItemCount {return _items.count-self.staticItemCount;}
+ (instancetype)collectProviders:(NSArray<NMBuildProvider *> *)providers configuration:(NSDictionary *)configuration error:(NSError **)error {
    @try {
        NSDictionary *input=NMBFreeze(configuration,error);if(!input)return nil;
        if(![providers isKindOfClass:NSArray.class]||providers.count>128){if(error)*error=NMBError(4,@"Invalid provider collection");return nil;}
        NSArray *snapshot=[providers copy];NSMutableSet *names=[NSMutableSet set];
        for(NMBuildProvider *p in snapshot){if(![p isKindOfClass:NMBuildProvider.class]||[names containsObject:p.identifier]){if(error)*error=NMBError(5,@"Duplicate or invalid provider");return nil;}[names addObject:p.identifier];}
        snapshot=[snapshot sortedArrayUsingComparator:^NSComparisonResult(NMBuildProvider *a,NMBuildProvider *b){return [a.identifier compare:b.identifier];}];
        NSMutableArray *items=[NSMutableArray array];NSMutableSet *identities=[NSMutableSet set];
        for(NMBuildProvider *provider in snapshot){
            NSError *failure=nil;NSArray *provided=nil;
            @try{provided=provider.collector(input,&failure);}@catch(NSException *exception){failure=NMBError(6,[NSString stringWithFormat:@"Provider %@ raised %@: %@",provider.identifier,exception.name,exception.reason?:@""]);}
            if(failure){if(error)*error=failure;return nil;}
            if(![provided isKindOfClass:NSArray.class]||provided.count>4096-items.count){if(error)*error=NMBError(7,[NSString stringWithFormat:@"Provider %@ returned invalid/oversized items",provider.identifier]);return nil;}
            for(NMBuildItem *item in [provided copy]){
                if(![item isKindOfClass:NMBuildItem.class]||![item.providerIdentifier isEqual:provider.identifier]){if(error)*error=NMBError(8,@"BuildItem does not belong to its provider");return nil;}
                NSArray *key=@[item.providerIdentifier,item.identifier];if([identities containsObject:key]){if(error)*error=NMBError(9,@"Duplicate provider/item identity");return nil;}[identities addObject:key];[items addObject:item];
            }
        }
        if(error)*error=nil;return [[self alloc] initWithItems:items];
    }@catch(NSException *exception){if(error)*error=NMBError(10,[NSString stringWithFormat:@"Manifest collection failed: %@",exception.reason?:exception.name]);return nil;}
}
- (NSData *)JSONDataWithError:(NSError **)error {
    NSMutableArray *rows=[NSMutableArray array];for(NMBuildItem *item in _items)[rows addObject:@{@"provider":item.providerIdentifier,@"kind":item.kind,@"identifier":item.identifier,@"domain":@(item.domain),@"metadata":item.metadata}];
    NSData *data=[NSJSONSerialization dataWithJSONObject:@{@"format":@"newmymenu.manifest",@"schemaVersion":@1,@"items":rows} options:NSJSONWritingSortedKeys error:error];
    if(data.length>4*1024*1024){if(error)*error=NMBError(2,@"Manifest JSON exceeds 4 MiB");return nil;}
    if(data&&error)*error=nil;return data;
}
+ (instancetype)manifestFromJSONData:(NSData *)data error:(NSError **)error {
    if(![data isKindOfClass:NSData.class]||data.length>4*1024*1024){if(error)*error=NMBError(11,@"Manifest input exceeds 4 MiB");return nil;}
    id root=[NSJSONSerialization JSONObjectWithData:data options:0 error:error];if(!root)return nil;
    if(![root isKindOfClass:NSDictionary.class]||!NMBKeys(root,@[@"format",@"schemaVersion",@"items"])||![root[@"format"] isEqual:@"newmymenu.manifest"]||![root[@"schemaVersion"] isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)root[@"schemaVersion"])==CFBooleanGetTypeID()||![root[@"schemaVersion"] isEqual:@1]||![root[@"items"] isKindOfClass:NSArray.class]||[root[@"items"] count]>4096){if(error)*error=NMBError(12,@"Unsupported Manifest schema");return nil;}
    NSMutableArray *items=[NSMutableArray array];NSMutableSet *identities=[NSMutableSet set];
    for(id row in root[@"items"]){
        if(![row isKindOfClass:NSDictionary.class]||!NMBKeys(row,@[@"provider",@"kind",@"identifier",@"domain",@"metadata"])||![row[@"domain"] isKindOfClass:NSNumber.class]||CFGetTypeID((__bridge CFTypeRef)row[@"domain"])==CFBooleanGetTypeID()||(![row[@"domain"] isEqual:@1]&&![row[@"domain"] isEqual:@2])){if(error)*error=NMBError(13,@"Invalid BuildItem schema");return nil;}
        NMBuildItem *item=[NMBuildItem itemWithProvider:row[@"provider"] kind:row[@"kind"] identifier:row[@"identifier"] domain:(NMBuildItemDomain)[row[@"domain"] unsignedIntegerValue] metadata:row[@"metadata"] error:error];if(!item)return nil;
        NSArray *key=@[item.providerIdentifier,item.identifier];if([identities containsObject:key]){if(error)*error=NMBError(9,@"Duplicate provider/item identity");return nil;}[identities addObject:key];[items addObject:item];
    }
    if(error)*error=nil;return [[self alloc] initWithItems:items];
}
@end
