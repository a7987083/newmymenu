#!/usr/bin/env python3
"""Collect only this fixture's incident reports before deleting its Simulator."""
import shutil
import sys
from pathlib import Path
output = Path(sys.argv[2]); output.mkdir(parents=True, exist_ok=True)
roots = [Path.home() / 'Library/Logs/DiagnosticReports', Path.home() / 'Library/Developer/CoreSimulator/Devices' / sys.argv[1] / 'data/Library/Logs/CrashReporter']
for index, root in enumerate(roots):
    if root.exists():
        for path in sorted(root.glob('NewMyMenuUIFixture*'))[-10:]:
            if path.is_file() and path.stat().st_size <= 4 * 1024 * 1024:
                shutil.copyfile(path, output / (str(index) + '-' + path.name))
