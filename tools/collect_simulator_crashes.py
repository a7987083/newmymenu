#!/usr/bin/env python3
"""Collect only this fixture's incident reports before deleting its Simulator."""
import shutil
import subprocess
import sys
from pathlib import Path
output = Path(sys.argv[2]); output.mkdir(parents=True, exist_ok=True)
roots = [Path.home() / 'Library/Logs/DiagnosticReports', Path.home() / 'Library/Developer/CoreSimulator/Devices' / sys.argv[1] / 'data/Library/Logs/CrashReporter']
for index, root in enumerate(roots):
    if root.exists():
        for path in sorted(root.glob('NewMyMenuUIFixture*'))[-10:]:
            if path.is_file() and path.stat().st_size <= 4 * 1024 * 1024:
                shutil.copyfile(path, output / (str(index) + '-' + path.name))

# A codesigning kill may have no app incident or app-process log entry.
checks = [('host-system.log', ['log', 'show', '--last', '5m', '--style', 'compact', '--predicate', 'eventMessage CONTAINS "NewMyMenuUIFixture" OR eventMessage CONTAINS "prepared.dylib"'])]
if len(sys.argv) > 3 and Path(sys.argv[3]).is_file():
    checks += [('prepared-signature.txt', ['codesign', '--verify', '--strict', '--verbose=4', sys.argv[3]]), ('prepared-dyld.txt', ['xcrun', 'dyld_info', '-validate_only', sys.argv[3]])]
for name, command in checks:
    with (output / name).open('wb') as stream:
        try:
            status = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=60).returncode
            stream.write(('\nexit=' + str(status) + '\n').encode())
        except subprocess.TimeoutExpired:
            stream.write(b'\nDiagnostic command timed out\n')
    path = output / name
    if path.stat().st_size > 4 * 1024 * 1024:
        with path.open('r+b') as stream:
            stream.truncate(4 * 1024 * 1024)
