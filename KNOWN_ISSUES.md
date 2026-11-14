# 已知问题

- 审计尚未完成；53项中部分是实现片段，完整依赖闭包与全部Swizzle目标仍待验证。
- 离线翻译、Action格式及执行/捕获契约组件已迁入；真实Runtime/Native adapter和完整菜单尚未迁移，不具备替换旧开发端条件。基础core的构建/测试独立记录，不等于完整产品验证。
- 原代码GCHandle使用范围/释放竞争及Native teardown风险，见FINDINGS.md；尚未在实机复现。
- 本机没有Apple SDK、clang或iOS设备。真实Runtime与ARM64实验由CI执行，状态见Actions；不能把实验结果当产品或实机结果。
- UIKit/IL2CPP及第三方Hook并发没有真实运行验证。

- M47多参数/ByRef分支绕过ordinal和explicit receiver，已在固定源隔离运行复现；生产未修复。
- ReceiverCapture旧timeout结束新会话，已在真实dispatch隔离运行复现；生产未修复。
- Build collector异常吞为空items及跨阶段全局store快照限制，详见BUILD_BOUNDARIES，业务运行影响未验证。

- SharedSite实际包含外部Class/SEL的诊断Hook及样本固定RVA，不是全部内部UI装饰器；保留迁移项，首批core不包含它。

- API2新增执行/捕获基础组件已通过Foundation和ARM64构建验证，但原M47/旧Capture UI未集成，旧源码缺陷仍保留在审计基线。
- custom lease的managed存活/地址/线程保证和capture safe close必须由待实现adapter提供；当前没有默认raw pointer fallback或Dobby成功即ack的实现。
- install/close永不ack时会话保持占用与自持有；无法证明安全时不强制释放。正常关闭/retry释放已实际测试。
