#import "NMMethodPresentation.h"
#import "NMMethodTranslator.h"
static NSString *NMText(id value){return [value isKindOfClass:NSString.class]?value:@"";}
@implementation NMMethodPresentation
+ (NSArray<NSDictionary *> *)fieldsForMethod:(NSDictionary *)method {
    NSMutableArray *fields=[NSMutableArray array];
    void (^add)(NSString *,NSString *)=^(NSString *label,NSString *value){
        [fields addObject:@{@"label":label,@"value":value,@"copyable":@(value.length>0&&![value isEqual:@"—"])}];
    };
    NSDictionary *identity=[method[@"classIdentity"] isKindOfClass:NSDictionary.class]?method[@"classIdentity"]:@{};
    add(@"Assembly",NMText(identity[@"assembly"]));add(@"Namespace",NMText(identity[@"namespace"]));add(@"Class",NMText(identity[@"class"]));add(@"Type",NMText(identity[@"fullType"]));
    NSString *name=NMText(method[@"method"]);add(@"Method",name);
    add(@"翻译",[NMMethodTranslator translateMethodName:name]?:@"");
    add(@"Signature",NMText(method[@"signature"]));add(@"Return",NMText(method[@"returnType"]));
    NSArray *params=[method[@"parameterTypes"] isKindOfClass:NSArray.class]?method[@"parameterTypes"]:@[];
    if([method[@"static"] isKindOfClass:NSNumber.class])add(@"Dispatch",[method[@"static"] boolValue]?@"static":@"instance");
    for(NSUInteger i=0;i<params.count;i++)add([NSString stringWithFormat:@"Arg %lu",(unsigned long)i],NMText(params[i]));
    return [fields copy];
}
+ (NSString *)subtitleForMethod:(NSDictionary *)method {
    NSString *translation=[NMMethodTranslator translateMethodName:NMText(method[@"method"])];
    NSString *signature=NMText(method[@"signature"]),*owner=NMText(method[@"classIdentity"][@"fullType"]);
    return [NSString stringWithFormat:@"%@%@%@",owner.length?[owner stringByAppendingString:@" · "]:@"",translation.length?[translation stringByAppendingString:@"\n"]:@"",signature];
}
@end
