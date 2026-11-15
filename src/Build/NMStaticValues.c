#include <string.h>
#include <math.h>
#include "NMStaticValues.h"
static uint32_t read32(const unsigned char *p){return (uint32_t)p[0]|(uint32_t)p[1]<<8|(uint32_t)p[2]<<16|(uint32_t)p[3]<<24;}
bool NMStaticDecodeImmediate(const void *bytes,size_t length,NMStaticValueType requested,NMStaticImmediate *out){
 if(!bytes||!out||!length||(length&3)||length>128||(unsigned)requested>6)return false;
 const unsigned char *p=bytes;uint32_t first=read32(p),reg=first&31u;NMStaticImmediate r={0,reg,1,requested};if(reg==31)return false;
 if((first&0x7f800000u)==0x52800000u){bool wide=(first&0x80000000u)!=0;uint32_t hw=(first>>21)&3u;if(!wide&&hw>1)return false;if(r.type==0)r.type=wide?NMStaticValueI64:NMStaticValueI32;if((wide&&(r.type!=NMStaticValueI64&&r.type!=NMStaticValueU64))||(!wide&&(r.type!=NMStaticValueI32&&r.type!=NMStaticValueU32)))return false;r.bits=(uint64_t)((first>>5)&0xffffu)<<(hw*16);
  for(size_t i=1;i<length/4;i++){uint32_t op=read32(p+i*4);if((op&0x7f800000u)!=0x72800000u||(op&31u)!=reg||((op^first)&0x80000000u))break;uint32_t shift=((op>>21)&3u)*16;if(!wide&&shift>16)return false;r.bits=(r.bits&~(UINT64_C(0xffff)<<shift))|((uint64_t)((op>>5)&0xffffu)<<shift);r.consumedInstructions++;}
 }else if((first&0xff201fe0u)==0x1e201000u&&((first>>22)&3u)<2){bool wide=((first>>22)&3u)==1;if(r.type==0)r.type=wide?NMStaticValueF64:NMStaticValueF32;if(r.type!=(wide?NMStaticValueF64:NMStaticValueF32))return false;uint8_t imm=(uint8_t)((first>>13)&255u);uint64_t sign=(imm>>7)&1u,b=(imm>>6)&1u,low=(imm>>4)&3u,frac=imm&15u;if(wide){uint64_t exp=((b?0u:1u)<<10)|(b?0x3fcu:0u)|low;r.bits=(sign<<63)|(exp<<52)|(frac<<48);}else{uint64_t exp=((b?0u:1u)<<7)|(b?0x7cu:0u)|low;r.bits=(sign<<31)|(exp<<23)|(frac<<19);}
 }else return false;
 *out=r;return true;
}

// Only presentation/range checks use double; U64 writes retain exact integer bits.
bool NMStaticValueToDouble(uint64_t bits,NMStaticValueType type,double *result){
 if(!result)return false;
 double value;
 switch(type){
 case NMStaticValueI32:{uint32_t raw=(uint32_t)bits;int32_t x;memcpy(&x,&raw,4);value=x;break;}
 case NMStaticValueU32:value=(uint32_t)bits;break;
 case NMStaticValueI64:{int64_t x;memcpy(&x,&bits,8);value=(double)x;break;}
 case NMStaticValueU64:value=(double)bits;break;
 case NMStaticValueF32:{uint32_t raw=(uint32_t)bits;float x;memcpy(&x,&raw,4);value=x;break;}
 case NMStaticValueF64:memcpy(&value,&bits,8);break;
 default:return false;
 }
 if(!isfinite(value))return false;
 *result=value;return true;
}
