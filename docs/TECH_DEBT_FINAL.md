# 交付时技术债复审

审查对象：API21源码e797351d；证据为同源五Job成功及下载产物。没有“零技术债”结论。

已替换/删除：旧巨型UI和associated-object分散搜索状态不进入新执行路径；历史DeviceProbe源码/构建入口已删除。单一Finder快照承担计数与卡片，唯一模态入口和picker身份回调，统一配置/地址/迁移/签名/Static执行所有者。旧工厂与旧schema不保留第二执行器；schema仅单向升级。成熟词典、迁移/payload/签名算法按证据复用，未复制整仓作为备用。

实际根因修复：AMFI wpmapped:1发布inode生命周期（已实际加载验证）；相对/绝对镜像路径身份；布尔数值误识别；继承/重复/外部IMP冲突检查；同标题导入被错误合并；逐行Static类型被全局默认覆盖；同组控件不一致在生产计划提前拒绝。UI单一快照防计数/卡片分裂，异步generation与picker身份阻止过期回调；4096行使用UITableView复用而非全量控件。

测试边界：Runtime fixture验证真实Objective-C方法交换和ABI行为，ARM64 fixture验证预埋执行/原值恢复/并发，Simulator验证实际Static加载和程序化UI。预防性生命周期保护不能凭源码宣称已复现所有旧游戏故障。Finder旧空卡片不能笼统归因于Swizzle。

剩余限制：游戏ABI与实机验收、外部未知Hook协作、进程pin卸载限制、未知Mach-O引用与命令、跨site原子性、JSON词法重复键、大镜像设备性能及runner逐位复现。详见KNOWN_ISSUES.md；不以删除必要功能消除这些风险。
