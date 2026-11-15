#!/usr/bin/env python3
"""Compile only the fixed original's pure Patch JSON helpers for an audit fixture."""
import hashlib
import json
from pathlib import Path
import sys
root = Path(sys.argv[1]) / 'iosruntimepatchmenu/src'
evidence = json.loads(Path('docs/audit/configuration-source.json').read_text())
s = (root / 'ZNPatchJSONImporter.mm').read_text()
if hashlib.sha256(s.encode()).hexdigest() != evidence['files']['ZNPatchJSONImporter.mm']:
    raise SystemExit('Patch importer baseline mismatch')
a = s.index('static NSString *ZNJIKey(')
b = s.index('static void ZNJICollectJSONNamesPOSIX(', a)
helpers = s[a:b]
Path(sys.argv[2]).write_text('#import <Foundation/Foundation.h>\n#include <errno.h>\n#include <stdint.h>\n#include <stdlib.h>\n#include <stdio.h>\n' + helpers + '\n' + Path('tests/core/patch_import_audit_body.inc').read_text())
print('PASS: fixed original Patch parser helpers extracted; no discovery gate or game Runtime code compiled')
