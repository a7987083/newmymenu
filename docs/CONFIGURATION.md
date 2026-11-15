# 离线业务配置

入口 include/NMConfiguration.h，唯一实现 src/Configuration/NMConfiguration.m。documentFromJSONData 解析旧 zonoe-authoring/schemaVersion=1 或 newmymenu.authoring/schemaVersion=1，再构建不可变 Runtime/Native 文档；不调用目标 Runtime。

Runtime 保留原方法身份、参数、控件、链和 instanceIndex；旧格式不能表示非零 instanceIndex，导出时明确拒绝。Native 保留模板1至5，冲突ID确定重映射。过期二进制地址缓存删除并产生警告，requiresTargetValidation 始终为真。原功能身份算法仅保留一个私有实现，10000组与固定原实现对照。

NMConfigurationStore 唯一拥有 document/revision。导入先在局部完成解析及合并，最终按 expectedRevision 原子提交；失败或旧revision不改变任何Runtime/Native状态。100个并发提交仅一个成功。

输入/输出4MiB，深度64，节点65536，每类列表最多256；原始树和标准化树均检查。与 Manifest/Patch 候选格式相互独立，不通过猜测把不同领域混为同一文档。

验证：make test-configuration；make test-configuration-parity SOURCE_BASELINE=/path/to/fixed-source。Foundation/ASan和原身份对照已通过。尚未接入最终UI、磁盘持久化、真实Invoke/Native执行或生产Build provider。
