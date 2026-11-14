#!/usr/bin/env python3
"""Real dispatch/timer reproduction; Dobby boundary only is controlled."""
import argparse,hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate(source,out):
 inv=json.loads((ROOT/'docs/audit/source-inventory.json').read_text());hashes={x['path']:x['sha256'] for x in inv['files']};used={}
 def read(name):
  path='iosruntimepatchmenu/src/'+name;data=(source/path).read_bytes();actual=hashlib.sha256(data).hexdigest()
  if actual!=hashes[path]:raise ValueError('Source mismatch: '+path)
  used[path]=actual;return data.decode()
 headers='\n'.join(re.sub(r'^#pragma once\n','',read(x),flags=re.M) for x in ['ZNM47DobbyCompat.h','ZNM47ReceiverCapture.h'])
 implementation=re.sub(r'^#import "[^"\n]+"\n','',read('ZNM47ReceiverCapture.mm'),flags=re.M)
 support=(ROOT/'tests/fixtures/capture_support.mm').read_text();prefix,suffix=support.split('// INSERT EXACT SOURCE HERE\n')
 out.parent.mkdir(parents=True,exist_ok=True);out.write_text('// GENERATED AUDIT ONLY\n'+headers+'\n'+prefix+'\n'+implementation+'\n'+suffix)
 report=dict(source_head=inv['source_head'],source_sha256=used,generated_sha256=hashlib.sha256(out.read_bytes()).hexdigest(),boundaries='DobbyInstrument/Destroy doubles; original receiver capture source and libdispatch timers are real',product=False)
 out.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n');return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('output',type=Path);a=p.parse_args();print(json.dumps(generate(a.source,a.output)))
