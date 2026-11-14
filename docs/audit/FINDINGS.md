# 关键发现（源码证据，运行状态分别记录）

物理位置均相对于固定候选 HEAD，避免 ZNUnifiedUI.mm 中 #line 指令导致诊断行号混淆。

## F01 已修复历史类结果空白：静态证据确立，设备回归未验证

`ZNUnifiedUI.mm:12452` 的 znm54_submitSearch: → HybridFinder zn64_searchClasses: → 主队列写 kZNM64ClassResultsKey、page=1 → renderPage → 最终 zn52x_renderResultsAtWidth:。

最后一个 Renderer 原来只读 zn60v3_candidates 方法数组；类数组不是这个状态。main commit 7216b55 在最终 Renderer 开头增加 ClassMode 且没有 selectedClass 的判断，转入 znm64_renderClassResultsAtWidth:。候选 :14245 已包含该分流。该修复没有添加 Swizzle。可确证历史修复的代码差异，不能据此保证当前所有空白故障均同因。

## F02 UI 版本装饰器串接：已确认架构债务

Makefile 直接编译 ZNUnifiedUI.mm；它包含大量 `#pragma mark - BEGIN` 内联版本段。启动入口 :2372 → NamedOffsetWorkspace → MethodFinderMenuBinding :4800 → 多层 installer。M5.4 和 M6.13.1 最终 Renderer 不继续调用旧 Renderer。早期实现不能因仍在文件内就视为当前有效实现，也不能因最终覆盖就整段删除：旧段可能仍提供 action/helper/搜索状态。

M4.3 Polish 安装调用已跳过；M4.4.1 的 search/results 交换已移除，但 endEditing 和 InvokeEngine 交换仍保留。应将 UI 状态、路由和 Renderer 合并为显式调用，逐项证明旧 helper 无引用再删除。

## F03 GCHandle 释放与读取范围：已确认同步缺口，崩溃未复现

ZNM462InstanceSafety.mm: selected getter 仅在锁内取得 selection，随后锁外 get_target(handle)。clear/reselect 在锁内移除/替换 selection，锁外 free(handle)。ObjC selection 被强引用不等于内部 GCHandle 尚未释放。存在 getter 与 free 并发交叠的代码路径，且取得裸 receiver 后到 Invoke 结束之间没有租约。

缺少 GC API 时还回退缓存原始地址，再调用 object_get_class；这不是托管对象存活证明。重构应引入受控执行范围的 ReceiverLease，完整调用期间持有 handle，延迟释放；缺少可证明的存活机制时返回明确不支持，不静默沿用裸指针缓存。IL2CPP GCHandle 实际 ABI 必须针对目标 Runtime 验证，不能将源注释当版本证据。

## F04 Native Hook teardown：已确认未见调用排空，运行风险未验证

ZNNativeHookRuntime.mm: removeTemporaryHookForCandidate: :1642 附近调用 DobbyDestroy 后立即将 slot original/actionID/target 清零。removeAction: :2164 类似。局部 atomic 字段不能证明整条卸载生命周期安全；尚未证明 DobbyDestroy 排空全部已经进入的 replacement。

本轮进一步读取 Dobby 固定 commit 5dfc8546954ce3b3198132ab13fddb89ee92cdd7 的 source/dobby.cpp:18：DobbyDestroy 仅 remove entry、restore_orig_code，然后 return；没有在途调用等待，且明确保留 `FIXME: delete entry safely`、注释掉 delete。source/Interceptor.h 的 find/remove/add 直接操作 vector，没有内部锁。因此不能把 DobbyDestroy 返回成功当调用排空，也不能声称它在这里释放了 trampoline。应关闭新操作、等待受控在途调用或拒绝运行中卸载。Static prepatch 与临时 Dobby 是不同后端，不能混用恢复规则。

## F05 早到安装被 dispatch_once 消耗：静态风险

多个 installer 在 dispatch_once 内查 Class/Method，缺失时直接 return。once 已消费，晚加载 Class 不再重试。需要独立 pending/installed/failed 状态。是否在真实启动顺序发生，未验证。

## F06 instanceIndex 不是稳定身份：已确认契约限制

ZNRuntimeActionFormat.h 使用 flag bit7 + bits16..23，0=自动，1..128=当次枚举序号。开发端 InvokeEngine :151 每次重新枚举后按 index-1 取 receiver。不能保证跨调用/场景/重启稳定；不能把“指定序号”当“固定对象”。customer 有 auto-bind unique receiver 的额外 lifecycle，开发端没有这个 customer wrapper。两者并非所有生命周期完全相同。

## F07 线程局部隐藏参数：已确认设计债务

InvokeEngine gZNExplicitReceiverOverride 是 thread_local，通过 @try/@finally 恢复，具备同线程嵌套恢复。但它仍然是隐藏执行上下文；移植为显式 InvocationRequest/ReceiverLease 参数，保留单一入口。

## F08 构建边界已存在，优先复用

ZNBuildExecutorBuildWorkspace 明确检查未恢复临时 Patch；Manifest → prepare → Static 或 Runtime-only base → emit providers → postprocess。禁止重写 Mach-O 基础算法。迁移前需把内部依赖及验证 fixture 补齐；当前不是已验证可用声明。

## F09 签名检查不足

旧 CI 的 ldid -e 使用 `|| true`，不是强制签名有效性验证；otool 依赖检查只排除 Dobby 动态依赖。新 CI 应独立检查 LC_CODE_SIGNATURE、实际签名、架构、导出白名单和依赖允许列表。

## F10 跨 dylib 并发修改 Runtime 的边界

objc Runtime 没有提供公开 compare-and-swap IMP 所有权接口。管理器可串行化自身、检查当前 IMP 并拒绝已发现冲突，不能承诺阻止任意其他 dylib 在检查与写入之间竞争。安装必须限定受控初始化窗口；必要恢复必须限定受控静止窗口，不能包装成万能线程安全。

## F11 Native lifecycle事件合并：源码竞态窗口，运行未验证

ZNNativeHookLifecycleBootstrap.mm 的 requestReconcile 在 scheduled=YES 时合并新事件。worker用before count调用prepare，完成后把lastImageCount赋为当时的最新count，再比较当前count与lastImageCount。若image在prepare期间新增、回调因scheduled=YES被合并，且prepare未包含该新image，完成时赋最新count会掩盖这次新增，末尾比较相等而不重跑。尚未证明具体prepare在该窗口漏项，故标为需fixture验证的竞争路径。应以处理过的generation而非完成时最新count作为完成水位。

## F12 旋转路径已定位，未声称不存在

ZNUnifiedUI.mm:548 的tick按window bounds/safeArea变化调用layoutForWindow，并非使用orientation关键词注册旋转通知。因此关键词没有命中不能等价“没有旋转处理”。布局还经过多个装饰层，必须继续追踪最终IMP与hostWindow选择；实机旋转/多scene未验证。
