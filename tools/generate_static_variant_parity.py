#!/usr/bin/env python3
"""Isolate the exact original pure NSData compositor; never compile old Builder."""
from pathlib import Path
import json,hashlib,sys
record=json.loads(Path('docs/audit/static-plan-source.json').read_text())
raw=(Path(sys.argv[1])/record['path']).read_bytes()
assert hashlib.sha256(raw).hexdigest()==record['sha256']
s=raw.decode();body=s[s.index('static NSData *ZNV3ComposedVariant('):s.index('static BOOL ZNV3ShiftU32(')]
Path('build/tests').mkdir(parents=True,exist_ok=True)
Path('build/tests/original-variant.inc').write_text(body)
print('PASS: exact hash-verified original NSData variant compositor extracted')
