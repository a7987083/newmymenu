# 统一ObjC Swizzle管理器

位置：include/NMSwizzleManager.h、src/Swizzle/NMSwizzleManager.m。设计先于实现见0010。它只管理必要ObjC方法替换；不承担Native Dobby、managed Invoke或UI状态修补。没有constructor自动安装，没有method_exchangeImplementations旧备用路径。

## 安装与执行契约

1. 全部目标消息调用经同一sharedManager.performInvocation读scope；所有竞争写入必须遵循同一协调域。安装方必须显式确认此条件，未确认返回错误，不做降级安装。
2. 入参只接受普通Class，拒绝直接传入metaclass造成二次object_getClass取错目标；随后从真实class/metaclass取出原Method和replacement Method。NSMethodSignature逐个比较return/arguments编码，不调用任意强转通用IMP。manager保存精确原IMP；replacement按编译器已知类型调用它并使用token.selector保留原_cmd语义。
3. try-write安装/恢复：活动读scope或其他mutation存在时直接拒绝，不阻塞等待，不在自己的Hook内部恢复造成死锁。
4. registry以runtime Class/metaclass+SEL唯一所有；重复安装拒绝。恢复检查当前IMP及继承owner的IMP；foreign/parent改变时拒绝覆盖其链。
5. token用dladdr/RTLD_NOLOAD持有两类及两IMP镜像，拒绝无法持有的动态地址和externally owned block-backed IMP。失败候选与restore token保持到写scope退出后再释放，避免dlclose在锁内重入。

共享锁不能禁止任意外部dylib直接写Runtime，也不是跨第三方method_setImplementation的CAS。未参与协调的宿主/第三方并发行为不在保证范围；不能只填YES就宣称外部调用被暂停。SharedSite真实外部诊断还需证明调度适配条件，当前没有自动接入。

## 继承语义

默认继承策略Reject，完全不修改父类或子类。显式LocalSnapshot才用class_addMethod隔离父类；恢复安装前IMP行为，但本地方法槽保留（公共Runtime没有删除方法API），今后父类变化不会自动传播到此槽。若安装期间父类IMP变化，恢复被拒绝。此策略不能冒充完全恢复动态继承。

Class Method对metaclass执行相同规则。恢复token只可成功一次，成功后registry移除；过期/重复恢复明确报错。state是Active/Restored，诊断最多保留128条事件，active Hook最多128个，资源状态不靠无关全局变量传递。

## 实际验证

`make test-swizzle`：macOS真实ObjC Runtime+AddressSanitizer，不是Mock成功路径。覆盖：

- instance/class method、整数/浮点/多参数结构体返回，原IMP与_cmd。
- 首次/重复安装、签名不符、block IMP拒绝、instance/metaclass独立所有权。
- 默认继承拒绝、显式子类覆盖、父类不变、父类变化拒绝恢复、本地槽保留。
- 1000个并发协调调用、另线程活动call与同线程重入时安装/恢复拒绝。
- foreign IMP变更识别、冲突解决后的恢复、过期token拒绝。
- 真实receiver释放、异常后的scope释放和继续使用、可观察诊断，以及128/129容量边界和安装/恢复诊断滚动保留。

正式core执行iOS ARM64编译、独立静态分析及导出/依赖/签名验证。实际设备、宿主外部诊断和未合作第三方并发均未验证；管理器组件通过不能当完整菜单Swizzle验收完成。

Runtime编码不携带variadic省略号语义，本管理器契约仅支持已确认的非变参方法；编码一致不是对未知C/变参声明的证明。
