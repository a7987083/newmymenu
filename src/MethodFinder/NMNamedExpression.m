#import "NMNamedExpression.h"
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <limits.h>
// Pure grammar reused from fixed original resolver; no Runtime/layout fallbacks.
static NSString *NMNamedTrim(NSString *value) {
    return [value ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static BOOL NMNamedMagnitude(NSString *text, uint64_t *value) {
    NSString *s = NMNamedTrim(text);
    if (!s.length) return NO;
    const char *c = s.UTF8String;
    char *end = NULL;
    errno = 0;
    unsigned long long v = strtoull(c, &end, 0);
    if (errno || end == c || (end && *end)) return NO;
    if (value) *value = (uint64_t)v;
    return YES;
}

@implementation NMNamedExpression
+ (NSDictionary<NSString *,id> *)parse:(NSString *)expression error:(NSString **)error {
    NSString *raw = NMNamedTrim(expression);
    if (!raw.length) {
        if (error) *error = @"Named Offset 不能为空";
        return nil;
    }

    NSString *core = raw;
    int64_t delta = 0;
    NSRegularExpression *deltaRE = [NSRegularExpression regularExpressionWithPattern:@"([+-])(0[xX][0-9A-Fa-f]+|[0-9]+)$" options:0 error:nil];
    NSTextCheckingResult *deltaMatch = [deltaRE firstMatchInString:core options:0 range:NSMakeRange(0, core.length)];
    if (deltaMatch && NSMaxRange(deltaMatch.range) == core.length) {
        NSString *sign = [core substringWithRange:[deltaMatch rangeAtIndex:1]];
        NSString *magnitudeText = [core substringWithRange:[deltaMatch rangeAtIndex:2]];
        uint64_t magnitude = 0;
        if (!NMNamedMagnitude(magnitudeText, &magnitude) || magnitude > (uint64_t)INT64_MAX) {
            if (error) *error = @"Named Offset delta 超出范围";
            return nil;
        }
        delta = [sign isEqualToString:@"-"] ? -(int64_t)magnitude : (int64_t)magnitude;
        core = NMNamedTrim([core substringToIndex:deltaMatch.range.location]);
    }

    NSInteger argumentCount = -1;
    BOOL argumentSpecified = NO;
    NSRegularExpression *argRE = [NSRegularExpression regularExpressionWithPattern:@"/([0-9]+)$" options:0 error:nil];
    NSTextCheckingResult *argMatch = [argRE firstMatchInString:core options:0 range:NSMakeRange(0, core.length)];
    if (argMatch && NSMaxRange(argMatch.range) == core.length) {
        NSString *argText = [core substringWithRange:[argMatch rangeAtIndex:1]];
        unsigned long long parsed = strtoull(argText.UTF8String, NULL, 10);
        if (parsed > INT_MAX) {
            if (error) *error = @"Named Offset 参数数量超出范围";
            return nil;
        }
        argumentCount = (NSInteger)parsed;
        argumentSpecified = YES;
        core = NMNamedTrim([core substringToIndex:argMatch.range.location]);
    }

    NSString *assembly = @"";
    NSRange bang = [core rangeOfString:@"!"];
    if (bang.location != NSNotFound) {
        assembly = NMNamedTrim([core substringToIndex:bang.location]);
        core = NMNamedTrim([core substringFromIndex:NSMaxRange(bang)]);
        if (!assembly.length || !core.length) {
            if (error) *error = @"Named Offset 的 Assembly!Method 格式无效";
            return nil;
        }
    }

    NSString *namespaceName = @"";
    NSString *className = @"";
    NSString *methodName = core;
    BOOL namespaceSpecified = NO;
    NSRange classSep = [core rangeOfString:@"::" options:NSBackwardsSearch];
    if (classSep.location != NSNotFound) {
        NSString *classSpec = NMNamedTrim([core substringToIndex:classSep.location]);
        methodName = NMNamedTrim([core substringFromIndex:NSMaxRange(classSep)]);
        if (!classSpec.length || !methodName.length) {
            if (error) *error = @"Named Offset 的 Class::Method 格式无效";
            return nil;
        }
        NSRange dot = [classSpec rangeOfString:@"." options:NSBackwardsSearch];
        if (dot.location != NSNotFound) {
            namespaceName = NMNamedTrim([classSpec substringToIndex:dot.location]);
            className = NMNamedTrim([classSpec substringFromIndex:NSMaxRange(dot)]);
            namespaceSpecified = YES;
        } else {
            className = classSpec;
        }
    }

    methodName = NMNamedTrim(methodName);
    if (!methodName.length) {
        if (error) *error = @"Named Offset 缺少方法名";
        return nil;
    }
    if ([methodName rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location != NSNotFound) {
        if (error) *error = @"Named Offset 方法名不能包含空白";
        return nil;
    }

    NSMutableDictionary *parsed = [@{
        @"raw": raw,
        @"assembly": assembly,
        @"namespace": namespaceName,
        @"class": className,
        @"method": methodName,
        @"argumentSpecified": @(argumentSpecified),
        @"namespaceSpecified": @(namespaceSpecified),
        @"delta": @(delta),
    } mutableCopy];
    if (argumentSpecified) parsed[@"argumentCount"] = @(argumentCount);
    return parsed;
}

@end
