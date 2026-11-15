#pragma once
#import <Foundation/Foundation.h>
#import "NMMachOAddress.h"
// Rebuild only segment-start index table when two no-fixup owned segments are inserted.
NSData * _Nullable NMExpandChainedStarts(NSData * _Nonnull blob,const NMMachOLayout * _Nonnull layout);
