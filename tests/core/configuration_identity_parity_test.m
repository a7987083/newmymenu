#import <Foundation/Foundation.h>
#import "NMAuthoringFeatureIdentity.h"
#import "ZNAuthoringRuntimeFeatureIdentity.h"
#include <stdio.h>
#include <stdlib.h>
int main(void){@autoreleasepool{
 for(NSUInteger i=0;i<10000;i++){@autoreleasepool{
  NSMutableDictionary *record=[NSMutableDictionary dictionary];
  if(i%3)record[@"method"]=@"SetValue";
  if(i%4)record[@"title"]=i%2?@"  Feature  ":@"  ";
  if(i%5)record[@"description"]=[NSString stringWithFormat:@"description-%lu",(unsigned long)i%31];
  record[@"executionKind"]=@(i%5);
  if(i%7)record[@"argumentValues"]=@[[NSString stringWithFormat:@"%lu",(unsigned long)i]];
  if(i%11)record[@"argumentControlConfigs"]=@[@{@"type":@"number",@"enabled":@YES}];
  if(i%13)record[@"immediateChain"]=@{@"class":@"Player",@"method":@"Next",@"argumentCount":@0};
  NSString *identity=@"Assembly-CSharp.dll!Game.Player::SetValue(System.Int32)";
  if(![NMAuthoringRuntimeFeatureIdentity(record,identity) isEqual:ZNAuthoringRuntimeFeatureIdentity(record,identity)]){fprintf(stderr,"Feature identity parity failed at %lu\n",(unsigned long)i);abort();}
 }}
 puts("PASS: 10000 Runtime authoring feature identities match original title/value/control/chain semantics");
 }return 0;}
