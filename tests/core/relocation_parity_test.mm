#import <Foundation/Foundation.h>
#include "NMARM64Relocation.h"
#include <cassert>
#include <cstdio>
#include <cstring>
#include "original-relocation.inc"
static uint32_t make(uint32_t op,uint32_t units,unsigned bits){return bits==26?op|units:bits==21?op|((units&3u)<<29)|((units>>2)<<5):op|(units<<5);}
int main(int argc,char **argv){@autoreleasepool{
 if(argc==2){assert(!strcmp(argv[1],"negative-audit"));uint32_t result=0;BOOL terminal=NO;NSString *error=nil;(void)ZNV3Relocate(0x17ffffff,0x100004004,0x100004104,0x100004004,0x100004008,&result,&terminal,&error);return 0;}
 const uint32_t ops[]={0x14000000,0x94000000,0x54000000,0x34000000,0x35000000,0x36000000,0x37000000,0x18000000,0x58000000,0x1c000000,0x10000000,0x90000000};const unsigned widths[]={26,26,19,19,19,14,14,19,19,19,21,21};size_t n=0;
 // Positive encoded immediates avoid the known original negative-left-shift UB, audited separately.
 for(size_t k=0;k<12;k++)for(uint32_t units=1;units<=2000;units++){uint64_t from=0x100004004,to=0x100004104;uint32_t insn=make(ops[k],units,widths[k]),old=0;BOOL terminal=NO;NSString *error=nil;BOOL a=ZNV3Relocate(insn,from,to,from,from+4,&old,&terminal,&error);NMARM64RelocationResult out={};auto b=NMARM64RelocateInstruction(insn,from,to,from,from+4,&out);assert((a!=NO)==(b==NMARM64RelocationOK));if(a){assert(out.instruction==old&&out.terminal==(terminal!=NO));}n++;}
 printf("PASS: %zu exact original relocation result/terminal/error comparisons on defined inputs\n",n);
}return 0;}
