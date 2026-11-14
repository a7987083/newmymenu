# 当前生成入口与旧 Builder Swizzle 边界

固定7066ede；此文只确认调用边界，未宣称完整Mach-O算法或混合构建验证通过。

## 当前开发端UI路径

`ZNUnifiedUI.mm:1600 zn44_buildBinary:`：检查workspace.isBuilding/hasAnyApplied/manifest.itemCount，设置building，后台调用 `ZNBuildExecutorBuildWorkspace`，主队列提交outputs/status。

Executor：Manifest→prepare providers→Static或Runtime-only base→emit providers→postprocess。Static有专用row snapshot，但Runtime/Native数据仍从各自全局store再次读取。

| 阶段 | 实际代码 | 关键依赖与保留约束 |
|---|---|---|
| Manifest collect | ZNBuildManifest.mm manifestForWorkspace | providers按identifier排序；items多为rowIndex/actionID/index元数据，不是整个构建输入不可变副本 |
| Static prepare | ZNBuildStaticPrepare.mm | workspace.validateAll、值控件规则、原始4字节窗口读取、validator模型；不能跳过这些检查 |
| Runtime prepare | ZNM69PrepareRuntimeMethodProvider | 修改RuntimeActionStore的slider范围配置；与manifest收集不是一个原子快照 |
| Native prepare | ZNNativeHookBuildPrepare.mm | 固定方法身份、preparedRVA/UUID/static；完整依赖仍待审计 |
| Base | ZNStaticBinaryBuilderV3BuildWorkspace / ZNRuntimeOnlyBinaryBuilderBuildWorkspace | Mach-O布局、__ZNDATA容量及旧ABI必须保留 |
| Native emit | ZNBuildInstallStaticPreparedNativeHooksV1 | 在磁盘目标完成预埋，之后写action表；不等于运行时Dobby安装 |
| Shared action emit | ZNM69EmitRuntimeActionTable | RuntimeActionEmbed、签名元数据、Runtime-only verifier；native/runtime共享emitGroup去重 |
| Postprocess | ZNGeneratedBinaryPostprocess.mm | 名称编码→RW value cell→RVA保护→ad-hoc签名→suffixless export |

Native与Runtime provider共享`runtime-action-table` emitGroup。当前排序native-hook在runtime-method-call前，先静态prepatch，再统一写两类action表，后者跳过重复emit。这是当前执行契约，不能把两个provider看成完全重复然后删掉其中一个。

## 与旧class-method Swizzle的关系

`ZNM592OffsetAuthoringPersistence.mm`仍交换`+[ZNStaticBinaryBuilder buildWorkspace:outputs:report:error:]`。旧`legacy/ZNLegacyStaticBinaryPipeline.mm`提供该class方法，并可进入V3。

当前UI→Executor的Static base调用是**C函数**`ZNStaticBinaryBuilderV3BuildWorkspace`，没有先调用这个旧class-method入口。故不能把M592 class-method wrapper当作当前生成路径必经的准备阶段。新工程应直接保留BuildExecutor/StaticPrepare的显式规则，而非迁移此wrapper。

这里只证明当前UI路径绕过旧入口，不证明原class方法没有其他API使用者；原仓库不删除它。M592的workspace修改/持久化包装是另一职责，仍需独立迁移到配置store提交阶段。

## 已发现的构建一致性限制

- collect中的异常被catch后转换为空items，没有向调用者传播错误，可能把失败误当“该provider无内容”。源码已确认，尚未通过业务fixture复现丢项。
- Manifest、prepare、action emit、签名augment分别读取或修改全局store；尚未证明构建期间UI所有编辑入口均被阻止。不能声称一次构建使用一个不可变输入。
- Runtime-only签名桥通过创建`.znpatched`硬链接适配旧后处理的文件名筛选。它是当前显式兼容桥，重构应消除后处理对文件名的隐含协议；不能直接删掉桥而不改被调用者。

新BuildEngine需要一个BuildRequest冻结rows/actions/hooks/provider快照；各阶段消费同一个request并返回typed stage error。底层Mach-O与ARM64算法优先复用，不重新发明。
