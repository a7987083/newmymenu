# 0001 首批独立模块迁移边界

状态：按模块源码审计闭包进入实施；不是全项目审计或功能对等验收。
固定来源7066ede，设计在业务代码迁入前记录。

## 证据与范围

1. 翻译：ZNUnifiedUI.mm:14376只将候选method名字交给translateMethodName用于gloss，不修改candidate身份。Translator完整依赖为Foundation、内嵌词典、确定性生成器和3000词条JSON，没有Runtime/Hook/UI依赖。完整实现已读，词典许可已随源保留。算法复用，仅改公开类/头文件名到NM命名空间，不保留ZN兼容别名。
2. Action格式：ZNRuntimeActionFormat.h的magic/version/kind/flags、64-byte header/entry及field offsets被Builder和Runtime消费。结构布局与常量原值复用并改为NM命名；不迁入不校验范围的旧encode/decode helper。公开checked codec拒绝无效序号并保持非序号flag，失败不修改输出。

## 架构与唯一所有者

- src/MethodFinder：翻译实现及私有生成数据；公开NMMethodTranslator，私有NSCache只属于翻译模块。
- include/NMRuntimeActionFormat.h：共享wire定义，纯C/C++可用。
- src/Configuration：唯一公开checked ordinal codec；不引入instance store，不把ordinal当稳定对象身份。
- src/NMCore.c：核心API版本标识，不做constructor或后台初始化。
- 构建只依赖Foundation/libobjc/libSystem，独立于原仓库、Theos、Dobby和旧UI。

## 验证与迁移门槛

本地C/C++测试验证layout、0..128序号、无效值和非序号flags；CI macOS真实Foundation运行翻译测试及与固定原实现的全词条/变体对照。旧实现只在回归test中从固定源checkout编译，不进入产品或生成结果。

CI固定Xcode16.4/iOS18.5、deployment14.0；编译独立ARM64核心dylib，检查架构/依赖/导出/签名/SHA。该产物没有菜单、Invoke/Native/Static功能，不得作为完整开发端交付。

## 暂不迁入

搜索Renderer、Invoke、ReceiverStore、Capture、Native和Build仍需各自有效调用/数据/生命周期审计。已发现的缺陷不得靠带入旧wrapper掩盖。SharedSite含外部ObjC Hook，不属于可整体删除的内部Swizzle链。
