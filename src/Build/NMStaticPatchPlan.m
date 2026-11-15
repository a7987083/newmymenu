#import "NMStaticPatchPlan.h"
#import "NMARM64Relocation.h"
#import <CommonCrypto/CommonDigest.h>
#include <string.h>
static NSError *NMSPError(NSInteger code,NSString *text){return [NSError errorWithDomain:@"newmymenu.static-plan" code:code userInfo:@{NSLocalizedDescriptionKey:text}];}
static BOOL NMSPText(id s){return [s isKindOfClass:NSString.class]&&[s length]&&[s length]<=1024&&[s rangeOfCharacterFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(0,1)]].location==NSNotFound;}
@interface NMStaticPatchDefinition ()
- (instancetype)initIdentifier:(NSString *)identifier kind:(NMMachOAddressKind)kind address:(uint64_t)address expected:(NSData *)expected replacement:(NSData *)replacement evidence:(NSString *)evidence;
@end
@implementation NMStaticPatchDefinition
- (instancetype)initIdentifier:(NSString *)identifier kind:(NMMachOAddressKind)kind address:(uint64_t)address expected:(NSData *)expected replacement:(NSData *)replacement evidence:(NSString *)evidence {self=[super init];if(self){_identifier=[identifier copy];_addressKind=kind;_address=address;_expectedBytes=[expected copy];_replacementBytes=[replacement copy];_expectedBytesSource=[evidence copy];}return self;}
+ (instancetype)definitionWithIdentifier:(NSString *)identifier kind:(NMMachOAddressKind)kind address:(uint64_t)address expected:(NSData *)expected replacement:(NSData *)replacement evidence:(NSString *)evidence error:(NSError **)error {
 if(error)*error=nil;
 if(!NMSPText(identifier)||!NMSPText(evidence)||kind<1||kind>3||![expected isKindOfClass:NSData.class]||![replacement isKindOfClass:NSData.class]||!expected.length||expected.length>65536||(expected.length&3)||replacement.length!=expected.length){if(error)*error=NMSPError(1,@"Invalid identity, explicit expected-byte evidence, address kind or aligned equal-length bytes");return nil;}
 return [[self alloc] initIdentifier:identifier kind:kind address:address expected:expected replacement:replacement evidence:evidence];
}
@end
static uint32_t NMSPRead32(const uint8_t *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
@interface NMStaticPatchPlan ()
- (instancetype)initDefinitions:(NSArray *)definitions sites:(NSArray *)sites mapping:(NSArray *)mapping source:(NSData *)source imageBase:(uint64_t)imageBase;
@end
@implementation NMStaticPatchPlan
- (instancetype)initDefinitions:(NSArray *)definitions sites:(NSArray *)sites mapping:(NSArray *)mapping source:(NSData *)source imageBase:(uint64_t)imageBase {self=[super init];if(self){_definitions=[definitions copy];_physicalSites=[sites copy];_logicalToPhysical=[mapping copy];_sourceLength=source.length;_imageBase=imageBase;unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(source.bytes,(CC_LONG)source.length,digest);NSMutableString *hex=[NSMutableString string];for(NSUInteger i=0;i<sizeof digest;i++)[hex appendFormat:@"%02x",digest[i]];_sourceSHA256=[hex copy];}return self;}
- (BOOL)requiresRelocationValidation{return YES;}
+ (instancetype)planForMachO:(NSData *)source definitions:(NSArray<NMStaticPatchDefinition *> *)definitions error:(NSError **)error {
 if(error)*error=nil;
 if(![source isKindOfClass:NSData.class]||!source.length||source.length>256*1024*1024||![definitions isKindOfClass:NSArray.class]||!definitions.count||definitions.count>256){if(error)*error=NMSPError(2,@"Source/definition capacity invalid");return nil;}
 // Frozen input is the only byte owner used for mapping, comparison, scan and hash.
 NSData *image=[source copy];NSArray *input=[definitions copy];NMMachOLayout layout;
 if(!NMMachOReadLayout(image.bytes,image.length,&layout)){if(error)*error=NMSPError(3,@"Unsupported or malformed Mach-O layout");return nil;}
 NSMutableSet *identifiers=[NSMutableSet set];NSMutableDictionary<NSNumber *,NSMutableArray *> *groups=[NSMutableDictionary dictionary];NSMutableArray *logicalRVAs=[NSMutableArray array];NSUInteger budget=0;
 for(id value in input){
  if([value class]!=NMStaticPatchDefinition.class){if(error)*error=NMSPError(1,@"Definitions must be concrete immutable factory values");return nil;}
  NMStaticPatchDefinition *d=value;
  if(!NMSPText(d.identifier)||!NMSPText(d.expectedBytesSource)||!d.expectedBytes.length||d.expectedBytes.length>65536||(d.expectedBytes.length&3)||d.replacementBytes.length!=d.expectedBytes.length||d.addressKind<1||d.addressKind>3){if(error)*error=NMSPError(1,@"Invalid immutable definition fields");return nil;}
  if([identifiers containsObject:d.identifier]){if(error)*error=NMSPError(4,@"Duplicate logical identifier");return nil;}[identifiers addObject:d.identifier];
  if(d.replacementBytes.length>4*1024*1024-budget){if(error)*error=NMSPError(2,@"Replacement budget exceeds 4 MiB");return nil;}budget+=d.replacementBytes.length;
  uint64_t off=0,rva=0;
  if(!NMMachOResolveRange(&layout,d.addressKind,d.address,d.expectedBytes.length,&off,&rva)||!NMMachOIsInstructionRange(&layout,rva,d.expectedBytes.length)){if(error)*error=NMSPError(5,@"Patch span is not a verified instruction section range");return nil;}
  if(memcmp((const uint8_t *)image.bytes+off,d.expectedBytes.bytes,d.expectedBytes.length)){if(error)*error=NMSPError(6,@"Expected bytes differ from frozen file bytes");return nil;}
  NSNumber *key=@(rva);NSMutableArray *members=groups[key];if(!members){members=[NSMutableArray array];groups[key]=members;}[members addObject:@(logicalRVAs.count)];[logicalRVAs addObject:key];
 }
 NSArray *keys=[groups.allKeys sortedArrayUsingSelector:@selector(compare:)];NSMutableArray *sites=[NSMutableArray array],*mapping=[NSMutableArray arrayWithCapacity:input.count];for(NSUInteger i=0;i<input.count;i++)[mapping addObject:@0];
 uint64_t starts[256],lengths[256],previousEnd=0;NSUInteger composedBudget=0;
 for(NSNumber *key in keys){
  uint64_t rva=key.unsignedLongLongValue,window=0,off=0,ignored=0;NSArray *members=groups[key];
  for(NSNumber *i in members){NMStaticPatchDefinition *d=input[i.unsignedIntegerValue];if(d.expectedBytes.length>window)window=d.expectedBytes.length;}
  if((sites.count&&rva<previousEnd)||!NMMachOResolveRange(&layout,NMMachOAddressRVA,rva,window,&off,&ignored)||!NMMachOIsInstructionRange(&layout,rva,window)){if(error)*error=NMSPError(7,@"Different-start overlapping windows or invalid physical span");return nil;}
  NSData *original=[image subdataWithRange:NSMakeRange((NSUInteger)off,(NSUInteger)window)];NSMutableArray *variants=[NSMutableArray array],*variantIndexes=[NSMutableArray array];
  for(NSNumber *i in members){NMStaticPatchDefinition *d=input[i.unsignedIntegerValue];
   if(window>16*1024*1024-composedBudget){if(error)*error=NMSPError(2,@"Composed variants exceed 16 MiB");return nil;}composedBudget+=(NSUInteger)window;
   NSMutableData *v=[original mutableCopy];[v replaceBytesInRange:NSMakeRange(0,d.replacementBytes.length) withBytes:d.replacementBytes.bytes];NSData *frozen=[v copy];NSUInteger index=[variants indexOfObject:frozen];if(index==NSNotFound){index=variants.count;[variants addObject:frozen];}[variantIndexes addObject:@(index)];mapping[i.unsignedIntegerValue]=@(sites.count);
  }
  starts[sites.count]=rva;lengths[sites.count]=window;previousEnd=rva+window;
  [sites addObject:@{@"rva":key,@"fileOffset":@(off),@"window":@(window),@"original":original,@"logicalIndexes":[members copy],@"variants":[variants copy],@"logicalVariantIndexes":[variantIndexes copy]}];
 }
 uint64_t scanBytes=0;for(size_t i=0;i<layout.instructionCount;i++){if(layout.instructions[i].length>64*1024*1024-scanBytes){if(error)*error=NMSPError(2,@"Instruction scan exceeds 64 MiB");return nil;}scanBytes+=layout.instructions[i].length;}
 const uint8_t *bytes=image.bytes;
 for(size_t i=0;i<layout.instructionCount;i++){NMMachOInstructionRegion region=layout.instructions[i];for(uint64_t at=0;at<region.length;at+=4){uint64_t target=0;if(!NMARM64DirectBranchTarget(NMSPRead32(bytes+region.fileoff+at),region.rva+at,&target))continue;
  // Single scan; binary search physical starts instead of rescanning the image per site.
  NSUInteger low=0,high=sites.count;while(low<high){NSUInteger mid=low+(high-low)/2;if(starts[mid]<=target)low=mid+1;else high=mid;}
  if(low&&target>starts[low-1]&&target-starts[low-1]<lengths[low-1]){if(error)*error=NMSPError(8,@"Direct branch enters a physical window interior");return nil;}
 }}
 return [[self alloc] initDefinitions:input sites:sites mapping:mapping source:image imageBase:layout.imageBase];
}
@end
