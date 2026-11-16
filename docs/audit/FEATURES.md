> 本文件及features.json是冻结的原仓库审计时点库存。当前迁移状态见[CURRENT_REGRESSION.md](CURRENT_REGRESSION.md)。

# 功能清单与迁移回归矩阵

53项源码入口索引，不是“全部可用”声明。部分项仅定位实现片段；传递依赖尚未补全。原行为按源码记录，新实现尚未迁移，回归均未验证。机器可读数据见features.json。

| 域 | 功能 | 固定源码入口 | 原实现/新实现/回归 | 迁移决定 |
|---|---|---|---|---|
| Method Finder | Class 搜索 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12175 `- (void)znm54_submitSearch:` | 已实现但未验证 / 尚未迁移 / 未验证 | RuntimeDiscovery/MethodFinder；显式搜索快照替代 associated-object 分散状态 |
| Method Finder | Method 搜索 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12176 `- (void)znm54_dispatchMethodSearch:` | 已实现但未验证 / 尚未迁移 / 未验证 | 保留 Assembly 优先/严格筛选的差异 |
| Method Finder | 模糊匹配 | iosruntimepatchmenu/src/ZNIL2CPPHybridFinder.mm:402 `streamingCandidates:` | 已实现但未验证 / 尚未迁移 / 未验证 | 需补实际输入输出 fixture，不凭名称认定匹配算法 |
| Method Finder | 类与方法切换 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12177 `- (void)znm64_toggleMode:` | 已实现但未验证 / 尚未迁移 / 未验证 | 单状态所有者 |
| Method Finder | 搜索计数 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12486 `匹配 %lu 个类` | 已实现但未验证 / 尚未迁移 / 未验证 | 计数与显示使用同一快照 |
| Method Finder | 结果渲染 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:13723 `- (void)zn52x_renderResultsAtWidth:` | 已实现但未验证 / 尚未迁移 / 未验证 | 历史分流修复已在候选，实机回归未验证 |
| Method Finder | 方法详情 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12172 `znm54_renderDetailAtWidth:` | 已实现但未验证 / 尚未迁移 / 未验证 | 迁移单 Renderer |
| Method Finder | 参数与返回类型 | iosruntimepatchmenu/src/ZNIL2CPPABIMetadata.mm:205 `ZNIL2CPPDescribeMethodABI` | 已实现但未验证 / 尚未迁移 / 未验证 | 复用分类，目标 Runtime ABI 另验 |
| Method Finder | 单字段复制 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:13016 `copyable` | 部分实现 / 尚未迁移 / 未验证 | 验证空值/不可复制字段 |
| Method Finder | 本地词典翻译 | iosruntimepatchmenu/src/ZNMethodTranslator.mm:100 `+ (NSString *)translateMethodName:` | 已实现但未验证 / 尚未迁移 / 未验证 | 可独立复用，保留词典许可 |
| Method Finder | 滚动恢复 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12144 `ZNM64RestoreScrollOffset` | 已实现但未验证 / 尚未迁移 / 未验证 | 主线程搜索状态 |
| Method Finder | 搜索缓存与刷新 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:14013 `ZNM613AnalysisCache` | 部分实现 / 尚未迁移 / 未验证 | 缓存身份/模块世代失效待专项验证 |
| Runtime Method | Method 解析 | iosruntimepatchmenu/src/ZNIL2CPPResolver.mm:720 `resolveMethodAssembly:` | 已实现但未验证 / 尚未迁移 / 未验证 | 复用，禁止重写查找基础算法 |
| Runtime Method | 实例枚举 | iosruntimepatchmenu/src/ZNIL2CPPInstanceResolver.mm:102 `candidateAddressesForAssembly:` | 已实现但未验证 / 尚未迁移 / 未验证 | 需 ReceiverLease，不能将地址当存活证明 |
| Runtime Method | 实例选择 | iosruntimepatchmenu/src/ZNIL2CPPInstanceSelectionV2.mm:96 `znm44_selectInstanceAddress:` | 已实现但未验证 / 尚未迁移 / 未验证 | 合并为单实例管理服务 |
| Runtime Method | 参数封送 | iosruntimepatchmenu/src/ZNRuntimeArgumentMarshaller.mm:335 `encodeValueTypeParameterForMethod:` | 部分实现 / 尚未迁移 / 未验证 | ByRef/结构单独 fixture |
| Runtime Method | 实际方法调用 | iosruntimepatchmenu/src/ZNIL2CPPInvokeEngine.mm:144 `executeAction:` | 已知存在错误 / 尚未迁移 / 未验证 | 显式上下文替代 TLS |
| Runtime Method | 返回值处理 | iosruntimepatchmenu/src/ZNM48ReturnCapture.mm:237 `ZNInstallM48ReturnCaptureDeferred` | 已实现但未验证 / 尚未迁移 / 未验证 | 取消内部类自我 Swizzle |
| Runtime Method | 异常错误反馈 | iosruntimepatchmenu/src/ZNIL2CPPInvokeEngine.mm:233 `FAILED_RESOLVE` | 已实现但未验证 / 尚未迁移 / 未验证 | 统一 typed error，不吞失败 |
| Runtime Method | 多参数复杂结构 | iosruntimepatchmenu/src/ZNComplexStructCodec.mm:98 `ZNRegisterBuiltInComplexStructCodecs` | 部分实现 / 尚未迁移 / 未验证 | 已实现范围必须逐类型核验，不能标全面支持 |
| Runtime Method | 对象生命周期 | iosruntimepatchmenu/src/ZNM462InstanceSafety.mm:52 `ZNM462ReleaseSelection` | 已实现但未验证 / 尚未迁移 / 未验证 | 同步范围缺口，见F03 |
| Runtime Method | instanceIndex 契约 | iosruntimepatchmenu/src/ZNRuntimeActionFormat.h:45 `ZNRuntimeActionDecodeInstanceIndex` | 已知存在错误 / 尚未迁移 / 未验证 | 不是稳定身份，见F06 |
| Native Hook | 安装 Hook | iosruntimepatchmenu/src/ZNNativeHookBackend.mm:28 `installReplacementAtAddress:` | 已实现但未验证 / 尚未迁移 / 未验证 | 与 ObjC Swizzle 分离 |
| Native Hook | Hook 参数传递 | iosruntimepatchmenu/src/ZNNativeHookRuntime.mm:1086 `supportedInt32ArgumentIndicesForCandidate:` | 已实现但未验证 / 尚未迁移 / 未验证 | 模板限制必须保留 |
| Native Hook | 调用原函数 | iosruntimepatchmenu/src/ZNNativeHookBackend.mm:36 `DobbyHook` | 已实现但未验证 / 尚未迁移 / 未验证 | 在途 trampoline 生命周期待证 |
| Native Hook | 恢复 Hook | iosruntimepatchmenu/src/ZNNativeHookRuntime.mm:1642 `removeTemporaryHookForCandidate:` | 已实现但未验证 / 尚未迁移 / 未验证 | 缺排空证据，F04 |
| Native Hook | Hook 返回值 | iosruntimepatchmenu/src/ZNNativeHookRuntime.mm:1653 `returnBoolSlot` | 已实现但未验证 / 尚未迁移 / 未验证 | 不泛化为任意返回值支持 |
| Native Hook | 多 Hook 冲突 | iosruntimepatchmenu/src/ZNNativeHookRuntime.mm:1655 `permanentOwner` | 已实现但未验证 / 尚未迁移 / 未验证 | 需并发竞争 fixture |
| Native Hook | Hook 生命周期 | iosruntimepatchmenu/src/ZNNativeHookLifecycleBootstrap.mm:104 `ZNNativeHookEarlyLifecycleBootstrap` | 部分实现 / 尚未迁移 / 未验证 | 生命周期状态机替代分散 bootstrap |
| Build/Configuration | Static Patch | iosruntimepatchmenu/src/ZNStaticBinaryBuilderV3.mm:1126 `ZNStaticBinaryBuilderV3BuildWorkspace` | 已实现但未验证 / 尚未迁移 / 未验证 | 优先复用并补 fixture |
| Build/Configuration | Runtime Action | iosruntimepatchmenu/src/ZNRuntimeActionBuilder.mm:239 `ZNRuntimeActionEmbedIntoGeneratedOutputs` | 部分实现 / 尚未迁移 / 未验证 | 保持64字节entry及flag版本兼容 |
| Build/Configuration | Native Hook Action | iosruntimepatchmenu/src/ZNNativeHookAction.mm:286 `addArgScaleInt32Candidate:` | 部分实现 / 尚未迁移 / 未验证 | 保留模板ABI限制 |
| Build/Configuration | Static Prepared Hook | iosruntimepatchmenu/src/ZNNativeHookStaticPrepatch.mm:268 `ZNBuildInstallStaticPreparedNativeHooksV1` | 部分实现 / 尚未迁移 / 未验证 | 不能与Dobby恢复混同 |
| Build/Configuration | 混合构建 | iosruntimepatchmenu/src/ZNBuildExecutor.mm:20 `ZNBuildExecutorBuildWorkspace` | 已实现但未验证 / 尚未迁移 / 未验证 | 单一build入口 |
| Build/Configuration | Manifest | iosruntimepatchmenu/src/ZNBuildManifest.mm:303 `manifestForWorkspace:` | 已实现但未验证 / 尚未迁移 / 未验证 | 与UI脱耦 |
| Build/Configuration | JSON 配置 | iosruntimepatchmenu/src/ZNPatchJSONImporter.mm:160 `importFile:` | 部分实现 / 尚未迁移 / 未验证 | 错误返回必须保留 |
| Build/Configuration | 配置导入 | iosruntimepatchmenu/src/ZNAuthoringJSONImport.mm:94 `importData:` | 部分实现 / 尚未迁移 / 未验证 | 禁止静默替换失败 |
| Build/Configuration | 配置导出 | iosruntimepatchmenu/src/ZNAuthoringJSONImport.mm:49 `exportDataWithError:` | 部分实现 / 尚未迁移 / 未验证 | 完整调用点尚待追踪 |
| Build/Configuration | Mach-O 修改 | iosruntimepatchmenu/src/ZNBinaryPatchWorkspace.mm:198 `validateAll:` | 部分实现 / 尚未迁移 / 未验证 | 禁止重写成熟算法 |
| Build/Configuration | 静态 Dispatch | iosruntimepatchmenu/src/ZNStaticDispatchRuntime.mm:519 `setEnabled:` | 部分实现 / 尚未迁移 / 未验证 | 需固定来源二进制fixture |
| Build/Configuration | 二进制签名 | iosruntimepatchmenu/src/ZNAdhocMachOSigner.mm:437 `ZNAdhocResignMachOAtPath` | 部分实现 / 尚未迁移 / 未验证 | 旧CI提取entitlements不等于验证 |
| Build/Configuration | 生成校验 | iosruntimepatchmenu/src/ZNGeneratedBinaryPostprocess.mm:7 `ZNPostProcessGeneratedBinaryOutputs` | 部分实现 / 尚未迁移 / 未验证 | 实际约束仍需单项审查 |
| Developer UI | 菜单显隐 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:57 `ZonoePatchShow` | 已实现但未验证 / 尚未迁移 / 未验证 | 生命周期服务 |
| Developer UI | 拖动布局 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:74 `kZNPanelPositionKey` | 已实现但未验证 / 尚未迁移 / 未验证 | scene坐标需要设备测 |
| Developer UI | 页面切换 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:487 `renderPage` | 已实现但未验证 / 尚未迁移 / 未验证 | 单Renderer路由 |
| Developer UI | 输入键盘 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:1436 `endEditing:` | 已实现但未验证 / 尚未迁移 / 未验证 | 主线程UI，focus设备测 |
| Developer UI | 滚动卡片 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:348 `cardAtY:` | 已实现但未验证 / 尚未迁移 / 未验证 | 禁止按标题扫描绑事件 |
| Developer UI | 搜索结果显示 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:12181 `znm64_renderClassResultsAtWidth:` | 已实现但未验证 / 尚未迁移 / 未验证 | 回归F01 |
| Developer UI | 功能编辑 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:7166 `znrmc_instanceEditingEnded:` | 已实现但未验证 / 尚未迁移 / 未验证 | UI只提交配置command |
| Developer UI | 生成错误反馈 | iosruntimepatchmenu/src/ZNBuildExecutor.mm:46 `prepareError` | 已实现但未验证 / 尚未迁移 / 未验证 | 明确阶段与错误 |
| Developer UI | 横竖屏 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:548 `- (void)tick:(NSTimer *)timer` | 部分实现 / 尚未迁移 / 未验证 | 细节仅文本定位，未验证 |
| Developer UI | 触摸穿透 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:2455 `hitTest:` | 部分实现 / 尚未迁移 / 未验证 | scene/UI fixture与设备测 |
| Developer UI | 多窗口 | iosruntimepatchmenu/src/ZNUnifiedUI.mm:225 `UIWindowScene` | 部分实现 / 尚未迁移 / 未验证 | 销毁/rebind生命周期未验证 |

API2的部分基础组件已独立迁移，见features.json的new_component与EXECUTION_CORE.md；表内“尚未迁移/未验证”指完整功能与旧UI/真实Runtime的集成回归，不否认基础组件已经实现。
