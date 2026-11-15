"""Read the fixture's real linker symbols without preloading its source image."""
import json
import subprocess
import sys
from pathlib import Path
wanted = {'NMStaticFixtureReturn', 'NMStaticFixtureU64', 'NMStaticFixtureF32', 'NMStaticFixtureF64'}
found = {}
for line in subprocess.check_output(['xcrun', 'nm', '-gU', sys.argv[1]], text=True).splitlines():
    columns = line.split()
    if len(columns) == 3 and columns[-1].startswith('_'):
        name = columns[-1][1:]
        if name in wanted:
            if name in found:
                raise SystemExit('Duplicate fixture symbol: ' + name)
            found[name] = int(columns[0], 16)
if set(found) != wanted:
    raise SystemExit('Missing fixture symbols: ' + repr(wanted - set(found)))
Path(sys.argv[2]).write_text(json.dumps(found, sort_keys=True) + '\n')
