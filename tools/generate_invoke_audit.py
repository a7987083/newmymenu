#!/usr/bin/env python3
"""Generate a bounded audit executable from exact, hash-pinned source fragments.
Only local imports are removed from M47; entry methods are byte-for-byte slices.
IL2CPP boundaries are controlled doubles. Objective-C dispatch and swaps are real.
"""
import argparse,hashlib,json,re
from pathlib import Path
from swizzle_audit import masked,closing
ROOT=Path(__file__).resolve().parents[1]
BASE='iosruntimepatchmenu/src/'
def method(text,selector_start):
 hits=list(re.finditer(r'^-\s*\([^\n]+?\)'+re.escape(selector_start),text,re.M))
 if len(hits)!=1:raise ValueError(f'Expected one method for {selector_start}, got {len(hits)}')
 start=hits[0].start();mask=masked(text);op=mask.index('{',hits[0].end());end=closing(mask,op,'{','}')
 if end is None:raise ValueError('unbalanced method')
 return text[start:end+1]
def generate(source,out):
 inv=json.loads((ROOT/'docs/audit/source-inventory.json').read_text());hashes={x['path']:x['sha256'] for x in inv['files']}
 def read(name):
  p=BASE+name;data=(source/p).read_bytes()
  if hashlib.sha256(data).hexdigest()!=hashes[p]:raise ValueError('Source mismatch: '+p)
  return data.decode()
 core=read('ZNIL2CPPInvokeEngine.mm');m47=read('ZNM47MultiArgInvoke.mm')
 entries=[method(core,'executeAction:(ZNRuntimeMethodAction *)action error:'),method(core,'executeAction:(ZNRuntimeMethodAction *)action\n')]
 # Distinguish normal error: entry and multiline receiver: overload exactly.
 if 'receiver:(uintptr_t)receiver' not in entries[1]:raise ValueError('wrong receiver overload')
 tls=re.search(r'^static thread_local uintptr_t gZNExplicitReceiverOverride = 0;$',core,re.M)
 if not tls:raise ValueError('missing exact TLS declaration')
 headers=['ZNRuntimeActionFormat.h','ZNRuntimeActionModel.h','ZNIL2CPPABIMetadata.h','ZNRuntimeArgumentMarshaller.h']
 headertext='\n'.join(re.sub(r'^#pragma once\n','',read(h),flags=re.M) for h in headers)
 m47=re.sub(r'^#import "[^"\n]+"\n','',m47,flags=re.M)
 prefix=(ROOT/'tests/fixtures/invoke_support_prefix.mm').read_text()
 suffix=(ROOT/'tests/fixtures/invoke_support_suffix.mm').read_text()
 out.parent.mkdir(parents=True,exist_ok=True)
 out.write_text('// GENERATED AUDIT ONLY; not product code.\n'+headertext+'\n'+tls.group(0)+'\n'+prefix+'\n@implementation ZNIL2CPPInvokeEngine\n'+'\n'.join(entries)+'\n@end\n'+m47+'\n'+suffix)
 report=dict(source_head=inv['source_head'],m47_sha256=hashes[BASE+'ZNM47MultiArgInvoke.mm'],core_sha256=hashes[BASE+'ZNIL2CPPInvokeEngine.mm'],entry_method_sha256=[hashlib.sha256(x.encode()).hexdigest() for x in entries],generated_sha256=hashlib.sha256(out.read_bytes()).hexdigest(),boundaries='IL2CPP resolver, ABI metadata and invoke are doubles; Objective-C method bodies/dispatch/swizzle are real',product=False)
 out.with_suffix('.json').write_text(json.dumps(report,indent=2)+'\n')
 return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('output',type=Path);a=p.parse_args();print(json.dumps(generate(a.source,a.output)))
