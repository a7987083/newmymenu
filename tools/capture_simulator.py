#!/usr/bin/env python3
"""Bounded system screenshot capture; UI acknowledgement has a separate I/O budget."""
import subprocess, sys
subprocess.run(['xcrun','simctl','io',sys.argv[1],'screenshot',sys.argv[2]],check=True,timeout=60)
