#import <Foundation/Foundation.h>
#import "NMMethodPresentation.h"
#import "NMMethodTranslator.h"
#include <stdio.h>
#include <stdlib.h>
static void check(BOOL ok,const char *message){if(!ok){fprintf(stderr,"FAIL presentation: %s\n",message);abort();}}
static NSDictionary *field(NSArray *fields,NSString *name){for(NSDictionary *f in fields)if([f[@"label"] isEqual:name])return f;return nil;}
int main(){@autoreleasepool{
 NSDictionary *identity=@{@"assembly":@"Assembly-CSharp.dll",@"namespace":@"Game",@"fullType":@"Game.Player"};
 NSDictionary *method=@{@"classIdentity":identity,@"method":@"GetHealth",@"signature":@"System.Int32 GetHealth(System.Int32&)",@"returnType":@"System.Int32",@"parameterTypes":@[@"System.Int32&"],@"static":@NO};
 NSArray *fields=[NMMethodPresentation fieldsForMethod:method];
 check([field(fields,@"Method")[@"value"] isEqual:@"GetHealth"],"clipboard name remains original");
 check([field(fields,@"Arg 0")[@"value"] isEqual:@"System.Int32&"],"ByRef type spelling preserved");
 check([field(fields,@"Return")[@"value"] isEqual:@"System.Int32"]&&[field(fields,@"Class")[@"value"] isEqual:@"Game.Player"],"return and owner fields independent");
 NSString *translation=[NMMethodTranslator translateMethodName:@"GetHealth"];
 check(translation.length&&[field(fields,@"翻译")[@"value"] isEqual:translation],"uses the existing offline translator");
 check([method[@"method"] isEqual:@"GetHealth"]&&[method[@"parameterTypes"][0] isEqual:@"System.Int32&"],"presentation never mutates metadata");
 check([[NMMethodPresentation subtitleForMethod:method] containsString:@"Game.Player"]&&[[NMMethodPresentation subtitleForMethod:method] containsString:translation],"subtitle renders owner and translation");
 NSArray *empty=[NMMethodPresentation fieldsForMethod:@{@"method":@"—"}];check(![field(empty,@"Method")[@"copyable"] boolValue]&&![field(empty,@"Return")[@"copyable"] boolValue],"unknown placeholders cannot be copied");
 check(!field(fields,@"RVA")&&!field(fields,@"Pointer"),"unverified native addresses are not invented");
 puts("PASS: method detail fields keep raw clipboard values, ByRef types, original identity and offline display translation");
 }return 0;}
