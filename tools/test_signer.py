#!/usr/bin/env python3
"""Exercise the signer with actual ARM64 Mach-O and an independent codesign verifier."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import plistlib
import shutil

binary = Path(sys.argv[1]).resolve()
driver = Path(sys.argv[2]).resolve()
executable = Path(sys.argv[3]).resolve()
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def call(source, output, expected):
    before = sha(source)
    r = subprocess.run([str(driver), str(source), str(output)], capture_output=True, text=True)
    if (r.returncode == 0) != expected:
        raise SystemExit(f'unexpected signer result: {r.returncode}: {r.stderr}')
    assert sha(source) == before, 'signer changed input'
    assert not list(output.parent.glob('.newmymenu-*')), 'temporary file leaked'
    return r
with tempfile.TemporaryDirectory(prefix='newmymenu-signer-') as folder:
    root = Path(folder)
    signed = root / 'signed.dylib'
    r = call(binary, signed, True)
    metadata = json.loads(r.stdout)
    assert metadata['finalPackageResignRequired'] is True
    assert metadata['publication'] == 'fresh-never-write-mapped-inode'
    subprocess.run(['codesign', '--verify', '--strict', '--verbose=4', str(signed)], check=True)
    requirement = subprocess.run(['codesign', '--display', '-r-', str(signed)], capture_output=True, text=True, check=True)
    assert 'cdhash' in requirement.stdout + requirement.stderr, 'ad-hoc designated requirement must be hash-derived'
    signed_hash = sha(signed)
    call(binary, signed, False)
    assert sha(signed) == signed_hash, 'existing output overwritten'
    call(binary, binary, False)
    link = root / 'source-link'; link.symlink_to(binary)
    call(link, root / 'symlink-output', False)
    assert not (root / 'symlink-output').exists()
    entitled = root / 'entitled-executable'; shutil.copyfile(executable, entitled)
    entitlements = root / 'entitlements.plist'; entitlements.write_bytes(plistlib.dumps({'get-task-allow': True}))
    subprocess.run(['codesign', '--force', '--sign', '-', '--timestamp=none', '--entitlements', str(entitlements), str(entitled)], check=True)
    content = entitled.read_bytes(); assert struct.unpack_from('<I', content, 12)[0] == 2, 'entitlements fixture must be MH_EXECUTE'
    offset = 32; slots = []
    for _ in range(struct.unpack_from('<I', content, 16)[0]):
        cmd, size = struct.unpack_from('<II', content, offset)
        if cmd == 0x1d:
            start, length = struct.unpack_from('<II', content, offset + 8)
            magic, total, count = struct.unpack_from('>III', content, start)
            assert magic == 0xfade0cc0 and total <= length and 12 + count * 8 <= total
            slots = [struct.unpack_from('>I', content, start + 12 + i * 8)[0] for i in range(count)]
            break
        offset += size
    assert 5 in slots or 7 in slots, 'negative fixture did not actually embed entitlements'
    refusal = call(entitled, root / 'entitled-output', False)
    assert 'entitlements' in refusal.stderr and not (root / 'entitled-output').exists(), 'permissions must not be silently dropped'
    raw = binary.read_bytes()
    variants = {'truncated': raw[:25], 'wrong-arch': raw[:4] + struct.pack('<I', 0x1000007) + raw[8:],
                'fat': b'\xca\xfe\xba\xbe' + raw[4:]}
    broken = bytearray(raw)
    struct.pack_into('<I', broken, 16, 0xffffffff)
    variants['invalid-command-count'] = broken
    broken = bytearray(raw)
    ncmds = struct.unpack_from('<I', raw, 16)[0]; offset = 32
    for _ in range(ncmds):
        cmd, size = struct.unpack_from('<II', raw, offset)
        if cmd == 0x19:
            struct.pack_into('<Q', broken, offset + 40, 0xfffffffffffffff0)
            struct.pack_into('<Q', broken, offset + 48, 0x100)
            break
        offset += size
    else:
        raise SystemExit('test Mach-O lacks LC_SEGMENT_64')
    variants['overflow-segment'] = broken
    for name, content in variants.items():
        source = root / name; source.write_bytes(content); output = root / (name + '.signed')
        call(source, output, False); assert not output.exists(), 'failed signing published output'
print('PASS: copied ARM64 signature verified independently; input/output protection, parser negatives and temporary cleanup')
