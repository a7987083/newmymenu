#include "NMMachOAddress.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
static void w32(unsigned char *p,uint32_t n){for(unsigned i=0;i<4;i++)p[i]=(unsigned char)(n>>(8*i));}
static void w64(unsigned char *p,uint64_t n){w32(p,(uint32_t)n);w32(p+4,(uint32_t)(n>>32));}
static void fixture(unsigned char *b){memset(b,0,1024);w32(b,0xfeedfacf);w32(b+4,0x100000c);w32(b+12,6);w32(b+16,2);w32(b+20,144);unsigned char *s=b+32;w32(s,0x19);w32(s+4,72);memcpy(s+8,"__TEXT",6);w64(s+24,0x100000000);w64(s+32,512);w64(s+48,512);s+=72;w32(s,0x19);w32(s+4,72);memcpy(s+8,"__DATA",6);w64(s+24,0x100001000);w64(s+32,1024);w64(s+40,512);w64(s+48,512);}
static void bad(unsigned char *b){NMMachOLayout l;memset(&l,0x55,sizeof l);NMMachOLayout saved=l;assert(!NMMachOReadLayout(b,1024,&l));assert(!memcmp(&l,&saved,sizeof l));}
int main(int argc,char **argv){if(argc==2){FILE *f=fopen(argv[1],"rb");assert(f);assert(!fseek(f,0,SEEK_END));long size=ftell(f);assert(size>0);rewind(f);void *data=malloc((size_t)size);assert(data);assert(fread(data,1,(size_t)size,f)==(size_t)size);assert(!fclose(f));NMMachOLayout real;assert(NMMachOReadLayout(data,(size_t)size,&real));uint64_t o=1,r=1;assert(NMMachOResolveRange(&real,NMMachOAddressRVA,0,32,&o,&r)&&o==0&&r==0);free(data);puts("PASS: actual built ARM64 dylib layout and image-base mapping");return 0;}assert(argc==1);unsigned char b[1025];fixture(b+1);NMMachOLayout l;assert(NMMachOReadLayout(b+1,1024,&l));uint64_t off=77,rva=88;
 assert(NMMachOResolveRange(&l,NMMachOAddressRVA,0x1000,512,&off,&rva)&&off==512&&rva==0x1000);
 assert(NMMachOResolveRange(&l,NMMachOAddressPreferredVA,0x100001004,4,&off,&rva)&&off==516&&rva==0x1004);
 assert(NMMachOResolveRange(&l,NMMachOAddressFileOffset,516,4,&off,&rva)&&off==516&&rva==0x1004);
 off=77;rva=88;assert(!NMMachOResolveRange(&l,NMMachOAddressRVA,0x11ff,2,&off,&rva));assert(off==77&&rva==88);
 assert(!NMMachOResolveRange(&l,NMMachOAddressRVA,UINT64_MAX,4,&off,&rva));assert(!NMMachOResolveRange(&l,NMMachOAddressRVA,1,UINT64_MAX,&off,&rva));assert(!NMMachOResolveRange(&l,NMMachOAddressFileOffset,1024,1,&off,&rva));assert(!NMMachOResolveRange(&l,4,0,4,&off,&rva));assert(!NMMachOResolveRange(&l,1,0,0,&off,&rva));
 fixture(b);w64(b+32+24,UINT64_MAX-256);bad(b);fixture(b);w64(b+104+24,0x100000100);bad(b);fixture(b);w64(b+104+40,400);bad(b);fixture(b);w64(b+104+48,UINT64_MAX);bad(b);fixture(b);w32(b+20,152);bad(b);fixture(b);w32(b+36,71);bad(b);fixture(b);w32(b+32+64,1);bad(b);fixture(b);w32(b+4,7);bad(b);fixture(b);w32(b+12,12);bad(b);
 for(size_t n=0;n<176;n++)assert(!NMMachOReadLayout(b,n,&l));
 fixture(b);assert(NMMachOReadLayout(b,1024,&l));l.count=129;assert(!NMMachOResolveRange(&l,1,0,4,&off,&rva));
 puts("PASS: unaligned ARM64 layout, full-span RVA/VA/file mapping, zero-fill, overflow, overlap, truncation and unchanged failure outputs");return 0;}
