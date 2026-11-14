import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from generate_invoke_audit import method
class InvokeExtractionTests(unittest.TestCase):
 def test_method_slice_preserves_body(self):
  source='- (id)invoke:(id)a error:(id*)error { NSString *s=@"}"; /* } */ if(a){return a;} return s; }\n'
  self.assertEqual(method(source,'invoke:(id)a error:'),source.rstrip())
 def test_ambiguity_fails(self):
  with self.assertRaises(ValueError):method('- (id)x {return nil;}\n- (id)x {return nil;}','x')
 def test_missing_method_fails(self):
  with self.assertRaises(ValueError):method('- (void)y {}','x')
if __name__=='__main__':unittest.main()
