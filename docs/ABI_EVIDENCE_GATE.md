# 真实Runtime ABI证据门槛

## 已有证据

Core API5解析器/类排名/元数据扫描与既有生命周期组件已经受控fixture/ASan/真实Foundation/Objective-C Runtime验证。只见4d9231c7用户照片中的面板显示；没有目标Runtime报告、目标UnityFramework/主可执行文件、版本匹配的IL2CPP头文件或目标执行日志。

## 不能照搬的旧假设

- 固定7066ede的ZNIL2CPPResolver.mm:293–308在method_get_pointer缺失时memcpy MethodInfo前两个机器字并检查可执行段。落入可执行段只证明地址可执行，不证明这是该方法入口/ABI/对应重载。
- ZNM462InstanceSafety.mm:11–20声明旧/新GCHandle宽度差异，并统一使用uintptr_t作为兼容性方案。这是源码的兼容性声明，不是当前目标二进制的返回值/参数宽度验证。
- NATIVE_BOUNDARIES记录DobbyDestroy不提供在途调用排空证明；原typed模板/原函数链必须和实际目标方法签名匹配，不能用fixture成功当真实宿主验证。

## 最少还需的数据

1. 首个验收宿主的确切版本/Build与对应Runtime镜像（UnityFramework或实际承载IL2CPP的主可执行文件；对应IPA也可）。需要UUID及目标指令/导出证据，不能只用另一个版本的dump。
2. 已交付只读验证版的检查Runtime、一个类展开和一个Method结果JSON；错误结果也保留。无需为此生成新验证dylib。
3. 后续设备执行日志/崩溃日志，用于校验真实Invoke/Hook/恢复。当前不把这一项当已经完成。

没有这些证据，仍可进行纯配置/Mach-O/文本等独立模块审计与fixture工作，但不能安全宣称managed adapter、native entry恢复和完整产品已接入/通过。不得为满足进度采用raw receiver fallback、MethodInfo字猜测或跳过ABI检查。

用户最新要求：不再中途分发dylib；最终产品完成才交付。CI内部构建产物仅作为证据保存，不向用户作为阶段成品分发。

## 用户后续范围调整

游戏ABI依赖已明确暂缓，不再作为整个工程暂停理由。搜索/配置/Manifest/ObjC Runtime生命周期/离线Mach-O与签名等工作继续。暂缓Invoke/managed receiver与需要目标布局的Native/Prepared部分，不把暂缓写成已完成。用户仍要求最终整合后再发dylib，本阶段不分发二进制。
