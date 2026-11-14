#pragma once
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "NMReceiverLease.h"
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, NMCaptureState) {
    NMCaptureStateIdle,
    NMCaptureStateInstalling,
    NMCaptureStateActive,
    NMCaptureStateClosing,
    NMCaptureStateCloseFailed,
    NMCaptureStateInvalidated,
};

__attribute__((visibility("default")))
@interface NMCaptureToken : NSObject <NSCopying>
@property(nonatomic,copy,readonly) NSUUID *identifier;
@property(nonatomic,copy,readonly) NSString *targetIdentity;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef void (^NMCaptureEvent)(NMReceiverLease *lease);
typedef void (^NMCaptureAcknowledgement)(NSError * _Nullable error);
// Nonblocking handlers; each install/close must eventually acknowledge once.
// Manager retains session ownership until successful close; no ack means no forced release.
typedef void (^NMCaptureInstallHandler)(NMCaptureToken *token, NMCaptureEvent event, NMCaptureAcknowledgement installed);
// Success means no callback/trampoline can still access released backend resources.
// DobbyDestroy returning 0 alone does not establish this guarantee.
typedef void (^NMCaptureCloseHandler)(NMCaptureToken *token, NMCaptureAcknowledgement closed);
typedef void (^NMCaptureCompletion)(NMCaptureToken *token, NMReceiverLease * _Nullable lease, NSError * _Nullable error);

__attribute__((visibility("default")))
@interface NMCaptureSessionManager : NSObject
@property(nonatomic,readonly) NMCaptureState state;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithInstallHandler:(NMCaptureInstallHandler)installHandler
                                  closeHandler:(NMCaptureCloseHandler)closeHandler
                                 callbackQueue:(dispatch_queue_t)callbackQueue;
- (nullable NMCaptureToken *)startForTarget:(NSString *)target timeout:(NSTimeInterval)timeout
                               completion:(NMCaptureCompletion)completion error:(NSError * _Nullable * _Nullable)error;
- (void)cancelSession:(NMCaptureToken *)token;
- (void)retryCloseForSession:(NMCaptureToken *)token;
// Reject new sessions; an in-flight install/close remains owned until acknowledged.
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
