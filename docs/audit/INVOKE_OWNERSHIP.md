# Invoke Engine 的真实职责与 selector 所有权

固定开发端7066ede；原仓库未修改。以下是源码安装顺序推导，假设所列Class/Method存在、installer成功且没有外部dylib修改。不是实际目标进程的IMP地址快照。

## 安装与最终入口

入口：`ZNUnifiedUI.mm:4800 ZNInstallIL2CPPMethodFinderMenuBindingDeferred`，按源语句顺序调用：

| 顺序 | installer / 文件 | 交换的公共入口 | 实现职责 | 旧实现是否继续 |
|---|---|---|---|---|
| 1 | M46SignatureExecution / ZNM46SignatureExecution.mm:131 | executeAction:error: ↔ znm46_executeAction:error: | 完整签名threadDictionary上下文；另交换Resolver方法入口 | 未提供有效签名时直通；否则try/finally包裹旧入口 |
| 2 | M47MultiArgInvoke / ZNM47MultiArgInvoke.mm:489 | executeAction:error: ↔ znm47_executeAction:error: | /2–/8及/1 ByRef解析、封送、receiver与runtime_invoke；另装capabilities | /0和普通/1直通；其他分支独立执行，不调用基础入口 |
| 3 | M48ReturnCapture / ZNM48ReturnCapture.mm:237 | executeAction:error: ↔ znm48_executeAction:error: | 取旧结果、ABI返回解码、合并result；全局pending状态文案 | 调用旧入口后继续 |
| 4 | M50ManagedReturnChaining / ZNM50ManagedReturnChaining.mm:189 | executeAction:error: ↔ znm50_executeAction:error: | 全局上次托管返回对象注入类selection、调用后恢复、捕获新返回 | 调用旧入口；恢复没有try/finally |
| 5 | M52ImmediateChainV2 / ZNM52ImmediateChainV2.mm:481 | executeAction:error: ↔ znm52_executeAction:error: | root/node调用、token/signature校验、返回与trace | 通过alias逐节点进入M50及内层 |

最终公共入口的预期链：M52 → M50 → M48 → M47。
M47根据arity/ByRef分支：

- /0、普通/1：M47 → M46 → 基础executeAction:error: → executeAssembly（它又被M441结构调用修饰）。
- /2–/8、typed /1 ByRef：M47直接解析签名、选择receiver并invoke；不经过基础executeAction及M46。

基础显式receiver重载保留TLS变量，但它随后再次调用公共executeAction，仍会进入这条装饰链。仅恢复TLS值不能保证下游实际读取过它。

## 实例契约缺陷：源码与隔离运行均确认

`ZNM47InstanceForAction` :156 只读取class-wide selected receiver或unique instance，不读取action.instanceIndex，也不读取基础TU的gZNExplicitReceiverOverride。
基础入口 :151 才处理instanceIndex；UI各路径确实传播该字段，但M47的独立分支绕过它。

实际CI Run43633875936，source2386068：生成器先核对源文件SHA256，完整编译原M47文件（仅移除本地imports），基础普通/显式receiver方法逐字节抽取；执行真实Objective-C exchange、dlsym与libdispatch。IL2CPP resolver、ABI和runtime_invoke使用明确的受控替身，不是目标游戏Runtime。

| 调用形态 | 请求receiver B | 实际receiver | 基础入口调用/枚举次数 |
|---|---|---|---|
| /0 | ordinal=2 或 explicit=B | B | ordinal路径1/1 |
| 普通/1 | ordinal=2 或 explicit=B | B | ordinal路径1/1 |
| /2、/8 | ordinal=2 或 explicit=B | A（现有class selection） | 0/0 |
| /1 Int32 ByRef | ordinal=2 或 explicit=B | A | 0/0 |

还确认：instanceIndex=129在基础路径拒绝，但/2路径仍执行A；原ByRef参数槽被受控invoke写成99，回传byRefResults读取99，说明测试真正进入了ByRef路径。

这验证了**旧源码的分支缺陷**，不是生产修复通过，也不证明真实游戏的枚举顺序、IL2CPP ABI或对象存活。

## 重构决策

1. `instanceIndex / explicit receiver / lease / signature / parameters` 在唯一入口先规范化为不可变InvocationRequest，所有arity使用同一契约。后端只能消费已解析ReceiverLease，不能自行读class-wide selection覆盖request。
2. 完整签名解析明确传递给resolver；M46线程字典不迁移。
3. 保留M47类型封送算法和ByRef约束；与旧源码比对后再逐类型迁移，不复制执行分流。
4. M48返回解码变为返回阶段；状态提示按invocation ID交回UI，不使用全局pending文案。
5. M50/M52的managed-return由显式chain session拥有，root/node的receiver/handle显式传递；不能用最近一次全局返回污染其他action。
6. runtime_invoke使用受控边界fixture验证逻辑只是必要条件，最终对象/GCHandle ABI仍须对应Runtime或实机验证。

## 补充生命周期风险（源码，尚未做完整运行复现）

M50在执行旧实现前更改全局selection，调用后才restore/free；缺少try/finally。若产生Objective-C异常，restore/free路径被跳过。它的全局gZNM50Generation也在锁外递增，不支持据此声称并发隔离。

M48的全局gZNM48PendingReturnSummary虽然有锁，但没有invocation身份匹配；不同调用/状态提交交错时仍可能展示其他调用的返回结果。互斥保证内存访问，不保证业务归属。
