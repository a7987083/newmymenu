#import "NMStaticBinaryImage.h"
#import "NMChainedFixupsPrivate.h"
#import <CommonCrypto/CommonDigest.h>
#include <cstring>
static uint32_t rd32(const uint8_t *p){uint32_t v;memcpy(&v,p,4);return v;}static uint64_t rd64(const uint8_t *p){uint64_t v;memcpy(&v,p,8);return v;}
static void wr32(uint8_t *p,uint32_t v){memcpy(p,&v,4);}static void wr64(uint8_t *p,uint64_t v){memcpy(p,&v,8);}
static NSError *NMSImageError(NSInteger code,NSString *text){return [NSError errorWithDomain:@"newmymenu.static-image" code:code userInfo:@{NSLocalizedDescriptionKey:text}];}
static NSString *digest(NSData *d){unsigned char hash[32];CC_SHA256(d.bytes,(CC_LONG)d.length,hash);NSMutableString *s=[NSMutableString string];for(unsigned i=0;i<32;i++)[s appendFormat:@"%02x",hash[i]];return s;}
// Shift a validated original file span; never move any text/data content.
static bool span(uint8_t *c,uint32_t offField,uint32_t countField,uint64_t element,uint64_t threshold,uint64_t shift,uint64_t fileSize){uint64_t off=rd32(c+offField),count=rd32(c+countField);if(count&&(!off||off>fileSize||count>(fileSize-off)/element))return false;if(off&&off>=threshold){if(off>UINT32_MAX-shift)return false;wr32(c+offField,(uint32_t)(off+shift));}return true;}
// Explicit command allowlist; unknown offset-bearing commands are never silently copied.
static bool shiftCommands(uint8_t *base,uint64_t end,uint64_t linkFile,uint64_t linkVM,uint64_t shift,uint64_t oldSize){
 for(uint64_t at=32;at<end;){uint8_t *c=base+at;uint32_t cmd=rd32(c),size=rd32(c+4);if(size<8||size>end-at)return false;
  switch(cmd){
   case 0x19:if(size<72)return false;if(rd64(c+40)==linkFile&&rd64(c+24)==linkVM){if(rd32(c+64))return false;wr64(c+40,linkFile+shift);wr64(c+24,linkVM+shift);}break;
   case 0x2:if(size<24||!span(c,8,12,16,linkFile,shift,oldSize)||!span(c,16,20,1,linkFile,shift,oldSize))return false;break;
   case 0xb:{if(size<80)return false;const uint64_t element[]={8,56,4,4,8,8};for(unsigned i=0;i<6;i++)if(!span(c,32+i*8,36+i*8,element[i],linkFile,shift,oldSize))return false;break;}
   case 0x22:case 0x80000022u:if(size<48)return false;for(unsigned f=8;f<48;f+=8)if(!span(c,f,f+4,1,linkFile,shift,oldSize))return false;break;
   case 0x16:if(size<16||!span(c,8,12,4,linkFile,shift,oldSize))return false;break;
   case 0x1d:case 0x1e:case 0x26:case 0x29:case 0x2b:case 0x2e:case 0x80000033u:case 0x80000034u:if(size<16||!span(c,8,12,1,linkFile,shift,oldSize))return false;break;
   case 0x31:{if(size<40)return false;uint64_t off=rd64(c+24),n=rd64(c+32);if(off>oldSize||n>oldSize-off)return false;if(off&&off>=linkFile){if(off>UINT64_MAX-shift)return false;wr64(c+24,off+shift);}break;}
   case 0x2c:if(size<24||rd32(c+16)||!span(c,8,12,1,linkFile,shift,oldSize))return false;break;
   case 0x32:if(size<24||rd32(c+20)>(size-24)/8)return false;break;
   case 0x1b:if(size!=24)return false;break;
   case 0x2a:if(size!=16)return false;break;
   case 0x24:case 0x25:case 0x2f:case 0x30:if(size!=16)return false;break;
   case 0x80000028u:if(size<24||rd64(c+8)>=linkFile)return false;break;
   case 0xc:case 0xd:case 0x80000018u:case 0x8000001fu:case 0x80000023u:case 0x20:{if(size<24)return false;uint32_t off=rd32(c+8);if(off<24||off>=size||!memchr(c+off,0,size-off))return false;break;}
   case 0xe:case 0xf:case 0x8000001cu:{if(size<12)return false;uint32_t off=rd32(c+8);if(off<12||off>=size||!memchr(c+off,0,size-off))return false;break;}
   default:return false;
  }
  at+=size;
 }
 return true;
}
// V3 owned-segment command ABI. No guessed code cave or zero-fill storage.
static void owned(uint8_t *c,const char *segment,const char *section,uint64_t va,uint64_t file,uint64_t size,uint64_t used,uint32_t prot,uint32_t flags){memset(c,0,152);wr32(c,0x19);wr32(c+4,152);memcpy(c+8,segment,strlen(segment));wr64(c+24,va);wr64(c+32,size);wr64(c+40,file);wr64(c+48,size);wr32(c+56,prot);wr32(c+60,prot);wr32(c+64,1);memcpy(c+72,section,strlen(section));memcpy(c+88,segment,strlen(segment));wr64(c+104,va);wr64(c+112,used);wr32(c+120,(uint32_t)file);wr32(c+124,prot&4?2:3);wr32(c+136,flags);}
@interface NMStaticBinaryImage ()
- (instancetype)initImage:(NSData *)image report:(NSDictionary *)report;
@end
@implementation NMStaticBinaryImage
- (instancetype)initImage:(NSData *)image report:(NSDictionary *)report{self=[super init];if(self){_image=[image copy];_report=[report copy];}return self;}
+ (instancetype)imageForSource:(NSData *)source plan:(NMStaticPatchPlan *)plan nonce:(uint64_t)nonce error:(NSError **)error{
 if(error)*error=nil;
 if(![source isKindOfClass:NSData.class]||!source.length||source.length>256*1024*1024||[plan class]!=NMStaticPatchPlan.class){if(error)*error=NMSImageError(1,@"Source/plan invalid");return nil;}
 NSData *input=[source copy];if(input.length!=plan.sourceLength||![digest(input) isEqual:plan.sourceSHA256]){if(error)*error=NMSImageError(2,@"Source differs from frozen plan identity");return nil;}
 NMMachOLayout l;if(!NMMachOReadLayout(input.bytes,input.length,&l)){if(error)*error=NMSImageError(3,@"Source layout invalid");return nil;}const NMMachOSegment *link=NULL;for(size_t i=0;i<l.count;i++){const NMMachOSegment *s=l.segments+i;if(!strcmp(s->name,"__LINKEDIT")){if(link){if(error)*error=NMSImageError(3,@"Duplicate LINKEDIT");return nil;}link=s;}if(!strcmp(s->name,"__NMTEXT")||!strcmp(s->name,"__NMDATA")||!strcmp(s->name,"__ZNTEXT")||!strcmp(s->name,"__ZNDATA")){if(error)*error=NMSImageError(3,@"Already prepared image; do not stack builders");return nil;}}
 if(!link||link!=l.segments+l.count-1||!link->filesize||(link->fileoff&16383)||(link->vmaddr&16383)||link->fileoff+link->filesize!=input.length||l.firstFileSectionOffset==UINT64_MAX||l.commandEnd>l.firstFileSectionOffset||l.firstFileSectionOffset-l.commandEnd<304){if(error)*error=NMSImageError(4,@"Final aligned LINKEDIT and 304 bytes of real header slack required");return nil;}
 for(size_t i=0;i<l.count;i++)if(l.segments+i!=link&&l.segments[i].vmsize&&l.segments[i].vmaddr+l.segments[i].vmsize>link->vmaddr){if(error)*error=NMSImageError(4,@"LINKEDIT must be final VM segment");return nil;}
 // Rebuild chained starts when segment indices change; never copy a stale seg_count.
 uint64_t linkCommand=0,chainsCommand=0,signatureCommand=0;NSData *expandedChains=nil;const uint8_t *raw=(const uint8_t *)input.bytes;
 for(uint64_t at=32;at<l.commandEnd;at+=rd32(raw+at+4)){uint32_t cmd=rd32(raw+at),size=rd32(raw+at+4);if(cmd==0x19&&!memcmp(raw+at+8,"__LINKEDIT",10))linkCommand=at;if(cmd==0x80000034u){if(chainsCommand||size<16){if(error)*error=NMSImageError(6,@"Invalid chained-fixups command");return nil;}chainsCommand=at;uint64_t off=rd32(raw+at+8),n=rd32(raw+at+12);if(off<link->fileoff||off>input.length||n>input.length-off){if(error)*error=NMSImageError(6,@"Chained-fixups span invalid");return nil;}expandedChains=NMExpandChainedStarts([input subdataWithRange:NSMakeRange((NSUInteger)off,(NSUInteger)n)],&l);if(!expandedChains){if(error)*error=NMSImageError(6,@"Unsupported or malformed chained starts");return nil;}}if(cmd==0x1d){if(signatureCommand||size<16){if(error)*error=NMSImageError(6,@"Invalid signature command");return nil;}signatureCommand=at;}}
 if(!signatureCommand||!linkCommand){if(error)*error=NMSImageError(6,@"Existing signature and LINKEDIT commands required for verified resigning");return nil;}
 uint64_t sigOff=rd32(raw+signatureCommand+8),sigSize=rd32(raw+signatureCommand+12);if(sigOff<link->fileoff||sigOff>input.length||sigSize!=input.length-sigOff||!sigSize){if(error)*error=NMSImageError(6,@"Signature must be final original file payload");return nil;}
 uint64_t tailExtra=expandedChains?((expandedChains.length+15)&~UINT64_C(15))+sigSize:0;
 NSDictionary *requirements=[NMStaticCodePayload requirementsForPlan:plan error:error];if(!requirements)return nil;uint64_t codeBytes=[requirements[@"codeBytes"] unsignedLongLongValue],dataBytes=[requirements[@"metadataBytes"] unsignedLongLongValue],codeSize=(codeBytes+16383)&~UINT64_C(16383),dataSize=(dataBytes+16383)&~UINT64_C(16383),shift=codeSize+dataSize;
 if(codeBytes>128*1024*1024||input.length+shift+tailExtra>512*1024*1024||shift>UINT32_MAX||input.length+shift+tailExtra>UINT32_MAX||shift+tailExtra>UINT64_MAX-link->vmaddr-link->vmsize){if(error)*error=NMSImageError(5,@"Owned-segment size/offset capacity exceeded");return nil;}
 NMStaticCodePayload *payload=[NMStaticCodePayload payloadForPlan:plan codeVA:link->vmaddr metadataVA:link->vmaddr+codeSize nonce:nonce error:error];if(!payload)return nil;
 NSMutableData *output=[NSMutableData dataWithLength:input.length+(NSUInteger)shift+(NSUInteger)tailExtra];uint8_t *bytes=(uint8_t *)output.mutableBytes;const uint8_t *original=(const uint8_t *)input.bytes;memcpy(bytes,original,(size_t)link->fileoff);memcpy(bytes+link->fileoff+shift,original+link->fileoff,(size_t)link->filesize);
 if(!shiftCommands(bytes,l.commandEnd,link->fileoff,link->vmaddr,shift,input.length)){if(error)*error=NMSImageError(6,@"Unsupported or malformed load-command payload; refuse unsafe offset shifting");return nil;}
 // Preserve VM/file segment command ordering. Only __LINKEDIT shifts to index +2.
 memmove(bytes+linkCommand+304,bytes+linkCommand,(size_t)(l.commandEnd-linkCommand));owned(bytes+linkCommand,"__NMTEXT","__nmcode",link->vmaddr,link->fileoff,codeSize,payload.code.length,5,0x80000400u);owned(bytes+linkCommand+152,"__NMDATA","__nmdata",link->vmaddr+codeSize,link->fileoff+codeSize,dataSize,payload.metadata.length,3,0);wr32(bytes+16,rd32(bytes+16)+2);wr32(bytes+20,rd32(bytes+20)+304);
 if(expandedChains){uint64_t chainOff=input.length+shift,newSig=chainOff+((expandedChains.length+15)&~UINT64_C(15));memcpy(bytes+chainOff,expandedChains.bytes,expandedChains.length);memcpy(bytes+newSig,original+sigOff,(size_t)sigSize);uint64_t chainCmd=chainsCommand+(chainsCommand>=linkCommand?304:0),sigCmd=signatureCommand+(signatureCommand>=linkCommand?304:0);wr32(bytes+chainCmd+8,(uint32_t)chainOff);wr32(bytes+chainCmd+12,(uint32_t)expandedChains.length);wr32(bytes+sigCmd+8,(uint32_t)newSig);uint64_t newLinkSize=link->filesize+tailExtra;wr64(bytes+linkCommand+304+48,newLinkSize);wr64(bytes+linkCommand+304+32,(newLinkSize+16383)&~UINT64_C(16383));}
 memcpy(bytes+link->fileoff,payload.code.bytes,payload.code.length);memcpy(bytes+link->fileoff+codeSize,payload.metadata.bytes,payload.metadata.length);
 for(NSDictionary *patch in payload.sitePatches){uint64_t off=[patch[@"fileOffset"] unsignedLongLongValue];NSData *expected=patch[@"expected"],*replacement=patch[@"replacement"];if(off>link->fileoff||expected.length>link->fileoff-off||memcmp(bytes+off,expected.bytes,expected.length)){if(error)*error=NMSImageError(7,@"Site bytes changed during image preparation");return nil;}memcpy(bytes+off,replacement.bytes,replacement.length);}
 NMMachOLayout checked;if(!NMMachOReadLayout(output.bytes,output.length,&checked)){if(error)*error=NMSImageError(8,@"Generated layout failed independent reparse");return nil;}
 NSDictionary *report=@{@"sourceSHA256":plan.sourceSHA256,@"unsignedImageSHA256":digest(output),@"codeRVA":@(link->vmaddr-l.imageBase),@"metadataRVA":@(link->vmaddr+codeSize-l.imageBase),@"codeBytes":@(payload.code.length),@"metadataBytes":@(payload.metadata.length),@"logicalCount":@(plan.definitions.count),@"physicalCount":@(plan.physicalSites.count),@"signed":@NO,@"deviceVerified":@NO};return [[self alloc] initImage:output report:report];
}
@end
