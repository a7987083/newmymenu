#!/usr/bin/env python3
"""Reproducible lexical inventory, never a claim of runtime reachability."""
import argparse, hashlib, json, re, subprocess
from pathlib import Path
APIS = ('method_exchangeImplementations','method_setImplementation','class_replaceMethod','class_addMethod','method_getImplementation','imp_implementationWithBlock','class_getInstanceMethod','class_getClassMethod','objc_getClass','objc_copyClassList','objc_getClassList','objc_copyMethodList','objc_msgSend')
def git(root,*args):
    return subprocess.check_output(['git','-C',str(root),*args],text=True).strip()
def inventory(root):
    base=root/'iosruntimepatchmenu'
    make=(base/'Makefile').read_text()
    compiled=set(re.search(r'^ZonoePatchV03_FILES\s*=\s*(.+)$',make,re.M).group(1).split())
    files=[]; sites=[]
    for p in sorted((base/'src').rglob('*')):
        if p.suffix not in ('.m','.mm','.h','.c','.cpp'): continue
        data=p.read_bytes(); txt=data.decode('utf-8'); rel=p.relative_to(root).as_posix()
        directly=p.relative_to(base).as_posix() in compiled
        files.append(dict(path=rel,sha256=hashlib.sha256(data).hexdigest(),direct_translation_unit=directly))
        section=''; callable_hint=''
        for n,line in enumerate(txt.splitlines(),1):
            if '#pragma mark - BEGIN' in line: section=line.split('BEGIN',1)[1].strip()
            if re.match(r'^(?:[-+]\s*\(|(?:extern "C" )?void ZNInstall|static .*\()',line): callable_hint=line[:240]
            for api in APIS:
                for match in re.finditer(r'\b'+api+r'\s*\(',line):
                    sites.append(dict(path=rel,line=n,column=match.start()+1,api=api,section=section,callable_hint=callable_hint,direct_translation_unit=directly,text=line[:240],status='lexical_candidate_not_runtime_verified'))
    refs=[]
    for line in git(root,'for-each-ref','--format=%(refname:short) %(objectname)','refs/remotes/origin').splitlines():
        ref,sha=line.split();
        if ref=='origin/HEAD': continue
        stats=git(root,'diff','--numstat','HEAD',sha,'--','iosruntimepatchmenu','customer','.github/workflows')
        refs.append(dict(ref=ref,sha=sha,diff_numstat_from_candidate=stats))
    return dict(schema_version=1,source_head=git(root,'rev-parse','HEAD'),source_repository='https://github.com/a7987083/mymenu',limitations=['Lexical scan includes comments, wrappers and headers.','Direct translation unit is a Makefile fact; not proof of runtime reachability.','Inlined source sections are recorded; standalone copies may not be linked.','callable_hint is a navigation hint, not a parsed call graph.'],branches=refs,files=files,sites=sites)
def main():
    p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    result=inventory(a.source);a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(f"{len(result['files'])} files, {len(result['sites'])} lexical API candidates; runtime reachability unverified")
if __name__=='__main__':main()
