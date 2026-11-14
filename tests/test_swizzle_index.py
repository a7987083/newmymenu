import sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from swizzle_audit import functions,masked,closing
class SwizzleIndexTests(unittest.TestCase):
 def test_strings_and_comments_do_not_create_functions_or_braces(self):
  text='// void ZNFalse() {\nstatic void ZNActual(Class cls) { NSString *s=@"} // {"; /* } */ if(cls){ foo(); } }\nextern "C" void ZNNext(void){bar();}'
  result=functions(text)
  self.assertEqual([x['name'] for x in result],['ZNActual','ZNNext'])
  self.assertTrue(result[0]['body'].endswith('}'))
  self.assertIn('foo()',result[0]['body'])
 def test_declaration_is_not_definition(self):
  self.assertEqual(functions('void ZNDeclaration(void);'),[])
 def test_balanced_call_keeps_nested_selectors(self):
  text='ZNSwap(cls,@selector(foo:),@selector(bar:))';m=masked(text);start=m.index('(')
  self.assertEqual(closing(m,start),len(text)-1)
if __name__=='__main__':unittest.main()
