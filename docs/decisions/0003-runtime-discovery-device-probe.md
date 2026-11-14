# 0003 Runtime导出/线程/元数据后端与实机验证入口

设计先于实现。源基线7066ede的Resolver/FullSignature/ABI C API已核对；不会读取猜测的MethodInfo/Class结构偏移。

## 边界

首个真实IL2CPP后端先提供只读类/方法元数据发现。函数从同一已加载镜像绑定并检查dladdr所有者，不混用RTLD_DEFAULT的不同Runtime。持有dlopen引用，operation前后检查Domain一致；未Ready返回可重试错误，不消费once成功状态。

每次元数据操作：已有thread_current则复用，否则attach当前Domain，并且只detach本次附加的thread；finally覆盖成功/失败/异常。所有元数据/TypeName在operation内复制成Foundation值，type_get_name产物通过同Runtime的il2cpp_free释放。返回描述符不保存原生Class/Method指针；后续类展开按完整身份重新定位，歧义拒绝。

扫描有数量/时间上限并明确truncated；计数与渲染使用同一results数组。线程ABI交叉核对BepInEx/Il2CppInterop原维护仓库，native size_t等宽度以原native源声明为依据，不把C# uint声明当原生宽度证据。该参考不是目标游戏ABI已验证声明。

## 实机Probe

独立、单文件、自包含dylib编入当前Core和Discovery，增加一个透明touch-through host与可拖动面板，不复制旧ZNUnifiedUI，不安装Swizzle/Dobby。用户点开后才进行Runtime/metadata操作；constructor仅安排主线程UI启动。

界面提供Runtime报告、类名搜索、类内方法列表与参数/返回类型、复制JSON报告。UIKit只读同一不可变结果快照；query generation拒绝旧worker回传。host选择实际foreground scene窗口，不驱动宿主旋转，布局跟随window bounds/safe area。

首轮实机需要验证加载/UI、真实metadata、计数/卡片一致、键盘、拖动、前后台与旋转。Invoke/GCHandle/Native backend未启用，不能将Probe成功当资源修改或完整开发端验收。

## 待证据

GCHandle32/指针宽度差异及整个managed调用范围的保活仍须目标Runtime确认，Probe只报告相关导出，不调用它们。样本专用外部ObjC Hook与Static Builder仍不在此Probe中。

API交叉参考：BepInEx/Il2CppInterop `81a6f78c8b653e0da4a3420ac4cd00819e8b6292` 的 `Il2CppInterop.Runtime/IL2CPP.cs`。只用于公开API/线程及分配释放配对交叉检查，没有据此声明目标游戏的ABI已经实测。
