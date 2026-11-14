# API2执行与捕获基础模块验证

设计先记录于decisions/0002-execution-lifecycle.md；没有修改原mymenu。

## 实际实现

- NMInvocationRequest：复制完整method identity、参数类型/值，检查static/automatic/ordinal/explicit互斥意图，所有arity/ByRef共用request。
- NMReceiverLease：强持有资源，scope必须在调用线程同步执行一次。ObjC默认scope强持有真实对象；custom scope由未来managed adapter保证整个操作期间存活与地址有效，拒绝裸资源缺失、空receiver、迟到、重复和跨线程operation。
- NMInvocationCoordinator：explicit lease跳过provider；auto/ordinal由provider取得lease；后端在该scope内执行一次，不用TLS或class-wide全局selection。异常和缺失结果明确失败。
- NMCaptureSessionManager：token隔离，Installing/Active/Closing/CloseFailed，等待install ack后关闭，等待安全close ack后才发布成功/解除占用。旧event/cancel/timer/ack不能修改不同token。关闭失败保留资源并允许retry，completion只发布一次。

manager在有会话时自持有，安全close ack后解除。测试确认正常关闭后manager释放；永不ack的违约backend会持续保留会话，不能伪造安全强制释放。

## 已实际运行的验证

Run43643448325，代码ae7f607，四job全部success。

| 检查 | 实际结果 | 边界 |
|---|---|---|
| /0、普通/1、/2、/8与typed/1 ByRef的ordinal/explicit receiver | 全部使用请求B，不再在coordinator内分叉到A | Foundation测试backend；未接真实IL2CPP |
| 并发调用 | 1000次explicit调用隔离，backend一次/请求 | 非游戏Runtime压力测试 |
| Request输入修改 | 原mutable string变化不影响request | 完整类型/元数据解析由adapter负责 |
| Scope违约 | 零次、重复、迟到、跨线程、空receiver拒绝；重复不导致第二次backend | 不能替不正确adapter证明原生地址安全 |
| 生命周期 | 外部ObjC引用释放后，scope执行期间对象存活；执行后一次释放 | 真实ObjC对象，不等于IL2CPP GCHandle ABI验证 |
| A/B捕获回归 | A完成后，B越过A旧deadline仍Active；旧event和cancel不影响B | 真实dispatch timer；Native install/close是控制边界 |
| Install取消 | 未ack保持Installing，阻止新session；ack后cleanup再发布取消 | 安装handler必须最终ack |
| Close等待/失败/retry | ack前不发布成功，失败后不复用；资源保持，retry成功后释放 | safe ack需真实backend保证，不是DobbyDestroy==0 |
| Completion与manager | 一次completion，安全关闭后manager解除自持有并释放 | 未ack持续保留是明确限制 |
| ARM64核心库 | 编译/签名成功，15项精确导出，白名单依赖，6个分析报告无diagnostics | iOS加载/设备未执行 |

原缺陷fixture仍验证固定旧源码会出错；它与新契约fixture是不同代码。不能把新backend替身的成功写成“旧UI/真实游戏已修复”。

## 构建与证据

- Source: ae7f607d2f938bcc29ac545dffcfd09bb15c5292
- Run: https://github.com/a7987083/newmymenu/actions/runs/43643448325
- Artifact: https://github.com/a7987083/newmymenu/actions/runs/43643448325/artifacts/14133306387
- dylib SHA256: 6adef025b3e6608711c504e0b05d3f5515b8a24ecb86aed18eddec784cd1588d
- report: docs/builds/execution-ae7f607.json

`make test-execution`编译并运行两个真实Foundation测试；`make core`生成iOS14.0+/SDK18.5 ARM64 core。产品构建不引用审计fixture或旧源码。

## 未完成的真实边界

当前coordinator同步在调用线程执行，不自动切主线程或attach IL2CPP线程。managed adapter必须显式处理线程与GCHandle版本、完整签名和元数据验证，不能将IL2CPP指针当id交给leaseRetainingObject。Native adapter必须证明关闭安全才ack。旧菜单/搜索UI、真实IL2CPP封送与返回链、Dobby/Static Prepared、完整Build与SwizzleManager尚未集成。
