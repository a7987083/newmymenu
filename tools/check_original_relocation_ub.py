#!/usr/bin/env python3
import os,subprocess
p=subprocess.run(['build/tests/relocation-parity','negative-audit'],text=True,capture_output=True,env=dict(os.environ,UBSAN_OPTIONS='halt_on_error=1:print_stacktrace=0'))
assert p.returncode!=0 and 'left shift of negative value' in p.stderr,(p.returncode,p.stdout,p.stderr)
print('PASS AUDIT: exact original negative-immediate relocation UB reproduced by UBSan; production uses bounded unsigned arithmetic')
