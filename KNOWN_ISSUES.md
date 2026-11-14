# 已知问题

- 审计尚未完成；53项中部分是实现片段，完整依赖闭包与全部Swizzle目标仍待验证。
- 仅离线翻译与Action格式核心源码迁入；完整菜单尚未迁移，不具备替换旧开发端条件。基础core的构建/测试独立记录，不等于完整产品验证。
- 原代码GCHandle使用范围/释放竞争及Native teardown风险，见FINDINGS.md；尚未在实机复现。
- 本机没有Apple SDK、clang或iOS设备。真实Runtime与ARM64实验由CI执行，状态见Actions；不能把实验结果当产品或实机结果。
- UIKit/IL2CPP及第三方Hook并发没有真实运行验证。

- M47多参数/ByRef分支绕过ordinal和explicit receiver，已在固定源隔离运行复现；生产未修复。
- ReceiverCapture旧timeout结束新会话，已在真实dispatch隔离运行复现；生产未修复。
- Build collector异常吞为空items及跨阶段全局store快照限制，详见BUILD_BOUNDARIES，业务运行影响未验证。

- SharedSite实际包含外部Class/SEL的诊断Hook及样本固定RVA，不是全部内部UI装饰器；保留迁移项，首批core不包含它。
