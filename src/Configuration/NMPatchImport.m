#import "NMPatchImport.h"
#import <CoreFoundation/CoreFoundation.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
static const NSUInteger NMPBudget=4*1024*1024;
@interface NMPParseState : NSObject
@property(nonatomic,strong) NSMutableArray *rows;
@property(nonatomic,strong) NSMutableSet *warnings;
@property(nonatomic,strong) NSMutableSet *aliasOnlyTables;
@property(nonatomic,strong,nullable) NSError *failure;
@property(nonatomic,assign) NSUInteger outputBytes;
@end
@implementation NMPParseState
- (instancetype)init{self=[super init];if(self){_rows=[NSMutableArray array];_warnings=[NSMutableSet set];_aliasOnlyTables=[NSMutableSet set];_outputBytes=128;}return self;}
@end
static BOOL NMPFail(NMPParseState *s,NSInteger code,NSString *message){if(!s.failure)s.failure=[NSError errorWithDomain:@"newmymenu.patch-import" code:code userInfo:@{NSLocalizedDescriptionKey:message}];return NO;}
static BOOL NMPBoolean(id value){return [value isKindOfClass:NSNumber.class]&&CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID();}
static BOOL NMPText(id value){return [value isKindOfClass:NSString.class]&&[value length]<=16384;}
static NSString *NMPTrim(NSString *value){return [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];}
static BOOL NMPTree(id node,NSUInteger depth,NSUInteger *count){if(depth>64||*count>=65536)return NO;(*count)++;if([node isKindOfClass:NSDictionary.class]){for(NSString *key in node){if(key.length>1024||!NMPTree(node[key],depth+1,count))return NO;}}else if([node isKindOfClass:NSArray.class])for(id child in node)if(!NMPTree(child,depth+1,count))return NO;return YES;}
// Key aliases and separators follow the fixed original Patch importer.
static NSString *NMPKey(NSString *key){NSString *text=key.lowercaseString;return [[text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_- .\t\r\n"]] componentsJoinedByString:@""];}
static id NMPValue(NSDictionary *dict,NSArray *names,NMPParseState *s){id value=nil;for(NSString *key in [dict.allKeys sortedArrayUsingSelector:@selector(compare:)])if([names containsObject:NMPKey(key)]){if(value&&![value isEqual:dict[key]]){NMPFail(s,2,[NSString stringWithFormat:@"Conflicting aliases for %@",names.firstObject]);return nil;}value=dict[key];}return value;}
static BOOL NMPUnsigned(NSString *text,int base,uint64_t max,uint64_t *out){if(!text.length||text.length>32||[text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(0,1)]].location!=NSNotFound||[text hasPrefix:@"-"]||[text hasPrefix:@"+"])return NO;const char *bytes=text.UTF8String;if(!bytes)return NO;char *end=NULL;errno=0;unsigned long long number=strtoull(bytes,&end,base);if(errno||end==bytes||!end||*end||number>max)return NO;*out=number;return YES;}
static BOOL NMPAddress(id value,uint64_t *out,NSString **interpretation){
 if([value isKindOfClass:NSNumber.class]){if(NMPBoolean(value))return NO;NSString *text=[value stringValue];if([text rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location!=NSNotFound)return NO;if(!NMPUnsigned(text,10,UINT64_MAX,out))return NO;*interpretation=@"numeric";return YES;}
 if(!NMPText(value))return NO;NSString *text=NMPTrim(value);BOOL hex=[text.lowercaseString hasPrefix:@"0x"],digits=[text rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location==NSNotFound;
 BOOL ambiguous=!hex&&digits&&text.length>1&&[text hasPrefix:@"0"];
 if(NMPUnsigned(text,0,UINT64_MAX,out)){*interpretation=ambiguous?@"legacy-octal":(hex?@"hex":@"decimal");return YES;}
 if(NMPUnsigned(text,16,UINT64_MAX,out)){*interpretation=ambiguous?@"legacy-hex-fallback":@"hex";return YES;}return NO;
}
static NSString *NMPHex(id value){
 if([value isKindOfClass:NSArray.class]){NSMutableString *text=[NSMutableString string];for(id byte in value){if(![byte isKindOfClass:NSNumber.class]||NMPBoolean(byte))return nil;NSString *number=[byte stringValue];if([number rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location!=NSNotFound)return nil;uint64_t n=0;if(!NMPUnsigned(number,10,255,&n))return nil;[text appendFormat:@"%02llX",(unsigned long long)n];}return text.length?[text copy]:nil;}
 if(![value isKindOfClass:NSString.class])return nil;NSString *input=NMPTrim(value);NSMutableString *text=[NSMutableString string];NSCharacterSet *hex=[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
 for(NSUInteger i=0;i<input.length;i++){unichar c=[input characterAtIndex:i];if([NSCharacterSet.whitespaceAndNewlineCharacterSet characterIsMember:c]||c==':'||c=='-'||c==','||c=='_')continue;if((c=='x'||c=='X')&&text.length==1&&[text isEqual:@"0"]){[text setString:@""];continue;}if(![hex characterIsMember:c])return nil;[text appendFormat:@"%C",c];}
 return text.length&&!(text.length&1)?text.uppercaseString:nil;
}
static BOOL NMPAmbiguous(NSString *kind){return [kind isEqual:@"legacy-octal"]||[kind isEqual:@"legacy-hex-fallback"];}
static BOOL NMPAdd(NMPParseState *s,NSString *target,uint64_t address,NSString *hex,NSString *title,NSString *group,NSString *path,double confidence,NSString *interpretation){
 if(s.rows.count>=4096)return NMPFail(s,3,@"Patch candidate limit exceeded");
 for(NSString *field in @[target,title,group,path])if(!NMPText(field))return NMPFail(s,3,@"Patch text/JSON path exceeds 16384 characters");
 if([target rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(0,1)]].location!=NSNotFound)return NMPFail(s,4,@"Target contains NUL and cannot be a file/image identifier");
 BOOL review=confidence<1||NMPAmbiguous(interpretation);
 NSDictionary *row=@{@"target":[target copy],@"offset":[NSString stringWithFormat:@"0x%llX",(unsigned long long)address],@"enabled":[hex copy],@"title":[title copy],@"group":group.length?[group copy]:@"Imported",@"path":[path copy],@"confidence":@(confidence),@"requiresReview":@(review),@"addressInterpretation":interpretation};
 NSData *encoded=[NSJSONSerialization dataWithJSONObject:row options:NSJSONWritingSortedKeys error:NULL];if(!encoded||encoded.length+1>NMPBudget-s.outputBytes)return NMPFail(s,3,@"Normalized Patch output exceeds 4 MiB");s.outputBytes+=encoded.length+1;[s.rows addObject:row];
 if(confidence<1)[s.warnings addObject:@"Unlabelled candidate requires manual review"];
 if(NMPAmbiguous(interpretation))[s.warnings addObject:@"Leading-zero address retains legacy interpretation and requires manual review"];
 return YES;
}
static NSString *NMPContext(NSDictionary *d,NSArray *names,NSString *parent,BOOL strict,NMPParseState *s){id value=NMPValue(d,names,s);if(s.failure)return nil;if(!value)return parent;if(!NMPText(value)){if([value isKindOfClass:NSString.class]||strict){NMPFail(s,4,@"Patch target/title/group must be text within bounds");return nil;}[s.warnings addObject:@"Nontext container metadata was not inherited as a Patch label/target"];return parent;}NSString *text=NMPTrim(value);return text.length?text:parent;}
static NSDictionary *NMPAliases(id root,NMPParseState *s){
 if(![root isKindOfClass:NSDictionary.class])return @{};
 NSArray *tableNames=@[@"targets",@"images",@"modules",@"binaries"],*imageNames=@[@"target",@"image",@"binary",@"module",@"modulename",@"executable"];
 id table=NMPValue(root,tableNames,s);if(s.failure)return nil;if(![table isKindOfClass:NSDictionary.class])return @{};
 NSMutableDictionary *aliases=[NSMutableDictionary dictionary];BOOL pure=YES;
 for(NSString *key in table){id value=table[key];if([value isKindOfClass:NSDictionary.class]){for(NSString *field in value)if(![imageNames containsObject:NMPKey(field)])pure=NO;value=NMPValue(value,imageNames,s);}else if(![value isKindOfClass:NSString.class])pure=NO;
 if(s.failure)return nil;if(![value isKindOfClass:NSString.class]){pure=NO;continue;}if(!NMPText(value)||!NMPTrim(value).length){NMPFail(s,4,@"Invalid target alias mapping");return nil;}
 NSString *alias=NMPTrim(key).lowercaseString,*image=NMPTrim(value);if(aliases[alias]&&![aliases[alias] isEqual:image]){NMPFail(s,2,@"Case-folded target aliases conflict");return nil;}aliases[alias]=image;
 }
 if(pure)for(NSString *key in root)if([tableNames containsObject:NMPKey(key)])[s.aliasOnlyTables addObject:key];
 return [aliases copy];
}
static BOOL NMPWalk(id node,NSString *path,NSString *parentTarget,NSString *parentTitle,NSString *parentGroup,NSDictionary *aliases,NMPParseState *s){
 if([node isKindOfClass:NSArray.class]){NSUInteger i=0;for(id child in node){@autoreleasepool{if(!NMPWalk(child,[path stringByAppendingFormat:@"[%lu]",(unsigned long)i++],parentTarget,parentTitle,parentGroup,aliases,s))return NO;}}return YES;}
 if(![node isKindOfClass:NSDictionary.class])return YES;
 NSDictionary *d=node;
 if([@[@"zonoe-authoring",@"newmymenu.authoring",@"newmymenu.manifest",@"newmymenu.patch-candidates"] containsObject:d[@"format"]])return NMPFail(s,7,@"Nested typed configuration must be imported through its own domain");
 id offset=NMPValue(d,@[@"offset",@"rva",@"address",@"addr",@"location"],s),bytes=NMPValue(d,@[@"enabled",@"patch",@"patchdata",@"bytes",@"patchbytes",@"data",@"value",@"on",@"enable",@"replacement",@"replace"],s);if(s.failure)return NO;
 NSString *target=NMPContext(d,@[@"target",@"image",@"binary",@"module",@"modulename",@"executable"],parentTarget,offset!=nil,s),*title=NMPContext(d,@[@"title",@"name",@"label",@"featuretitle"],parentTitle,offset!=nil,s),*group=NMPContext(d,@[@"group",@"category",@"section",@"tab"],parentGroup,offset!=nil,s);if(s.failure)return NO;target=aliases[target.lowercaseString]?:target;
 if(offset){uint64_t address=0;NSString *kind=nil;if(!NMPAddress(offset,&address,&kind))return NMPFail(s,5,[NSString stringWithFormat:@"Invalid unsigned Patch address at %@",path]);NSString *hex=NMPHex(bytes);if(!hex)return NMPFail(s,6,[NSString stringWithFormat:@"Invalid or missing Patch bytes at %@",path]);if(!NMPAdd(s,target,address,hex,title,group,path,1,kind))return NO;}
 else if(!bytes){NSMutableArray *addresses=[NSMutableArray array],*hexes=[NSMutableArray array];for(NSString *key in [d.allKeys sortedArrayUsingSelector:@selector(compare:)]){id value=d[key];if(![value isKindOfClass:NSString.class])continue;NSString *text=NMPTrim(value);if([text.lowercaseString hasPrefix:@"0x"]){uint64_t address=0;NSString *kind=nil;if(NMPAddress(text,&address,&kind))[addresses addObject:@(address)];}else{NSString *hex=NMPHex(text);if(hex.length>=8&&!(hex.length%8))[hexes addObject:hex];}}
 if(addresses.count==1&&hexes.count==1&&!NMPAdd(s,target,[addresses.firstObject unsignedLongLongValue],hexes.firstObject,title,group,path,.55,@"hex"))return NO;}
 else [s.warnings addObject:@"Patch-like metadata without an address was not promoted to a candidate"];
 for(NSString *key in [d.allKeys sortedArrayUsingSelector:@selector(compare:)]){@autoreleasepool{if([path isEqual:@"$"]&&[s.aliasOnlyTables containsObject:key])continue;id value=d[key];if([value isKindOfClass:NSArray.class]||[value isKindOfClass:NSDictionary.class])if(!NMPWalk(value,[path stringByAppendingFormat:@".%@",key],target,title,group,aliases,s))return NO;}}
 return YES;
}
static BOOL NMPCanonical(NSDictionary *root,NMPParseState *s){
 if(![[NSSet setWithArray:root.allKeys] isEqual:[NSSet setWithArray:@[@"format",@"schemaVersion",@"candidates"]]]||NMPBoolean(root[@"schemaVersion"])||![root[@"schemaVersion"] isEqual:@1]||![root[@"candidates"] isKindOfClass:NSArray.class])return NMPFail(s,7,@"Invalid Patch candidate schema");
 NSSet *keys=[NSSet setWithArray:@[@"target",@"offset",@"enabled",@"title",@"group",@"path",@"confidence",@"requiresReview",@"addressInterpretation"]];
 for(id row in root[@"candidates"]){if(![row isKindOfClass:NSDictionary.class]||![[NSSet setWithArray:[row allKeys]] isEqual:keys])return NMPFail(s,7,@"Invalid candidate fields");for(NSString *key in @[@"target",@"offset",@"enabled",@"title",@"group",@"path",@"addressInterpretation"])if(!NMPText(row[key]))return NMPFail(s,7,@"Candidate text field invalid");
 NSString *kind=row[@"addressInterpretation"];id number=row[@"confidence"];if(![@[@"numeric",@"decimal",@"hex",@"legacy-octal",@"legacy-hex-fallback"] containsObject:kind]||![number isKindOfClass:NSNumber.class]||NMPBoolean(number)||([number doubleValue]!=1&&[number doubleValue]!=.55)||!NMPBoolean(row[@"requiresReview"])||[row[@"requiresReview"] boolValue]!=([number doubleValue]<1||NMPAmbiguous(kind)))return NMPFail(s,7,@"Candidate confidence/review provenance is inconsistent");
 uint64_t address=0;NSString *ignored=nil,*hex=NMPHex(row[@"enabled"]);if(!NMPAddress(row[@"offset"],&address,&ignored)||!hex)return NMPFail(s,7,@"Invalid normalized address/bytes");if(!NMPAdd(s,row[@"target"],address,hex,row[@"title"],row[@"group"],row[@"path"],[number doubleValue],kind))return NO;}
 return YES;
}
@interface NMPatchImportDocument ()
- (instancetype)initRows:(NSArray *)rows warnings:(NSArray *)warnings;
@end
@implementation NMPatchImportDocument
- (instancetype)initRows:(NSArray *)rows warnings:(NSArray *)warnings{self=[super init];if(self){_candidates=[rows copy];_warnings=[warnings copy];}return self;}
- (BOOL)requiresBinaryValidation{return YES;}
+ (instancetype)documentFromJSONData:(NSData *)data error:(NSError **)error {
 NMPParseState *s=[NMPParseState new];NMPatchImportDocument *document=nil;
 @try{if(![data isKindOfClass:NSData.class]||!data.length||data.length>NMPBudget){NMPFail(s,1,@"Patch JSON must be nonempty and within 4 MiB");}
 else{id root=[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];NSUInteger nodes=0;if((![root isKindOfClass:NSDictionary.class]&&![root isKindOfClass:NSArray.class])||!NMPTree(root,0,&nodes))NMPFail(s,1,@"Patch JSON shape, nesting or complexity is invalid");
 else {BOOL ok=NO;id format=[root isKindOfClass:NSDictionary.class]?root[@"format"]:nil;
 if([format isEqual:@"newmymenu.patch-candidates"])ok=NMPCanonical(root,s);
 else if([@[@"zonoe-authoring",@"newmymenu.authoring",@"newmymenu.manifest"] containsObject:format])NMPFail(s,7,@"This JSON belongs to another configuration domain");
 else {NSDictionary *aliases=NMPAliases(root,s);if(aliases)ok=NMPWalk(root,@"$",@"",@"",@"Imported",aliases,s);}
 if(ok&&!s.rows.count)NMPFail(s,8,@"No addressed Patch records or reviewable candidates found");
 if(ok&&!s.failure)document=[[self alloc] initRows:s.rows warnings:[[s.warnings allObjects] sortedArrayUsingSelector:@selector(compare:)]];
 }}
 }@catch(NSException *exception){NMPFail(s,9,exception.reason?:exception.name);document=nil;}
 if(error)*error=s.failure;return s.failure?nil:document;
}
- (NSData *)JSONDataWithError:(NSError **)error{NSData *data=[NSJSONSerialization dataWithJSONObject:@{@"format":@"newmymenu.patch-candidates",@"schemaVersion":@1,@"candidates":_candidates} options:NSJSONWritingSortedKeys error:error];if(data.length>NMPBudget){if(error)*error=[NSError errorWithDomain:@"newmymenu.patch-import" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Patch candidate output exceeds 4 MiB"}];return nil;}if(data&&error)*error=nil;return data;}
@end
