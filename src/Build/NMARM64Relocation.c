#include "NMARM64Relocation.h"
#include <stddef.h>
// Exact V3 encoding masks/fields, with defined unsigned address arithmetic.
static bool delta(uint64_t from,uint64_t to,unsigned bits,unsigned scale,uint64_t *encoded){
 uint64_t unit=UINT64_C(1)<<scale,limit=UINT64_C(1)<<(bits-1),distance=from<=to?to-from:from-to;
 if(distance&(unit-1))return false;
 distance>>=scale;if(from<=to){if(distance>=limit)return false;*encoded=distance;}else{if(distance>limit)return false;*encoded=((UINT64_C(1)<<bits)-distance)&((UINT64_C(1)<<bits)-1);}return true;
}
static bool target(uint64_t pc,uint64_t immediate,unsigned bits,unsigned scale,uint64_t *out){
 uint64_t sign=UINT64_C(1)<<(bits-1);if(immediate&sign){uint64_t distance=((UINT64_C(1)<<bits)-immediate)<<scale;if(pc<distance)return false;*out=pc-distance;}else{uint64_t distance=immediate<<scale;if(distance>UINT64_MAX-pc)return false;*out=pc+distance;}return true;
}
bool NMARM64DirectBranchTarget(uint32_t insn,uint64_t pc,uint64_t *out){
 if(!out||(pc&3))return false;
 unsigned bits=0;uint64_t field=0;
 if((insn&0x7c000000u)==0x14000000u){bits=26;field=insn&0x3ffffffu;}
 else if((insn&0xff000010u)==0x54000000u||(insn&0x7e000000u)==0x34000000u){bits=19;field=(insn>>5)&0x7ffffu;}
 else if((insn&0x7e000000u)==0x36000000u){bits=14;field=(insn>>5)&0x3fffu;}
 else return false;
 return target(pc,field,bits,2,out);
}
bool NMARM64EncodeBranch(uint64_t from,uint64_t to,bool link,uint32_t *out){uint64_t imm=0;if(!out||(from&3)||(to&3)||!delta(from,to,26,2,&imm))return false;*out=(link?0x94000000u:0x14000000u)|(uint32_t)imm;return true;}
NMARM64RelocationStatus NMARM64RelocateInstruction(uint32_t insn,uint64_t from,uint64_t to,uint64_t start,uint64_t end,NMARM64RelocationResult *out){
 if(!out||(from&3)||(to&3)||(start&3)||(end&3)||end<=start||from<start||end-from<4||from>=end)return NMARM64RelocationInvalid;
 NMARM64RelocationResult result={insn,false};uint64_t t=0,imm=0;unsigned bits=0;uint32_t field=0;
 if((insn&0x7c000000u)==0x14000000u){bits=26;field=insn&0x3ffffffu;}
 else if((insn&0xff000010u)==0x54000000u||(insn&0x7e000000u)==0x34000000u||(insn&0x3b000000u)==0x18000000u){bits=19;field=(insn>>5)&0x7ffffu;}
 else if((insn&0x7e000000u)==0x36000000u){bits=14;field=(insn>>5)&0x3fffu;}
 else if((insn&0xff000010u)==0x54000010u)return NMARM64RelocationUnsupported; // BC.cond: no silent stale PC copy.
 if(bits){
  if(!target(from,field,bits,2,&t))return NMARM64RelocationOverflow;
  if(t>=start&&t<end)return NMARM64RelocationInterior;
  if(!delta(to,t,bits,2,&imm))return NMARM64RelocationOutOfRange;
  if(bits==26){result.instruction=(insn&~0x03ffffffu)|(uint32_t)imm;result.terminal=(insn&0x80000000u)==0;}
  else{uint32_t mask=bits==19?0x00ffffe0u:0x0007ffe0u;result.instruction=(insn&~mask)|((uint32_t)imm<<5);}
 }else{
  uint32_t kind=insn&0x9f000000u;
  if(kind==0x10000000u||kind==0x90000000u){
   unsigned scale=kind==0x90000000u?12:0;uint64_t pc=from&~((UINT64_C(1)<<scale)-1),destination=to&~((UINT64_C(1)<<scale)-1);
   field=(((insn>>5)&0x7ffffu)<<2)|((insn>>29)&3u);
   if(!target(pc,field,21,scale,&t))return NMARM64RelocationOverflow;
   if(t>=start&&t<end)return NMARM64RelocationInterior;
   if(!delta(destination,t,21,scale,&imm))return NMARM64RelocationOutOfRange;
   result.instruction=(insn&~((3u<<29)|(0x7ffffu<<5)))|((uint32_t)(imm&3u)<<29)|((uint32_t)(imm>>2)<<5);
  }else result.terminal=(insn&0xfffffc1fu)==0xd65f0000u||(insn&0xfffffc1fu)==0xd61f0000u;
 }
 *out=result;return NMARM64RelocationOK;
}
