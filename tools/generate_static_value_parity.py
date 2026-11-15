#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys
path=Path(sys.argv[1])/'iosruntimepatchmenu/src/ZNStaticValueCellV1.mm'
record=json.loads(Path('docs/audit/static-values-source.json').read_text());raw=path.read_bytes();assert hashlib.sha256(raw).hexdigest()==record['sha256'];s=raw.decode();body='\n'.join(line for line in s.splitlines() if line.startswith('static uint32_t ZNVCExpandF32(') or line.startswith('static uint64_t ZNVCExpandF64('));assert body.count('static ')==2
text='#include "NMStaticValues.h"\n#include <assert.h>\n#include <stdio.h>\n'+body+'\nint main(void){NMStaticImmediate r={0};for(unsigned i=0;i<256;i++){uint32_t f=0x1e201000u|(i<<13),d=f|0x400000u;assert(NMStaticDecodeImmediate(&f,4,NMStaticValueF32,&r)&&r.bits==ZNVCExpandF32((uint8_t)i));assert(NMStaticDecodeImmediate(&d,4,NMStaticValueF64,&r)&&r.bits==ZNVCExpandF64((uint8_t)i));}puts("PASS: all 512 immediate values match exact hash-verified original FP expansion");return 0;}\n'
Path('build/tests').mkdir(parents=True,exist_ok=True);Path('build/tests/static-value-parity.c').write_text(text)
