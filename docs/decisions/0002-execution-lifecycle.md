# 0002 显式调用与捕获生命周期（实现前设计）

源码依据：固定7066ede的M47接收器分流、M462 handle使用范围、Capture全局active/timeout，详见既有隔离复现。目标是先提供可独立验证的基础契约，不在没有目标Runtime证据时构造IL2CPP API或安装Dobby。

## 调用

InvocationRequest不可变，包含完整method identity、参数类型/值、static与receiver选择。0..8参数/ByRef共用一个Coordinator入口；explicit lease不再交给class-wide selection覆盖。自动/ordinal通过provider取得同一种lease，后端只消费该request和lease范围内的receiver。

ReceiverLease持有资源owner及同步scope。ObjC默认实现强持有对象；未来IL2CPP adapter必须提供在整个scope内保证对象存活及地址有效的资源，不允许裸地址fallback。scope必须在调用线程内同步调用operation一次；框架拒绝零次、重复、晚到/跨线程operation。不承诺靠retain一个NSObject就能保住IL2CPP对象。

后端/Provider异常转成明确NSError；不吞失败，不做隐式重试或rollback。backend有副作用后抛异常不代表副作用可撤销。

## 捕获

每个manager拥有serial queue；每个session拥有不可变token和target identity。
状态：Idle→Installing→Active→Closing→Idle；关闭失败进入CloseFailed，禁止新会话，允许retryClose。失效后不再启动新会话。

install handler接收带token的event和install ack。先收到event或cancel时保留意图，等待install ack才关闭；不允许“安装尚未完成就复用slot”。timeout在install成功后才开始。event只接受已经持有资源的ReceiverLease，不把裸指针异步投递。

每个timeout/event/ack/cancel检查token身份。关闭成功ack之前不发布成功结果或允许新会话；关闭失败明确报告，并保留资源/slot所有权。close ack必须由backend在真正安全后给出，不能用DobbyDestroy返回值冒充调用排空。

外部回调必须非阻塞且最终ack；未ack的install/close无法证明安全，因此保持占用，不强制释放。manager在会话期间自持有，只有安全关闭ack后解除；违约的永不ack后端会使该会话持续保留，不能报告已释放或允许复用。iOS/Dobby/IL2CPP adapter尚未接入，不能宣称实际Hook恢复安全。

## 验证

使用真实Foundation对象验证scope期间存活及释放；真实并发调用覆盖arity/ByRef共用receiver。使用真实libdispatch timer验证A完成后旧event/cancel/timeout不能结束B；覆盖安装取消、关闭等待、关闭失败/重试和一次性completion。

保留旧源码缺陷复现作为对照，但不把“新契约测试通过”写成“旧UI/Invoke/真实游戏已修复”。新模块加入独立ARM64 core并执行严格导出/签名/依赖检查。
