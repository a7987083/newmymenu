# 开发路线与验收

## 已完成的明确范围

- 固定原开发端7066ede，建立功能/Swizzle库存和关键调用证据；不是完整动态IMP审计。
- 实际隔离复现M47接收器契约绕过和Capture旧timeout跨会话问题。
- 完成首批离线翻译与Action wire/checked codec的模块审计、设计、独立源码迁移、测试和ARM64 core构建。
- f385c8a的Run43638969924四job通过；基础core机器报告位于docs/builds。

## 本轮 DeviceProbe

Finder单一不可变页面状态与类列表返回/滚动恢复已通过Foundation/ASan；UIKit设备恢复待验证。RuntimeDiscovery 的同镜像导出绑定、线程所有权与元数据值复制已实现；自包含只读 UIKit 验证入口用于收集真实游戏证据。具体设备步骤见 [DEVICE_VALIDATION](docs/DEVICE_VALIDATION.md)。这不等于 MethodFinder/Invoke 的完整迁移。

## 下一阶段

1. InvocationRequest/ReceiverLease/Coordinator基础组件已实现并经Foundation验证。下一步接入版本明确的IL2CPP解析/线程/GCHandle/封送/返回adapter和显式chain session，保持所有arity使用同一契约。
2. CaptureSessionManager新状态机已通过真实timer、失败/retry与释放测试。下一步接Native adapter；不能以DobbyDestroy成功代替在途调用排空。
3. RuntimeDiscovery/MethodFinder状态与单Renderer迁移。验收：count和卡片同一快照；类/方法切换、取消、滚动、复制与翻译保持行为。
4. Native/Build迁移：临时Dobby、StaticPrepared及外部SharedSite诊断各自生命周期；BuildRequest冻结输入并显式传播错误。成熟Mach-O/ABI算法优先复用。
5. 必要外部ObjC Hook进入统一SwizzleManager，完成真实Runtime冲突/继承/恢复fixture；不因旧版本装饰器多就删除有用外部诊断。
6. 完整开发端ARM64 dylib构建、功能矩阵回归、技术债复审与真实iOS加载/交互验证，再交付Release。

首批core成功不等于完整产品；未执行的设备/业务回归一直标未验证。

## Finder后续验收顺序

API4已接方法关键词/公开元数据详情/原词典/字段复制；矩阵见docs/METHOD_FINDER.md。下一批优先审计复用原表达式/parser，建立命名空间/assembly/参数个数与错误输入对照fixture，然后补排名、显式取消和地址查询，不凭关键词版成功删需求。真实Invoke接入仍需目标Runtime报告确认ABI/生命周期。

## 连续推进与证据门槛

API5 parser/qualified filters/排名已实际编译回归通过，不再中途发送验证版。Invoke/Native高风险接入先补版本匹配Runtime二进制/导出/日志证据，见docs/ABI_EVIDENCE_GATE.md；其余未迁移Configuration/Build/外部诊断仍保留在路线，不以该门槛表示它们已完成。

## ABI独立路线实际推进

- 协作取消及取消后的generation失效已通过CI。
- 不可变BuildItem/Manifest、唯一冻结配置、collector错误传播和Manifest-only JSON往返已通过Foundation/ASan与ARM64构建。旧authoring/Patch JSON导入尚未迁移。
- 复用签名器在独立codesign校验中暴露的ad-hoc标志/证书要求矛盾已根因修复；源文件保护、临时副本、不覆盖发布及损坏输入验证已实现。当前集成/权限拒绝负例以CI为准。
- 接下来：必要ObjC Swizzle生命周期与真实Runtime fixture、配置模型/UI导入导出、独立Static Patch/Mach-O构建闭包及最终DeveloperUI。游戏ABI暂缓不是全局阻塞。

## SwizzleManager独立组件

统一manager/token已实现并接入API9核心：合作式调度、类型检查、原IMP/代码镜像所有权、重复/foreign/parent冲突拒绝、显式继承策略和恢复。真实ObjC Runtime fixture覆盖参数/返回/原IMP与并发/生命周期；不依赖游戏ABI。

剩余：真实SharedSite诊断的调度适配不能仅填coordinated=YES；必须证明全部目标调用与writer参与同一域。未经证明不安装。参见docs/SWIZZLE_MANAGER.md，不能把组件测试通过当旧诊断功能已整体迁移。
