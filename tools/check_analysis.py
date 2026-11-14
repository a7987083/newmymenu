#!/usr/bin/env python3
"""Fail CI when Clang analyzer reports diagnostics or no report was produced."""
import plistlib
import sys
from pathlib import Path


def main(paths):
    if not paths:
        raise SystemExit("No analyzer reports supplied")
    for name in paths:
        path = Path(name)
        report = plistlib.loads(path.read_bytes())
        if not isinstance(report.get("diagnostics"), list):
            raise SystemExit(f"Invalid analyzer report: {path}")
        if report["diagnostics"]:
            raise SystemExit(f"{path}: {len(report['diagnostics'])} analyzer diagnostics")
    print(f"PASS: {len(paths)} analyzer reports, zero diagnostics")


if __name__ == "__main__":
    main(sys.argv[1:])
