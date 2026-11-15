#include "NMMachOAddress.h"
#include <string.h>
#include <limits.h>
static uint32_t u32(const unsigned char *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
static uint64_t u64(const unsigned char *p){return u32(p)|(uint64_t)u32(p+4)<<32;}
static bool bounded(uint64_t start,uint64_t size,uint64_t limit){return start<=limit&&size<=limit-start;}
static bool overlap(uint64_t a,uint64_t n,uint64_t b,uint64_t m){return n&&m&&(a<=b?b-a<n:a-b<m);}
static bool valid(const NMMachOLayout *l){
 if(!l||!l->count||l->count>NM_MACHO_MAX_SEGMENTS||l->commandEnd<32||l->commandEnd>l->fileSize)return false;
 size_t text=0;
 for(size_t i=0;i<l->count;i++){
  const NMMachOSegment *s=l->segments+i;
  if(!bounded(s->vmaddr,s->vmsize,UINT64_MAX)||!bounded(s->fileoff,s->filesize,l->fileSize)||s->filesize>s->vmsize||s->name[16])return false;
  if(!strcmp(s->name,"__TEXT")){if(s->vmaddr!=l->imageBase||s->fileoff||s->filesize<l->commandEnd)return false;text++;}
  for(size_t j=0;j<i;j++){const NMMachOSegment *t=l->segments+j;if(overlap(s->vmaddr,s->vmsize,t->vmaddr,t->vmsize)||overlap(s->fileoff,s->filesize,t->fileoff,t->filesize))return false;}
 }
 return text==1;
}
bool NMMachOReadLayout(const void *bytes,size_t length,NMMachOLayout *output){
 if(!bytes||!output||length<32)return false;
 const unsigned char *p=bytes;uint32_t type=u32(p+12),commands=u32(p+16),commandSize=u32(p+20);
 if(u32(p)!=0xfeedfacf||u32(p+4)!=0x100000c||(type!=2&&type!=6&&type!=8)||commands>4096||commandSize>16*1024*1024||!bounded(32,commandSize,length))return false;
 NMMachOLayout l={0};l.fileSize=length;l.commandEnd=32+(uint64_t)commandSize;uint64_t at=32;
 for(uint32_t i=0;i<commands;i++){
  if(!bounded(at,8,l.commandEnd))return false;
  const unsigned char *c=p+at;uint32_t cmd=u32(c),size=u32(c+4);
  if(size<8||(size&7)||!bounded(at,size,l.commandEnd))return false;
  if(cmd==0x19){
   if(size<72||l.count==NM_MACHO_MAX_SEGMENTS)return false;
   uint32_t sections=u32(c+64);if(sections>(size-72)/80)return false;
   NMMachOSegment *s=l.segments+l.count++;memcpy(s->name,c+8,16);s->vmaddr=u64(c+24);s->vmsize=u64(c+32);s->fileoff=u64(c+40);s->filesize=u64(c+48);s->protection=u32(c+60);
   if(!strcmp(s->name,"__TEXT"))l.imageBase=s->vmaddr;
   // Preserve segment-based mapping; validate sections instead of relying on them as ranges.
   for(uint32_t j=0;j<sections;j++){const unsigned char *sec=c+72+(uint64_t)j*80;uint64_t va=u64(sec+32),n=u64(sec+40);uint32_t off=u32(sec+48),kind=u32(sec+64)&255;
    if(va<s->vmaddr||!bounded(va-s->vmaddr,n,s->vmsize))return false;
    if(kind!=1&&kind!=12&&kind!=18&&n){if(off<s->fileoff||!bounded(off-s->fileoff,n,s->filesize)||!bounded(off,n,length))return false;}
   }
  }else if(cmd==0x2c){if(size<24||u32(c+16))return false;}
  at+=size;
 }
 if(at!=l.commandEnd||!valid(&l))return false;
 *output=l;return true;
}
bool NMMachOResolveRange(const NMMachOLayout *l,NMMachOAddressKind kind,uint64_t address,uint64_t length,uint64_t *offset,uint64_t *rva){
 if(!offset||!rva||offset==rva||!length||!valid(l))return false;
 uint64_t va=address;
 if(kind==NMMachOAddressRVA){if(!bounded(l->imageBase,address,UINT64_MAX))return false;va=l->imageBase+address;}
 else if(kind!=NMMachOAddressPreferredVA&&kind!=NMMachOAddressFileOffset)return false;
 for(size_t i=0;i<l->count;i++){
  const NMMachOSegment *s=l->segments+i;uint64_t start=kind==NMMachOAddressFileOffset?s->fileoff:s->vmaddr;
  uint64_t input=kind==NMMachOAddressFileOffset?address:va;
  if(input<start||!bounded(input-start,length,s->filesize))continue;
  uint64_t delta=input-start;if(s->vmaddr<l->imageBase&&l->imageBase-s->vmaddr>delta)return false;
  uint64_t preferred=s->vmaddr+delta;if(preferred<l->imageBase)return false;
  *offset=s->fileoff+delta;*rva=preferred-l->imageBase;return true;
 }
 return false;
}
