#!/usr/bin/env python3
"""Extract only hash-verified original mapping function, never execute original builder."""
from pathlib import Path
import hashlib,json,sys
source=json.loads(Path('docs/audit/macho-address-source.json').read_text())
p=Path(sys.argv[1])/source['path'];raw=p.read_bytes()
assert hashlib.sha256(raw).hexdigest()==source['sha256']
s=raw.decode();body=s[s.index('static BOOL ZNV3RVAToFile('):s.index('static BOOL ZNV3InstructionRange(')]
header='''#include <vector>
#include <cstdint>
#include <cassert>
#include <cstdio>
#include "NMMachOAddress.h"
#define BOOL bool
#define YES true
#define NO false
struct ZNV3Segment { uint64_t vmaddr,filesize,fileoff; };
'''
test='''
int main(){NMMachOLayout l={};l.fileSize=4096;l.commandEnd=128;l.imageBase=0x100000000;l.count=1;auto &s=l.segments[0];s.vmaddr=l.imageBase;s.vmsize=4096;s.filesize=4096;__builtin_memcpy(s.name,"__TEXT",7);std::vector<ZNV3Segment> old={{s.vmaddr,s.filesize,0}};
for(uint64_t r=0;r<4096;r++)for(uint64_t n: {1u,4u,16u,128u}){uint64_t a=0,b=0,v=0;size_t i=0;bool x=ZNV3RVAToFile(old,l.imageBase,r,n,a,i),y=NMMachOResolveRange(&l,NMMachOAddressRVA,r,n,&b,&v);assert(x==y);if(x)assert(a==b&&v==r);}
uint64_t a=0,b=0,r=0;size_t i=0;assert(ZNV3RVAToFile(old,l.imageBase,8,UINT64_MAX,a,i));assert(!NMMachOResolveRange(&l,NMMachOAddressRVA,8,UINT64_MAX,&b,&r));puts("PASS: 16384 original mapping parity cases; original span overflow reproduced and new mapper rejects");}
'''
Path('build/tests').mkdir(parents=True,exist_ok=True);Path('build/tests/address-parity.cpp').write_text(header+body+test)
print('PASS: original mapping function hash verified and isolated')
