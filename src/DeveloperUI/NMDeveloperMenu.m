#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "NMConfiguration.h"
#import "NMOfflineBuildRequest.h"
#import "NMCore.h"
#import "NMIL2CPPDiscovery.h"
#import "NMFinderSession.h"
#import "NMMethodPresentation.h"
#include <math.h>
#ifndef NM_BUILD_SHA
#define NM_BUILD_SHA "local"
#endif
__attribute__((visibility("default"))) const char *NewMyMenuDeveloperVersion(void) { return NM_BUILD_SHA; }
static CGFloat NMClamp(CGFloat x,CGFloat low,CGFloat high){return MAX(low,MIN(MAX(low,high),x));}

@interface NMDeveloperOverlay : UIView <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UITextViewDelegate,UIDocumentPickerDelegate>
@end
@interface NMDeveloperOverlay () {
    UIView *_panel,*_header;
    UIButton *_floating,*_close,*_refresh,*_search,*_back,*_copy,*_share;
    UILabel *_title,*_status;
    UISegmentedControl *_searchMode;
    UITextField *_query;
    UITableView *_table;
    NMFinderSession *_finder;
    NSProgress *_progress;
    __weak UIViewController *_ownedModal;
    NMIL2CPPDiscovery *_service;
    dispatch_queue_t _worker;
    CGFloat _keyboardTop;
    UISegmentedControl *_pages,*_addressKind;
    UIView *_configPage,*_buildPage,*_diagnosticPage;
    UITextView *_configEditor,*_patchEditor,*_review,*_diagnosticText;
    UIButton *_configPaste,*_configImport,*_configApply,*_configSave,*_configExport;
    UIButton *_chooseBinary,*_patchPaste,*_preview,*_generate,*_exportBuild;
    UILabel *_binaryLabel,*_ackLabel;
    UISwitch *_ack;
    NMConfigurationStore *_configuration;
    NSData *_binaryData;
    NSString *_binaryName;
    NMOfflineBuildRequest *_buildRequest;
    NSDictionary *_buildResult;
    NSUInteger _buildGeneration;
    NSInteger _pickerMode;
    BOOL _buildBusy,_configDraftEdited;

    CGPoint _panelOrigin,_floatCenter;
}
@end
@implementation NMDeveloperOverlay
- (UIButton *)button:(NSString *)title action:(SEL)action {
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];[button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];button.backgroundColor=[UIColor colorWithRed:.08 green:.22 blue:.33 alpha:1];
    button.titleLabel.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];button.layer.cornerRadius=6;[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return button;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];if(!self)return nil;
    self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;self.backgroundColor=UIColor.clearColor;
    _worker=dispatch_queue_create("newmymenu.developer.worker",DISPATCH_QUEUE_SERIAL);_finder=[NMFinderSession new];
    _floating=[self button:@"NM DEV" action:@selector(toggle:)];[self addSubview:_floating];
    [_floating addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFloating:)]];
    _panel=[UIView new];_panel.backgroundColor=[UIColor colorWithRed:.035 green:.055 blue:.085 alpha:.98];_panel.layer.cornerRadius=12;_panel.layer.borderWidth=1;_panel.layer.borderColor=[UIColor colorWithRed:.1 green:.7 blue:.95 alpha:1].CGColor;_panel.clipsToBounds=YES;_panel.hidden=YES;[self addSubview:_panel];
    _header=[UIView new];[_panel addSubview:_header];[_header addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanel:)]];
    _title=[UILabel new];_title.text=[NSString stringWithFormat:@"newmymenu · DEV %@",[NSString stringWithUTF8String:NM_BUILD_SHA]];_title.textColor=UIColor.whiteColor;_title.font=[UIFont systemFontOfSize:12 weight:UIFontWeightBold];[_header addSubview:_title];
    _close=[self button:@"收起" action:@selector(toggle:)];[_header addSubview:_close];
    _status=[UILabel new];_status.text=@"进入游戏后检查 Runtime，再输入类名关键词。";_status.textColor=[UIColor colorWithWhite:.85 alpha:1];_status.font=[UIFont systemFontOfSize:11];_status.numberOfLines=2;[_panel addSubview:_status];
    _query=[UITextField new];_query.backgroundColor=[UIColor colorWithWhite:.16 alpha:1];_query.textColor=UIColor.whiteColor;_query.font=[UIFont systemFontOfSize:13];_query.attributedPlaceholder=[[NSAttributedString alloc] initWithString:@"类名关键词，例如 Cheat / Player" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:.65 alpha:1]}];_query.borderStyle=UITextBorderStyleRoundedRect;_query.delegate=self;_query.returnKeyType=UIReturnKeySearch;_query.autocorrectionType=UITextAutocorrectionTypeNo;_query.autocapitalizationType=UITextAutocapitalizationTypeNone;[_panel addSubview:_query];
    _searchMode=[[UISegmentedControl alloc] initWithItems:@[@"Class",@"Method",@"Expression"]];_searchMode.selectedSegmentIndex=0;_searchMode.backgroundColor=[UIColor colorWithWhite:.2 alpha:1];[_searchMode setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateNormal];[_searchMode addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];[_panel addSubview:_searchMode];
    _refresh=[self button:@"检查 Runtime" action:@selector(refresh:)];_search=[self button:@"查找类" action:@selector(search:)];_back=[self button:@"‹ 类列表" action:@selector(back:)];_copy=[self button:@"复制报告" action:@selector(copyReport:)];_share=[self button:@"导出报告" action:@selector(shareReport:)];
    for(UIView *v in @[_refresh,_search,_back,_copy,_share])[_panel addSubview:v];_back.hidden=YES;
    _table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];_table.backgroundColor=UIColor.clearColor;_table.separatorColor=[UIColor colorWithWhite:.25 alpha:1];_table.dataSource=self;_table.delegate=self;_table.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;_table.rowHeight=80;[_table registerClass:UITableViewCell.class forCellReuseIdentifier:@"NMDeveloperRow"];[_panel addSubview:_table];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboard:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboard:) name:UIKeyboardWillHideNotification object:nil];
    [self setupDeveloperPages];
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
    _status.frame=CGRectMake(10,74,width-20,38);_query.frame=CGRectMake(10,148,width-20,34);
    _searchMode.frame=CGRectMake(10,114,width-20,28);
    CGFloat col=(width-26)/2;_refresh.frame=CGRectMake(10,188,col,30);_search.frame=CGRectMake(16+col,188,col,30);
    _back.frame=CGRectMake(10,148,width-20,34);_copy.frame=CGRectMake(10,224,col,28);_share.frame=CGRectMake(16+col,224,col,28);
    _table.frame=CGRectMake(6,258,width-12,MAX(0,height-264));
    [self layoutDeveloperPagesWidth:width height:height];
}
- (void)toggle:(id)sender {(void)sender;_panel.hidden=!_panel.hidden;if(_panel.hidden)[self endEditing:YES];[self setNeedsLayout];}
- (void)dragPanel:(UIPanGestureRecognizer *)gesture {CGPoint t=[gesture translationInView:self];_panelOrigin.x+=t.x;_panelOrigin.y+=t.y;[gesture setTranslation:CGPointZero inView:self];[self setNeedsLayout];}
- (void)dragFloating:(UIPanGestureRecognizer *)gesture {CGPoint t=[gesture translationInView:self];_floatCenter.x+=t.x;_floatCenter.y+=t.y;[gesture setTranslation:CGPointZero inView:self];[self setNeedsLayout];}
- (void)keyboard:(NSNotification *)note {
    if([note.name isEqual:UIKeyboardWillHideNotification])_keyboardTop=0;
    else if(_query.isFirstResponder||_configEditor.isFirstResponder||_patchEditor.isFirstResponder){CGRect frame=[note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];_keyboardTop=[self convertRect:frame fromCoordinateSpace:self.window.screen.coordinateSpace].origin.y;}
    [self setNeedsLayout];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {(void)field;[self search:nil];return YES;}
- (void)setBusy:(BOOL)busy {_refresh.enabled=!busy;_search.enabled=YES;[_search setTitle:busy?@"取消":(_searchMode.selectedSegmentIndex?@"查找方法":@"查找类") forState:UIControlStateNormal];_back.enabled=!busy;_table.userInteractionEnabled=!busy;_searchMode.enabled=!busy;}
- (NSDictionary *)hostInfo {
    NSBundle *bundle=NSBundle.mainBundle;
    return @{@"bundleID":bundle.bundleIdentifier?:@"",@"appVersion":[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]?:@"",@"build":[bundle objectForInfoDictionaryKey:@"CFBundleVersion"]?:@"",@"system":UIDevice.currentDevice.systemVersion?:@""};
}
- (void)runQuery:(NSString *)query classIdentity:(NSDictionary *)identity refresh:(BOOL)refresh {
    [self endEditing:YES];NSUInteger generation=[_finder beginRequestResetClasses:(refresh||!identity) classOffset:_table.contentOffset.y];[self setBusy:YES];_status.text=@"正在读取 Runtime 元数据…";
    [_progress cancel];NSProgress *progress=[NSProgress progressWithTotalUnitCount:1];_progress=progress;
    BOOL methodSearch=_searchMode.selectedSegmentIndex==1,expressionSearch=_searchMode.selectedSegmentIndex==2;
    NSDictionary *host=[self hostInfo];__weak NMDeveloperOverlay *weakSelf=self;
    dispatch_async(_worker,^{
        NMDeveloperOverlay *owner=weakSelf;if(!owner||progress.cancelled)return;
        NSError *error=nil;NSDictionary *capabilities=[NMIL2CPPDiscovery loadedRuntimeCapabilities];
        if(refresh||!owner->_service)owner->_service=[NMIL2CPPDiscovery loadedRuntimeWithError:&error];
        NSDictionary *snapshot=nil;
        if(owner->_service&&!error){if(identity)snapshot=[owner->_service methodsForClass:identity limit:200 progress:progress error:&error];else if(query)snapshot=expressionSearch?[owner->_service searchMethodExpression:query limit:200 progress:progress error:&error]:methodSearch?[owner->_service searchMethods:query limit:200 progress:progress error:&error]:[owner->_service searchClasses:query limit:200 progress:progress error:&error];}
        NSDictionary *report=@{@"schemaVersion":@1,@"developerBuild":[NSString stringWithUTF8String:NM_BUILD_SHA],@"coreAPI":@(NewMyMenuCoreGetAPIVersion()),@"mode":@"Developer metadata discovery; game execution adapters deferred",@"host":host,@"capabilities":capabilities,@"runtime":owner->_service.runtimeReport?:@{},@"lastSnapshot":snapshot?:@{},@"error":error.localizedDescription?:@"",@"timestamp":[NSISO8601DateFormatter.new stringFromDate:NSDate.date]};
        dispatch_async(dispatch_get_main_queue(),^{
            NMDeveloperOverlay *view=weakSelf;if(!view)return;
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
- (void)modeChanged:(id)sender {(void)sender;[_search setTitle:_searchMode.selectedSegmentIndex?@"查找方法":@"查找类" forState:UIControlStateNormal];_query.placeholder=_searchMode.selectedSegmentIndex==2?@"Class::Method/参数个数":(_searchMode.selectedSegmentIndex?@"方法名关键词，例如 GetValue":@"类名关键词，例如 Cheat / Player");if(_query.text.length)[self search:nil];else [self refresh:nil];}
- (void)refresh:(id)sender {(void)sender;[self runQuery:nil classIdentity:nil refresh:YES];}
- (void)search:(id)sender {(void)sender;if(_finder.busy){[_progress cancel];[_finder cancelPending];[self renderSessionRestoringOffset:NO];_status.text=@"已取消；旧请求结果不会覆盖新页面。";return;}NSString *query=[_query.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(!query.length){_status.text=@"请输入类名关键词";return;}[self runQuery:query classIdentity:nil refresh:NO];}
- (void)back:(id)sender {(void)sender;if([_finder returnToClasses])[self renderSessionRestoringOffset:YES];}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;(void)section;return (NSInteger)_finder.rows.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"NMDeveloperRow" forIndexPath:indexPath];
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
    [alert addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];_ownedModal=alert;[[self topController] presentViewController:alert animated:YES completion:nil];
}
- (NSData *)reportData {
    NSError *error=nil;NSData *data=[NSJSONSerialization dataWithJSONObject:_finder.report options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&error];
    if(!data)_status.text=error.localizedDescription?:@"报告编码失败";return data;
}
- (void)copyReport:(id)sender {(void)sender;NSData *data=[self reportData];if(data){UIPasteboard.generalPasteboard.string=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];_status.text=@"报告已复制，可直接粘贴回传。";}}
- (void)shareReport:(UIButton *)sender {
    NSData *data=[self reportData];if(!data)return;
    NSURL *url=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"newmymenu-runtime-%s.json",NM_BUILD_SHA]]];NSError *error=nil;
    if(![data writeToURL:url options:NSDataWritingAtomic error:&error]){_status.text=error.localizedDescription;return;}
    UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];share.popoverPresentationController.sourceView=sender;share.popoverPresentationController.sourceRect=sender.bounds;_ownedModal=share;[[self topController] presentViewController:share animated:YES completion:nil];
}
- (UITextView *)editor:(BOOL)editable {
    UITextView *v=[UITextView new];v.backgroundColor=[UIColor colorWithWhite:.09 alpha:1];v.textColor=UIColor.whiteColor;v.font=[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];v.layer.cornerRadius=7;v.editable=editable;v.delegate=self;if(editable){UIToolbar *bar=[[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,40)];bar.items=@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],[[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(finishEditing:)]];v.inputAccessoryView=bar;}v.autocorrectionType=UITextAutocorrectionTypeNo;v.autocapitalizationType=UITextAutocapitalizationTypeNone;return v;
}
- (void)setupDeveloperPages {
    _configuration=[NMConfigurationStore new];_pages=[[UISegmentedControl alloc] initWithItems:@[@"查找",@"配置",@"构建",@"状态"]];_pages.selectedSegmentIndex=0;_pages.backgroundColor=[UIColor colorWithWhite:.18 alpha:1];[_pages setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor} forState:UIControlStateNormal];[_pages addTarget:self action:@selector(pageChanged:) forControlEvents:UIControlEventValueChanged];[_panel addSubview:_pages];
    _configPage=[UIView new];_buildPage=[UIView new];_diagnosticPage=[UIView new];for(UIView *v in @[_configPage,_buildPage,_diagnosticPage]){v.hidden=YES;[_panel addSubview:v];}
    _configEditor=[self editor:YES];_configEditor.accessibilityIdentifier=@"nm.config.editor";_configEditor.text=@"{\n  \"format\": \"newmymenu.authoring\",\n  \"schemaVersion\": 1,\n  \"runtimeMethods\": [],\n  \"nativeHooks\": []\n}";[_configPage addSubview:_configEditor];
    _configPaste=[self button:@"粘贴" action:@selector(configPaste:)];_configImport=[self button:@"导入文件" action:@selector(configImport:)];_configApply=[self button:@"校验并应用" action:@selector(configApply:)];_configSave=[self button:@"保存项目" action:@selector(configSave:)];_configExport=[self button:@"导出配置" action:@selector(configExport:)];for(UIView *v in @[_configPaste,_configImport,_configApply,_configSave,_configExport])[_configPage addSubview:v];
    _binaryLabel=[UILabel new];_binaryLabel.text=@"尚未选择待构建 Mach-O";_binaryLabel.textColor=UIColor.whiteColor;_binaryLabel.font=[UIFont systemFontOfSize:11];[_buildPage addSubview:_binaryLabel];_chooseBinary=[self button:@"选择二进制" action:@selector(chooseBinary:)];_patchPaste=[self button:@"粘贴 Patch JSON" action:@selector(patchPaste:)];_addressKind=[[UISegmentedControl alloc] initWithItems:@[@"RVA",@"VA",@"File Offset"]];_addressKind.selectedSegmentIndex=0;_addressKind.backgroundColor=[UIColor colorWithWhite:.22 alpha:1];[_addressKind addTarget:self action:@selector(buildInputChanged:) forControlEvents:UIControlEventValueChanged];_patchEditor=[self editor:YES];_patchEditor.accessibilityIdentifier=@"nm.patch.editor";_patchEditor.text=@"{\"patches\":[{\"offset\":\"0x0\",\"enabled\":\"C0035FD6\",\"title\":\"功能名称\"}]}";_review=[self editor:NO];_review.text=@"选择已解密二进制，填写 Patch，再校验原字节和地址。";
    _preview=[self button:@"校验与预览" action:@selector(previewBuild:)];_generate=[self button:@"生成" action:@selector(generateBuild:)];_exportBuild=[self button:@"导出结果" action:@selector(exportBuild:)];_ack=[UISwitch new];_ack.enabled=NO;_ackLabel=[UILabel new];_ackLabel.text=@"已核对所选文件、原字节及替换字节";_ackLabel.textColor=UIColor.whiteColor;_ackLabel.font=[UIFont systemFontOfSize:10];_ackLabel.numberOfLines=2;for(UIView *v in @[_chooseBinary,_patchPaste,_addressKind,_patchEditor,_review,_preview,_generate,_exportBuild,_ack,_ackLabel])[_buildPage addSubview:v];
    _diagnosticText=[self editor:NO];[_diagnosticPage addSubview:_diagnosticText];_exportBuild.enabled=NO;[self updateDiagnostics];[self loadSavedProject];
}
- (void)layoutDeveloperPagesWidth:(CGFloat)width height:(CGFloat)height {
    _pages.frame=CGRectMake(10,40,width-20,28);CGFloat h=MAX(0,height-120),w=width-20;for(UIView *v in @[_configPage,_buildPage,_diagnosticPage])v.frame=CGRectMake(10,116,w,h);CGFloat third=(w-12)/3,half=(w-6)/2;
    _configPaste.frame=CGRectMake(0,0,third,28);_configImport.frame=CGRectMake(third+6,0,third,28);_configApply.frame=CGRectMake((third+6)*2,0,third,28);_configSave.frame=CGRectMake(0,34,half,28);_configExport.frame=CGRectMake(half+6,34,half,28);_configEditor.frame=CGRectMake(0,68,w,MAX(0,h-68));
    _binaryLabel.frame=CGRectMake(0,0,w,20);_chooseBinary.frame=CGRectMake(0,22,half,28);_patchPaste.frame=CGRectMake(half+6,22,half,28);_addressKind.frame=CGRectMake(0,56,w,26);CGFloat textHeight=MAX(35,MIN(90,(h-185)/2));_patchEditor.frame=CGRectMake(0,88,w,textHeight);_preview.frame=CGRectMake(0,94+textHeight,w,27);_review.frame=CGRectMake(0,127+textHeight,w,MAX(20,h-textHeight-204));_ack.frame=CGRectMake(0,h-71,51,31);_ackLabel.frame=CGRectMake(58,h-71,w-58,31);_generate.frame=CGRectMake(0,h-34,half,28);_exportBuild.frame=CGRectMake(half+6,h-34,half,28);_diagnosticText.frame=CGRectMake(0,0,w,h);
    BOOL patchTyping=_keyboardTop>0&&_patchEditor.isFirstResponder,configTyping=_keyboardTop>0&&_configEditor.isFirstResponder;
    for(UIView *v in @[_binaryLabel,_chooseBinary,_patchPaste,_addressKind,_review,_preview,_generate,_exportBuild,_ack,_ackLabel])v.hidden=patchTyping;
    for(UIView *v in @[_configPaste,_configImport,_configApply,_configSave,_configExport])v.hidden=configTyping;
    if(patchTyping)_patchEditor.frame=CGRectMake(0,0,w,h);if(configTyping)_configEditor.frame=CGRectMake(0,0,w,h);
}
- (void)pageChanged:(id)sender {(void)sender;[_progress cancel];[_finder cancelPending];[self endEditing:YES];_buildGeneration++;_buildBusy=NO;[_generate setTitle:@"生成" forState:UIControlStateNormal];BOOL search=_pages.selectedSegmentIndex==0;for(UIView *v in @[_query,_searchMode,_refresh,_search,_back,_copy,_share,_table])v.hidden=!search;_configPage.hidden=_pages.selectedSegmentIndex!=1;_buildPage.hidden=_pages.selectedSegmentIndex!=2;_diagnosticPage.hidden=_pages.selectedSegmentIndex!=3;if(search)[self renderSessionRestoringOffset:NO];else if(_pages.selectedSegmentIndex==1)_status.text=_configuration.snapshot.document.requiresTargetValidation?@"Runtime / Native 离线配置；目标执行 ABI 暂缓。":@"项目为空：粘贴或导入配置；空 JSON 不会清空现有项目。";else if(_pages.selectedSegmentIndex==2)_status.text=@"只写入新文件；原二进制保持只读。";else{_status.text=@"各项验证状态分开记录。";[self updateDiagnostics];}[self setNeedsLayout];}
- (void)finishEditing:(id)sender {(void)sender;[self endEditing:YES];}
- (void)loadSavedProject {NSError *error=nil;NSURL *url=[self projectURL:&error];if(!url)return;NSNumber *size=nil;[url getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];if(!size)return;if(size.unsignedLongLongValue>4*1024*1024){_status.text=@"已保存项目超过上限，未载入。";return;}__weak NMDeveloperOverlay *weak=self;dispatch_async(_worker,^{NSError *failure=nil;NSData *data=[NSData dataWithContentsOfURL:url options:0 error:&failure];NMConfigurationDocument *document=data?[NMConfigurationDocument documentFromJSONData:data error:&failure]:nil;dispatch_async(dispatch_get_main_queue(),^{NMDeveloperOverlay *view=weak;if(!view||view->_configDraftEdited||view->_configuration.snapshot.revision)return;if(!document){view->_status.text=[NSString stringWithFormat:@"上次项目未载入：%@",failure.localizedDescription];return;}NSError *commit=nil;if([view->_configuration commitDocument:document mode:NMConfigurationImportReplace expectedRevision:0 error:&commit]){view->_configEditor.text=[[NSString alloc] initWithData:[document JSONDataWithError:NULL] encoding:NSUTF8StringEncoding];}else view->_status.text=commit.localizedDescription;});});}
- (void)clearBuildResult {if(_buildResult){NSString *folder=[_buildResult[@"binary"] stringByDeletingLastPathComponent];[NSFileManager.defaultManager removeItemAtPath:folder error:NULL];}_buildResult=nil;_exportBuild.enabled=NO;}
- (BOOL)applyDraft {
    NSData *data=[_configEditor.text dataUsingEncoding:NSUTF8StringEncoding];NSError *error=nil;BOOL ok=[_configuration importJSONData:data mode:NMConfigurationImportReplace expectedRevision:_configuration.snapshot.revision error:&error];_status.text=ok?[NSString stringWithFormat:@"已应用：Runtime %lu / Native %lu，仍需目标验证。",(unsigned long)_configuration.snapshot.document.runtimeMethods.count,(unsigned long)_configuration.snapshot.document.nativeHooks.count]:[NSString stringWithFormat:@"配置未应用：%@",error.localizedDescription];return ok;
}
- (void)configPaste:(id)sender {(void)sender;if(UIPasteboard.generalPasteboard.string)_configEditor.text=UIPasteboard.generalPasteboard.string;_configDraftEdited=YES;}
- (void)configApply:(id)sender {(void)sender;[self endEditing:YES];[self applyDraft];}
- (NSURL *)projectURL:(NSError **)error {NSURL *base=[NSFileManager.defaultManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:error];if(!base)return nil;NSURL *folder=[base URLByAppendingPathComponent:@"newmymenu" isDirectory:YES];if(![NSFileManager.defaultManager createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:error])return nil;return [folder URLByAppendingPathComponent:@"authoring.json"];}
- (void)configSave:(id)sender {(void)sender;if(![self applyDraft])return;NSError *error=nil;NSData *data=[_configuration.snapshot.document JSONDataWithError:&error];NSURL *url=[self projectURL:&error];if(!data||!url||![data writeToURL:url options:NSDataWritingAtomic error:&error])_status.text=[NSString stringWithFormat:@"已应用，但保存失败：%@",error.localizedDescription];else _status.text=@"项目已保存；游戏执行绑定仍未验证。";}
- (void)shareURLs:(NSArray<NSURL *> *)urls sender:(UIView *)sender {UIActivityViewController *share=[[UIActivityViewController alloc] initWithActivityItems:urls applicationActivities:nil];share.popoverPresentationController.sourceView=sender;share.popoverPresentationController.sourceRect=sender.bounds;_ownedModal=share;[[self topController] presentViewController:share animated:YES completion:nil];}
- (void)configExport:(UIButton *)sender {if(![self applyDraft])return;NSError *error=nil;NSData *data=[_configuration.snapshot.document JSONDataWithError:&error];NSURL *url=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"newmymenu-authoring-%@.json",NSUUID.UUID.UUIDString]]];if(!data||![data writeToURL:url options:NSDataWritingWithoutOverwriting error:&error]){_status.text=error.localizedDescription;return;}[self shareURLs:@[url] sender:sender];}
- (void)showPicker:(NSInteger)mode {_pickerMode=mode;UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeData] asCopy:YES];picker.delegate=self;picker.allowsMultipleSelection=NO;_ownedModal=picker;[[self topController] presentViewController:picker animated:YES completion:nil];}
- (void)configImport:(id)sender {(void)sender;[self showPicker:0];}
- (void)chooseBinary:(id)sender {(void)sender;[self showPicker:1];}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {(void)controller;if(!urls.count)return;NSURL *url=urls.firstObject;NSInteger mode=_pickerMode;NSUInteger generation=++_buildGeneration;_status.text=@"正在读取所选文件…";__weak NMDeveloperOverlay *weak=self;dispatch_async(_worker,^{BOOL scoped=[url startAccessingSecurityScopedResource];NSError *error=nil;NSNumber *size=nil;[url getResourceValue:&size forKey:NSURLFileSizeKey error:&error];NSData *data=nil;if(size&&size.unsignedLongLongValue<=(mode?256*1024*1024:4*1024*1024))data=[NSData dataWithContentsOfURL:url options:0 error:&error];if(scoped)[url stopAccessingSecurityScopedResource];dispatch_async(dispatch_get_main_queue(),^{NMDeveloperOverlay *view=weak;if(!view||view->_buildGeneration!=generation)return;if(!data){view->_status.text=[NSString stringWithFormat:@"读取失败或文件超限：%@",error.localizedDescription?:@"请选择有效文件"];return;}if(mode){view->_binaryData=data;view->_binaryName=url.lastPathComponent;view->_binaryLabel.text=[NSString stringWithFormat:@"%@ · %.2f MiB",url.lastPathComponent,data.length/1048576.0];[view buildInputChanged:nil];view->_status.text=@"已读取只读快照；下一步校验 Patch。";}else{NSString *text=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];if(text){view->_configEditor.text=text;view->_configDraftEdited=YES;view->_status.text=@"配置已载入草稿；校验并应用后才改变项目。";}else view->_status.text=@"配置不是 UTF-8 JSON。";}});});}
- (void)patchPaste:(id)sender {(void)sender;if(UIPasteboard.generalPasteboard.string)_patchEditor.text=UIPasteboard.generalPasteboard.string;[self buildInputChanged:nil];}
- (void)textViewDidChange:(UITextView *)view {if(view==_configEditor)_configDraftEdited=YES;if(view==_patchEditor)[self buildInputChanged:nil];}
- (void)buildInputChanged:(id)sender {(void)sender;_buildGeneration++;[_progress cancel];_buildRequest=nil;[self clearBuildResult];_ack.on=NO;_ack.enabled=NO;_buildBusy=NO;[_generate setTitle:@"生成" forState:UIControlStateNormal];_review.text=@"输入已变化，请重新校验；旧预览不能用于生成。";}
- (void)previewBuild:(id)sender {(void)sender;[self endEditing:YES];if(!_binaryData){_status.text=@"先选择要构建的二进制。";return;}NSData *source=_binaryData,*json=[_patchEditor.text dataUsingEncoding:NSUTF8StringEncoding];NSString *name=_binaryName;NMMachOAddressKind kind=(NMMachOAddressKind)(_addressKind.selectedSegmentIndex+1);NSUInteger generation=++_buildGeneration;_buildRequest=nil;_ack.on=NO;_ack.enabled=NO;_status.text=@"正在检查地址、原字节、冲突和指令区域…";__weak NMDeveloperOverlay *weak=self;dispatch_async(_worker,^{NSError *error=nil;NMOfflineBuildRequest *request=[NMOfflineBuildRequest requestWithSource:source name:name patchJSON:json kind:kind error:&error];dispatch_async(dispatch_get_main_queue(),^{NMDeveloperOverlay *view=weak;if(!view||view->_buildGeneration!=generation)return;if(!request){view->_status.text=[NSString stringWithFormat:@"校验失败：%@",error.localizedDescription];return;}view->_buildRequest=request;view->_ack.enabled=YES;NSMutableString *text=[NSMutableString stringWithFormat:@"源 SHA-256：%@\n逻辑 %lu / 物理 %lu\n",request.plan.sourceSHA256,(unsigned long)request.plan.definitions.count,(unsigned long)request.plan.physicalSites.count];for(NSDictionary *row in request.reviewRows)[text appendFormat:@"\n%@ · %@\n原：%@\n新：%@%@\n",row[@"title"],row[@"rva"],row[@"expected"],row[@"replacement"],[row[@"requiresReview"] boolValue]?@"\n含弱候选/旧地址解释，必须复核":@""];for(NSString *warning in request.warnings)[text appendFormat:@"\n提示：%@",warning];view->_review.text=text;view->_status.text=@"地址与原字节校验通过；核对后勾选确认，再生成。";});});}
- (void)generateBuild:(id)sender {(void)sender;if(_buildBusy){[_progress cancel];_buildGeneration++;_buildBusy=NO;[_generate setTitle:@"生成" forState:UIControlStateNormal];_status.text=@"已取消；当前后台步骤完成后释放，不发布旧结果。";return;}if(!_buildRequest||!_ack.on){_status.text=@"先完成预览，并确认所选文件及原/新字节。";return;}[self endEditing:YES];[self clearBuildResult];NMOfflineBuildRequest *request=_buildRequest;NSProgress *progress=[NSProgress progressWithTotalUnitCount:1];_progress=progress;NSUInteger generation=++_buildGeneration;_buildBusy=YES;[_generate setTitle:@"取消" forState:UIControlStateNormal];_status.text=@"正在生成独占 segment 并签名…";NSString *folder=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"newmymenu-build-%@",NSUUID.UUID.UUIDString]];uint64_t nonce=0;arc4random_buf(&nonce,sizeof nonce);__weak NMDeveloperOverlay *weak=self;dispatch_async(_worker,^{NSError *error=nil;NSDictionary *result=[request generateInNewDirectory:folder reviewAcknowledged:YES nonce:nonce progress:progress error:&error];dispatch_async(dispatch_get_main_queue(),^{NMDeveloperOverlay *view=weak;if(!view||view->_buildGeneration!=generation){if(result)[NSFileManager.defaultManager removeItemAtPath:folder error:NULL];return;}view->_buildBusy=NO;[view->_generate setTitle:@"生成" forState:UIControlStateNormal];view->_buildResult=result;view->_exportBuild.enabled=result!=nil;view->_status.text=result?@"新文件已生成并完成内部签名校验；请导出，替换后仍须包级重签与实机测试。":[NSString stringWithFormat:@"生成失败：%@",error.localizedDescription];});});}
- (void)exportBuild:(UIButton *)sender {if(!_buildResult){_status.text=@"尚无成功构建结果。";return;}[self shareURLs:@[[NSURL fileURLWithPath:_buildResult[@"binary"]],[NSURL fileURLWithPath:_buildResult[@"report"]]] sender:sender];}
- (void)updateDiagnostics {_diagnosticText.text=[NSString stringWithFormat:@"newmymenu DEV %s\nCore API %u\n\n已接入：\n• Method Finder / 原始字段复制\n• Runtime 与 Native 离线配置\n• Static Patch 预览、构建、签名、导出\n\n游戏 ABI：按要求暂缓\nRuntime Invoke / Native 执行适配：未接入\n设备 UI、键盘、旋转、多窗口：未验证\n\nCI 不等于实机验证。\n项目保存仅包含已应用的离线配置。",NM_BUILD_SHA,NewMyMenuCoreGetAPIVersion()];}
- (BOOL)ownsPresentedController {return _ownedModal.presentingViewController!=nil||_ownedModal.isBeingPresented;}
- (void)suspend {[_progress cancel];[_finder cancelPending];_buildGeneration++;[self endEditing:YES];}

@end

@interface NMDeveloperHost : NSObject
+ (instancetype)shared;
- (void)start;
@end
@implementation NMDeveloperHost {
    NMDeveloperOverlay *_overlay;
    __weak UIWindow *_preferredWindow;
    NSTimer *_timer;
}
+ (instancetype)shared {static NMDeveloperHost *host;static dispatch_once_t once;dispatch_once(&once,^{host=[NMDeveloperHost new];});return host;}
- (UIWindow *)foregroundWindow {
    UIWindow *existing=_preferredWindow?:_overlay.window;
    if(existing&&!existing.hidden&&existing.isKeyWindow&&existing.windowLevel==UIWindowLevelNormal&&existing.windowScene.activationState==UISceneActivationStateForegroundActive)return existing;
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
    if(!_overlay)_overlay=[[NMDeveloperOverlay alloc] initWithFrame:window.bounds];
    if(_overlay.superview!=window){[_overlay removeFromSuperview];_overlay.frame=window.bounds;[window addSubview:_overlay];}
    _overlay.hidden=[_overlay ownsPresentedController];if(!_overlay.hidden)[window bringSubviewToFront:_overlay];[_overlay setNeedsLayout];
}
- (void)active:(NSNotification *)notification {
    if([notification.object isKindOfClass:UIWindow.class]){UIWindow *window=notification.object;if(window.windowLevel==UIWindowLevelNormal)_preferredWindow=window;}[self refresh];
    if(!_timer){__weak NMDeveloperHost *weak=self;_timer=[NSTimer scheduledTimerWithTimeInterval:0.75 repeats:YES block:^(__unused NSTimer *timer){[weak refresh];}];}
}
- (void)inactive:(NSNotification *)notification {(void)notification;[_overlay suspend];_overlay.hidden=YES;[_timer invalidate];_timer=nil;}
- (void)start {
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(active:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(active:) name:UIWindowDidBecomeKeyNotification object:nil];
    [center addObserver:self selector:@selector(active:) name:UISceneDidActivateNotification object:nil];
    [center addObserver:self selector:@selector(inactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self active:nil];
}
@end
__attribute__((constructor)) static void NMDeveloperBootstrap(void) {
    dispatch_async(dispatch_get_main_queue(),^{ [[NMDeveloperHost shared] start]; });
}
