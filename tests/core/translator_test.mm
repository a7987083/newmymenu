#import <Foundation/Foundation.h>
#import "NMMethodTranslator.h"
#import <dispatch/dispatch.h>
#include <atomic>
#include <stdio.h>
static void check(BOOL value,const char *message){if(!value){fprintf(stderr,"FAIL %s\n",message);abort();}}
int main(){@autoreleasepool{
 NSDictionary *cases=@{@"set_LoginSdkName":@"设置登录 SDK 名称",@"add_coin":@"增加金币",@"addcoin":@"增加金币",@"AddCoin":@"增加金币",@"addCoinGem":@"增加金币和宝石",@"addcoingem":@"增加金币和宝石",@"AddDiamond":@"增加钻石",@"getplayerlevel":@"获取玩家等级",@"BuyWeeklyPass":@"购买周卡"};
 for(NSString *name in cases)check([[NMMethodTranslator translateMethodName:name] isEqual:cases[name]],"baseline expected gloss");
 for(NSString *name in @[@"",@"zzzznotaword",@"!@#",@"中文"])check([NMMethodTranslator translateMethodName:name]==nil,"unknown names do not invent a gloss");
 // UI retains the original name; this API may only return display text.
 NSMutableString *name=[@"AddCoin" mutableCopy];NSString *before=[name copy];
 check([[NMMethodTranslator translateMethodName:name] isEqual:@"增加金币"] && [name isEqual:before],"input name remains unchanged");
 std::atomic<unsigned> failures(0);std::atomic<unsigned> *counter=&failures;
 dispatch_apply(1000,dispatch_get_global_queue(QOS_CLASS_DEFAULT,0),^(size_t index){
  @autoreleasepool{(void)index;if(![[NMMethodTranslator translateMethodName:@"AddCoin"] isEqual:@"增加金币"])counter->fetch_add(1);}
 });
 check(failures.load()==0,"concurrent cache use");
 puts("PASS: translator baseline names, unknowns, input preservation and 1000 concurrent cache calls");
 }return 0;}
