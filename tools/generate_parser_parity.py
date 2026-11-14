#!/usr/bin/env python3
"""Extract only the fixed baseline's pure parser; never compile its Runtime code."""
import hashlib
import json
import sys
from pathlib import Path
source = Path(sys.argv[1]) / 'iosruntimepatchmenu/src/ZNIL2CPPResolver.mm'
s = source.read_text()
evidence = json.loads(Path('docs/audit/parser-source.json').read_text())
if hashlib.sha256(s.encode()).hexdigest() != evidence['sha256']:
    raise SystemExit('Parser baseline hash mismatch')
trim = s[s.index('static NSString *ZNIL2CPPTrim('):s.index('\nstatic NSString *ZNIL2CPPString(')]
a = s.index('static BOOL ZNIL2CPPParseMagnitude(')
mag = s[a:s.index('\n@interface ZNIL2CPPResolver', a)]
a = s.index('+ (NSDictionary<NSString *,id> *)parseNamedOffsetExpression:')
method = s[a:s.index('\n- (NSDictionary<NSString *,id> *)candidateForMethod:', a)]
method = method.replace('parseNamedOffsetExpression:', 'parse:')
Path(sys.argv[2]).write_text('#import <Foundation/Foundation.h>\n#include <stdint.h>\n#include <stdlib.h>\n#include <errno.h>\n#include <limits.h>\n' + trim + '\n' + mag + '\n@interface NMOriginalNamedExpression : NSObject\n+ (NSDictionary *)parse:(NSString *)s error:(NSString **)e;\n@end\n@implementation NMOriginalNamedExpression\n' + method + '\n@end\n')
print('PASS: original pure parser extracted from hash-verified baseline')
