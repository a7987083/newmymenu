#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import sys
source = Path(sys.argv[1]) / 'iosruntimepatchmenu/src'
evidence = json.loads(Path('docs/audit/configuration-source.json').read_text())
for name, expected in evidence['files'].items():
    if hashlib.sha256((source / name).read_bytes()).hexdigest() != expected:
        raise SystemExit('Configuration baseline hash mismatch: ' + name)
print('PASS: fixed configuration source hashes reproduced')
