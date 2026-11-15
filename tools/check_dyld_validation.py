#!/usr/bin/env python3
from pathlib import Path
import sys
text=Path(sys.argv[1]).read_text()
# The tool may report malformedness without a failing exit; retain output and reject any diagnostics.
assert not any(word in text.lower() for word in ('malformed','error','warning','invalid','unknown option','usage:')),text
print('PASS: independent Apple dyld_info validation emitted no malformedness diagnostics')
