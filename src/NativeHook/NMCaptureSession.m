#import "NMCaptureSession.h"
#include <math.h>

static const char kNMCaptureQueueKey;
static NSError *NMCaptureError(NSInteger code, NSString *message, NSError *underlying) {
    NSMutableDictionary *info=[@{NSLocalizedDescriptionKey:message} mutableCopy];
    if (underlying) info[NSUnderlyingErrorKey]=underlying;
    return [NSError errorWithDomain:@"newmymenu.capture" code:code userInfo:info];
}

@interface NMCaptureToken ()
- (instancetype)initWithTarget:(NSString *)target;
@end
@implementation NMCaptureToken
- (instancetype)initWithTarget:(NSString *)target {
    self=[super init]; if (self) { _identifier=[NSUUID UUID]; _targetIdentity=[target copy]; } return self;
}
- (id)copyWithZone:(NSZone *)zone { (void)zone; return self; }
@end

@interface NMCaptureSessionManager () {
    @private
    dispatch_queue_t _queue;
    dispatch_queue_t _callbackQueue;
    dispatch_source_t _timer;
    NMCaptureInstallHandler _install;
    NMCaptureCloseHandler _close;
    NMCaptureToken *_token;
    id _sessionLifetimeHold;
    NMCaptureCompletion _completion;
    NMReceiverLease *_resultLease;
    NSError *_resultError;
    NMCaptureState _phase;
    NSTimeInterval _timeout;
    BOOL _invalidated;
    BOOL _installAcknowledged;
    BOOL _finishRequested;
    NSUInteger _closeAttempt;
}
- (void)performSync:(dispatch_block_t)block;
- (void)receivedLease:(NMReceiverLease *)lease token:(NMCaptureToken *)token;
- (void)installedToken:(NMCaptureToken *)token error:(nullable NSError *)error;
- (void)requestFinish:(NMCaptureToken *)token lease:(nullable NMReceiverLease *)lease error:(nullable NSError *)error;
- (void)beginClose;
- (void)closedToken:(NMCaptureToken *)token attempt:(NSUInteger)attempt error:(nullable NSError *)error;
- (void)publishLease:(nullable NMReceiverLease *)lease error:(nullable NSError *)error;
@end

@implementation NMCaptureSessionManager
- (instancetype)initWithInstallHandler:(NMCaptureInstallHandler)installHandler closeHandler:(NMCaptureCloseHandler)closeHandler callbackQueue:(dispatch_queue_t)callbackQueue {
    if (!installHandler || !closeHandler || !callbackQueue) return nil;
    self=[super init];
    if (self) {
        _queue=dispatch_queue_create("newmymenu.capture.state",DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_queue,&kNMCaptureQueueKey,(__bridge void *)self,NULL);
        _callbackQueue=callbackQueue; _install=[installHandler copy]; _close=[closeHandler copy]; _phase=NMCaptureStateIdle;
    }
    return self;
}
- (void)performSync:(dispatch_block_t)block {
    if (dispatch_get_specific(&kNMCaptureQueueKey)==(__bridge void *)self) block();
    else dispatch_sync(_queue,block);
}
- (NMCaptureState)state {
    __block NMCaptureState state;
    [self performSync:^{ state=self->_token?self->_phase:(self->_invalidated?NMCaptureStateInvalidated:NMCaptureStateIdle); }];
    return state;
}
- (NMCaptureToken *)startForTarget:(NSString *)target timeout:(NSTimeInterval)timeout completion:(NMCaptureCompletion)completion error:(NSError **)error {
    if (![target isKindOfClass:NSString.class] || !target.length || !isfinite(timeout) || timeout<0.5 || timeout>15.0 || !completion) {
        if (error) *error=NMCaptureError(1,@"Capture requires target, completion, and timeout within 0.5..15 seconds",nil);
        return nil;
    }
    NSString *targetCopy=[target copy];
    __block NMCaptureToken *created=nil; __block NSError *failure=nil;
    [self performSync:^{
        if (self->_invalidated || self->_token) { failure=NMCaptureError(2,@"Capture manager is invalidated or still owns a session",nil); return; }
        created=[[NMCaptureToken alloc] initWithTarget:targetCopy];
        self->_sessionLifetimeHold=self;
        self->_token=created; self->_phase=NMCaptureStateInstalling; self->_completion=[completion copy];
        self->_resultLease=nil; self->_resultError=nil; self->_finishRequested=NO; self->_installAcknowledged=NO;
        self->_timeout=timeout; self->_closeAttempt=0;
        dispatch_async(self->_queue,^{
            @try {
                self->_install(created,^(NMReceiverLease *lease) {
                    dispatch_async(self->_queue,^{ [self receivedLease:lease token:created]; });
                },^(NSError *installError) {
                    dispatch_async(self->_queue,^{ [self installedToken:created error:installError]; });
                });
            } @catch (NSException *exception) {
                [self installedToken:created error:NMCaptureError(3,[NSString stringWithFormat:@"Capture install exception: %@",exception.reason?:exception.name],nil)];
            }
        });
    }];
    if (error) *error=failure;
    return created;
}
- (void)installedToken:(NMCaptureToken *)token error:(NSError *)error {
    if (_token!=token || _installAcknowledged || _phase!=NMCaptureStateInstalling) return;
    _installAcknowledged=YES;
    if (error) { _resultError=error; _finishRequested=YES; }
    if (_finishRequested) { [self beginClose]; return; }
    _phase=NMCaptureStateActive;
    _timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,_queue);
    dispatch_source_set_timer(_timer,dispatch_time(DISPATCH_TIME_NOW,(int64_t)(_timeout*NSEC_PER_SEC)),DISPATCH_TIME_FOREVER,0);
    dispatch_source_set_event_handler(_timer,^{ [self requestFinish:token lease:nil error:NMCaptureError(4,@"Capture timed out",nil)]; });
    dispatch_resume(_timer);
}
- (void)receivedLease:(NMReceiverLease *)lease token:(NMCaptureToken *)token {
    if (![lease isKindOfClass:NMReceiverLease.class]) {
        [self requestFinish:token lease:nil error:NMCaptureError(5,@"Capture backend supplied no owned receiver lease",nil)];
        return;
    }
    [self requestFinish:token lease:lease error:nil];
}
- (void)requestFinish:(NMCaptureToken *)token lease:(NMReceiverLease *)lease error:(NSError *)error {
    if (_token!=token || _finishRequested || (_phase!=NMCaptureStateInstalling && _phase!=NMCaptureStateActive)) return;
    _finishRequested=YES; _resultLease=lease; _resultError=error;
    if (_installAcknowledged) [self beginClose];
}
- (void)beginClose {
    if (!_token || !_installAcknowledged) return;
    if (_timer) { dispatch_source_cancel(_timer); _timer=nil; }
    _phase=NMCaptureStateClosing;
    NMCaptureToken *token=_token; NSUInteger attempt=++_closeAttempt;
    @try {
        _close(token,^(NSError *closeError) {
            dispatch_async(self->_queue,^{ [self closedToken:token attempt:attempt error:closeError]; });
        });
    } @catch (NSException *exception) {
        [self closedToken:token attempt:attempt error:NMCaptureError(6,[NSString stringWithFormat:@"Capture close exception: %@",exception.reason?:exception.name],nil)];
    }
}
- (void)closedToken:(NMCaptureToken *)token attempt:(NSUInteger)attempt error:(NSError *)error {
    if (_token!=token || _phase!=NMCaptureStateClosing || _closeAttempt!=attempt) return;
    if (error) {
        _phase=NMCaptureStateCloseFailed;
        [self publishLease:nil error:NMCaptureError(7,@"Capture backend could not confirm safe closure; session remains owned",error)];
        return;
    }
    [self publishLease:_resultLease error:_resultError];
    _resultLease=nil; _resultError=nil; _token=nil; _phase=NMCaptureStateIdle; _sessionLifetimeHold=nil;
}
- (void)publishLease:(NMReceiverLease *)lease error:(NSError *)error {
    if (!_completion) return;
    NMCaptureCompletion completion=_completion; _completion=nil;
    NMCaptureToken *token=_token;
    dispatch_async(_callbackQueue,^{ completion(token,error?nil:lease,error); });
}
- (void)cancelSession:(NMCaptureToken *)token {
    dispatch_async(_queue,^{ [self requestFinish:token lease:nil error:NMCaptureError(8,@"Capture cancelled",nil)]; });
}
- (void)retryCloseForSession:(NMCaptureToken *)token {
    dispatch_async(_queue,^{ if (self->_token==token && self->_phase==NMCaptureStateCloseFailed) [self beginClose]; });
}
- (void)invalidate {
    dispatch_async(_queue,^{
        self->_invalidated=YES;
        if (self->_token) [self requestFinish:self->_token lease:nil error:NMCaptureError(9,@"Capture manager invalidated",nil)];
    });
}
@end
