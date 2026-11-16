# 当前53项功能对照

源码e797351d；原行为来自固定基线源码，原版运行本身未验证。当前原生/Simulator证据不等于游戏或实机。每项入口、旧调用链与差异详见[current-regression.json](current-regression.json)。旧features.json保留审计时点状态，不代表当前迁移进度。

|序号|功能|当前状态|验证与差异|
|---|---|---|---|
|0|Class 搜索|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|1|Method 搜索|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|2|模糊匹配|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|3|类与方法切换|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|4|搜索计数|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|5|结果渲染|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|6|方法详情|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|7|参数与返回类型|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|8|单字段复制|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|9|本地词典翻译|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|10|滚动恢复|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|11|搜索缓存与刷新|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|12|Method 解析|只读发现/单快照Finder及详情已实现|test-discovery/test-finder/test-presentation/test-parser；Simulator Finder卡片/详情/滚动；游戏Runtime导出适配与真实复制点击未实机验证|
|13|实例枚举|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|14|实例选择|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|15|参数封送|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|16|实际方法调用|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|17|返回值处理|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|18|异常错误反馈|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|19|多参数复杂结构|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|20|对象生命周期|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|21|instanceIndex 契约|instanceIndex线协议已实现并通过原版对照|516往返、129wire对照；游戏实例执行暂缓；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|22|安装 Hook|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|23|Hook 参数传递|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|24|调用原函数|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|25|恢复 Hook|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|26|Hook 返回值|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|27|多 Hook 冲突|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|28|Hook 生命周期|契约/生命周期基础设施部分实现；游戏执行适配暂缓|test-execution/test-swizzle及独立Objective-C Runtime fixture；不证明Native游戏执行；实例发现/Invoke/Native安装/恢复/返回值未完成游戏验证|
|29|Static Patch|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|30|Runtime Action|离线描述/配置部分实现；游戏执行/Prepared桥接暂缓|配置/Manifest/codec fixture；没有实际游戏执行或Prepared Native桥接|
|31|Native Hook Action|离线描述/配置部分实现；游戏执行/Prepared桥接暂缓|配置/Manifest/codec fixture；没有实际游戏执行或Prepared Native桥接|
|32|Static Prepared Hook|离线描述/配置部分实现；游戏执行/Prepared桥接暂缓|配置/Manifest/codec fixture；没有实际游戏执行或Prepared Native桥接|
|33|混合构建|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|34|Manifest|统一Manifest/配置及导入导出已实现|test-manifest/test-configuration及原版identity对照；Simulator有效/无效配置、picker回调读取、保存；Runtime/Native仅离线描述；实际Files选择/分享目标交互与设备重启恢复未实机验证|
|35|JSON 配置|统一Manifest/配置及导入导出已实现|test-manifest/test-configuration及原版identity对照；Simulator有效/无效配置、picker回调读取、保存；Runtime/Native仅离线描述；实际Files选择/分享目标交互与设备重启恢复未实机验证|
|36|配置导入|统一Manifest/配置及导入导出已实现|test-manifest/test-configuration及原版identity对照；Simulator有效/无效配置、picker回调读取、保存；Runtime/Native仅离线描述；实际Files选择/分享目标交互与设备重启恢复未实机验证|
|37|配置导出|统一Manifest/配置及导入导出已实现|test-manifest/test-configuration及原版identity对照；Simulator有效/无效配置、picker回调读取、保存；Runtime/Native仅离线描述；实际Files选择/分享目标交互与设备重启恢复未实机验证|
|38|Mach-O 修改|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|39|静态 Dispatch|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|40|二进制签名|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|41|生成校验|ABI独立Static构建/加载后控制已实现|Static计划/迁移/payload/image/runtime/signer原生fixture；Simulator实际签名加载及混合Static控件；三域混合执行暂缓；仅新格式预埋，ad-hoc非完整IPA签名|
|42|菜单显隐|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|43|拖动布局|新五页DeveloperUI已实现|源码路径已审查；该实际手势/生命周期未验证；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|44|页面切换|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|45|输入键盘|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|46|滚动卡片|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|47|搜索结果显示|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|48|功能编辑|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|49|生成错误反馈|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|50|横竖屏|新五页DeveloperUI已实现|源码路径已审查；该实际手势/生命周期未验证；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|51|触摸穿透|新五页DeveloperUI已实现|tests/ui/main.m程序化UIKit fixture；ui-fixture/result.json；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
|52|多窗口|新五页DeveloperUI已实现|源码路径已审查；该实际手势/生命周期未验证；真实手势/逐字键盘/复制/旋转/前后台/多窗口未验证；JSON编辑替代旧表单|
