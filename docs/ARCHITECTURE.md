# 架构草案与迁移门槛

当前进入首批独立基础模块迁移：离线翻译与Action wire/checked codec，见decisions/0001。UI、Invoke、Native与Build尚未迁移；这不是全功能验收。

## 唯一职责

- RuntimeDiscovery：ObjC 与 IL2CPP 分开的 provider；输出带模块世代的元数据身份。Runtime API 缺失必须报告。
- MethodFinder：唯一搜索状态，query/mode/filter/generation/results/scroll。worker 接收不可变查询，主线程提交与 generation 相符的完整快照；count 与 Renderer 使用同一快照。模糊匹配保持原行为直到 fixture 明确。
- DeveloperUI：SceneSession 管理 host window、keyboard、gesture、timer；单 Renderer 路由，显式 actions，不再 Swizzle 自己的页面方法。
- InvokeEngine：唯一 InvocationRequest 入口，显式 method identity、参数、ReceiverLease、执行线程策略、typed result/error。复用 ABI classifier、Marshaller、ComplexStructCodec；不擅自支持未知签名。
- ReceiverStore：单一所有者，租约覆盖完整 managed 调用；枚举序号与身份严格区分；没有可证存活机制时明确失败。不得以 ObjC retain 假装持有 IL2CPP 对象。
- SwizzleManager：仅确证必要的外部 ObjC Hook。安装按 Class/metaclass+SEL 唯一键；保存 original/installed IMP、types、owner、state；签名检查、类局部方法隔离、自身锁、重复/冲突识别。不得承诺原子阻止第三方 runtime 写入。
- NativeHookEngine：与 ObjC 分离，Dobby temporary 与 StaticPreparedHook 分离；固定后端，核实 trampoline 生命周期。无法排空时拒绝热卸载。
- BuildEngine：沿用 Manifest→prepare→base→emit→postprocess；保持单入口。Mach-O、地址转换、签名基础设施通过 fixture 后复用。
- Configuration：版本化 Feature/Action；迁移必须固定64字节原始entry、instanceIndex flags及JSON语义，统一校验和错误。

## Swizzle 生命周期约束

必要目标列表尚未完成，所以不先写泛型“万能 Swizzle”框架。自身 UI 自我修饰改为直接函数调用，不迁移旧 installer 链。

安装仅在明确受控窗口；未加载目标保留 pending，不消费安装成功状态。继承目标 class_addMethod 本地化，不能直接交换父类 Method。恢复原 IMP 只能恢复当时的行为，公开 Runtime API 不能删除已加本地 Method，后续父类修改不会自动继承：必须记录限制。

不能通过“activeCount==0”的一次检查证明安全：新调用可能同时进入，且第三方仍可持有替换 IMP。必须明确调用准入、停止新调用和所有者生命周期。无此保证拒绝运行中恢复，保留已安装代码到进程结束，不能释放 block IMP/trampoline。

## 旧模块处置

| 模块 | 决定 | 原因/迁移门槛 |
|---|---|---|
| ZNUnifiedUI 历史装饰器链 | 完全替代 | 同一 selector 多版本所有者；先提取有效 action/helper 的依赖 |
| HybridFinder/Resolver | 小范围重构 | 已有元数据发现，提取查询上下文与cache generation |
| ABI/Marshaller/StructCodec | 评估直接复用 | 每类参数/返回/ByRef需真实fixture |
| InstanceSelection/M462 | 完全替代生命周期层 | 租约缺失、raw fallback风险 |
| NativeHook backend与ARM64桥 | 暂缓迁移 | Dobby拆卸语义、ABI与在途调用证据不足 |
| Static Builder/Manifest/Mach-O/签名 | 小范围重构外围 | 保留底层算法，补固定二进制fixture和独立校验 |
| 翻译器与词典 | 评估直接复用 | 模块独立；保留许可，运行现有测试 |
| customer UI /网络观察器/hfamap | 不迁移 | 与独立开发端无关 |
| 旧源码中未直接编译文件 | 尚不删除或迁入 | 须排查内联、include、导出与脚本依赖 |

## 下一迁移门槛

1. 完成全部必要 Swizzle 的实际 target/replacement/signature/install-order 列表；目前只有文本库存，不能宣布完成。
2. 完成53项功能的传递依赖闭包、执行入口和范围；弱锚点不能标已实现。
3. 真实ObjC Runtime实验通过后，仅验证Runtime基础结论；不得当成旧菜单回归。
4. 每个业务模块独立迁移、测试、构建、提交；禁止把实验fixture dylib作为产品交付。
