"""Every production implementation is compiled once in the explicit build inventory."""
from pathlib import Path
import subprocess, unittest

class BuildInventory(unittest.TestCase):
    def test_complete_and_unique_sources(self):
        listed=subprocess.check_output(['bash','-c','source scripts/source_lists.sh; printf "%s\\n" "${NM_C_SOURCES[@]}" "${NM_M_SOURCES[@]}" "${NM_MM_SOURCES[@]}" "${NM_UI_SOURCES[@]}"'],text=True).splitlines()
        actual={str(p) for p in Path('src').rglob('*') if p.suffix in {'.c','.m','.mm'}}
        self.assertEqual(set(listed),actual)
        self.assertEqual(len(listed),len(set(listed)))
        names=[Path(p).stem for p in listed]
        self.assertEqual(len(names),len(set(names)), 'object basenames must not collide')
