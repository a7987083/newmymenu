#import <Foundation/Foundation.h>
#import "NMMethodTranslator.h"
#import "ZNMethodTranslator.h" // Test-only fixed original implementation.
#include <stdio.h>
static void compare(NSString *name){
 NSString *fresh=[NMMethodTranslator translateMethodName:name],*old=[ZNMethodTranslator translateMethodName:name];
 if(fresh!=old && ![fresh isEqual:old]){NSLog(@"FAIL translation parity %@: %@ != %@",name,fresh,old);abort();}
}
int main(int argc,char **argv){@autoreleasepool{
 if(argc!=2)return 2;
 NSData *data=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];NSError *error=nil;
 NSDictionary *doc=data?[NSJSONSerialization JSONObjectWithData:data options:0 error:&error]:nil;
 NSDictionary *words=doc[@"entries"];
 if(error||![words isKindOfClass:NSDictionary.class]||words.count!=3000)return 3;
 NSUInteger total=0;
 for(NSString *key in words){
  for(NSString *name in @[key,key.uppercaseString,[key stringByAppendingString:@"_coin"],[NSString stringWithFormat:@"Get_%@",key]]){compare(name);total++;}
 }
 for(NSString *name in @[@"",@"zzzznotaword",@"AddCoinGem",@"set_LoginSdkName",@"getplayerlevel",@"中文",@"Vector3"])compare(name);
 printf("PASS: %lu dictionary-derived translations match original implementation; additional edge cases match\n",(unsigned long)total);
 }return 0;}
