#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "NMCore.h"
#import "NMIL2CPPDiscovery.h"
#import "NMFinderSession.h"
#import "NMMethodPresentation.h"
#include <math.h>
#ifndef NM_BUILD_SHA
#define NM_BUILD_SHA "local"
#endif
__attribute__((visibility("default"))) const char *NewMyMenuDeviceProbeVersion(void) { return NM_BUILD_SHA; }
static CGFloat NMClamp(CGFloat x,CGFloat low,CGFloat high){return MAX(low,MIN(MAX(low,high),x));}

@interface NMProbeOverlay : UIView <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@end
@interface NMProbeOverlay () {
    UIView *_panel,*_header;
    UIButton *_floating,*_close,*_refresh,*_search,*_back,*_copy,*_share;
    UILabel *_title,*_status;
    UISegmentedControl *_searchMode;
    UITextField *_query;
    UITableView *_table;
    NMFinderSession *_finder;
    NMIL2CPPDiscovery *_service;
    dispatch_queue_t _worker;
    CGFloat _keyboardTop;
    CGPoint _panelOrigin,_floatCenter;
}
@end
@implementation NMProbeOverlay
- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];[button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];button.backgroundColor=[UIColor colorWithRed:.08 green:.22 blue:.33 alpha:1];
    button.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];button.layer.cornerRadius=6;[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return button;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];if(!self)return nil;
    self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;self.backgroundColor=UIColor.clearColor;
    _worker=dispatch_queue_create("newmymenu.probe.metadata",DISPATCH_QUEUE_SERIAL);_finder=[NMFinderSession new];
    _floating=[self button:@"NM 验证" action:@selector(toggle:)];[self addSubview:_floating];
    [_floating addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloating:)]];
    _panel=[UIView new];_panel.backgroundColor=[UIColor colorWithRed:.035 green:.055 blue:.085 alpha:.98];_panel.layer.cornerRadius=12;_panel.layer.borderWidth=1;_panel.layer.borderColor=[UIColor colorWithRed:.1 green:.7 blue:.95 alpha:1].CGColor;_panel.clipsToBounds=YES;_panel.hidden=YES;[self addSubview:_panel];
    _header=[UIView new];[_panel addSubview:_header];[_header addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanel:)]];
    _title=[UILabel new];_title.text=[NSString stringWithFormat:@"newmymenu · 只读验证 %@",[NSString stringWithUTF8String:NM_BUILD_SHA]];_title.textColor=UIColor.whiteColor;_title.font=[UIFont systemFontOfSize:12 weight:UIFontWeightBold];[_header addSubview:_title];
    _close=[self button:@"收起" action:@selector(toggle:)];[_header addSubview:_close];
    _status=[UILabel new];_status.text=@"进入游戏后检查 Runtime，再输入类名关键词。";_status.textColor=[UIColor colorWithWhite:.85 alpha:1];_status.font=[UIFont systemFontOfSize:11];_status.numberOfLines=2;[_panel addSubview:_status];
    _query=[UITextField new];_query.backgroundColor=[UIColor colorWithWhite:.16 alpha:1];_query.textColor=UIColor.whiteColor;_query.font=[UIFont systemFontOfSize:13];_query.attributedPlaceholder=[[NSAttributedString alloc] initWithString:@"类名关键词，例如 Cheat / Player" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:.65 alpha:1]}];_query.borderStyle=UITextBorderStyleRoundedRect;_query.delegate=self;_query.returnKeyType=UIReturnKeySearch;_query.autocorrectionType=UITextAutocorrectionTypeNo;_query.autocapitalizationType=UITextAutocapitalizationTypeNone;[_panel addSubview:_query];
    _searchMode=[[UISegmentedControl alloc] initWithItems:@[@"Class",@"Method"]];_searchMode.selectedSegmentIndex=0;_searchMode.backgroundColor=[UIColor colorWithWhite:.2 alpha:1];[_searchMode setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateNormal];[_searchMode addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];[_panel addSubview:_searchMode];
    _refresh=[self button:@"检查 Runtime" action:@selector(refresh:)];_search=[self button:@"查找类" action:@selector(search:)];_back=[self button:@"‹ 类列表" action:@selector(back:)];_copy=[self button:@"复制报告" action:@selector(copyReport:)];_share=[self button:@"导出报告" action:@selector(shareReport:)];
    for(UIView *v in @[_refresh,_search,_back,_copy,_share])[_panel addSubview:v];_back.hidden=YES;
    _table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];_table.backgroundColor=UIColor.clearColor;_table.separatorColor=[UIColor colorWithWhite:.25 alpha:1];_table.dataSource=self;_table.delegate=self;_table.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;_table.rowHeight=80;[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"NMProbeRow"];[_panel addSubview:_table];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboard:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboard:) name:UIKeyboardWillHideNotification object:nil];
    return self;
}
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self];}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit=[super hitTest:point withEvent:event];return hit==self?nil:hit;
}
- (void)layoutSubviews {
    [super layoutSubviews];UIEdgeInsets safe=self.safeAreaInsets;CGFloat left=safe.left+8,right=self.bounds.size.width-safe.right-8,top=safe.top+8,bottom=self.bounds.size.height-safe.bottom-8;
    if(CGPointEqualToPoint(_floatCenter,CGPointZero))_floatCenter=CGPointMake(right-40,top+20);
    _floatCenter=CGPointMake(NMClamp(_floatCenter.x,left+38,right-38),NMClamp(_floatCenter.y,top+18,bottom-18));_floating.frame=CGRectMake(_floatCenter.x-38,_floatCenter.y-18,76,36);
    CGFloat usableBottom=_keyboardTop>top?MIN(bottom,_keyboardTop-6):bottom;CGFloat width=MIN(360,MAX(100,right-left)),height=MIN(540,MAX(120,usableBottom-top));
    if(CGPointEqualToPoint(_panelOrigin,CGPointZero))_panelOrigin=CGPointMake(left,top+44);
    _panelOrigin=CGPointMake(NMClamp(_panelOrigin.x,left,right-width),NMClamp(_panelOrigin.y,top,usableBottom-height));_panel.frame=CGRectMake(_panelOrigin.x,_panelOrigin.y,width,height);
    _header.frame=CGRectMake(0,0,width,38);_title.frame=CGRectMake(10,0,MAX(0,width-72),38);_close.frame=CGRectMake(width-58,6,48,27);
    _status.frame=CGRectMake(10,40,width-20,38);_query.frame=CGRectMake(10,114,width-20,34);
    _searchMode.frame=CGRectMake(10,80,width-20,28);
    CGFloat col=(width-26)/2;_refresh.frame=CGRectMake(10,154,col,30);_search.frame=CGRectMake(16+col,154,col,30);
    _back.frame=CGRectMake(10,114,width-20,34);_copy.frame=CGRectMake(10,190,col,28);_share.frame=CGRectMake(16+col,190,col,28);
    _table.frame=CGRectMake(6,224,width-12,MAX(0,height-230));
}
- (void)toggle:(id)sender {(void)sender;_panel.hidden=!_panel.hidden;if(_panel.hidden)[self endEditing:YES];[self setNeedsLayout];}
- (void)dragPanel:(UIPanGestureRecognizer *)gesture {CGPoint t=[gesture translationInView:self];_panelOrigin.x+=t.x;_panelOrigin.y+=t.y;[gesture setTranslation:CGPointZero inView:self];[self setNeedsLayout];}
- (void)dragFloating:(UIPanGestureRecognizer *)gesture {CGPoint t=[gesture translationInView:self];_floatCenter.x+=t.x;_floatCenter.y+=t.y;[gesture setTranslation:CGPointZero inView:self];[self setNeedsLayout];}
- (void)keyboard:(NSNotification *)note {
    if([note.name isEqual:UIKeyboardWillHideNotification])_keyboardTop=0;
    else if(_query.isFirstResponder){CGRect frame=[note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];_keyboardTop=[self convertRect:frame fromView:nil].origin.y;}
    [self setNeedsLayout];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {(void)field;[self search:nil];return YES;}
- (void)setBusy:(BOOL)busy {_refresh.enabled=!busy;_search.enabled=!busy;_back.enabled=!busy;_table.userInteractionEnabled=!busy;_searchMode.enabled=!busy;}
- (NSDictionary *)hostInfo {
    NSBundle *bundle=NSBundle.mainBundle;
    return @{@"bundleID":bundle.bundleIdentifier?:@"",@"appVersion":[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]?:@"",@"build":[bundle objectForInfoDictionaryKey:@"CFBundleVersion"]?:@"",@"system":UIDevice.currentDevice.systemVersion?:@""};
}
- (void)runQuery:(NSString *)query classIdentity:(NSDictionary *)identity refresh:(BOOL)refresh {
    [self endEditing:YES];NSUInteger generation=[_finder beginRequestResetClasses:(refresh||!identity) classOffset:_table.contentOffset.y];[self setBusy:YES];_status.text=@"正在读取 Runtime 元数据…";
    BOOL methodSearch=_searchMode.selectedSegmentIndex==1;
    NSDictionary *host=[self hostInfo];__weak NMProbeOverlay *weakSelf=self;
    dispatch_async(_worker,^{
        NMProbeOverlay *owner=weakSelf;if(!owner)return;
        NSError *error=nil;NSDictionary *capabilities=[NMIL2CPPDiscovery loadedRuntimeCapabilities];
        if(refresh||!owner->_service)owner->_service=[NMIL2CPPDiscovery loadedRuntimeWithError:&error];
        NSDictionary *snapshot=nil;
        if(owner->_service&&!error){if(identity)snapshot=[owner->_service methodsForClass:identity limit:200 error:&error];else if(query)snapshot=methodSearch?[owner->_service searchMethods:query limit:200 error:&error]:[owner->_service searchClasses:query limit:200 error:&error];}
        NSDictionary *report=@{@"schemaVersion":@1,@"probeBuild":[NSString stringWithUTF8String:NM_BUILD_SHA],@"coreAPI":@(NewMyMenuCoreGetAPIVersion()),@"mode":@"read-only metadata; no runtime_invoke/GCHandle/Hook",@"host":host,@"capabilities":capabilities,@"runtime":owner->_service.runtimeReport?:@{},@"lastSnapshot":snapshot?:@{},@"error":error.localizedDescription?:@"",@"timestamp":[NSISO8601DateFormatter.new stringFromDate:NSDate.date]};
        dispatch_async(dispatch_get_main_queue(),^{
            NMProbeOverlay *view=weakSelf;if(!view)return;
            if(![view->_finder acceptSnapshot:snapshot report:report generation:generation])return;
            [view renderSessionRestoringOffset:NO];
        });
    });
}
- (void)renderSessionRestoringOffset:(BOOL)restore {
    [self setBusy:NO];_back.hidden=!_finder.canReturnToClasses;_query.hidden=_finder.canReturnToClasses;
    NSString *error=_finder.report[@"error"];
    if(error.length)_status.text=[NSString stringWithFormat:@"读取失败：%@",error];
    else if(_finder.snapshot[@"kind"])_status.text=[NSString stringWithFormat:@"%@ %lu 项%@",_finder.methodMode?@"方法":@"类",(unsigned long)_finder.rows.count,[_finder.snapshot[@"truncated"] boolValue]?@" · 扫描受限/结果未完整":@""];
    else _status.text=@"Runtime 导出已绑定；选择模式并输入关键词。";
    [_table reloadData];[self setNeedsLayout];[self layoutIfNeeded];[_table layoutIfNeeded];
    CGFloat low=-_table.adjustedContentInset.top,high=MAX(low,_table.contentSize.height-_table.bounds.size.height+_table.adjustedContentInset.bottom);
    [_table setContentOffset:CGPointMake(0,NMClamp(restore?_finder.classOffset:low,low,high)) animated:NO];
}
- (void)modeChanged:(id)sender {(void)sender;[_search setTitle:_searchMode.selectedSegmentIndex?@"查找方法":@"查找类" forState:UIControlStateNormal];_query.placeholder=_searchMode.selectedSegmentIndex?@"方法名关键词，例如 GetValue":@"类名关键词，例如 Cheat / Player";if(_query.text.length)[self search:nil];else [self refresh:nil];}
- (void)refresh:(id)sender {(void)sender;[self runQuery:nil classIdentity:nil refresh:YES];}
- (void)search:(id)sender {(void)sender;NSString *query=[_query.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!query.length){_status.text=@"请输入类名关键词";return;}[self runQuery:query classIdentity:nil refresh:NO];}
- (void)back:(id)sender {(void)sender;if([_finder returnToClasses])[self renderSessionRestoringOffset:YES];}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;(void)section;return (NSInteger)_finder.rows.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"NMProbeRow" forIndexPath:indexPath];
    UIListContentConfiguration *content=cell.defaultContentConfiguration;
    cell.backgroundColor=UIColor.clearColor;content.textProperties.color=UIColor.whiteColor;content.textProperties.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];content.textProperties.numberOfLines=2;
    content.secondaryTextProperties.color=[UIColor colorWithWhite:.7 alpha:1];content.secondaryTextProperties.font=[UIFont systemFontOfSize:10];content.secondaryTextProperties.numberOfLines=3;
    if((NSUInteger)indexPath.row>=_finder.rows.count){content.text=@"结果已更新";content.secondaryText=nil;cell.contentConfiguration=content;return cell;}
    NSDictionary *row=_finder.rows[(NSUInteger)indexPath.row];content.text=_finder.methodMode?row[@"method"]:row[@"fullType"];
    content.secondaryText=_finder.methodMode?[NMMethodPresentation subtitleForMethod:row]:[NSString stringWithFormat:@"%@ · %@",row[@"assembly"],row[@"namespace"]];
    cell.contentConfiguration=content;cell.accessoryType=_finder.methodMode?UITableViewCellAccessoryNone:UITableViewCellAccessoryDisclosureIndicator;return cell;
}
- (UIViewController *)topController {
    UIViewController *top=self.window.rootViewController;while(top.presentedViewController&&!top.presentedViewController.isBeingDismissed)top=top.presentedViewController;return top;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];if((NSUInteger)indexPath.row>=_finder.rows.count)return;NSDictionary *row=_finder.rows[(NSUInteger)indexPath.row];
    if(!_finder.methodMode){[self runQuery:nil classIdentity:row refresh:NO];return;}
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:row[@"method"] message:row[@"signature"] preferredStyle:UIAlertControllerStyleAlert];
    for(NSDictionary *field in [NMMethodPresentation fieldsForMethod:row]){
        if(![field[@"copyable"] boolValue])continue;
        NSString *value=field[@"value"];
        [alert addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"复制 %@：%@",field[@"label"],value] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){UIPasteboard.generalPasteboard.string=value;}]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];[[self topController] presentViewController:alert animated:YES completion:nil];
}
- (NSData *)reportData {
    NSError *error=nil;NSData *data=[NSJSONSerialization dataWithJSONObject:_finder.report options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&error];
    if(!data)_status.text=error.localizedDescription?:@"报告编码失败";return data;
}
- (void)copyReport:(id)sender {(void)sender;NSData *data=[self reportData];if(data){UIPasteboard.generalPasteboard.string=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];_status.text=@"报告已复制，可直接粘贴回传。";}}
- (void)shareReport:(UIButton *)sender {
    NSData *data=[self reportData];if(!data)return;
    NSURL *url=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"newmymenu-probe-%s.json",NM_BUILD_SHA]]];NSError *error=nil;
    if(![data writeToURL:url options:NSDataWritingAtomic error:&error]){_status.text=error.localizedDescription;return;}
    UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];share.popoverPresentationController.sourceView=sender;share.popoverPresentationController.sourceRect=sender.bounds;[[self topController] presentViewController:share animated:YES completion:nil];
}
@end

@interface NMProbeHost : NSObject
+ (instancetype)shared;
- (void)start;
@end
@implementation NMProbeHost {
    NMProbeOverlay *_overlay;
    NSTimer *_timer;
}
+ (instancetype)shared {static NMProbeHost *host;static dispatch_once_t once;dispatch_once(&once,^{host=[NMProbeHost new];});return host;}
- (UIWindow *)foregroundWindow {
    for(UIScene *scene in UIApplication.sharedApplication.connectedScenes){
        if(![scene isKindOfClass:UIWindowScene.class]||scene.activationState!=UISceneActivationStateForegroundActive)continue;
        for(UIWindow *window in ((UIWindowScene *)scene).windows)if(window.isKeyWindow&&!window.hidden&&window.windowLevel==UIWindowLevelNormal)return window;
    }
    // Unity titles may use the pre-scene UIApplicationDelegate window lifecycle.
    if(UIApplication.sharedApplication.connectedScenes.count==0){
        id<UIApplicationDelegate> delegate=UIApplication.sharedApplication.delegate;
        if([delegate respondsToSelector:@selector(window)]){
            UIWindow *window=delegate.window;
            if(window.isKeyWindow&&!window.hidden&&window.windowLevel==UIWindowLevelNormal)return window;
        }
    }
    return nil;
}
- (void)refresh {
    if(UIApplication.sharedApplication.applicationState!=UIApplicationStateActive)return;
    UIWindow *window=[self foregroundWindow];if(!window)return;
    if(!_overlay)_overlay=[[NMProbeOverlay alloc] initWithFrame:window.bounds];
    if(_overlay.superview!=window){[_overlay removeFromSuperview];_overlay.frame=window.bounds;[window addSubview:_overlay];}
    _overlay.hidden=NO;[window bringSubviewToFront:_overlay];[_overlay setNeedsLayout];
}
- (void)active:(NSNotification *)notification {
    (void)notification;[self refresh];
    if(!_timer){__weak NMProbeHost *weak=self;_timer=[NSTimer scheduledTimerWithTimeInterval:0.75 repeats:YES block:^(__unused NSTimer *timer){[weak refresh];}];}
}
- (void)inactive:(NSNotification *)notification {(void)notification;[_overlay endEditing:YES];_overlay.hidden=YES;[_timer invalidate];_timer=nil;}
- (void)start {
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(active:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(active:) name:UIWindowDidBecomeKeyNotification object:nil];
    [center addObserver:self selector:@selector(active:) name:UISceneDidActivateNotification object:nil];
    [center addObserver:self selector:@selector(inactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self active:nil];
}
@end
__attribute__((constructor)) static void NMDeviceProbeBootstrap(void) {
    dispatch_async(dispatch_get_main_queue(),^{ [[NMProbeHost shared] start]; });
}
