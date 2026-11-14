#pragma once
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger,NMSwizzleInheritance){NMSwizzleInheritanceReject=0,NMSwizzleInheritanceLocalSnapshot=1};
typedef NS_ENUM(NSUInteger,NMSwizzleState){NMSwizzleStateActive=1,NMSwizzleStateRestored=2};
__attribute__((visibility("default")))
@interface NMSwizzleToken : NSObject
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic,readonly) IMP originalImplementation;
@property(nonatomic,readonly) IMP replacementImplementation;
@property(nonatomic,readonly) SEL selector;
@property(nonatomic,readonly) BOOL createdLocalMethod;
@property(atomic,readonly) NMSwizzleState state;
@end
__attribute__((visibility("default")))
@interface NMSwizzleManager : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (nullable instancetype)sharedManager;
// Contract: all target dispatch and competing writers must participate in this domain.
// Uncoordinated external calls/writes cannot be made safe by this manager's lock.
- (BOOL)performInvocation:(void (NS_NOESCAPE ^)(void))operation error:(NSError * _Nullable * _Nullable)error;
- (nullable NMSwizzleToken *)installClass:(Class)target selector:(SEL)selector classMethod:(BOOL)classMethod replacementClass:(Class)replacementClass replacementSelector:(SEL)replacementSelector inheritance:(NMSwizzleInheritance)inheritance dispatchIsCoordinated:(BOOL)coordinated error:(NSError * _Nullable * _Nullable)error;
- (BOOL)restoreToken:(NMSwizzleToken *)token error:(NSError * _Nullable * _Nullable)error;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *diagnostics;
@end
NS_ASSUME_NONNULL_END
