#import "NMFinderSession.h"
#include <math.h>
@implementation NMFinderSession {
    NSUInteger _generation;
    BOOL _busy;
    NSDictionary *_snapshot,*_report,*_classSnapshot,*_classReport;
    double _classOffset;
}
- (instancetype)init {self=[super init];if(self){_snapshot=@{};_report=@{};}return self;}
- (NSUInteger)generation {return _generation;}
- (BOOL)isBusy {return _busy;}
- (NSDictionary *)snapshot {return _snapshot;}
- (NSDictionary *)report {return _report;}
- (NSArray *)rows {return _snapshot[@"results"]?:@[];}
- (BOOL)methodMode {return [_snapshot[@"kind"] isEqual:@"methods"];}
- (BOOL)canReturnToClasses {return _classSnapshot!=nil&&_snapshot!=_classSnapshot;}
- (double)classOffset {return _classOffset;}
- (NSUInteger)beginRequestResetClasses:(BOOL)reset classOffset:(double)offset {
    NSAssert(NSThread.isMainThread,@"Finder state must be owned by the main thread");
    _generation++;_busy=YES;
    if(reset){_classSnapshot=nil;_classReport=nil;_classOffset=0;_snapshot=@{};_report=@{};}
    else if([_snapshot[@"kind"] isEqual:@"classes"]){_classOffset=isfinite(offset)?MAX(0,offset):0;}
    return _generation;
}
- (BOOL)acceptSnapshot:(NSDictionary *)snapshot report:(NSDictionary *)report generation:(NSUInteger)generation {
    NSAssert(NSThread.isMainThread,@"Finder state must be owned by the main thread");
    if(generation!=_generation)return NO;
    _busy=NO;
    // JSON decoding returns deeply immutable values, independent of producer mutations.
    NSDictionary *payload=@{@"snapshot":snapshot?:@{},@"report":report};
    NSData *data=[NSJSONSerialization isValidJSONObject:payload]?[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil]:nil;
    NSDictionary *frozen=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]:nil;
    NSDictionary *candidate=frozen[@"snapshot"];NSArray *rows=candidate[@"results"];
    BOOL valid=!snapshot || ([rows isKindOfClass:NSArray.class]&&[candidate[@"count"] isKindOfClass:NSNumber.class]&&[candidate[@"count"] unsignedIntegerValue]==rows.count&&([candidate[@"kind"] isEqual:@"classes"]||[candidate[@"kind"] isEqual:@"methods"]));
    if(valid&&snapshot){for(id row in rows)if(![row isKindOfClass:NSDictionary.class]){valid=NO;break;}}
    if(!frozen||!valid){_snapshot=@{};_report=@{@"error":@"Invalid Finder snapshot; refusing count/rows divergence"};return YES;}
    _snapshot=candidate;_report=frozen[@"report"];
    if([candidate[@"kind"] isEqual:@"classes"]){_classSnapshot=candidate;_classReport=_report;_classOffset=0;}
    return YES;
}
- (BOOL)returnToClasses {
    NSAssert(NSThread.isMainThread,@"Finder state must be owned by the main thread");
    if(!_classSnapshot)return NO;
    _generation++;_busy=NO;_snapshot=_classSnapshot;_report=_classReport;return YES;
}
- (void)cancelPending {
    NSAssert(NSThread.isMainThread,@"Finder state must be owned by the main thread");
    if(_busy){_generation++;_busy=NO;}
}
@end
