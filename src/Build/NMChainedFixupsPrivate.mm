#import "NMChainedFixupsPrivate.h"
#include <cstring>
static uint32_t r32(const uint8_t *p){uint32_t v;memcpy(&v,p,4);return v;}static uint16_t r16(const uint8_t *p){uint16_t v;memcpy(&v,p,2);return v;}static uint64_t r64(const uint8_t *p){uint64_t v;memcpy(&v,p,8);return v;}static void w32(uint8_t *p,uint32_t v){memcpy(p,&v,4);}
NSData *NMExpandChainedStarts(NSData *blob,const NMMachOLayout *l){
 if(blob.length<28||blob.length>64*1024*1024||l->count<1)return nil;const uint8_t *b=(const uint8_t *)blob.bytes;uint64_t start=r32(b+4),imports=r32(b+8),symbols=r32(b+12),count=r32(b+16),format=r32(b+20),element=format==1?4:format==2?8:format==3?16:0;
 if(r32(b)||r32(b+24)||!element||start<28||(start&3)||start>blob.length-4||imports>blob.length||symbols>blob.length||imports>symbols||count>(symbols-imports)/element)return nil;
 uint32_t segments=r32(b+start);if(segments!=l->count&&segments+1!=l->count)return nil;uint64_t end=start+4+(uint64_t)segments*4;if(end>imports)return nil;
 for(uint32_t i=0;i<segments;i++){uint64_t off=r32(b+start+4+(uint64_t)i*4);if(!off)continue;if(i>=l->count-1||off<4+(uint64_t)segments*4||off>imports-start||imports-start-off<22)return nil;const uint8_t *seg=b+start+off;uint64_t size=r32(seg),pages=r16(seg+20),pageSize=r16(seg+4);if(size<22+pages*2||size>imports-start-off||(pageSize!=4096&&pageSize!=16384)||l->segments[i].vmaddr<l->imageBase||r64(seg+8)!=l->segments[i].vmaddr-l->imageBase)return nil;}
 uint64_t extra=(l->count+2-segments)*4;NSMutableData *out=[NSMutableData dataWithLength:blob.length+(NSUInteger)extra];uint8_t *p=(uint8_t *)out.mutableBytes;memcpy(p,b,(size_t)end);memcpy(p+end+extra,b+end,blob.length-(NSUInteger)end);w32(p+start,(uint32_t)l->count+2);
 for(uint32_t i=0;i<segments;i++){uint32_t off=r32(p+start+4+(uint64_t)i*4);if(off)w32(p+start+4+(uint64_t)i*4,off+(uint32_t)extra);}
 w32(p+8,(uint32_t)(imports+extra));w32(p+12,(uint32_t)(symbols+extra));return [out copy];
}
