import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('audit',ROOT/'tools/source_audit.py');audit=importlib.util.module_from_spec(spec);spec.loader.exec_module(audit)
class AuditIntegrity(unittest.TestCase):
 def test_source_hashes_and_refs(self):
  d=json.loads((ROOT/'docs/audit/source-inventory.json').read_text())
  self.assertEqual(d['source_head'],'7066edeaf9e47580c89440be670c517280534b69')
  self.assertEqual(len({x['path'] for x in d['files']}),len(d['files']))
  for x in d['files']: self.assertRegex(x['sha256'],r'^[a-f0-9]{64}$')
  for x in d['sites']:
   self.assertGreater(x['line'],0);self.assertEqual(x['status'],'lexical_candidate_not_runtime_verified')
  self.assertTrue(any(x['api']=='method_setImplementation' and x['direct_translation_unit'] for x in d['sites']))
 def test_features_do_not_claim_parity(self):
  rows=json.loads((ROOT/'docs/audit/features.json').read_text())
  self.assertGreaterEqual(len(rows),50)
  for x in rows:
   self.assertEqual(x['regression'],'未验证');self.assertEqual(x['new_behavior'],'尚未迁移')
   self.assertNotEqual(x['status'],'已验证可用')
 def test_scanner_exposes_uncompiled_candidates(self):
  # Text candidates include comments by design; test this boundary explicitly.
  with tempfile.TemporaryDirectory() as tmp:
   root=Path(tmp);src=root/'iosruntimepatchmenu/src';src.mkdir(parents=True)
   (src.parent/'Makefile').write_text('ZonoePatchV03_FILES = src/a.mm\n')
   (src/'a.mm').write_text('#pragma mark - BEGIN Inlined.mm\nvoid foo(){method_setImplementation(a,b);}\n')
   (src/'dead.mm').write_text('// method_exchangeImplementations(a,b);\n')
   old=audit.git
   audit.git=lambda root,*args: '0'*40 if args[0]=='rev-parse' else ''
   try:d=audit.inventory(root)
   finally:audit.git=old
   self.assertEqual(len(d['sites']),2)
   self.assertEqual(d['sites'][0]['section'],'Inlined.mm')
   self.assertFalse(d['sites'][1]['direct_translation_unit'])
if __name__=='__main__':unittest.main()
