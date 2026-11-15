# 原功能与新实现回归矩阵

固定原源码基线7066ede。原运行行为没有完整设备证据，以下只比较有证据的源码行为与新实现；不是53项全部通过证明。API19核心8bb60d21在Run43770082803/foundation-core通过；新Simulator路径仍待完成。上次整套通过为17878f28 / Run43689802080。

| 功能 | 原行为证据 | 新实现/调用链 | 验证与差异 |
|---|---|---|---|
| 类/方法搜索 | HybridFinder→最终UI，历史Class分流曾遗漏 | NMIL2CPPDiscovery→NMFinderSession generation→单table Renderer | test-discovery/finder；受控原生API表通过，真实游戏未验证 |
| 模糊/限定搜索 | exact/prefix/suffix/contains及NamedExpression | 有界类排名；NMNamedExpression限定assembly/namespace/class/method/arity | parser/排名fixture及10020原输入对照；RVA/offset未迁移 |
| 计数/卡片/取消/返回位置 | 旧多wrapper/关联状态 | count/rows同快照；generation拒旧提交；最近类页面offset | Foundation/ASan通过；实际设备滚动未验证 |
| 详情/翻译/字段复制 | P4词典与P5字段 | 单NMMethodPresentation；复制原值 | 12000翻译对照及字段fixture通过；不伪造native地址 |
| Swizzle | 多层内部装饰器与必要外部诊断混杂 | UI直接调用；唯一NMSwizzleManager owner/token | test-swizzle真实ObjC Runtime：签名/原IMP/重复/继承/冲突/并发/恢复；外部诊断未接入 |
| Runtime执行/实例 | M47分支绕过ordinal与显式receiver已复现 | request/coordinator/receiver lease唯一契约基础 | test-execution基础通过；真实IL2CPP adapter暂缓，不能执行游戏 |
| Native Capture/Hook | 旧timer跨session与teardown风险 | NMCaptureSession token/ack隔离 | 捕获状态fixture通过；Native后端与ABI桥暂缓 |
| 配置/Manifest | 旧authoring与全局store | NMConfigurationDocument/Store→不可变Manifest | test-configuration/manifest、10000身份对照；UI导入/保存/无效输入已在Simulator执行 |
| Static地址/规划 | 原V3公式与同起点合并 | NMMachOAddress→NMStaticPatchPlan冻结字节/冲突检查 | 16384地址对照、2000合成结果及边界fixture通过 |
| ARM64 relocate/dispatch | 原V3 fragment/thunk | NMARM64Relocation→NMStaticCodePayload，保留ABI | 原定义域24000对照、真实ARM64 OFF/ON/1000恢复通过；indirect安全不作扩大解释 |
| 数值类型 | MOVZ/MOVK/FMOV及RW cell | NMStaticValues单解码；每逻辑numeric独立cell | 六类型真实ARM64执行、512 FP即时数及独立性通过；API19 typed输入与边界在真实ARM64通过 |
| 文件生成/签名 | Static Builder/Signer | NMOfflineBuildRequest冻结输入→owned段→新目录→签名→报告 | test-static-image/offline-build、Mach-O/dyld_info/codesign；不覆盖原文件 |
| 加载后控制 | 原SharedSite恢复逻辑 | NMStaticRuntime pin→physical owner-stack→CAS RW | API19 test-static-runtime真实ARM64通过；不支持强制卸载 |
| 开发端UI | 历史大类与Swizzle装饰器 | 查找/配置/构建/功能/状态，各自明确数据入口 | 既有Simulator配置/构建/键盘/触摸通过；新功能页实际执行fixture待最新CI |
| 混合构建/Prepared Native | 原Static/Runtime/Native管线 | 离线模型保留，真实ABI provider未接入 | 暂缓相关ABI部分；不能声称混合运行完成 |

运行命令以.github/workflows/audit.yml为唯一CI执行清单，报告记录被编译HEAD。文档提交不改变旧产物source_head。设备行为一律未验证，直到有真实设备结果。
