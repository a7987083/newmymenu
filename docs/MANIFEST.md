# 不依赖游戏ABI的Build Manifest

## 来源与职责

沿用固定原源的BuildItem字段：providerIdentifier/kind/identifier/domain/metadata，Static=1、Runtime=2。新模块`include/NMBuildManifest.h`与`src/Build/NMBuildManifest.m`把原可变item收敛为深冻结对象；NMBuildProvider显式注入collector，NMBuildManifest冻结configuration后再按provider稳定排序收集。没有默认全局registry，没有跨阶段读取store的内置路径。

原ZNBuildManifest.mm:315–316的collector异常转空数组机制已替换：异常、nil而无error、返回error、重复provider、重复(provider,item)身份、条目来源不符均明确失败。成功空列表只能由明确的空provider集合或合法空collector返回。错误回调使用强持有通道，内层autoreleasepool退出不使错误悬空。

items/metadata/configuration在后续源字典变化后保持不变；计数与activeProviderIdentifiers都从相同items推导，避免重复状态。后续prepare/emit必须消费此snapshot，不可回读全局store。当前尚未接入生产prepare/emit和旧UI。

## JSON边界

Manifest自身交换格式为`format=newmymenu.manifest`、`schemaVersion=1`、`items`数组。item精确包含provider/kind/identifier/domain/metadata；schema和domain拒绝bool、非法数字、未知键、错误类型和重复身份。输入/导出4MiB限制，provider最多128个、items最多4096个。metadata仅限JSON字典且深复制；未知provider payload不在这里解释。

这不是旧zonoe-authoring或Patch JSON的兼容解析器；原业务配置格式、control模型和UI导入导出仍待单独迁移。不能据此声称Static/Runtime/Native混合构建已完成。

## 真实测试

`make test-manifest`：macOS Foundation + AddressSanitizer，验证混合Static/Runtime计数、配置冻结、metadata深冻结、排序、全部collector失败路径、错误对象生存期，以及严格JSON字节稳定往返/坏schema/重复身份/非法枚举等。

模块进入独立iOS ARM64 core，适用静态分析与导出/依赖/签名校验。CI结果仅证明组件行为，不等价真实Build输出或设备回归。
