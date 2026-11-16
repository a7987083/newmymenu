# 独立开发端架构

当前核心API21；代码与组件验证范围见PROJECT_STATE和docs/builds。原仓库只读固定7066ede，架构与迁移决定从decisions/0001到后续编号保留，早期“未迁移”状态不是当前实现清单。

| 模块 | 唯一职责/状态所有者 | 核心入口 |
|---|---|---|
| RuntimeDiscovery | 同镜像公开IL2CPP API与每次Domain/thread scope；只返回元数据值身份 | NMIL2CPPDiscovery |
| MethodFinder | 查询模式、generation、不可变结果、最近类页面与offset | NMFinderSession；NMNamedExpression；NMMethodPresentation |
| Swizzle | 合作域内Class/metaclass+SEL唯一owner；IMP/类型/代码镜像与恢复 | NMSwizzleManager.sharedManager |
| Execution | 不可变request、receiver lease覆盖调用scope；不默认保活managed指针 | NMInvocationCoordinator / NMReceiverLease |
| Native Capture | token/ack会话、停止/关闭/排空责任显式化 | NMCaptureSessionManager；真实后端暂缓 |
| Configuration | 唯一离线authoring model与revision提交；候选只提取不执行 | NMConfigurationDocument/Store；NMPatchImportDocument |
| Build | 冻结输入、地址/原字节/冲突/重定位、owned段、签名与新目录事务 | NMOfflineBuildRequest→NMStaticPatchPlan→NMStaticCodePayload→NMStaticBinaryImage→NMMachOSigner |
| Manifest | 版本化不可变功能数据；说明表只是Manifest文本的派生wire投影 | NMBuildManifest |
| Loaded Static | dyld清单、process-lifetime pin、每物理站点owner-stack及RW CAS | NMStaticRuntime.sharedRuntime |
| DeveloperUI | 呈现快照/编辑草稿/提交操作，无底层执行或自我Swizzle | NMDeveloperMenu；NMStaticControlsView |

Finder的worker只做元数据发现；主线程generation检查后一次提交count/rows，单table Renderer展示。类返回复用已保存快照和offset，搜索/刷新使旧缓存失效；没有多个关联对象状态源。

构建只读冻结输入；用户明确选择地址域和控件类型。候选→definition保存expected bytes来源→plan校验→代码/元数据派生→owned RX/RW段→私有签名工作节点→全新未写映射发布节点只读验签→独占发布。失败不覆盖原文件或既有输出。签名页hash正确与当前vnode可执行性是不同证据；AMFI问题见决策0023，后续加载结果决定是否修复。

Loaded Static把实际开关和数值保存在受管prepared镜像RW单元；没有运行时RX写入。不同logical共享站点按owner栈恢复；Imported同标题保持不同逻辑身份，显式group依logicalIndex排序取第一成员说明。工作线程绑定后，UI真正提交时读取最新快照，防旧异步状态覆盖。表格复用可见卡片，草稿/反馈按稳定ID保存，不能当成引擎实际执行状态。

必要Swizzle仅在证明目标调用/writer全部加入合作域后安装；组件不自动给外部SharedSite填coordinated=YES。继承默认拒绝，LocalSnapshot的本地槽限制明确保留。Native Hook与ObjC Swizzle不共用执行器；无法证明在途排空时不强行卸载。

游戏ABI相关adapter保持暂缓：真实Invoke/GCHandle、复杂参数/ByRef、多实例执行、Native/Prepared桥及对应混合执行provider没有目标证据就拒绝接入。公开类型名不等于MethodInfo布局证明，RVA/offset反查不能靠猜指针补齐。

src的唯一构建清单是scripts/source_lists.sh，Core/Developer/Simulator及分析从同一清单取源；没有旧菜单或历史installer备用执行路径。真实ObjC Runtime、macOS ARM64执行、iOS编译、Simulator、实机分别记录，互不替代。
