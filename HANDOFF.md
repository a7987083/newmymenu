# 当前交接：API21，ABI独立范围整合交付

仓库 a7987083/newmymenu，分支 main。二进制源码 HEAD `e797351d23fd9166f6653255c7d615fbfdbf7c31`；之后文档提交不改变该来源。当前文档 HEAD 用 `git rev-parse HEAD` 查询。

原仓库保持只读，固定基线 feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69。原分支、源码hash、入口与Swizzle证据见 docs/audit；不得改写原历史。

## 已完成与证据

[CI Run43779727851](https://github.com/a7987083/newmymenu/actions/runs/43779727851) 五Job全部成功：source-audit、runtime-audit、invoke-contract-audit、foundation-core、developer-menu。Developer Artifact14187618734，iOS ARM64 MH_DYLIB，60导出，ad-hoc签名校验通过，仅系统动态依赖；SHA256 `842cfc16900c6bf568fc06225110887bdd17b8d29597259ecb855ebf5b78b1d9`。ZIP SHA256 `6dc059b729d0fc48a5af59e0b7b1e3e6dbcab9be8bb6b575e620beed68418126`。已下载重新核对ZIP、dylib和source_head；完整报告 docs/builds/developer-e797351d.json。

固定Xcode16.4/16F6、iOS SDK18.5、deployment14.0。开发端自包含，只注入 NewMyMenuDeveloper.dylib。历史DeviceProbe已删除，不额外注入Core或旧菜单。

## 架构与关键位置

- RuntimeDiscovery/NMIL2CPPDiscovery.m：只读公开导出元数据枚举；不猜MethodInfo私有布局。
- MethodFinder/NMFinderSession.m：单一不可变搜索快照、generation、缓存/滚动；NMMethodPresentation.m承担详情/原字段；UI只渲染。
- DeveloperUI/NMDeveloperMenu.m：五页、唯一presentOwnedController入口、按picker身份管理回调、前台generation取消旧任务。NMStaticControlsView.m：复用表格、草稿/反馈按stableID。
- Configuration：统一离线模型及导入导出；Patch review schema3，旧schema仅升级到同一模型。
- Build：OfflineBuildRequest冻结输入→地址/原字节/冲突计划→统一ARM64迁移与payload→owned RX/RW段→签名新文件。支持逐条Static控件和数值类型、说明及显式分组。
- NMStaticRuntime.mm：仅绑定已加载的新格式预埋镜像，校验文件/内存、独立RW数值、owner栈、CAS冲突检测、受控恢复和进程期pin。
- Swizzle/NMSwizzleManager.m：唯一协作域管理器，原IMP/签名/继承/重复/冲突与恢复检查。没有为UI状态增加Swizzle。执行协议与实际游戏适配严格分开。

## 构建与验证

Linux `make test-portable`。macOS设 DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer 后 `make core developer-menu`；完整原生/ASan/静态分析及独立Runtime fixture命令以 .github/workflows/audit.yml 为准。Simulator入口 scripts/test_ui_simulator.sh。

真实macOS Objective-C/ARM64 fixture与iOS18.5 Simulator已执行。Simulator实际预埋、签名、dlopen、Static控件、U64输入/溢出、4096行复用、Finder卡片/详情/滚动、不一致计数拒绝、模态/picker归属、配置、混合Static构建、focus/Done通知、触摸穿透通过。Simulator不是实机；实际键盘逐字输入、复制点击、旋转/手势/多窗口未做设备验收。

## 已修复首错与边界

签名后共享可写映射inode直接发布导致AMFI dlopen前终止（wpmapped:1），现保留成熟签名算法，将结果复制到从未写映射的新inode、只读验签后独占发布；实际Simulator加载已通过。保留失败记录，不放宽AMFI或跳过测试。

游戏ABI执行按用户要求暂缓：MethodInfo/GCHandle、游戏实例发现/调用、Native/Prepared Hook桥接与三域混合执行未验证。协议fixture通过不代表游戏调用通过。新Runtime拒绝旧__ZN与早期API18/19预埋目录，不叠加旧构建器。

## 接手任务

先按 docs/DEVICE_ACCEPTANCE.md 实机验收已交付范围，记录原始报告与设备信息。之后只有取得匹配二进制/只读报告及ABI证据才恢复游戏适配。53项逐项状态见 docs/audit/CURRENT_REGRESSION.md；原 features.json 是审计时点冻结数据。限制见 KNOWN_ISSUES.md，技术债复审 docs/TECH_DEBT_FINAL.md。
