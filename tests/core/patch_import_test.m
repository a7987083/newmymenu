#import <Foundation/Foundation.h>
#import "NMPatchImport.h"
#include <stdio.h>
#include <stdlib.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL Patch import: %s\n",message);abort();}}
static NSData *json(id root){return [NSJSONSerialization dataWithJSONObject:root options:NSJSONWritingSortedKeys error:nil];}
static NMPatchImportDocument *parse(id root){NSError *e=nil;NMPatchImportDocument *d=[NMPatchImportDocument documentFromJSONData:json(root) error:&e];check(d&&!e,"valid Patch fixture");return d;}
int main(void){@autoreleasepool{
 NSError *error=nil;
 NSDictionary *input=@{@"targets":@{@"u":@"UnityFramework"},@"target":@"u",@"title":@"Feature",@"group":@"Test",@"patches":@[@{@"rva":@"0x10",@"patchData":@"0xAA:bb-CC_dd"},@{@"offset":@32,@"bytes":@[@0,@255]}]};
 NMPatchImportDocument *d=parse(input);check(d.candidates.count==2&&d.requiresBinaryValidation,"all candidates remain unvalidated binary data");
 check([d.candidates[0][@"target"] isEqual:@"UnityFramework"]&&[d.candidates[0][@"title"] isEqual:@"Feature"]&&[d.candidates[0][@"enabled"] isEqual:@"AABBCCDD"]&&[d.candidates[1][@"offset"] isEqual:@"0x20"],"legacy aliases/context/hex separators preserved");
 NSArray *invalidAddresses=@[@"-1",@(-1),@YES,@1.9,@"18446744073709551616",@"0x10000000000000000",@"+1"];
 for(id value in invalidAddresses)check(![NMPatchImportDocument documentFromJSONData:json(@{@"offset":value,@"bytes":@"11223344"}) error:&error]&&error.code==5,"invalid unsigned address cannot coerce or wrap");
 for(id bytes in @[@[@YES],@[@1.9],@[@(-1)],@[@256],@"XYZ",@"123",@[]])check(![NMPatchImportDocument documentFromJSONData:json(@{@"offset":@16,@"bytes":bytes}) error:&error]&&error.code==6,"invalid bytes cannot silently coerce");
 check(![NMPatchImportDocument documentFromJSONData:json(@[@{@"offset":@16,@"bytes":@"11223344"},@{@"offset":@32,@"bytes":@"bad-value"}]) error:&error]&&error.code==6,"one invalid explicit sibling rejects entire import");
 check(![NMPatchImportDocument documentFromJSONData:json(@{@"offset":@16,@"rva":@32,@"bytes":@"11223344"}) error:&error]&&error.code==2,"contradictory aliases never depend on dictionary order");
 check(parse(@{@"offset":@16,@"rva":@16,@"bytes":@"11223344"}).candidates.count==1,"equal aliases are supported");
 d=parse(@{@"offset":@"00000100",@"bytes":@"11223344"});check([d.candidates[0][@"offset"] isEqual:@"0x40"]&&[d.candidates[0][@"requiresReview"] boolValue]&&[d.candidates[0][@"addressInterpretation"] isEqual:@"legacy-octal"],"octal legacy meaning is explicit and review-required");
 check([parse(@{@"offset":@"0018",@"bytes":@"11223344"}).candidates[0][@"addressInterpretation"] isEqual:@"legacy-hex-fallback"],"ambiguous fallback remains review-required");
 NMPatchImportDocument *weak=parse(@{@"arbitrary":@"0x10",@"unrelated":@"AABBCCDD"});check([weak.candidates[0][@"confidence"] doubleValue]==.55&&[weak.candidates[0][@"requiresReview"] boolValue]&&weak.warnings.count,"weak heuristic remains a reviewable candidate");
 for(NMPatchImportDocument *document in @[d,weak]){NSData *saved=[document JSONDataWithError:&error];NMPatchImportDocument *again=[NMPatchImportDocument documentFromJSONData:saved error:&error];check(again&&!error&&[[again JSONDataWithError:&error] isEqual:saved]&&[again.candidates[0][@"requiresReview"] boolValue],"normalized roundtrip cannot promote weak/ambiguous provenance");}
 NSMutableDictionary *normalized=[NSJSONSerialization JSONObjectWithData:[weak JSONDataWithError:&error] options:NSJSONReadingMutableContainers error:nil];normalized[@"candidates"][0][@"requiresReview"]=@NO;check(![NMPatchImportDocument documentFromJSONData:json(normalized) error:&error]&&error.code==7,"inconsistent serialized review flag is rejected");
 NSArray *two=@[@{@"offset":@16,@"bytes":@"11223344",@"title":@"One"},@{@"offset":@16,@"bytes":@"11223344",@"title":@"Two"}];check(parse(two).candidates.count==2,"candidate extraction cannot silently erase distinct authored definitions");
 d=parse(@{@"targets":@{@"offset":@"UnityFramework"},@"patches":@[@{@"target":@"offset",@"offset":@16,@"bytes":@"11223344"}]});check(d.candidates.count==1&&[d.candidates[0][@"target"] isEqual:@"UnityFramework"],"pure alias tables are not interpreted as Patch records");
 d=parse(@{@"name":@42,@"patches":@[@{@"offset":@16,@"bytes":@"11223344"}]});check(d.candidates.count==1&&d.warnings.count,"unrelated nontext container labels do not erase valid descendants");
 check(![NMPatchImportDocument documentFromJSONData:json(@{@"format":@"zonoe-authoring",@"schemaVersion":@1}) error:&error]&&error.code==7,"authoring JSON cannot be routed into Patch heuristics");
 check(![NMPatchImportDocument documentFromJSONData:json(@[@{@"format":@"newmymenu.patch-candidates",@"candidates":@[]}]) error:&error]&&error.code==7,"nested typed documents cannot bypass provenance parsing");
 NSMutableArray *many=[NSMutableArray array];for(NSUInteger i=0;i<4097;i++)[many addObject:@{@"offset":@(i),@"bytes":@"11223344"}];check(![NMPatchImportDocument documentFromJSONData:json(many) error:&error]&&error.code==3,"candidate capacity never returns a partial list");[many removeLastObject];check(parse(many).candidates.count==4096,"exact candidate capacity remains supported");
 NSMutableArray *expanded=[NSMutableArray array];for(NSUInteger i=0;i<400;i++)[expanded addObject:@{@"offset":@(i),@"bytes":@"11223344"}];NSString *large=[@"A" stringByPaddingToLength:16384 withString:@"A" startingAtIndex:0];check(![NMPatchImportDocument documentFromJSONData:json(@{@"title":large,@"patches":expanded}) error:&error]&&error.code==3,"inherited label expansion is bounded before whole-output serialization");
 id deep=@{};for(NSUInteger i=0;i<70;i++)deep=@{@"child":deep};check(![NMPatchImportDocument documentFromJSONData:json(deep) error:&error]&&error.code==1,"nesting limits apply before recursive scanning");
 check(![NMPatchImportDocument documentFromJSONData:[@"{bad" dataUsingEncoding:NSUTF8StringEncoding] error:&error]&&error,"broken JSON reports failure");
 puts("PASS: bounded Patch candidates, exact numeric/byte validation, alias/context handling, atomic rejection and persistent review provenance; no binary applied");
 }return 0;}
