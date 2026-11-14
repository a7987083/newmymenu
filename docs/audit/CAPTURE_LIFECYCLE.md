# Receiver Capture 会话生命周期

固定开发端7066ede，源码 `ZNM47ReceiverCapture.mm`（Makefile直接编译）。

UI最终入口 `ZNUnifiedUI.mm:14782` 的长按处理调用 `ZNM47StartReceiverCapture`。流程：原子active标志→全局instrumentAddress/completion→DobbyInstrument→preHandler读x0→主队列Finish→Destroy→completion→校验并保存实例。

## 已确认的源码缺口

每次start创建dispatch_after，但没有capture session ID，也没有取消该旧timer。Finish仅比较全局active是否true。

可疑事件序列：A任务0.5秒超时；A在0.5秒前成功，completion启动B任务（15秒）；A的旧timer触发时active属于B，于是Finish(YES)销毁B并调用B的completion。

此外，Cancel同样只是异步调用全局Finish，没有绑定请求时的session，排队期间新任务开始后也可能错取消新任务。Dobby callback只检查全局active，不验证address或generation，旧在途回调是否能污染新session需单独验证。

## 验证设计与状态

`generate_capture_audit.py` 先按库存核对原`.mm`和两个header SHA，然后完整带入原实现（仅移除本地imports）。真实arm64 macOS、Foundation与libdispatch运行实际异步与timer；DobbyInstall/Destroy是记录调用的受控替身，不实际改代码。

A完成后立即创建B；检查A的旧0.5秒timer是否会销毁B。已在CI Run43634163884（10efd67）编译并实际运行通过：A完成后B的15秒任务，在约0.543秒被A的旧timer结束；两次Install和两次Destroy均被边界记录。此结果只确认状态机缺陷，不确认真实Dobby teardown或iOS行为。

## 必须采用的生命周期

CaptureSession拥有唯一generation、target、completion、timeout和hook ownership。所有start/cancel/finish/callback都携带session身份；在唯一状态队列上比较仍是当前session，旧任务只可释放自己的资源。

active bool不能充当身份。Dobby teardown仍需NativeHookEngine的独立在途调用策略；session身份修复并不等于Dobby热卸载安全。
