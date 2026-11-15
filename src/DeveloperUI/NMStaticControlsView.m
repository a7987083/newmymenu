#import "NMStaticControlsView.h"
#import "NMStaticRuntime.h"
#import "NMStaticValues.h"
#include <math.h>
@interface NMStaticControlRow : UIView <UITextFieldDelegate>
@property(nonatomic,copy) NSString *featureIdentifier;
@property(nonatomic,copy) void (^submit)(NMStaticControlRow *,BOOL,NSString *);
@property(nonatomic,strong) UILabel *title,*state;
@property(nonatomic,strong) UITextField *value;
@property(nonatomic,strong) UISwitch *toggle;
@property(nonatomic,strong) UISlider *slider;
@property(nonatomic,strong) UIButton *apply,*restore;
@property(nonatomic) BOOL numeric,integralSlider;
@end
@implementation NMStaticControlRow
- (instancetype)initWithFrame:(CGRect)frame {self=[super initWithFrame:frame];if(self){self.backgroundColor=[UIColor colorWithWhite:.10 alpha:1];self.layer.cornerRadius=8;_title=[UILabel new];_title.textColor=UIColor.whiteColor;_title.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];_state=[UILabel new];_state.textColor=[UIColor colorWithWhite:.75 alpha:1];_state.font=[UIFont systemFontOfSize:10];_state.numberOfLines=2;_value=[UITextField new];_value.delegate=self;_value.borderStyle=UITextBorderStyleRoundedRect;_value.backgroundColor=[UIColor colorWithWhite:.18 alpha:1];_value.textColor=UIColor.whiteColor;_value.keyboardType=UIKeyboardTypeNumbersAndPunctuation;_value.autocorrectionType=UITextAutocorrectionTypeNo;_value.returnKeyType=UIReturnKeyDone;_value.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];_toggle=[UISwitch new];[_toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];_slider=[UISlider new];_slider.continuous=NO;[_slider addTarget:self action:@selector(slid:) forControlEvents:UIControlEventValueChanged];_apply=[UIButton buttonWithType:UIButtonTypeSystem];[_apply setTitle:@"应用" forState:UIControlStateNormal];[_apply addTarget:self action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];_restore=[UIButton buttonWithType:UIButtonTypeSystem];[_restore setTitle:@"恢复" forState:UIControlStateNormal];[_restore addTarget:self action:@selector(restore:) forControlEvents:UIControlEventTouchUpInside];for(UIView *v in @[_title,_state,_value,_toggle,_slider,_apply,_restore])[self addSubview:v];}return self;}
- (void)layoutSubviews {[super layoutSubviews];CGFloat w=self.bounds.size.width;_title.frame=CGRectMake(10,7,w-82,24);_toggle.frame=CGRectMake(w-61,4,51,31);_state.frame=CGRectMake(10,35,w-20,32);_value.frame=CGRectMake(10,71,MAX(0,w-142),32);_apply.frame=CGRectMake(w-128,71,58,32);_restore.frame=CGRectMake(w-64,71,54,32);_slider.frame=CGRectMake(10,109,w-20,28);}
- (void)toggled:(UISwitch *)sender {if(_submit)_submit(self,sender.on,nil);}
- (void)apply:(id)sender {(void)sender;[self endEditing:YES];if(_submit)_submit(self,YES,_numeric?_value.text:nil);}
- (void)restore:(id)sender {(void)sender;[self endEditing:YES];if(_submit)_submit(self,NO,nil);}
- (void)slid:(UISlider *)sender {_value.text=[NSString stringWithFormat:@"%.7g",(_integralSlider?roundf(sender.value):sender.value)];[self apply:nil];}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[field resignFirstResponder];return YES;}
@end
@implementation NMStaticControlsView {
 UIButton *_refresh;
 UILabel *_summary;
 UIScrollView *_scroll;
 NSMutableArray<NMStaticControlRow *> *_rows;
 dispatch_queue_t _worker;
 BOOL _refreshing;
}
- (instancetype)initWithFrame:(CGRect)frame {self=[super initWithFrame:frame];if(self){_worker=dispatch_queue_create("newmymenu.static-controls",DISPATCH_QUEUE_SERIAL);_rows=[NSMutableArray array];_refresh=[UIButton buttonWithType:UIButtonTypeSystem];[_refresh setTitle:@"扫描已加载预埋" forState:UIControlStateNormal];[_refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];_refresh.accessibilityIdentifier=@"nm.static.refresh";_summary=[UILabel new];_summary.textColor=[UIColor colorWithWhite:.85 alpha:1];_summary.font=[UIFont systemFontOfSize:11];_summary.numberOfLines=2;_summary.text=@"只控制已加载的 Static 预埋功能。";_scroll=[UIScrollView new];_scroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;[self addSubview:_refresh];[self addSubview:_summary];[self addSubview:_scroll];}return self;}
- (void)layoutSubviews {[super layoutSubviews];CGFloat w=self.bounds.size.width;_refresh.frame=CGRectMake(0,0,w,30);_summary.frame=CGRectMake(0,34,w,38);_scroll.frame=CGRectMake(0,78,w,MAX(0,self.bounds.size.height-78));CGFloat y=0;for(NMStaticControlRow *row in _rows){row.frame=CGRectMake(0,y,w,row.slider.hidden?110:143);y+=row.frame.size.height+8;}_scroll.contentSize=CGSizeMake(w,y);}
- (void)refresh {if(_refreshing)return;[self endEditing:YES];_refreshing=YES;_refresh.enabled=NO;_summary.text=@"正在检查已加载镜像…";__weak NMStaticControlsView *weak=self;dispatch_async(_worker,^{NSError *error=nil;BOOL ok=[NMStaticRuntime.sharedRuntime refreshLoadedImagesWithError:&error];NSDictionary *snapshot=NMStaticRuntime.sharedRuntime.snapshot;dispatch_async(dispatch_get_main_queue(),^{NMStaticControlsView *view=weak;if(!view)return;view->_refreshing=NO;view->_refresh.enabled=YES;[view render:snapshot];view->_summary.text=ok?[NSString stringWithFormat:@"已绑定 %@ 个镜像，%lu 个功能。",snapshot[@"imageCount"],(unsigned long)[snapshot[@"features"] count]]:error.localizedDescription;});});}
- (void)render:(NSDictionary *)snapshot {for(UIView *row in _rows)[row removeFromSuperview];[_rows removeAllObjects];for(NSDictionary *feature in snapshot[@"features"]){NMStaticControlRow *row=[NMStaticControlRow new];row.featureIdentifier=feature[@"identifier"];row.accessibilityIdentifier=[@"nm.static.feature." stringByAppendingString:row.featureIdentifier];row.title.text=feature[@"title"];row.state.text=[NSString stringWithFormat:@"%@ · %@%@",feature[@"image"],[feature[@"active"] boolValue]?([feature[@"effective"] boolValue]?@"已启用":@"已启用，被后启用功能覆盖"):@"已恢复",[feature[@"foreign"] boolValue]?@" · 外部冲突":@""];NSInteger control=[feature[@"control"] integerValue];row.integralSlider=[feature[@"integralSlider"] boolValue];row.numeric=control==NMStaticControlSlider||control==NMStaticControlNumber;row.value.hidden=!row.numeric;row.value.text=feature[@"value"];row.toggle.hidden=control!=NMStaticControlSwitch;row.toggle.on=[feature[@"active"] boolValue];row.slider.hidden=control!=NMStaticControlSlider;row.slider.minimumValue=0;row.slider.maximumValue=row.integralSlider?floorf([feature[@"maximum"] floatValue]):[feature[@"maximum"] floatValue];row.slider.value=[feature[@"value"] floatValue];row.apply.hidden=control==NMStaticControlSwitch;__weak NMStaticControlsView *weak=self;row.submit=^(NMStaticControlRow *sender,BOOL enabled,NSString *value){NMStaticControlsView *view=weak;if(!view)return;NSError *error=nil;BOOL ok=[NMStaticRuntime.sharedRuntime setFeature:sender.featureIdentifier enabled:enabled value:value error:&error];[view render:NMStaticRuntime.sharedRuntime.snapshot];view->_summary.text=ok?(enabled?@"功能已应用。":@"已恢复此功能；其他功能按启用顺序接管。"):error.localizedDescription;};[_rows addObject:row];[_scroll addSubview:row];}[self setNeedsLayout];}
@end
