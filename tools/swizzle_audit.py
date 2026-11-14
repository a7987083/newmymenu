#!/usr/bin/env python3
"""Source-only installer/selector index. Does not infer installed runtime IMPs."""
import argparse,json,re
from pathlib import Path
from source_audit import inventory

def masked(text):
 # Preserve offsets and newlines; remove strings as well as comments for braces.
 pattern=r'//[^\n]*|/\*[\s\S]*?\*/|@?"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\''
 return re.sub(pattern,lambda m:''.join('\n' if c=='\n' else ' ' for c in m.group()),text)
def closing(mask,start,left='(',right=')'):
 depth=0
 for i in range(start,len(mask)):
  if mask[i]==left:depth+=1
  elif mask[i]==right:
   depth-=1
   if depth==0:return i
 return None
def functions(text):
 mask=masked(text);out=[]
 for m in re.finditer(r'\b(?:static\s+)?void\s+(ZN\w+)\s*\([^;{}]*\)\s*\{',mask):
  start=mask.index('{',m.start());end=closing(mask,start,'{','}')
  if end is not None:out.append(dict(name=m.group(1),start=m.start(),body_start=start,end=end,body=text[start:end+1]))
 return out
def build(root):
 inv=inventory(root);entries=[];defs={};wrappers=set();sourcefiles={}
 for f in inv['files']:
  if not f['direct_translation_unit']:continue
  text=(root/f['path']).read_text();sourcefiles[f['path']]=text
  for fn in functions(text):
   fn.update(path=f['path'],line=text.count('\n',0,fn['start'])+1,body_line=text.count('\n',0,fn['body_start'])+1)
   # Multiple definitions must remain visible rather than silently overwrite.
   defs.setdefault(fn['name'],[]).append(fn)
   if 'method_exchangeImplementations' in masked(fn['body']):
    if not fn['name'].startswith('ZNInstall'):wrappers.add(fn['name'])
 roots=['ZNInstallRuntimeMenuV055Deferred','ZNInstallFeatureGroupUIDeferred','ZNInstallPublicCompactDefaultsDeferred','ZNInstallIL2CPPNamedOffsetWorkspaceDeferred','ZNInstallFeatureBuilderUIDeferred','ZNInstallRuntimeMethodCallBuilderUIDeferred','ZNInstallMethodFinderUnifiedUIDeferred','ZNInstallM630HardCutUIDeferred']
 edges={}
 for name,variants in defs.items():
  calls=set()
  for fn in variants:
   calls.update(re.findall(r'\b(ZN\w+)\s*\(',masked(fn['body'])))
  edges[name]=sorted(calls-{name})
 reachable=set();pending=list(roots)
 while pending:
  node=pending.pop()
  if node in reachable:continue
  reachable.add(node);pending.extend(edges.get(node,[]))
 for name,variants in defs.items():
  for fn in variants:
   body=fn['body'];mask=masked(body)
   if not any(api in mask for api in ('method_exchangeImplementations','method_setImplementation','class_replaceMethod','class_addMethod')) and not any(re.search(r'\b'+w+r'\s*\(',mask) for w in wrappers):continue
   local_classes={m.group(1):m.group(2).strip() for m in re.finditer(r'Class\s+(\w+)\s*=\s*([^;]+);',body)}
   lookups=[]
   for m in re.finditer(r'\b(class_getInstanceMethod|class_getClassMethod)\s*\(\s*([^,]+),\s*@selector\(([^)]+)\)',body):
    lookups.append(dict(api=m.group(1),class_expression=m.group(2).strip(),selector=m.group(3)))
   swaps=[]
   for wrapper in sorted(wrappers):
    for m in re.finditer(r'\b'+wrapper+r'\s*\(',mask):
     op=mask.index('(',m.start());end=closing(mask,op)
     if end is None:continue
     call=body[m.start():end+1]
     sels=re.findall(r'@selector\(([^)]+)\)',call)
     swaps.append(dict(wrapper=wrapper,call=call,line=fn['body_line']+body.count('\n',0,m.start()),selectors=sels))
   entries.append(dict(function=name,path=fn['path'],line=fn['line'],source_call_graph_reachable_from_activation=name in reachable,reachability_limit='C function graph only; conditional branches and ObjC dispatch are unresolved',class_bindings=local_classes,method_lookups=lookups,wrapper_calls=swaps,dispatch_once='dispatch_once' in mask,type_encoding_used='method_getTypeEncoding' in mask,has_imp_read='method_getImplementation' in mask,has_imp_write='method_setImplementation' in mask,has_exchange='method_exchangeImplementations' in mask,review_status='needs_selector_ownership_ABI_and_runtime_confirmation'))
 return dict(schema_version=1,source_head=inv['source_head'],activation_roots=roots,wrappers=sorted(wrappers),functions=entries,limitations=['This index does not establish necessity, actual installation order, runtime type encodings or original IMPs.','Non-void helper functions, ObjC method dispatch and callbacks can create additional edges.','Local variable class bindings are navigation aids, not semantic evaluation.'])
def main():
 p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args();d=build(a.source);a.output.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n');print(len(d['wrappers']),'wrappers;',len(d['functions']),'mutation/helper functions;',sum(len(x['wrapper_calls']) for x in d['functions']),'wrapper calls')
if __name__=='__main__':main()
