# 已知问题

- 审计尚未完成；53项中部分是实现片段，完整依赖闭包与全部Swizzle目标仍待验证。
- 离线翻译、Action格式及执行/捕获契约组件已迁入；真实Runtime/Native adapter和完整菜单尚未迁移，不具备替换旧开发端条件。基础core的构建/测试独立记录，不等于完整产品验证。
- 原代码GCHandle使用范围/释放竞争及Native teardown风险，见FINDINGS.md；尚未在实机复现。
- 本机没有Apple SDK、clang或iOS设备。真实Runtime与ARM64实验由CI执行，状态见Actions；不能把实验结果当产品或实机结果。
- UIKit/IL2CPP及第三方Hook并发没有真实运行验证。

- M47多参数/ByRef分支绕过ordinal和explicit receiver，已在固定源隔离运行复现；生产未修复。
- ReceiverCapture旧timeout结束新会话，已在真实dispatch隔离运行复现；生产未修复。
- Build collector异常吞为空items及跨阶段全局store快照限制，详见BUILD_BOUNDARIES，业务运行影响未验证。

- SharedSite实际包含外部Class/SEL的诊断Hook及样本固定RVA，不是全部内部UI装饰器；保留迁移项，首批core不包含它。

- API2新增执行/捕获基础组件已通过Foundation和ARM64构建验证，但原M47/旧Capture UI未集成，旧源码缺陷仍保留在审计基线。
- custom lease的managed存活/地址/线程保证和capture safe close必须由待实现adapter提供；当前没有默认raw pointer fallback或Dobby成功即ack的实现。
- install/close永不ack时会话保持占用与自持有；无法证明安全时不强制释放。正常关闭/retry释放已实际测试。

## API3 / 只读 DeviceProbe 的验证边界

- DeviceProbe 不是完整开发端。只提供 IL2CPP 类/方法元数据搜索和报告，现已增加有界全局 Method 关键词搜索、词典翻译与公开元数据字段复制；仍没有表达式/RVA完整查询、地址级详情、跨查询索引缓存、Invoke/实例、Native Hook 或混合 Build。
- IL2CPP API 测试使用受控 C 函数表。真实游戏导出、ABI、Domain/线程行为必须依赖设备报告；缺导出或多个 Runtime 所有者明确拒绝绑定。
- UIKit host 为 foreground UIScene window 或无 UIScene 时的 UIApplicationDelegate.window。多窗口、键盘、触摸穿透、旋转和前后台行为尚未实机验证。
- 新实现错误对象曾在内层 autoreleasepool 后悬空，CI ASan 已复现并修复，原失败用例保留。静态分析的 NSError 可空通道已加守卫，分析器 findings 由显式 plist gate 拦截。
- Probe 只保留最近一次操作报告，类与方法页面需分别导出。扫描上限会显示 truncated，不能当完整游戏索引。

- 05840d7b已实现单一页面状态、最近类页面缓存及返回滚动位置恢复，Foundation/ASan通过；实际UIKit滚动恢复尚未设备验证。照片只证明4d9231c7面板显示，不证明Runtime搜索成功。

- API4方法搜索目前为name contains关键词；原限定表达式/参数个数/RVA反查和类排名对等尚未迁移。详情仅复制公开元数据type name/static，不代表复杂结构封送或Invoke ABI已支持；不伪造原生地址。详细对照docs/METHOD_FINDER.md。

- API5已补Named Expression与assembly/namespace/class/exact method/arity过滤，10020原解析器对照和类排名limit-one回归通过；非零delta/RVA地址路径仍未迁移。真实Runtime镜像/报告缺失，ABI证据缺口见docs/ABI_EVIDENCE_GATE.md，不能复制MethodInfo猜布局或raw receiver fallback后自称完成。

- 用户已暂缓游戏ABI；不再等待目标游戏作为整个工程继续的条件。Invoke/managed保活与依赖目标布局的Native/Prepared路径仍未完成。
- Manifest JSON是newmymenu.manifest/schemaVersion1，不是原zonoe-authoring或Patch JSON兼容导入器；后者及prepare/emit业务尚未接入，不得把基础snapshot/JSON测试通过写成混合构建完成。
- 签名器限定thin ARM64且需现存LC_CODE_SIGNATURE，拒绝带entitlements的输入，最终IPA身份/权限重签必须由包级签名流程承担；没有设备加载验证。旧签名器两项缺陷与本轮修复记录见docs/SIGNER.md。

- SwizzleManager采用明确的合作式调度/写入契约，不能阻止任意第三方不合作的Runtime修改；实际SharedSite外部Hook尚未接入该域。继承默认拒绝，显式LocalSnapshot会留下本地方法槽，不是完整动态继承还原。无法持有代码镜像及block-backed IMP明确拒绝，详情docs/SWIZZLE_MANAGER.md。
