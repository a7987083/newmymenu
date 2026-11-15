#!/usr/bin/env python3
"""Strict, bounded thin Mach-O/exports/dependencies/signature validation."""
import hashlib,json,struct,subprocess,sys
from pathlib import Path
EXPECTED_EXPORTS={'_NMStaticValueToDouble','_NMARM64EncodeLiteral','_NMStaticDecodeImmediate','_NMARM64EncodeADRP','_NMARM64DirectBranchTarget','_NMARM64EncodeBranch','_NMARM64RelocateInstruction','_NMMachOIsInstructionRange','_NMMachOReadLayout','_NMMachOResolveRange','_NewMyMenuCoreGetAPIVersion','_NMRuntimeActionTryEncodeInstanceIndex','_NMRuntimeActionTryDecodeInstanceIndex','_OBJC_CLASS_$_NMMethodTranslator','_OBJC_METACLASS_$_NMMethodTranslator'}
EXPECTED_EXPORTS |= {prefix+name for name in ('NMStaticRuntime','NMOfflineBuildRequest','NMStaticCodePayload','NMStaticBinaryImage','NMStaticPatchDefinition','NMStaticPatchPlan','NMPatchImportDocument','NMConfigurationDocument','NMConfigurationSnapshot','NMConfigurationStore','NMSwizzleManager','NMSwizzleToken','NMMachOSigner','NMBuildItem','NMBuildProvider','NMBuildManifest','NMIL2CPPDiscovery','NMReceiverLease','NMInvocationRequest','NMInvocationCoordinator','NMCaptureToken','NMCaptureSessionManager') for prefix in ('_OBJC_CLASS_$_','_OBJC_METACLASS_$_')}
ALLOWED_DEPS={'/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation','/System/Library/Frameworks/Foundation.framework/Foundation','/usr/lib/libobjc.A.dylib','/usr/lib/libSystem.B.dylib','/usr/lib/libc++.1.dylib'}
def inspect(data, *, install_name='@rpath/NewMyMenuCore.dylib', allowed_deps=None):
 if allowed_deps is None:allowed_deps=ALLOWED_DEPS
 if len(data)<32:raise ValueError('truncated header')
 magic,cpu,subtype,kind,ncmds,sizecmds,flags,reserved=struct.unpack_from('<8I',data)
 if (magic,cpu,kind)!=(0xfeedfacf,0x100000c,6):raise ValueError('expected thin arm64 dylib')
 end=32+sizecmds
 if end>len(data):raise ValueError('load commands out of bounds')
 cursor=32;build=[];signatures=[];deps=[];identities=[]
 for _ in range(ncmds):
  if cursor+8>end:raise ValueError('truncated load command')
  command,size=struct.unpack_from('<2I',data,cursor)
  if size<8 or size%8 or cursor+size>end:raise ValueError('invalid load command size')
  if command==0x32:
   if size<24:raise ValueError('truncated build version')
   platform,minimum,sdk,tools=struct.unpack_from('<4I',data,cursor+8)
   if 24+tools*8>size:raise ValueError('invalid build tools')
   build.append((platform,minimum,sdk))
  elif command==0x1d:
   if size!=16:raise ValueError('invalid signature command')
   offset,length=struct.unpack_from('<2I',data,cursor+8)
   if not length or offset>len(data) or length>len(data)-offset:raise ValueError('signature range out of bounds')
   signatures.append((offset,length))
  elif command in (0xd,0xc,0x80000018,0x8000001f,0x80000023):
   if size<24:raise ValueError('truncated dylib command')
   offset=struct.unpack_from('<I',data,cursor+8)[0]
   if not 24<=offset<size:raise ValueError('invalid dylib name offset')
   string=data[cursor+offset:cursor+size]
   if b'\0' not in string:raise ValueError('unterminated dylib name')
   name=string.split(b'\0',1)[0].decode('utf-8')
   (identities if command==0xd else deps).append(name)
  cursor+=size
 if cursor!=end:raise ValueError('load command size mismatch')
 if build!=[(2,14<<16,(18<<16)|(5<<8))]:raise ValueError('unexpected platform/minimum/SDK: '+repr(build))
 if len(signatures)!=1:raise ValueError('expected one code signature')
 if identities!=[install_name]:raise ValueError('unexpected install name')
 if not deps or any(x not in allowed_deps for x in deps):raise ValueError('unexpected dependencies: '+repr(deps))
 return dict(architecture='arm64',filetype='MH_DYLIB',deployment='14.0',sdk='18.5',dependencies=deps,install_name=identities[0])
def main(path, developer_menu=False):
 allowed=ALLOWED_DEPS|{'/System/Library/Frameworks/UIKit.framework/UIKit','/System/Library/Frameworks/QuartzCore.framework/QuartzCore','/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics','/System/Library/Frameworks/UniformTypeIdentifiers.framework/UniformTypeIdentifiers'} if developer_menu else ALLOWED_DEPS
 result=inspect(path.read_bytes(),install_name='@rpath/NewMyMenuDeveloper.dylib' if developer_menu else '@rpath/NewMyMenuCore.dylib',allowed_deps=allowed)
 expected=EXPECTED_EXPORTS|{'_NewMyMenuDeveloperVersion'} if developer_menu else EXPECTED_EXPORTS
 exports=subprocess.check_output(['nm','-gU',str(path)],text=True)
 symbols={line.split()[-1] for line in exports.splitlines() if line.strip()}
 if symbols!=expected:raise ValueError('export mismatch: '+repr(symbols^expected))
 check=subprocess.run(['codesign','--verify','--strict','--verbose=4',str(path)],text=True,capture_output=True,check=True)
 result.update(exports=sorted(symbols),signature_verified=True,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),product_scope='developer integration UI with offline configuration/Static build; game execution and device validation incomplete' if developer_menu else 'modular foundation library; full developer product and device validation incomplete',source_head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip())
 path.with_name('verification.json').write_text(json.dumps(result,indent=2)+'\n')
 path.with_name('signature.txt').write_text(check.stdout+check.stderr)
 path.with_name('SHA256.txt').write_text(result['sha256']+'  '+path.name+'\n')
 print(json.dumps(result,ensure_ascii=False))
if __name__=='__main__':main(Path(sys.argv[1]), '--developer-menu' in sys.argv[2:])
