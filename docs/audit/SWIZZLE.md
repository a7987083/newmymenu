# Swizzle 源码安装索引（尚未完成必要性审计）

固定来源与物理位置见 BASELINE.md 和 swizzle-installers.json。

在 Makefile 直接编译单元中展开 void helper/installer 函数与显式 selector 调用，发现47个 exchange wrapper、124个包含 mutation/helper 调用的函数、164处 wrapper 调用。**不是124/164个实际Hook**：wrapper定义、条件分支、未调用installer、ObjC间接dispatch都需要进一步确认。文本库存另包含325个API候选，二者口径不同。

每条索引含 class表达式、显式方法查找、selector对、原IMP读取线索、dispatch_once使用、类型编码读取线索，以及受限的C调用图可达性。C函数可达不能证明分支在运行时发生；不可达也不能证明死代码，因为尚未解析ObjC dispatch。

## 已确认职责

| 目标 | 当前机制 | 迁移建议 | 证据范围 |
|---|---|---|---|
| ZNRuntimeMenuControllerV040 | 多版本UI Renderer、action、布局和输入修饰 | 显式单Renderer与command路由 | 源码安装器与selectors已索引；动态最终IMP未取得 |
| ZNIL2CPPHybridFinder | 搜索版本与zero VMAddr修正 | 将有效逻辑整合为发现/查询服务 | SearchV2/ZeroVMAddrFix安装器 |
| ZNIL2CPPInstanceResolver | 选择状态和GCHandle包装 | ReceiverStore+调用范围租约 | F03，原始实例枚举仍需保留 |
| ZNIL2CPPInvokeEngine | 签名、多参数、返回链修饰 | 显式InvocationRequest单入口 | 需补完整原IMP链顺序 |
| ZNBinaryPatchWorkspace / ZNStaticBinaryBuilder | 地址校验、数值语义、导出/构建修饰 | 原算法复用，显式prepare/build/postprocess | 每个builder修饰仍需传递依赖审计 |
| ZNRuntimeActionStore | 持久化和链式控制修饰 | 唯一配置store与codec | 显式序列化契约，不复制旧installer |
| ZNPatchManager / ZNPatchRuntimeValidator | Runtime Patch和地址校验迭代层 | 合并有效规则 | 不以文件版本名判定弃用 |
| SharedSite Probe 类 | 实验probe替换和block IMP | 是否保留由实际开发端诊断功能证据决定 | 尚未确认可以删除 |

目前已解析的局部Class绑定主要指向工程自有ZN类，支持“内部装饰器可用直接调用替代”的方向；**尚未据此宣布所有Swizzle均无必要或没有外部目标**。

## 必须补齐

每项必要候选的实际运行 types、original/replacement IMP、父类归属、安装线程/顺序、第三方冲突及安全恢复状态仍未取得。type_encoding_used=false只是函数体没显式读取，不等价于经跨函数分析证明完全不校验。

新工程不会简单迁移47个wrapper。先完成有效业务调用链，再决定是否需要生产SwizzleManager。真实Runtime实验已经证明继承方法直接exchange的通用风险，不能据此声称原工程所有目标都存在继承污染。
