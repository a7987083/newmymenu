#import "NMStaticPatchPlan.h"
#include <cassert>
#include <cstdio>
#include <cstring>
struct ZNV3Physical {NSData *original;};
struct ZNV3Logical {NSData *enabled;};
#include "original-variant.inc"
static void write32(uint8_t *p,uint32_t n){for(unsigned i=0;i<4;i++)p[i]=(uint8_t)(n>>(i*8));}
static void write64(uint8_t *p,uint64_t n){write32(p,(uint32_t)n);write32(p+4,(uint32_t)(n>>32));}
int main(){@autoreleasepool{NSMutableData *image=[NSMutableData dataWithLength:1024];uint8_t *p=(uint8_t *)image.mutableBytes;write32(p,0xfeedfacf);write32(p+4,0x100000c);write32(p+12,6);write32(p+16,1);write32(p+20,152);uint8_t *s=p+32;write32(s,0x19);write32(s+4,152);memcpy(s+8,"__TEXT",6);write64(s+24,0x100000000);write64(s+32,1024);write64(s+48,1024);write32(s+60,5);write32(s+64,1);uint8_t *sec=s+72;write64(sec+32,0x100000100);write64(sec+40,512);write32(sec+48,256);write32(sec+64,0x80000400);for(size_t j=256;j<768;j+=4)write32(p+j,0xd503201f);
 for(NSUInteger i=0;i<1000;i++){@autoreleasepool{NSUInteger window=4*((i%16)+1),shortSize=4*((i%(window/4))+1);NSData *original=[image subdataWithRange:NSMakeRange(256,window)];NSMutableData *shortBytes=[NSMutableData dataWithLength:shortSize],*longBytes=[NSMutableData dataWithLength:window];memset(shortBytes.mutableBytes,(int)(i&255),shortSize);memset(longBytes.mutableBytes,(int)((i*17)&255),window);
 NMStaticPatchDefinition *a=[NMStaticPatchDefinition definitionWithIdentifier:@"a" kind:NMMachOAddressFileOffset address:256 expected:[original subdataWithRange:NSMakeRange(0,shortSize)] replacement:shortBytes evidence:@"hash-fixed compositor fixture" error:NULL];NMStaticPatchDefinition *b=[NMStaticPatchDefinition definitionWithIdentifier:@"b" kind:NMMachOAddressPreferredVA address:0x100000100 expected:original replacement:longBytes evidence:@"hash-fixed compositor fixture" error:NULL];NMStaticPatchPlan *plan=[NMStaticPatchPlan planForMachO:image definitions:@[a,b] error:NULL];assert(plan&&plan.physicalSites.count==1);NSDictionary *site=plan.physicalSites[0];NSArray *variants=site[@"variants"],*indices=site[@"logicalVariantIndexes"];ZNV3Physical physical={original};ZNV3Logical logical={shortBytes};assert([variants[[indices[0] unsignedIntegerValue]] isEqual:ZNV3ComposedVariant(physical,logical)]);logical.enabled=longBytes;assert([variants[[indices[1] unsignedIntegerValue]] isEqual:ZNV3ComposedVariant(physical,logical)]);}}
 puts("PASS: 1000 physical-window plans / 2000 composed variants match exact original NSData compositor; explicit FileOffset and PreferredVA normalize to one site");}return 0;}
