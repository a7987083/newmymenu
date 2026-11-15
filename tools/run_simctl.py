#!/usr/bin/env python3
"""Bound Simulator subprocess I/O so failures reach artifact collection."""
import subprocess
import sys
command = sys.argv[1:]
if not command:
    raise SystemExit('simctl command required')
# Cold hosted-runner installation exceeded 90s; keep I/O separate from app assertions.
timeout = 360 if command[0] == 'launch' else 240 if command[0] in ('bootstatus', 'install') else 180 if command[0] == 'list' else 90
try:
    result = subprocess.run(['xcrun', 'simctl', *command], timeout=timeout)
except subprocess.TimeoutExpired:
    raise SystemExit('simctl timed out: ' + command[0])
raise SystemExit(result.returncode)
