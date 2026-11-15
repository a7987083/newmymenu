#import "NMStaticCodePayload.h"
#import "NMARM64Relocation.h"
#import "NMBuildManifest.h"
#import "NMRuntimeActionFormat.h"
#include "NMStaticLayoutPrivate.h"
#include "NMStaticFormatPrivate.h"
#include <vector>
#include <cstring>
static NSError *NMSCodeError(NSInteger code,NSString *text){return [NSError errorWithDomain:@"newmymenu.static-code" code:code userInfo:@{NSLocalizedDescriptionKey:text}];}
static uint32_t read32(const uint8_t *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
static void write32(uint8_t *p,uint32_t v){for(unsigned i=0;i<4;i++)p[i]=(uint8_t)(v>>(8*i));}
static void copyUTF8(char *to,size_t capacity,NSString *text){NSData *d=[text dataUsingEncoding:NSUTF8StringEncoding];size_t n=MIN(d.length,capacity-1);const uint8_t *bytes=(const uint8_t *)d.bytes;if(n<d.length)while(n&&(bytes[n]&0xc0)==0x80)n--;memset(to,0,capacity);if(n)memcpy(to,bytes,n);}
// V3 fragment writer: same permutation and per-fragment branch layout, bounded private buffer.
struct NMSLocation { uint64_t file,va; };
static BOOL variant(uint8_t *base,uint64_t file,uint64_t va,NSData *source,uint64_t sourceVA,uint64_t state,uint64_t *entry,std::vector<NMSLocation> *positions){
 size_t count=source.length/4;std::vector<uint32_t> slots(count);for(size_t i=0;i<count;i++)slots[i]=(uint32_t)i;NMLayoutShuffleU32(slots.data(),count,state);
 // Linear full permutation check replaces original quadratic check without dropping validation.
 std::vector<bool> seen(count,false);for(uint32_t slot:slots){if(slot>=count||seen[slot])return NO;seen[slot]=true;}
 *entry=va+(uint64_t)slots[0]*NMLayout_PAYLOAD_SLOT_SIZE;const uint8_t *bytes=(const uint8_t *)source.bytes;
 for(size_t i=0;i<count;i++){
  uint64_t at=file+(uint64_t)slots[i]*NMLayout_PAYLOAD_SLOT_SIZE,pc=va+(uint64_t)slots[i]*NMLayout_PAYLOAD_SLOT_SIZE;
  if(!i){write32(base+at,0xa8c147f0u);at+=4;pc+=4;}
  NMARM64RelocationResult r={};if(NMARM64RelocateInstruction(read32(bytes+i*4),sourceVA+i*4,pc,sourceVA,sourceVA+source.length,&r)!=NMARM64RelocationOK)return NO;if(positions)positions->push_back({at,pc});write32(base+at,r.instruction);if(r.terminal)break;
  uint64_t next=i+1<count?va+(uint64_t)slots[i+1]*NMLayout_PAYLOAD_SLOT_SIZE:sourceVA+source.length;uint32_t branch=0;if(!NMARM64EncodeBranch(pc+4,next,false,&branch))return NO;write32(base+at+4,branch);
 }
 return YES;
}
static BOOL thunk(uint8_t *base,uint64_t file,uint64_t va,uint64_t selectedVA,uint64_t offVA,uint64_t state){
 uint32_t nops=(uint32_t)(NMLayoutNextLayoutWord(&state)%3),adrp=0,branch=0;uint64_t offPC=va+16+(uint64_t)nops*4,selectedPC=offPC+4;
 if((selectedVA&7)||!NMARM64EncodeADRP(va+4,selectedVA,17,&adrp)||!NMARM64EncodeBranch(offPC,offVA,false,&branch))return NO;
 write32(base+file,0xa9bf47f0u);write32(base+file+4,adrp);write32(base+file+8,0xf9400000u|((uint32_t)((selectedVA&4095)>>3)<<10)|(17u<<5)|17u);write32(base+file+12,0xb5000011u|((uint32_t)((selectedPC-(va+12))/4)<<5));write32(base+file+16+(uint64_t)nops*4,branch);write32(base+file+20+(uint64_t)nops*4,0xd61f0220u);return YES;
}
static BOOL numeric(NMStaticPatchDefinition *d){return d.controlType==NMStaticControlSlider||d.controlType==NMStaticControlNumber;}
static NSArray<NSDictionary *> *generatedGroups(NMStaticPatchPlan *plan,NSDictionary *site){
 NSMutableArray *out=[NSMutableArray array];NSMutableDictionary *byKey=[NSMutableDictionary dictionary];NSArray *members=site[@"logicalIndexes"],*indices=site[@"logicalVariantIndexes"];
 for(NSUInteger i=0;i<members.count;i++){NSNumber *logical=members[i],*source=indices[i];NSString *key=numeric(plan.definitions[logical.unsignedIntegerValue])?[@"n:" stringByAppendingString:logical.stringValue]:[@"s:" stringByAppendingString:source.stringValue];NSMutableDictionary *g=byKey[key];if(!g){g=[@{@"source":source,@"members":[NSMutableArray array]} mutableCopy];byKey[key]=g;[out addObject:g];}[g[@"members"] addObject:logical];}
 return out;
}
static NSData *manifestData(NMStaticPatchPlan *plan,NSError **error){
 NMBuildProvider *provider=[NMBuildProvider providerWithIdentifier:@"static" collector:^NSArray<NMBuildItem *> *(NSDictionary *configuration,NSError *__strong *failure){(void)configuration;NSMutableArray *items=[NSMutableArray array];for(NSUInteger i=0;i<plan.definitions.count;i++){NMStaticPatchDefinition *d=plan.definitions[i];NSDictionary *metadata=@{@"logicalIndex":@(i),@"title":d.title,@"group":d.group,@"control":@(d.controlType),@"valueType":@(d.valueType)};NMBuildItem *item=[NMBuildItem itemWithProvider:@"static" kind:@"patch" identifier:d.identifier domain:NMBuildItemDomainStatic metadata:metadata error:failure];if(!item)return nil;[items addObject:item];}return items;}];
 NMBuildManifest *manifest=[NMBuildManifest collectProviders:@[provider] configuration:@{@"sourceSHA256":plan.sourceSHA256} error:error];return [manifest JSONDataWithError:error];
}
@interface NMStaticCodePayload ()
- (instancetype)initCode:(NSData *)code metadata:(NSData *)metadata patches:(NSArray *)patches hash:(NSString *)hash codeVA:(uint64_t)codeVA metadataVA:(uint64_t)metadataVA;
@end
@implementation NMStaticCodePayload
- (instancetype)initCode:(NSData *)code metadata:(NSData *)metadata patches:(NSArray *)patches hash:(NSString *)hash codeVA:(uint64_t)codeVA metadataVA:(uint64_t)metadataVA{self=[super init];if(self){_code=[code copy];_metadata=[metadata copy];_sitePatches=[patches copy];_sourceSHA256=[hash copy];_codeVA=codeVA;_metadataVA=metadataVA;}return self;}
+ (NSDictionary *)requirementsForPlan:(NMStaticPatchPlan *)plan error:(NSError **)error {
 if(error)*error=nil;if([plan class]!=NMStaticPatchPlan.class||!plan.definitions.count||!plan.physicalSites.count){if(error)*error=NMSCodeError(1,@"Nonempty concrete plan required");return nil;}
 uint64_t size=0;BOOL cells=NO;for(NMStaticPatchDefinition *d in plan.definitions)cells|=numeric(d);
 for(NSDictionary *site in plan.physicalSites){uint64_t stride=NMLayoutVariantStrideBytes([site[@"window"] unsignedLongLongValue]),groups=generatedGroups(plan,site).count,needed=NMLayout_PAYLOAD_THUNK_STRIDE+stride*(groups+1);if(!stride||needed>128*1024*1024-size){if(error)*error=NMSCodeError(2,@"Static code budget exceeds 128 MiB");return nil;}size+=needed;}
 NSData *catalog=manifestData(plan,error);if(!catalog)return nil;uint64_t dataSize=sizeof(NMStaticStaticHeader)+sizeof(NMStaticStaticEntry)*plan.definitions.count+sizeof(NMStaticFeatureDescriptionHeader)+sizeof(NMStaticFeatureDescriptionEntry)*plan.definitions.count+sizeof(NMRuntimeActionHeader)+sizeof(NMStaticManifestHeader)+catalog.length;if(cells)dataSize=(dataSize+plan.definitions.count*8+16383)&~UINT64_C(16383);
 return @{@"codeBytes":@(size),@"metadataBytes":@(dataSize),@"valueCells":@(cells),@"manifest":catalog};
}
+ (instancetype)payloadForPlan:(NMStaticPatchPlan *)plan codeVA:(uint64_t)codeVA metadataVA:(uint64_t)dataVA nonce:(uint64_t)nonce error:(NSError **)error{
 if(error)*error=nil;
 if([plan class]!=NMStaticPatchPlan.class||!plan.definitions.count||!plan.physicalSites.count||(codeVA&15)||(dataVA&15)||codeVA<plan.imageBase||dataVA<plan.imageBase){if(error)*error=NMSCodeError(1,@"Concrete nonempty plan and aligned preferred VAs required");return nil;}
 NSDictionary *requirements=[self requirementsForPlan:plan error:error];if(!requirements)return nil;uint64_t codeSize=[requirements[@"codeBytes"] unsignedLongLongValue],dataSize=[requirements[@"metadataBytes"] unsignedLongLongValue];
 if(codeSize>UINT64_MAX-codeVA||dataSize>UINT64_MAX-dataVA||((codeVA<=dataVA)?dataVA-codeVA<codeSize:codeVA-dataVA<dataSize)){if(error)*error=NMSCodeError(2,@"Code/metadata span overflow or overlap");return nil;}
 NSMutableData *code=[NSMutableData dataWithLength:(NSUInteger)codeSize],*data=[NSMutableData dataWithLength:(NSUInteger)dataSize];uint8_t *bytes=(uint8_t *)code.mutableBytes;for(uint64_t i=0;i<codeSize;i+=4)write32(bytes+i,0xd503201f);
 NMStaticStaticHeader *header=(NMStaticStaticHeader *)data.mutableBytes;header->magic0=NMStatic_STATIC_MAGIC0;header->magic1=NMStatic_STATIC_MAGIC1;header->version=NMStatic_STATIC_VERSION_V3;header->count=(uint32_t)plan.definitions.count;header->entrySize=sizeof(NMStaticStaticEntry);header->flags=NMStatic_STATIC_HEADER_FLAG_PAYLOAD_PROTECTION_V2|NMStatic_STATIC_HEADER_FLAG_GENERATED_LAYOUT_V1|NM_STATIC_HEADER_FLAG_MANIFEST_V1;
 NMStaticStaticEntry *entries=(NMStaticStaticEntry *)(header+1);NSData *catalog=requirements[@"manifest"];uint64_t descriptionOffset=sizeof(*header)+sizeof(*entries)*plan.definitions.count;NMStaticFeatureDescriptionHeader *descriptions=(NMStaticFeatureDescriptionHeader *)((uint8_t *)data.mutableBytes+descriptionOffset);descriptions->magic0=NMStatic_FEATURE_DESC_MAGIC0;descriptions->magic1=NMStatic_FEATURE_DESC_MAGIC1;descriptions->count=(uint32_t)plan.definitions.count;descriptions->entrySize=sizeof(NMStaticFeatureDescriptionEntry);NMStaticFeatureDescriptionEntry *descriptionEntries=(NMStaticFeatureDescriptionEntry *)(descriptions+1);for(NSUInteger i=0;i<plan.definitions.count;i++)descriptionEntries[i].patchID=(uint32_t)i+1;uint64_t actionOffset=descriptionOffset+sizeof(*descriptions)+sizeof(*descriptionEntries)*plan.definitions.count;NMRuntimeActionHeader *actions=(NMRuntimeActionHeader *)((uint8_t *)data.mutableBytes+actionOffset);actions->magic=NM_RUNTIME_ACTION_MAGIC;actions->version=NM_RUNTIME_ACTION_VERSION;actions->entrySize=sizeof(NMRuntimeMethodCallEntry);actions->totalSize=sizeof(*actions);actions->stringPoolOffset=sizeof(*actions);uint64_t catalogOffset=actionOffset+sizeof(*actions);NMStaticManifestHeader *catalogHeader=(NMStaticManifestHeader *)((uint8_t *)data.mutableBytes+catalogOffset);catalogHeader->magic=NM_STATIC_MANIFEST_MAGIC;catalogHeader->version=1;catalogHeader->length=(uint32_t)catalog.length;memcpy(catalogHeader+1,catalog.bytes,catalog.length);NSMutableArray *patches=[NSMutableArray array];std::vector<NMStaticValueType> resolved(plan.definitions.count,NMStaticValueAuto);uint64_t cursor=0;NSUInteger physicalIndex=0;
 for(NSDictionary *site in plan.physicalSites){
  uint64_t rva=[site[@"rva"] unsignedLongLongValue],window=[site[@"window"] unsignedLongLongValue],sourceVA=plan.imageBase+rva;NSArray *members=site[@"logicalIndexes"],*variants=site[@"variants"];NSUInteger canonical=[members.firstObject unsignedIntegerValue];
  uint64_t state=NMLayoutDeriveLayoutState(nonce,rva,0x80000000u|(uint32_t)physicalIndex),thunkFile=cursor+((NMLayoutNextLayoutWord(&state)&1)?16:0),thunkVA=codeVA+thunkFile;cursor+=NMLayout_PAYLOAD_THUNK_STRIDE;uint64_t stride=NMLayoutVariantStrideBytes(window),offState=NMLayoutDeriveLayoutState(nonce,rva,0),offFile=cursor+(NMLayoutNextLayoutWord(&offState)%5)*16,offVA=0;cursor+=stride;
  if(!variant(bytes,offFile,codeVA+offFile,site[@"original"],sourceVA,offState,&offVA,nullptr)){if(error)*error=NMSCodeError(3,@"OFF variant relocation/range failure");return nil;}
  NSArray *groups=generatedGroups(plan,site);std::vector<uint64_t> onVAs;NSMutableDictionary<NSNumber *,NSNumber *> *generatedForLogical=[NSMutableDictionary dictionary];
  for(NSUInteger i=0;i<groups.count;i++){
   NSDictionary *group=groups[i];NSArray *logicalMembers=group[@"members"];NSUInteger first=[logicalMembers.firstObject unsignedIntegerValue],sourceIndex=[group[@"source"] unsignedIntegerValue];NMStaticPatchDefinition *definition=plan.definitions[first];
   uint64_t vState=NMLayoutDeriveLayoutState(nonce,rva,(uint32_t)i+1),file=cursor+(NMLayoutNextLayoutWord(&vState)%5)*16,entry=0;cursor+=stride;std::vector<NMSLocation> positions;
   if(!variant(bytes,file,codeVA+file,variants[sourceIndex],sourceVA,vState,&entry,numeric(definition)?&positions:nullptr)){if(error)*error=NMSCodeError(3,@"ON variant relocation/range failure");return nil;}
   if(numeric(definition)){
    NMStaticImmediate immediate;if(!NMStaticDecodeImmediate(definition.replacementBytes.bytes,definition.replacementBytes.length,definition.valueType,&immediate)||positions.size()<immediate.consumedInstructions){if(error)*error=NMSCodeError(6,@"Numeric immediate/fragment mapping invalid");return nil;}
    uint64_t cellOffset=dataSize-plan.definitions.count*8+first*8;uint32_t op=immediate.type<=NMStaticValueU32?0x18000000u:immediate.type<=NMStaticValueU64?0x58000000u:immediate.type==NMStaticValueF32?0x1c000000u:0x5c000000u,literal=0;
    if(!NMARM64EncodeLiteral(positions[0].va,dataVA+cellOffset,op,immediate.reg,&literal)){if(error)*error=NMSCodeError(6,@"Numeric value cell exceeds literal-load range");return nil;}
    write32(bytes+positions[0].file,literal);for(size_t k=1;k<immediate.consumedInstructions;k++)write32(bytes+positions[k].file,0xd503201fu);memcpy((uint8_t *)data.mutableBytes+cellOffset,&immediate.bits,8);resolved[first]=immediate.type;header->flags|=NMStatic_STATIC_HEADER_FLAG_VALUE_CELLS_V1;
   }
   onVAs.push_back(entry);for(NSNumber *logical in logicalMembers)generatedForLogical[logical]=@(i);
  }
  if(!thunk(bytes,thunkFile,thunkVA,dataVA+sizeof(*header)+canonical*sizeof(*entries),offVA,state)){if(error)*error=NMSCodeError(4,@"Dispatch thunk target range/alignment failure");return nil;}
  uint32_t entryBranch=0;if(!NMARM64EncodeBranch(sourceVA,thunkVA,false,&entryBranch)){if(error)*error=NMSCodeError(4,@"Source-to-thunk branch exceeds range");return nil;}
  NSMutableData *patch=[NSMutableData dataWithLength:(NSUInteger)window];for(uint64_t at=0;at<window;at+=4)write32((uint8_t *)patch.mutableBytes+at,at?0xd503201fu:entryBranch);[patches addObject:@{@"rva":@(rva),@"fileOffset":site[@"fileOffset"],@"expected":site[@"original"],@"replacement":[patch copy]}];
  for(NSUInteger i=0;i<members.count;i++){NSUInteger logical=[members[i] unsignedIntegerValue],index=[generatedForLogical[members[i]] unsignedIntegerValue];NMStaticStaticEntry *e=entries+logical;e->offRVA=offVA-plan.imageBase;e->onRVA=onVAs[index]-plan.imageBase;e->siteRVA=rva;e->windowLength=(uint32_t)window;e->patchID=(uint32_t)logical+1;e->enabledLength=(uint32_t)plan.definitions[logical].replacementBytes.length;e->physicalID=(uint32_t)physicalIndex+1;e->canonicalIndex=(uint32_t)canonical;e->flags=(logical==canonical?NMStatic_STATIC_ENTRY_FLAG_CANONICAL:0)|(members.count>1?NMStatic_STATIC_ENTRY_FLAG_SHARED:0);e->flags|=((uint32_t)plan.definitions[logical].controlType<<8)|((uint32_t)plan.definitions[logical].valueType<<11);if(numeric(plan.definitions[logical]))e->flags|=NMStatic_STATIC_ENTRY_FLAG_VALUE_CELL_V1|NMStaticStaticValueCellTypeFlags((uint32_t)resolved[logical]);copyUTF8(e->title,sizeof(e->title),plan.definitions[logical].title);copyUTF8(e->group,sizeof(e->group),plan.definitions[logical].group);}
  physicalIndex++;
 }
 if(cursor!=codeSize){if(error)*error=NMSCodeError(5,@"Static code accounting mismatch");return nil;}
 return [[self alloc] initCode:code metadata:data patches:patches hash:plan.sourceSHA256 codeVA:codeVA metadataVA:dataVA];
}
@end
