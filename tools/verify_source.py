#!/usr/bin/env python3
"""Verify the fixed source snapshot; remote branch tips are deliberately excluded."""
import json,sys
from pathlib import Path
from source_audit import inventory
expected=json.loads((Path(__file__).resolve().parents[1]/'docs/audit/source-inventory.json').read_text())
actual=inventory(Path(sys.argv[1]))
for key in ('source_head','files','sites'):
 if actual[key]!=expected[key]:raise SystemExit('Source audit mismatch: '+key)
print('PASS: fixed HEAD, all file hashes and Runtime API candidate locations reproduce')
