#import "NMStaticControlsView.h"
#import "NMStaticRuntime.h"
#import "NMStaticValues.h"
#include <math.h>
@interface NMStaticControlRow : UIView <UITextFieldDelegate>
@property(nonatomic,copy) NSString *featureIdentifier;
@property(nonatomic,copy) void (^submit)(NMStaticControlRow *,BOOL,NSString *);
@property(nonatomic,copy) void (^draftChanged)(NMStaticControlRow *,NSString *);
@property(nonatomic,strong) UILabel *title,*state,*descriptionLabel;
@property(nonatomic,strong) UITextField *value;
@property(nonatomic,strong) UISwitch *toggle;
@property(nonatomic,strong) UISlider *slider;
@property(nonatomic,strong) UIButton *apply,*restore;
@property(nonatomic) BOOL numeric,integralSlider;
@end
@implementation NMStaticControlRow
- (instancetype)initWithFrame:(CGRect)frame {self=[super initWithFrame:frame];if(self){self.backgroundColor=[UIColor colorWithWhite:.10 alpha:1];self.layer.cornerRadius=8;_title=[UILabel new];_title.textColor=UIColor.whiteColor;_title.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];_descriptionLabel=[UILabel new];_descriptionLabel.textColor=[UIColor colorWithWhite:.85 alpha:1];_descriptionLabel.font=[UIFont systemFontOfSize:11];_descriptionLabel.numberOfLines=2;_state=[UILabel new];_state.textColor=[UIColor colorWithWhite:.75 alpha:1];_state.font=[UIFont systemFontOfSize:10];_state.numberOfLines=2;_value=[UITextField new];_value.delegate=self;_value.borderStyle=UITextBorderStyleRoundedRect;_value.backgroundColor=[UIColor colorWithWhite:.18 alpha:1];_value.textColor=UIColor.whiteColor;_value.keyboardType=UIKeyboardTypeNumbersAndPunctuation;_value.autocorrectionType=UITextAutocorrectionTypeNo;_value.returnKeyType=UIReturnKeyDone;_value.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];[_value addTarget:self action:@selector(edited:) forControlEvents:UIControlEventEditingChanged];_toggle=[UISwitch new];[_toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];_slider=[UISlider new];_slider.continuous=NO;[_slider addTarget:self action:@selector(slid:) forControlEvents:UIControlEventValueChanged];_apply=[UIButton buttonWithType:UIButtonTypeSystem];[_apply setTitle:@"应用" forState:UIControlStateNormal];[_apply addTarget:self action:@selector(apply:) forControlEvents:UIControlEventTouchUpInside];_restore=[UIButton buttonWithType:UIButtonTypeSystem];[_restore setTitle:@"恢复" forState:UIControlStateNormal];[_restore addTarget:self action:@selector(restore:) forControlEvents:UIControlEventTouchUpInside];for(UIView *v in @[_title,_descriptionLabel,_state,_value,_toggle,_slider,_apply,_restore])[self addSubview:v];}return self;}
- (void)layoutSubviews {[super layoutSubviews];CGFloat w=self.bounds.size.width,shift=_descriptionLabel.hidden?0:36;_descriptionLabel.frame=CGRectMake(10,33,w-20,34);_title.frame=CGRectMake(10,7,w-82,24);_toggle.frame=CGRectMake(w-61,4,51,31);_state.frame=CGRectMake(10,35+shift,w-20,32);_value.frame=CGRectMake(10,71+shift,MAX(0,w-142),32);_apply.frame=CGRectMake(w-128,71+shift,58,32);_restore.frame=CGRectMake(w-64,71+shift,54,32);_slider.frame=CGRectMake(10,109+shift,w-20,28);}
- (void)edited:(id)sender {(void)sender;void (^operation)(NMStaticControlRow *,NSString *)=[_draftChanged copy];if(operation)operation(self,_value.text?:@"");}
- (void)submitEnabled:(BOOL)enabled value:(NSString *)value {void (^operation)(NMStaticControlRow *,BOOL,NSString *)=[_submit copy];if(operation)operation(self,enabled,value);}
- (void)toggled:(UISwitch *)sender {[self submitEnabled:sender.on value:nil];}
- (void)apply:(id)sender {(void)sender;if(_numeric)[self edited:_value];[self endEditing:YES];[self submitEnabled:YES value:_numeric?_value.text:nil];}
- (void)restore:(id)sender {(void)sender;[self endEditing:YES];[self submitEnabled:NO value:nil];}
- (void)slid:(UISlider *)sender {_value.text=[NSString stringWithFormat:@"%.7g",(_integralSlider?roundf(sender.value):sender.value)];[self apply:nil];}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[field resignFirstResponder];return YES;}
@end
@interface NMStaticControlCell : UITableViewCell
@property(nonatomic,strong) NMStaticControlRow *row;
@end
@implementation NMStaticControlCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    self=[super initWithStyle:style reuseIdentifier:identifier];
    if(self){self.backgroundColor=UIColor.clearColor;self.selectionStyle=UITableViewCellSelectionStyleNone;_row=[NMStaticControlRow new];[self.contentView addSubview:_row];}
    return self;
}
- (void)layoutSubviews {[super layoutSubviews];_row.frame=CGRectInset(self.contentView.bounds,0,4);}
- (void)prepareForReuse {[super prepareForReuse];[_row endEditing:YES];_row.submit=nil;_row.draftChanged=nil;}
@end

@interface NMStaticControlsView () <UITableViewDataSource,UITableViewDelegate>
@end
@implementation NMStaticControlsView {
    UIButton *_refresh;
    UILabel *_summary;
    UITableView *_table;
    NSArray<NSDictionary *> *_features;
    NSMutableDictionary<NSString *,NSString *> *_drafts,*_feedback;
    dispatch_queue_t _worker;
    BOOL _refreshing;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self=[super initWithFrame:frame];
    if(self){
        _worker=dispatch_queue_create("newmymenu.static-controls",DISPATCH_QUEUE_SERIAL);
        _features=@[];_drafts=[NSMutableDictionary dictionary];_feedback=[NSMutableDictionary dictionary];
        _refresh=[UIButton buttonWithType:UIButtonTypeSystem];
        [_refresh setTitle:@"扫描已加载预埋" forState:UIControlStateNormal];
        [_refresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
        _refresh.accessibilityIdentifier=@"nm.static.refresh";
        _summary=[UILabel new];_summary.textColor=[UIColor colorWithWhite:.85 alpha:1];
        _summary.font=[UIFont systemFontOfSize:11];_summary.numberOfLines=2;
        _summary.text=@"只控制已加载的 Static 预埋功能。";
        _table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _table.backgroundColor=UIColor.clearColor;_table.separatorStyle=UITableViewCellSeparatorStyleNone;
        _table.dataSource=self;_table.delegate=self;_table.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag;
        [_table registerClass:NMStaticControlCell.class forCellReuseIdentifier:@"NMStaticControl"];
        [self addSubview:_refresh];[self addSubview:_summary];[self addSubview:_table];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];CGFloat w=self.bounds.size.width;
    _refresh.frame=CGRectMake(0,0,w,30);_summary.frame=CGRectMake(0,34,w,38);
    _table.frame=CGRectMake(0,78,w,MAX(0,self.bounds.size.height-78));
    for(NMStaticControlCell *cell in _table.visibleCells)if(cell.row.value.isFirstResponder){
        CGRect input=[cell.row.value convertRect:cell.row.value.bounds toView:_table];
        [_table scrollRectToVisible:CGRectInset(input,-4,-8) animated:NO];break;
    }
}
- (BOOL)editingValue {
    for(NMStaticControlCell *cell in _table.visibleCells)if(cell.row.value.isFirstResponder)return YES;
    return NO;
}
- (void)refresh {
    if(_refreshing)return;
    [self endEditing:YES];_refreshing=YES;_refresh.enabled=NO;_summary.text=@"正在检查已加载镜像…";
    __weak NMStaticControlsView *weak=self;
    dispatch_async(_worker,^{
        NSError *error=nil;BOOL ok=[NMStaticRuntime.sharedRuntime refreshLoadedImagesWithError:&error];
        dispatch_async(dispatch_get_main_queue(),^{
            NMStaticControlsView *view=weak;if(!view)return;
            view->_refreshing=NO;view->_refresh.enabled=YES;
            // Read the current engine state at commit time, after any intervening UI operation.
            NSDictionary *snapshot=NMStaticRuntime.sharedRuntime.snapshot;
            [view render:snapshot];
            view->_summary.text=ok?[NSString stringWithFormat:@"已绑定 %@ 个镜像，%lu 个功能。",snapshot[@"imageCount"],(unsigned long)[snapshot[@"features"] count]]:error.localizedDescription;
        });
    });
}
- (void)submitRow:(NMStaticControlRow *)row enabled:(BOOL)enabled value:(NSString *)value {
    NSError *error=nil;
    BOOL ok=[NMStaticRuntime.sharedRuntime setFeature:row.featureIdentifier enabled:enabled value:value error:&error];
    if(ok)[_drafts removeObjectForKey:row.featureIdentifier];
    _feedback[row.featureIdentifier]=ok?(enabled?@"已应用":@"已恢复"):error.localizedDescription;
    [self render:NMStaticRuntime.sharedRuntime.snapshot];
    _summary.text=ok?(enabled?@"功能已应用。":@"已恢复此功能；其他功能按启用顺序接管。"):error.localizedDescription;
}
- (void)configureRow:(NMStaticControlRow *)row feature:(NSDictionary *)feature {
    row.featureIdentifier=feature[@"identifier"];
    row.accessibilityIdentifier=[@"nm.static.feature." stringByAppendingString:row.featureIdentifier];
    row.title.text=feature[@"title"];row.descriptionLabel.text=feature[@"description"];
    row.descriptionLabel.hidden=!row.descriptionLabel.text.length;
    row.state.text=[NSString stringWithFormat:@"%@ · %@%@",feature[@"image"],[feature[@"active"] boolValue]?([feature[@"effective"] boolValue]?@"已启用":@"已登记，当前未生效"):@"已恢复",[feature[@"foreign"] boolValue]?@" · 外部冲突":@""];
    NSString *feedback=_feedback[row.featureIdentifier];
    if(feedback.length)row.state.text=[row.state.text stringByAppendingFormat:@" · %@",feedback];
    NSInteger control=[feature[@"control"] integerValue];
    row.integralSlider=[feature[@"integralSlider"] boolValue];
    row.numeric=control==NMStaticControlSlider||control==NMStaticControlNumber;
    row.value.hidden=!row.numeric;
    if(!row.value.isFirstResponder)row.value.text=_drafts[row.featureIdentifier]?:feature[@"value"];
    row.toggle.hidden=control!=NMStaticControlSwitch;row.toggle.on=[feature[@"active"] boolValue];
    row.slider.hidden=control!=NMStaticControlSlider;row.slider.minimumValue=0;
    row.slider.maximumValue=row.integralSlider?floorf([feature[@"maximum"] floatValue]):[feature[@"maximum"] floatValue];
    row.slider.value=[feature[@"value"] floatValue];row.apply.hidden=control==NMStaticControlSwitch;
    __weak NMStaticControlsView *weak=self;
    row.draftChanged=^(NMStaticControlRow *sender,NSString *text){NMStaticControlsView *view=weak;if(view)view->_drafts[sender.featureIdentifier]=text;};
    row.submit=^(NMStaticControlRow *sender,BOOL enabled,NSString *value){NMStaticControlsView *view=weak;[view submitRow:sender enabled:enabled value:value];};
    [row setNeedsLayout];
}
- (void)render:(NSDictionary *)snapshot {
    NSArray *next=[snapshot[@"features"] copy];
    BOOL sameIdentity=[[_features valueForKey:@"identifier"] isEqual:[next valueForKey:@"identifier"]];
    _features=next;
    if(!sameIdentity){[_table reloadData];[_table layoutIfNeeded];}
    else for(NMStaticControlCell *cell in _table.visibleCells){
        NSIndexPath *index=[_table indexPathForCell:cell];
        if(index&&index.row<(NSInteger)_features.count)[self configureRow:cell.row feature:_features[(NSUInteger)index.row]];
    }
    [self setNeedsLayout];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;(void)section;return (NSInteger)_features.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;NSDictionary *feature=_features[(NSUInteger)indexPath.row];
    return ([feature[@"control"] integerValue]==NMStaticControlSlider?143:110)+([feature[@"description"] length]?36:0)+8;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NMStaticControlCell *cell=[tableView dequeueReusableCellWithIdentifier:@"NMStaticControl" forIndexPath:indexPath];
    [self configureRow:cell.row feature:_features[(NSUInteger)indexPath.row]];return cell;
}
@end
