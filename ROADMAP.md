# 开发路线与验收

## 已完成的明确范围

- 固定原开发端7066ede，建立功能/Swizzle库存和关键调用证据；不是完整动态IMP审计。
- 实际隔离复现M47接收器契约绕过和Capture旧timeout跨会话问题。
- 完成首批离线翻译与Action wire/checked codec的模块审计、设计、独立源码迁移、测试和ARM64 core构建。
- f385c8a的Run43638969924四job通过；基础core机器报告位于docs/builds。

## 下一阶段

1. 完成Invoke/Receiver依赖闭包，设计不可变InvocationRequest、完整调用范围ReceiverLease和显式chain session。验收：所有arity/ByRef消费同一receiver契约，不能再用隐藏TLS分流。
2. 重写CaptureSession生命周期。验收：旧timeout/callback/cancel不能影响新session；teardown必须由backend确认安全后才允许释放/复用。
3. RuntimeDiscovery/MethodFinder状态与单Renderer迁移。验收：count和卡片同一快照；类/方法切换、取消、滚动、复制与翻译保持行为。
4. Native/Build迁移：临时Dobby、StaticPrepared及外部SharedSite诊断各自生命周期；BuildRequest冻结输入并显式传播错误。成熟Mach-O/ABI算法优先复用。
5. 必要外部ObjC Hook进入统一SwizzleManager，完成真实Runtime冲突/继承/恢复fixture；不因旧版本装饰器多就删除有用外部诊断。
6. 完整开发端ARM64 dylib构建、功能矩阵回归、技术债复审与真实iOS加载/交互验证，再交付Release。

首批core成功不等于完整产品；未执行的设备/业务回归一直标未验证。
