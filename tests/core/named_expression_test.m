#import <Foundation/Foundation.h>
#import "NMNamedExpression.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
@interface NMOriginalNamedExpression : NSObject
+ (NSDictionary *)parse:(NSString *)s error:(NSString **)e;
@end
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL parser: %s\n",message);abort();}}
static void parity(NSString *input){
 NSString *a=nil,*b=nil;NSDictionary *old=[NMOriginalNamedExpression parse:input error:&a],*current=[NMNamedExpression parse:input error:&b];
 check((!old&&!current)||[old isEqual:current],"result differs from original parser");check((!a&&!b)||[a isEqual:b],"error differs from original parser");
}
int main(void){@autoreleasepool{
 NSArray *cases=@[@"",@" ",@"GetValue",@"  GetValue  ",@"Assembly-CSharp.dll!Game.Player::SetValue/2+0x10",@".Player::Run/0",@"Player::Run-8",@"Player::",@"!Run",@"Game.Player::Bad Name",@"Get/2147483648",@"Get+9223372036854775808",@"Get+08",@"A!B!Run",@"A::::Run",@"Get/00",@"Get/18446744073709551616",@"Get-0x7FFFFFFFFFFFFFFF",@"类::方法/1",@"Get/1/2"];
 for(NSString *input in cases)parity(input);
 uint32_t random=0x51f17e;NSString *alphabet=@"abcXYZ019 !.:/+_-\t\n";
 for(NSUInteger i=0;i<10000;i++){@autoreleasepool{NSMutableString *s=[NSMutableString string];random=random*1664525u+1013904223u;NSUInteger length=random%90;for(NSUInteger j=0;j<length;j++){random=random*1664525u+1013904223u;[s appendFormat:@"%C",[alphabet characterAtIndex:random%alphabet.length]];}parity(s);}}
 NSString *error=nil;NSDictionary *p=[NMNamedExpression parse:@"Assembly-CSharp.dll!Game.Player::SetValue/2-0x10" error:&error];
 check(!error&&[p[@"assembly"] isEqual:@"Assembly-CSharp.dll"]&&[p[@"namespace"] isEqual:@"Game"]&&[p[@"class"] isEqual:@"Player"]&&[p[@"method"] isEqual:@"SetValue"]&&[p[@"argumentCount"] intValue]==2&&[p[@"delta"] longLongValue]==-16,"qualified grammar contract");
 puts("PASS: 10020 named expression cases match original result/error; qualified owner, arity, delta and overflow cases");
 }return 0;}
