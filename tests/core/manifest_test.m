#import <Foundation/Foundation.h>
#import "NMBuildManifest.h"
#include <stdio.h>
#include <stdlib.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL manifest: %s\n",message);abort();}}
static NMBuildItem *item(NSString *provider,NSString *identifier,NMBuildItemDomain domain,NSDictionary *meta){NSError *e=nil;NMBuildItem *i=[NMBuildItem itemWithProvider:provider kind:@"fixture" identifier:identifier domain:domain metadata:meta error:&e];check(i&&!e,"fixture item created");return i;}
static NSData *data(id root){return [NSJSONSerialization dataWithJSONObject:root options:0 error:nil];}
int main(void){@autoreleasepool{
 NSError *error=nil;NSMutableDictionary *metadata=[@{@"values":[NSMutableArray arrayWithObject:@1]} mutableCopy];
 NMBuildItem *owned=item(@"a",@"one",NMBuildItemDomainStatic,metadata);[metadata[@"values"] addObject:@2];check([owned.metadata[@"values"] count]==1,"item metadata deep-frozen");
 NSMutableDictionary *input=[@{@"nested":[@{@"value":@7} mutableCopy]} mutableCopy];
 NMBuildProvider *a=[NMBuildProvider providerWithIdentifier:@"a" collector:^NSArray *(NSDictionary *configuration,NSError *__strong *failure){(void)failure;input[@"nested"][@"value"]=@9;return @[item(@"a",@"one",NMBuildItemDomainStatic,configuration)];}];
 NMBuildProvider *b=[NMBuildProvider providerWithIdentifier:@"b" collector:^NSArray *(NSDictionary *configuration,NSError *__strong *failure){(void)failure;return @[item(@"b",@"one",NMBuildItemDomainRuntime,configuration)];}];
 NMBuildManifest *manifest=[NMBuildManifest collectProviders:@[b,a] configuration:input error:&error];
 check(manifest&&!error&&manifest.items.count==2&&manifest.staticItemCount==1&&manifest.runtimeItemCount==1,"mixed domain counts derived from snapshot");
 check([manifest.activeProviderIdentifiers isEqual:@[@"a",@"b"]]&&[manifest.items[0].providerIdentifier isEqual:@"a"],"providers have deterministic order");
 check([manifest.items[0].metadata[@"nested"][@"value"] intValue]==7&&[manifest.items[1].metadata[@"nested"][@"value"] intValue]==7,"all collectors consume the same frozen configuration");
 NSData *encoded=[manifest JSONDataWithError:&error];NMBuildManifest *decoded=[NMBuildManifest manifestFromJSONData:encoded error:&error];check(decoded&&!error&&[[decoded JSONDataWithError:&error] isEqual:encoded],"manifest import/export byte-stable roundtrip");
 check([NMBuildManifest collectProviders:@[a,a] configuration:@{} error:&error]==nil&&error.code==5,"duplicate provider rejected before collect");
 NMBuildProvider *duplicate=[NMBuildProvider providerWithIdentifier:@"a" collector:^NSArray *(NSDictionary *c,NSError *__strong *e){(void)c;(void)e;return @[owned,owned];}];
 check([NMBuildManifest collectProviders:@[duplicate] configuration:@{} error:&error]==nil&&error.code==9,"duplicate provider/item identity rejected");
 NMBuildProvider *foreign=[NMBuildProvider providerWithIdentifier:@"b" collector:^NSArray *(NSDictionary *c,NSError *__strong *e){(void)c;(void)e;return @[owned];}];
 check([NMBuildManifest collectProviders:@[foreign] configuration:@{} error:&error]==nil&&error.code==8,"provider cannot forge item ownership");
 NMBuildProvider *throws=[NMBuildProvider providerWithIdentifier:@"throw" collector:^NSArray *(NSDictionary *c,NSError *__strong *e){(void)c;(void)e;[NSException raise:@"Fixture" format:@"collector failure"];return nil;}];
 check([NMBuildManifest collectProviders:@[throws] configuration:@{} error:&error]==nil&&error.code==6,"collector exception is failure, never empty success");
 NMBuildProvider *nilItems=[NMBuildProvider providerWithIdentifier:@"nil" collector:^NSArray *(NSDictionary *c,NSError *__strong *e){(void)c;(void)e;return nil;}];
 check([NMBuildManifest collectProviders:@[nilItems] configuration:@{} error:&error]==nil&&error.code==7,"nil without error rejected");
 NMBuildProvider *errorItems=[NMBuildProvider providerWithIdentifier:@"error" collector:^NSArray *(NSDictionary *c,NSError *__strong *e){(void)c;@autoreleasepool{*e=[NSError errorWithDomain:@"fixture" code:777 userInfo:nil];return @[];}}];
 check([NMBuildManifest collectProviders:@[errorItems] configuration:@{} error:&error]==nil&&error.code==777,"collector error retained before inner autoreleasepool drains");
 check([NMBuildManifest collectProviders:@[] configuration:@{} error:&error].items.count==0&&!error,"explicit empty provider list valid");
 NSMutableDictionary *root=[NSJSONSerialization JSONObjectWithData:encoded options:NSJSONReadingMutableContainers error:nil];
 root[@"schemaVersion"]=@YES;check([NMBuildManifest manifestFromJSONData:data(root) error:&error]==nil&&error.code==12,"boolean cannot masquerade as schema version");root[@"schemaVersion"]=@1;
 root[@"extra"]=@0;check([NMBuildManifest manifestFromJSONData:data(root) error:&error]==nil&&error.code==12,"unknown root key rejected");[root removeObjectForKey:@"extra"];
 root[@"items"][0][@"domain"]=@YES;check([NMBuildManifest manifestFromJSONData:data(root) error:&error]==nil&&error.code==13,"boolean cannot masquerade as item domain");root[@"items"][0][@"domain"]=@1.5;
 check([NMBuildManifest manifestFromJSONData:data(root) error:&error]==nil&&error.code==13,"fractional domain rejected");root[@"items"][0][@"domain"]=@1;
 [root[@"items"] addObject:root[@"items"][0]];check([NMBuildManifest manifestFromJSONData:data(root) error:&error]==nil&&error.code==9,"duplicate JSON identity rejected");
 check([NMBuildManifest manifestFromJSONData:[@"{bad" dataUsingEncoding:NSUTF8StringEncoding] error:&error]==nil&&error,"broken JSON returns error");
 check([NMBuildItem itemWithProvider:@"a" kind:@"x" identifier:@"id" domain:3 metadata:@{} error:&error]==nil&&error.code==3,"invalid enum rejected");
 check([NMBuildItem itemWithProvider:@"a" kind:@"x" identifier:@"id" domain:1 metadata:(id)@[] error:&error]==nil&&error.code==1,"metadata root must be dictionary");
 puts("PASS: immutable mixed Manifest, frozen collector inputs, explicit failures/ownership/duplicates and strict versioned JSON roundtrip");
 }return 0;}
