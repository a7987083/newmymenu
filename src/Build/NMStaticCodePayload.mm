#import "NMStaticCodePayload.h"
#import "NMARM64Relocation.h"
#include "NMStaticLayoutPrivate.h"
#include "NMStaticFormatPrivate.h"
#include <vector>
#include <cstring>
static NSError *NMSCodeError(NSInteger code,NSString *text){return [NSError errorWithDomain:@"newmymenu.static-code" code:code userInfo:@{NSLocalizedDescriptionKey:text}];}
static uint32_t read32(const uint8_t *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
static void write32(uint8_t *p,uint32_t v){for(unsigned i=0;i<4;i++)p[i]=(uint8_t)(v>>(8*i));}
static void copyUTF8(char *to,size_t capacity,NSString *text){NSData *d=[text dataUsingEncoding:NSUTF8StringEncoding];size_t n=MIN(d.length,capacity-1);const uint8_t *bytes=(const uint8_t *)d.bytes;if(n<d.length)while(n&&(bytes[n]&0xc0)==0x80)n--;memset(to,0,capacity);if(n)memcpy(to,bytes,n);}
// V3 fragment writer: same permutation and per-fragment branch layout, bounded private buffer.
static BOOL variant(uint8_t *base,uint64_t file,uint64_t va,NSData *source,uint64_t sourceVA,uint64_t state,uint64_t *entry){
 size_t count=source.length/4;std::vector<uint32_t> slots(count);for(size_t i=0;i<count;i++)slots[i]=(uint32_t)i;NMLayoutShuffleU32(slots.data(),count,state);
 // Linear full permutation check replaces original quadratic check without dropping validation.
 std::vector<bool> seen(count,false);for(uint32_t slot:slots){if(slot>=count||seen[slot])return NO;seen[slot]=true;}
 *entry=va+(uint64_t)slots[0]*NMLayout_PAYLOAD_SLOT_SIZE;const uint8_t *bytes=(const uint8_t *)source.bytes;
 for(size_t i=0;i<count;i++){
  uint64_t at=file+(uint64_t)slots[i]*NMLayout_PAYLOAD_SLOT_SIZE,pc=va+(uint64_t)slots[i]*NMLayout_PAYLOAD_SLOT_SIZE;
  if(!i){write32(base+at,0xa8c147f0u);at+=4;pc+=4;}
  NMARM64RelocationResult r={};if(NMARM64RelocateInstruction(read32(bytes+i*4),sourceVA+i*4,pc,sourceVA,sourceVA+source.length,&r)!=NMARM64RelocationOK)return NO;write32(base+at,r.instruction);if(r.terminal)break;
  uint64_t next=i+1<count?va+(uint64_t)slots[i+1]*NMLayout_PAYLOAD_SLOT_SIZE:sourceVA+source.length;uint32_t branch=0;if(!NMARM64EncodeBranch(pc+4,next,false,&branch))return NO;write32(base+at+4,branch);
 }
 return YES;
}
static BOOL thunk(uint8_t *base,uint64_t file,uint64_t va,uint64_t selectedVA,uint64_t offVA,uint64_t state){
 uint32_t nops=(uint32_t)(NMLayoutNextLayoutWord(&state)%3),adrp=0,branch=0;uint64_t offPC=va+16+(uint64_t)nops*4,selectedPC=offPC+4;
 if((selectedVA&7)||!NMARM64EncodeADRP(va+4,selectedVA,17,&adrp)||!NMARM64EncodeBranch(offPC,offVA,false,&branch))return NO;
 write32(base+file,0xa9bf47f0u);write32(base+file+4,adrp);write32(base+file+8,0xf9400000u|((uint32_t)((selectedVA&4095)>>3)<<10)|(17u<<5)|17u);write32(base+file+12,0xb5000011u|((uint32_t)((selectedPC-(va+12))/4)<<5));write32(base+file+16+(uint64_t)nops*4,branch);write32(base+file+20+(uint64_t)nops*4,0xd61f0220u);return YES;
}
@interface NMStaticCodePayload ()
- (instancetype)initCode:(NSData *)code metadata:(NSData *)metadata patches:(NSArray *)patches hash:(NSString *)hash codeVA:(uint64_t)codeVA metadataVA:(uint64_t)metadataVA;
@end
@implementation NMStaticCodePayload
- (instancetype)initCode:(NSData *)code metadata:(NSData *)metadata patches:(NSArray *)patches hash:(NSString *)hash codeVA:(uint64_t)codeVA metadataVA:(uint64_t)metadataVA{self=[super init];if(self){_code=[code copy];_metadata=[metadata copy];_sitePatches=[patches copy];_sourceSHA256=[hash copy];_codeVA=codeVA;_metadataVA=metadataVA;}return self;}
+ (instancetype)payloadForPlan:(NMStaticPatchPlan *)plan codeVA:(uint64_t)codeVA metadataVA:(uint64_t)dataVA nonce:(uint64_t)nonce error:(NSError **)error{
 if(error)*error=nil;
 if([plan class]!=NMStaticPatchPlan.class||!plan.definitions.count||!plan.physicalSites.count||(codeVA&15)||(dataVA&15)||codeVA<plan.imageBase||dataVA<plan.imageBase){if(error)*error=NMSCodeError(1,@"Concrete nonempty plan and aligned preferred VAs required");return nil;}
 uint64_t codeSize=0;for(NSDictionary *site in plan.physicalSites){uint64_t stride=NMLayoutVariantStrideBytes([site[@"window"] unsignedLongLongValue]),variants=[site[@"variants"] count];uint64_t needed=NMLayout_PAYLOAD_THUNK_STRIDE+stride*(variants+1);if(!stride||needed>128*1024*1024-codeSize){if(error)*error=NMSCodeError(2,@"Static code budget exceeds 128 MiB");return nil;}codeSize+=needed;}
 uint64_t dataSize=sizeof(NMStaticStaticHeader)+sizeof(NMStaticStaticEntry)*plan.definitions.count;
 if(codeSize>UINT64_MAX-codeVA||dataSize>UINT64_MAX-dataVA||((codeVA<=dataVA)?dataVA-codeVA<codeSize:codeVA-dataVA<dataSize)){if(error)*error=NMSCodeError(2,@"Code/metadata span overflow or overlap");return nil;}
 NSMutableData *code=[NSMutableData dataWithLength:(NSUInteger)codeSize],*data=[NSMutableData dataWithLength:(NSUInteger)dataSize];uint8_t *bytes=(uint8_t *)code.mutableBytes;for(uint64_t i=0;i<codeSize;i+=4)write32(bytes+i,0xd503201f);
 NMStaticStaticHeader *header=(NMStaticStaticHeader *)data.mutableBytes;header->magic0=NMStatic_STATIC_MAGIC0;header->magic1=NMStatic_STATIC_MAGIC1;header->version=NMStatic_STATIC_VERSION_V3;header->count=(uint32_t)plan.definitions.count;header->entrySize=sizeof(NMStaticStaticEntry);header->flags=NMStatic_STATIC_HEADER_FLAG_PAYLOAD_PROTECTION_V2|NMStatic_STATIC_HEADER_FLAG_GENERATED_LAYOUT_V1;
 NMStaticStaticEntry *entries=(NMStaticStaticEntry *)(header+1);NSMutableArray *patches=[NSMutableArray array];uint64_t cursor=0;NSUInteger physicalIndex=0;
 for(NSDictionary *site in plan.physicalSites){
  uint64_t rva=[site[@"rva"] unsignedLongLongValue],window=[site[@"window"] unsignedLongLongValue],sourceVA=plan.imageBase+rva;NSArray *members=site[@"logicalIndexes"],*variants=site[@"variants"],*indices=site[@"logicalVariantIndexes"];NSUInteger canonical=[members.firstObject unsignedIntegerValue];
  uint64_t state=NMLayoutDeriveLayoutState(nonce,rva,0x80000000u|(uint32_t)physicalIndex),thunkFile=cursor+((NMLayoutNextLayoutWord(&state)&1)?16:0),thunkVA=codeVA+thunkFile;cursor+=NMLayout_PAYLOAD_THUNK_STRIDE;uint64_t stride=NMLayoutVariantStrideBytes(window),offState=NMLayoutDeriveLayoutState(nonce,rva,0),offFile=cursor+(NMLayoutNextLayoutWord(&offState)%5)*16,offVA=0;cursor+=stride;
  if(!variant(bytes,offFile,codeVA+offFile,site[@"original"],sourceVA,offState,&offVA)){if(error)*error=NMSCodeError(3,@"OFF variant relocation/range failure");return nil;}
  std::vector<uint64_t> onVAs;for(NSUInteger i=0;i<variants.count;i++){uint64_t vState=NMLayoutDeriveLayoutState(nonce,rva,(uint32_t)i+1),file=cursor+(NMLayoutNextLayoutWord(&vState)%5)*16,entry=0;cursor+=stride;if(!variant(bytes,file,codeVA+file,variants[i],sourceVA,vState,&entry)){if(error)*error=NMSCodeError(3,@"ON variant relocation/range failure");return nil;}onVAs.push_back(entry);}
  if(!thunk(bytes,thunkFile,thunkVA,dataVA+sizeof(*header)+canonical*sizeof(*entries),offVA,state)){if(error)*error=NMSCodeError(4,@"Dispatch thunk target range/alignment failure");return nil;}
  uint32_t entryBranch=0;if(!NMARM64EncodeBranch(sourceVA,thunkVA,false,&entryBranch)){if(error)*error=NMSCodeError(4,@"Source-to-thunk branch exceeds range");return nil;}
  NSMutableData *patch=[NSMutableData dataWithLength:(NSUInteger)window];for(uint64_t at=0;at<window;at+=4)write32((uint8_t *)patch.mutableBytes+at,at?0xd503201fu:entryBranch);[patches addObject:@{@"rva":@(rva),@"fileOffset":site[@"fileOffset"],@"expected":site[@"original"],@"replacement":[patch copy]}];
  for(NSUInteger i=0;i<members.count;i++){NSUInteger logical=[members[i] unsignedIntegerValue],index=[indices[i] unsignedIntegerValue];NMStaticStaticEntry *e=entries+logical;e->offRVA=offVA-plan.imageBase;e->onRVA=onVAs[index]-plan.imageBase;e->siteRVA=rva;e->windowLength=(uint32_t)window;e->patchID=(uint32_t)logical+1;e->enabledLength=(uint32_t)plan.definitions[logical].replacementBytes.length;e->physicalID=(uint32_t)physicalIndex+1;e->canonicalIndex=(uint32_t)canonical;e->flags=(logical==canonical?NMStatic_STATIC_ENTRY_FLAG_CANONICAL:0)|(members.count>1?NMStatic_STATIC_ENTRY_FLAG_SHARED:0);copyUTF8(e->title,sizeof(e->title),plan.definitions[logical].title);copyUTF8(e->group,sizeof(e->group),plan.definitions[logical].group);}
  physicalIndex++;
 }
 if(cursor!=codeSize){if(error)*error=NMSCodeError(5,@"Static code accounting mismatch");return nil;}
 return [[self alloc] initCode:code metadata:data patches:patches hash:plan.sourceSHA256 codeVA:codeVA metadataVA:dataVA];
}
@end
