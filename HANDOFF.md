# 当前接手入口：API19 prepared Static Runtime

当前精确HEAD执行`git rev-parse HEAD`。API19核心8bb60d21已通过Run43770082803/foundation-core（59导出、22分析零诊断、真实ARM64 Runtime及既有回归）。Developer/Simulator仍进行中；上次五Job全通过仍为17878f28 / Run43689802080。完整报告docs/builds/static-runtime-8bb60d21.json。

新增实现：include/NMStaticRuntime.h、src/Build/NMStaticRuntime.mm，契约和边界见docs/STATIC_RUNTIME.md。独立Static控件Renderer为src/DeveloperUI/NMStaticControlsView.m，主菜单现有查找/配置/构建/功能/状态五页。

验证命令：`make test-static-image`后`make test-static-runtime`；macOS ARM64实际动态加载fixture覆盖owner栈、U64/F32/F64、Slider、元数据/外部冲突及并发。`scripts/test_ui_simulator.sh`新增真正Simulator平台dylib预埋/签名/加载和UI控制断言。原Core平台iOS镜像仍只作为离线构建输入，不加载进Simulator。

失败记录：Run43768726795 iOS SDK拒绝mach_vm.h，改用公开vm_read_overwrite/vm_region_64；Run43769003422 fixture传NULL给要求双输出的NMMachOResolveRange，修正调用，未放宽API检查。最新CI需重新查Actions。Linux17项Python+codec通过；本机LSan受ptrace阻断，普通数值C测试通过，不能声称本机ASan完整通过。

本地环境已恢复；HTTPS git push没有凭据，使用GitHub连接器create_tree/create_commit/update_ref(expected_sha)发布，然后git fetch/rebase同步；勿在源码或日志写token。原mymenu仍只读。

额外失败：43769306253/43769727679绑定Image is not loaded，最终修正相对/绝对路径canonicalization后核心通过；fixture从真实nm读取符号，不预加载原图像。Simulator子进程与失败截图增加有界等待，确保异常能抵达Artifact收集。

下一任务：先处理Simulator首错直至实际运行通过；检查截图、整合文档/回归矩阵，做最终技术债复审。游戏ABI执行适配继续暂缓；设备未验证。用户要求不发中间dylib，只交最终整合候选，不能把CI成功当实机成功。

---
以下为之前的交接基线，冲突时以上述新入口和真实Git/CI为准。

# newmymenu 当前交接

当前以 `git rev-parse HEAD` 或 GitHub main ref 为准，文档提交不是二进制 source_head。原 a7987083/mymenu 仅只读，固定基线 `7066edeaf9e47580c89440be670c517280534b69`；分支和审计证据见 docs/audit。

## 当前事实与继续方式

- 最后完整成功：`546fb05b5b3998a27b87e7d453e8a27739b01e2c` / Run43686304743，五job通过。Developer Artifact14150603385，SHA256 `20bee9cfa33e549cce807bc50460d471ab054ed909375ea929368d151f10de12`。已下载核对ZIP/dylib/Mach-O；Simulator result.json实际通过配置、picker读取、预览/签名生成、keyboard focus/Done、触摸穿透。物理设备未验证。窗口截图发现选中项对比度与拍摄时机问题，后续源码已修正，系统截图等待重跑。
- API18 数值cell/catalog源码已在main，尚不能标实际执行通过。Run43687721904先暴露collector强NSError输出转传autoreleasing参数；4dadd345修正为局部NSError后又被Analyzer要求输出指针空值保护。最新修正保持Analyzer不变。
- Run43688515706的Simulator已走到系统build截图；simctl截图实际约23秒，fixture仅给15秒I/O确认导致超时。最新单独限制截图CLI为60秒，App确认等90秒；业务UI等待/断言未删改，不以放宽产品检查掩盖问题。
- 本地执行环境已断开。此后通过GitHub connector编辑和macOS CI持续推进。旧本地工作树曾存在未提交NMStaticRuntime草稿及一次执行结果不确定的修改，不视为已提交或可用；恢复本地后先保留该工作树，再用独立checkout跟随main，禁止盲目reset覆盖草稿。

## 已完成且有实际证据的模块

- 单一MethodFinder状态/Renderer、关键词与表达式/排名/取消/滚动、字段复制和原词典；真实IL2CPP元数据仍只有受控API fixture，游戏设备未验证。
- InvocationRequest/ReceiverLease/Coordinator、CaptureSession状态组件；真实游戏Invoke/GCHandle/Dobby关闭适配暂缓。
- SwizzleManager合作式调度/原IMP与代码镜像所有权、冲突/继承/恢复，真实ObjC Runtime fixture；样本专用SharedSite外部诊断不自动安装，见SWIZZLE_MANAGER和NATIVE_BOUNDARIES。
- NMConfigurationDocument/Store离线Runtime/Native描述、原子revision提交，10000原身份对照；NMPatchImport严格候选与review来源。
- NMMachOAddress及单一ARM64 relocation模块：16384映射、23997独立目标检查、24000原函数对照、旧负数左移UBSan复现。
- NMStaticPatchPlan逻辑→物理聚合/原字节/冲突/direct branch；2000原合成对照。
- NMStaticCodePayload复用V3 fragment/thunk；宿主ARM64 OFF=7/shared ON=42/99及1000切换通过。
- NMStaticBinaryImage独占RX/RW segment、chained-start重建；实际iOS ARM64输出经签名、codesign和dyld_info验证。实际macOS prepared dylib也经dyld加载，OFF/ON执行/恢复/卸载通过。
- NMOfflineBuildRequest人工review、target匹配、取消、新目录独占发布、内部签名、报告、中文安全截断和不覆盖通过。
- 唯一DeveloperMenu已替代旧Probe：四页查找/配置/构建/状态，项目保存/恢复、系统文件选择、预览、后台生成和导出。来源清单 scripts/source_lists.sh 驱动Core/UI/Simulator和分析，17个portable测试含实现完整性。

## 当前关键源码

`src/Build/NMStaticCodePayload.mm`：numeric同源逻辑分离ON代码/cell，普通byte变体仍去重；requirements统一预算。完整名称/分组复用NMBuildManifest catalog，保留GeneratedData V1描述表/零ActionHeader，不占reserved。API18该路径尚待当前CI真正跑到执行fixture。

`src/DeveloperUI/NMDeveloperMenu.m`：唯一overlay，普通Delegate和window三指long-press+上下滑呼出；不Swizzle。键盘Done/编辑区适配、代次拒绝旧完成、自己展示modal时让位；实际三指/旋转/多scene需设备测试。

## 构建与测试

固定Xcode16.4/16F6、SDK18.5、iOS14.0，不任意升级。make core；make developer-menu。CI audit.yml 五job，Simulator脚本 tests/ui/main.m + scripts/test_ui_simulator.sh，物理设备状态独立记录。

核心命令见Makefile：test-portable；test-swizzle；test-configuration / test-configuration-parity；test-patch-import；test-static-plan / test-static-variant-parity；test-arm64-relocation / test-relocation-parity；test-static-values；test-static-image；test-offline-build；test-static-loaded-image；test-static-numeric。原源对照需要 SOURCE_BASELINE 指向固定原checkout。host fixtures不能等价iOS设备。

## 下一任务

1. 获取新CI第一处真实错误，先完成API18六类型cell隔离/RW更新/OFF恢复与系统截图复核；不关闭检查。
2. 实现受强镜像pin保护的loaded Static runtime：完整Manifest名称分组、per physical owner stack、last enabled wins/restore prior owner、foreign target CAS冲突、typed cell输入、页面控制。未提交草稿不能直接宣称已迁移。
3. 保留所有不依赖游戏ABI的功能继续回归，处理运行时控制UI、配置/混合build差异与技术债，更新状态/矩阵/交接。
4. 游戏ABI按用户要求暂缓；不得因此停掉独立工作，也不得假设MethodInfo/GCHandle/Native签名。最后才交付整合dylib，不发送阶段二进制。

旧API1–16机器报告保留在docs/builds，不能把其source_head混作当前已编译HEAD。所有历史Commit不改写，原仓库不修改。
