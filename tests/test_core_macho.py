import struct,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from verify_core import inspect

def dylib(command,name):
 data=name.encode()+b'\0';size=(24+len(data)+7)&~7
 return struct.pack('<6I',command,size,24,0,0,0)+data+b'\0'*(size-24-len(data))
def fixture(sdk=(18<<16)|(5<<8),dependency='/usr/lib/libSystem.B.dylib'):
 commands=[struct.pack('<6I',0x32,24,2,14<<16,sdk,0),dylib(0xd,'@rpath/NewMyMenuCore.dylib'),dylib(0xc,dependency)]
 total=sum(map(len,commands))+16;commands.append(struct.pack('<4I',0x1d,16,32+total,4))
 return struct.pack('<8I',0xfeedfacf,0x100000c,0,6,len(commands),total,0,0)+b''.join(commands)+b'fake'
class CoreMachOTests(unittest.TestCase):
 def test_expected_platform_layout(self):self.assertEqual(inspect(fixture())['architecture'],'arm64')
 def test_wrong_sdk_rejected(self):
  with self.assertRaises(ValueError):inspect(fixture(sdk=17<<16))
 def test_foreign_dependency_rejected(self):
  with self.assertRaises(ValueError):inspect(fixture(dependency='@rpath/libdobby.dylib'))
 def test_truncated_signature_rejected(self):
  with self.assertRaises(ValueError):inspect(fixture()[:-1])
 def test_bad_name_offset_rejected(self):
  data=bytearray(fixture());struct.pack_into('<I',data,32+24+8,4)
  with self.assertRaises(ValueError):inspect(data)
 def test_bad_command_count_rejected(self):
  data=bytearray(fixture());struct.pack_into('<I',data,16,200)
  with self.assertRaises(ValueError):inspect(data)
if __name__=='__main__':unittest.main()
