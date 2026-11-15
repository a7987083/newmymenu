#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,sys
record=json.loads(Path('docs/audit/static-plan-source.json').read_text());raw=(Path(sys.argv[1])/record['path']).read_bytes();assert hashlib.sha256(raw).hexdigest()==record['sha256'];s=raw.decode()
def part(a,b):return s[s.index(a):s.index(b)]
body=part('static int64_t ZNV3SX(', 'static uint32_t ZNV3Read32(')+part('static BOOL ZNV3EncodeB(', 'static BOOL ZNV3EncodeADRPX17(')+part('static BOOL ZNV3IsRET(', 'static BOOL ZNV3InboundInterior(')
Path('build/tests').mkdir(parents=True,exist_ok=True);Path('build/tests/original-relocation.inc').write_text(body);print('PASS: exact original V3 relocation and encoder isolated from hash-verified source')
