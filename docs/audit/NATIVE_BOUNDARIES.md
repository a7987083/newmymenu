# Native与外部ObjC诊断的迁移边界

来源固定7066ede；原源码只读。此文补足职责，不把源码审计等价于目标Runtime通过。

## Native的三条不同路径

| 路径 | 已核对调用链 | 地址/生命周期 | 迁移决定 |
|---|---|---|---|
| 临时Native Hook | 最终卡片handler→ZNNativeHookRuntime的template安装→ZNNativeHookBackend→DobbyHook/Instrument | 当前methodPointer；slot owner；恢复DobbyDestroy | 后端与模板算法评估复用，先解决在途调用/冲突和签名完整性，再接新UI |
| 正式StaticPrepared Hook | BuildManifest native prepare→ZNBuildPrepareNativeHookDescriptorsV1→StaticPrepatch emit→runtime scheduler/installAction | prepared RVA/UUID/static/slot/trampoline；磁盘预埋后运行时写slot | 独立于临时Dobby，不能迁成同一套恢复规则 |
| Receiver Capture | candidate methodPointer→M47 capture→DobbyInstrument读x0→main completion→类型校验/selection | 原全局active、completion、timeout | 已复现跨会话timer缺陷，完全替代会话生命周期，Dobby后端另审 |

Prepare内部使用resolveMethodAssembly(name/arity)取得methodInfo/pointer，method_get_flags确定static，dyld/Mach-O UUID换算RVA。StructField codec getter/setter必须与目标同一build。它未直接消费action.parameterTypeNames，不能据此宣称prepared定位对所有同arity重载都精确；Resolver只有在class_get_method_from_name失败后的枚举fallback中才显式拒绝多匹配。此为源码限制，未在真实Runtime复现错绑。

Scheduler用serial queue组织正式action，但临时UI测试会直接进入Runtime，不能因为存在scheduler就推定所有Native写操作已经串行。teardown不移除可能排队的旧retry generation，状态按actionID共享，重用ID/版本切换需要单独fixture。

## 外部ObjC Hook确实存在

SharedSite并非仅给自有ZN类做装饰：

- ZNSharedSiteProbeV2.mm:ZNSSPFindTargetClass优先找外部MdhpNuX/-setActive:，fallback枚举class并以方法/镜像匹配EarntoDieRogue。
- installWithClass保存原IMP，block IMP继续执行原方法，class_addMethod隔离继承或method_setImplementation替换直接方法。只检查types非空，不等于验证BOOL参数ABI一致。
- V3Bootstrap在外部同一setActive:上再挂包装，原IMP链靠全局gZNSSP3FeatureChainIMP。
- V3执行探针还枚举目标镜像的metaclass方法，按签名识别offset/resolved apply和native hook registration API，缓存owner/selector/original后method_setImplementation。

因此不能宣布Swizzle全部为内部UI代码，也不能按扫描到的ZN函数名字把目标归成自有Class。V2/V3存在有用途的外部诊断Hook，但原实现没有完整的统一所有权/冲突/恢复机制。

UI :1857–1915明确把它描述为已知EarntoDieRogue样本的开发者专项探针；源码固定class、image和RVA0x2E25904。这是样本专用诊断，不是通用Method Finder/Invoke/Builder基础设施。

## 决策

- 保留功能清单中的诊断项，不把它当无用代码直接删除。
- 不作为首批核心默认constructor运行，不把样本RVA当其他目标可用地址。
- 后续迁为显式启用、带目标描述的诊断能力，必要ObjC Hook交给统一SwizzleManager；需要实际type编码、owner与生命周期策略。
- 当前独立翻译/Action格式模块无需任何Swizzle或Native backend；只对这两个模块允许先迁，不代表高风险Native模块审计通过。
