#import <Foundation/Foundation.h>
#import "NMFinderSession.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
static void check(BOOL condition,const char *message){if(!condition){fprintf(stderr,"FAIL Finder: %s\n",message);abort();}}
static NSDictionary *classes(NSArray *rows){return @{@"kind":@"classes",@"results":rows,@"count":@(rows.count),@"truncated":@NO};}
int main(void){@autoreleasepool{
 NMFinderSession *state=[NMFinderSession new];check(state.rows.count==0&&!state.canReturnToClasses,"initial state empty");
 NSUInteger old=[state beginRequestResetClasses:YES classOffset:0],latest=[state beginRequestResetClasses:YES classOffset:0];
 check(![state acceptSnapshot:classes(@[@{@"class":@"Old"}]) report:@{} generation:old],"out of order result discarded");
 NSMutableDictionary *row=[@{@"class":@"Player"} mutableCopy];NSMutableArray *rows=[NSMutableArray arrayWithObject:row];
 check([state acceptSnapshot:classes(rows) report:@{@"query":@"Player"} generation:latest],"latest result accepted");
 row[@"class"]=@"Changed";[rows removeAllObjects];check(state.rows.count==1&&[state.rows[0][@"class"] isEqual:@"Player"],"deep immutable result independent of producer");
 NSUInteger detail=[state beginRequestResetClasses:NO classOffset:860.5];
 NSDictionary *methods=@{@"kind":@"methods",@"results":@[@{@"method":@"SetValue"}],@"count":@1};
 [state acceptSnapshot:methods report:@{@"query":@"detail"} generation:detail];
 check(state.methodMode&&state.canReturnToClasses&&state.rows.count==1,"detail state derived from snapshot");
 check([state returnToClasses]&&!state.methodMode&&state.classOffset==860.5&&[state.report[@"query"] isEqual:@"Player"],"return restores original classes report and offset without backend");
 check(![state acceptSnapshot:methods report:@{} generation:detail],"return invalidates pending detail completion");
 detail=[state beginRequestResetClasses:NO classOffset:INFINITY];[state acceptSnapshot:nil report:@{@"error":@"missing metadata"} generation:detail];
 check(state.canReturnToClasses&&state.rows.count==0&&state.classOffset==0,"failed detail retains class snapshot and sanitizes offset");check([state returnToClasses]&&state.rows.count==1,"return after error works");
 latest=[state beginRequestResetClasses:YES classOffset:99];check(!state.canReturnToClasses,"new search invalidates prior cache");
 [state acceptSnapshot:classes(@[]) report:@{} generation:latest];check(state.rows.count==0&&[state.snapshot[@"count"] unsignedIntegerValue]==0,"zero results clears old rendered count");
 latest=[state beginRequestResetClasses:YES classOffset:0];[state acceptSnapshot:@{@"kind":@"classes",@"results":@[],@"count":@3} report:@{} generation:latest];
 check(state.rows.count==0&&[state.report[@"error"] length]>0,"count and rows divergence rejected");
 latest=[state beginRequestResetClasses:YES classOffset:0];[state acceptSnapshot:classes(@[@{@"class":@"Fresh"}]) report:@{} generation:latest];
 latest=[state beginRequestResetClasses:YES classOffset:0];[state acceptSnapshot:nil report:@{@"error":@"runtime reset"} generation:latest];check(![state returnToClasses]&&state.rows.count==0,"runtime refresh cannot restore stale binding");
 NSUInteger pending=[state beginRequestResetClasses:YES classOffset:0];check(state.busy&&state.rows.count==0,"fresh request clears stale rendered snapshot");
 [state cancelPending];check(!state.busy,"cancel leaves no busy state");
 check(![state acceptSnapshot:classes(@[@{@"class":@"Late"}]) report:@{} generation:pending]&&state.rows.count==0,"cancelled completion cannot repopulate rows");
 NSUInteger afterCancel=state.generation;[state cancelPending];check(state.generation==afterCancel,"idle cancel is idempotent");
 puts("PASS: Finder immutable snapshots, count/rows parity, stale completion rejection, cached return/scroll and refresh invalidation");
 }return 0;}
