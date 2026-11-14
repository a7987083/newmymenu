# newmymenu 当前交接

## 仓库与基线

新仓库 https://github.com/a7987083/newmymenu ，main。当前工作树精确HEAD用`git rev-parse HEAD`；构建报告记录真实被编译代码HEAD，文档更新不能自称重新构建。
源仓库 https://github.com/a7987083/mymenu 只读，未修改远程或历史。
固定候选 `feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`；main7216b55，customer92d675e。所有远程分支SHA与源文件hash在docs/audit/source-inventory.json。

## 当前最新：ABI独立组件 API8

已验证代码`1aab363abda06d2d3de61dbf3fd468d258b69bf8`，Run [43654350053](https://github.com/a7987083/newmymenu/actions/runs/43654350053)五job通过。Core Artifact14137721557；SHA256 `49dc035cf803b25e050e15cb014cfa8375a19ec54fe587c0a756c21bec7f8f08`。下载ZIP/hash/Mach-O/10份core分析报告已复核。报告docs/builds/abi-independent-1aab363a.json；历史d21ab48记录保留。集成清理仅移除已由生产core承担的重复signer对象/分析步骤，必要检查全部保留。

用户范围：游戏ABI暂缓，不再阻塞独立组件；完成最终整合前不发送阶段dylib。

- API6：Discovery4个公开查询入口增加NSProgress参数（不保留旧selector备用实现）；进入VM前、扫描、参数类型复制和发布前取消检查；finally清理owned线程/typename。NMFinderSession持有busy/generation；用户取消立即使旧completion失效，新请求清空旧snapshot。受控取消与Foundation状态fixture通过，UIKit实机未验证。
- API7：include/NMBuildManifest.h、src/Build/NMBuildManifest.m。不可变Item/provider/Manifest，单一冻结configuration，collector异常/nil/error/重复/foreign ownership都明确失败；Manifest-only JSON严格往返。见docs/MANIFEST.md。原authoring/Patch兼容导入与生产prepare/emit尚未完成。
- API8：include/NMMachOSigner.h、src/Build/NMMachOSigner.mm。复用原页哈希/CodeDirectory/SuperBlob，自包含副本签名、失败清理、禁止覆盖。独立codesign暴露并修复原flags=0及不可能满足的证书designated requirement；改为ad-hoc/cdhash身份。真实ARM64输入上严格验证通过；拒绝现存entitlements，保护不支持的权限保留，包级重签仍必须。见docs/SIGNER.md。
- 命令：make test-manifest；make core；make test-signer（后者需已构建core，macOS ASan驱动使用真实ARM64文件，签名负例是真实MH_EXECUTE且先断言XML/DER slots存在）。固定Xcode16.4/SDK18.5不变。

仍未完成SwizzleManager、完整配置/Static/Runtime/Native业务闭包和最终UI。ObjC Runtime fixture不需要游戏ABI，可继续；需要目标布局的managed/Native部分明确暂缓。不能把本次核心库构建当完整开发端或实机验收。

## API5命名表达式与类排名（历史）

编译代码 `09cae3ce4a5e05c58bb973faed1151d5f421c186`，Run43650787572五job通过。Core/Probe机器报告见docs/builds/*-09cae3ce.json。用户要求不再分发阶段dylib，本轮未进行中间交付。

- 私有src/MethodFinder/NMNamedExpression.m复用固定原纯解析算法；tools/generate_parser_parity.py仅从hash确认的原源提取parser用于测试，10020输入结果/错误对照通过ASan。
- Discovery.searchMethodExpression经唯一scan循环落实assembly/namespace/class/exact method/arity；非零delta在进入VM前拒绝，等待地址resolver。
- 类搜索候选池复用原exact/prefix/suffix/contains排名，修复达到limit后漏掉后续exact的问题；新增limit=1晚到exact回归通过。namespace/type附加contains是明确的扩展，不冒充原name-only语义。
- 8份core/3份Probe分析零diagnostics，既有元数据/Finder/字段/执行/capture和原实现翻译12000、wire129回归通过；ARM64/签名/依赖/导出/hash通过。实机未验证。
- 高风险接入需要真实Runtime证据：旧MethodInfo前两字fallback及GCHandle宽度声明不能仅凭源码认定适用于目标。详见docs/ABI_EVIDENCE_GATE.md。现有材料只有旧Probe面板照片，无目标镜像/报告。

## API4方法关键词搜索、详情与翻译（历史）

编译代码 `3115e2b3638eb044c73761cd9cfef0428a52fa5e`，Run [43649811591](https://github.com/a7987083/newmymenu/actions/runs/43649811591) 五job通过。Probe [Artifact14135153726](https://github.com/a7987083/newmymenu/actions/runs/43649811591/artifacts/14135153726)，SHA256 `c8175ac64f294707aed12b89ba41aa5eb488c343f3a6d28fb56156b5beb06d6b`；Core Artifact14135965621，SHA256 `a69cffbf85b4fb08e89061df3e642afa084372439229b1f76af4ecadb614b5db`。报告docs/builds/*-3115e2b3.json。文档HEAD前进不改变二进制来源。

- Discovery增加searchMethods公开方法，Core API4；类/方法关键词共用scanQuery，类展开/全局方法共用NMDLCopyMethod复制类型/static/owner。没有新增Runtime绑定/签名解析副本。
- Probe Class/Method→同runQuery/同state/同table renderer。`src/MethodFinder/NMMethodPresentation.m`统一字段和subtitle，复用已验证Translator。Class原短名、Type完整类型，复制value不带label/格式/替换翻译。
- `make test-discovery test-finder test-presentation`：macOS ASan fixture通过，含全局method contains/limit/no match/owner和字段/ByRef/翻译；原wire129/翻译12000回归继续通过。7份core+3份Probe分析零diagnostics。ZIP/二进制hash和Mach-O已下载复核；签名在macOS CI验证。
- 实机状态：仅旧4d9231c7照片证实面板显示。当前版本Runtime/搜索/字段复制/键盘/生命周期均未验证。
- 原表达式/参数个数/RVA/排名不由本关键词版替代，差异矩阵与下一步见docs/METHOD_FINDER.md。成熟Resolver/parser优先评估复用；仍没有Invoke/Hook/Build业务入口，不能称完整开发端验收。

## Finder单一页面状态与滚动恢复（历史）

最新编译代码 `05840d7bde3183615e6d0866f3d4996915f928c6`，Run [43649083590](https://github.com/a7987083/newmymenu/actions/runs/43649083590) 五job通过。Artifact [14134789796](https://github.com/a7987083/newmymenu/actions/runs/43649083590/artifacts/14134789796)，SHA256 `b2699b16de7a83cb2fa6a7f8cb451b92861ccc7f74fc479c718b7e7c7bb7a370`。报告 `docs/builds/finder-05840d7b.json`。文档HEAD前进不改变二进制来源。

`src/MethodFinder/NMFinderSession.{h,m}` 是Probe私有Foundation页面状态，所有读写在主线程；rows/count/mode来自同一冻结snapshot。请求开始生成generation；worker只负责Runtime读取；主线程提交时拒绝旧generation。进入类保存offset，方法页面返回直接恢复class snapshot/report/offset；新搜索或Runtime刷新清除缓存。UI不再保留独立_rows/_snapshot/_methodMode/generation副本。缓存只保留最近类页面，非无界索引。

`make test-finder` 在macOS ASan实际运行：深层不可变快照、旧completion拒绝、返回位置/报告、失败后返回、零结果、count/rows不一致拒绝与刷新失效全部通过。Probe新增state和UI两份分析报告零diagnostics；原7份core分析及既有回归继续通过。Core API仍为3，无公开ABI变化，state只链接进Probe。

用户4d9231c7照片仅确认旧Probe面板显示。最新05840d7b及真实Runtime/搜索/键盘/旋转等仍未实机验证。重点测试：向下滚动类列表→打开类→返回，应保持位置且不重新扫描；随后搜索另一关键词/刷新Runtime不得复用旧结果。仍为只读验证版，完整视觉设计、全局Method搜索、翻译UI、Invoke/Hook/Build未完成。

## API3首轮只读 DeviceProbe（历史）

最新编译代码 `4d9231c7e7cc428a8c8947230970d37631c05afa`，Run [43647531696](https://github.com/a7987083/newmymenu/actions/runs/43647531696) 五个 job 全部通过。文档提交之后 HEAD 会前进，二进制 source_head 保持此代码提交。

- 自包含 DeviceProbe Artifact [14133719131](https://github.com/a7987083/newmymenu/actions/runs/43647531696/artifacts/14133719131)，SHA256 `3b0ce6555c45360072257a1c701503fab9dfa9abcd6a7d0d1eb3a0709f93b3bc`。只注入此一个 probe，不另加 Core。build report: `docs/builds/device-probe-4d9231c7.json`。
- Core API3 Artifact14134279302；SHA256 `da325b58e77890322febbe133805d6f0a1ddfb310a94c95c2339b838845b7048`；report `docs/builds/foundation-core-4d9231c7.json`。API3新增NMIL2CPPDiscovery，原wire布局与执行组件契约未改。
- 7份core和1份UI分析报告零diagnostics；增加显式plist gate，不能只靠clang --analyze退出码。实际下载重新核对ZIP/dylib哈希、Mach-O和分析报告；签名验证发生在macOS CI。
- RuntimeDiscovery: `src/RuntimeDiscovery/NMIL2CPPDiscovery.m`、私有API表，公开 `include/NMIL2CPPDiscovery.h`。loadedRuntimeCapabilities→同镜像绑定→withMetadata线程scope→类快照→完整identity重定位→方法值快照。无原生Class/Method指针跨操作缓存。
- `src/DeviceProbe/NMDeviceProbe.m`：constructor仅dispatch主线程host；foreground window/delegate window→透明overlay→唯一table renderer；serial worker结果用generation校验。没有Swizzle/Hook/managed invoke安装。
- `make test-discovery` 已在macOS ASan实际运行，覆盖搜索/签名、线程/分配释放、异常、歧义、Domain变化与stale descriptor。真实目标IL2CPP ABI/导出与UIKit运行仍未验证，步骤见 [DEVICE_VALIDATION](docs/DEVICE_VALIDATION.md)。
- 修复证据：Run43647225475在歧义错误路径objc_retain崩溃；内部NSError**隐式autoreleasing在内层pool后writeback。私有通道改NSError* __strong*后ASan原用例通过。公有NSError**契约不变。

完整开发端尚未完成；Probe不包含Invoke/GCHandle、Native Hook/恢复、Build、完整MethodFinder状态/缓存/翻译UI。不能用Probe成功宣称功能对等。等待设备元数据/交互报告后，先确认目标API/生命周期，再接managed adapter；不猜GCHandle宽度/布局。

## API2执行组件的首次通过记录（历史）

最新被验证代码`ae7f607d2f938bcc29ac545dffcfd09bb15c5292`，Run43643448325四job通过，Artifact14133306387。基础版f385c8a结果作为历史保留，不是最新core。
新增include/NMReceiverLease.h、NMInvocationCoordinator.h、NMCaptureSession.h，对应src/Execution/*.m、src/NativeHook/NMCaptureSession.m。设计见0002，实际语义/测试/限制见EXECUTION_CORE.md，报告docs/builds/execution-ae7f607.json。
`make test-execution`实际运行统一receiver、1000并发、真实对象lease、token/ack session、close失败/retry与资源/manager释放。core API版本2，ARM64签名/依赖/15导出全部通过，6个分析报告无diagnostics。
真实IL2CPP/Dobby/旧UI未接入，完整产品及设备未验证。下一任务是版本明确的managed adapter和显式线程/GCHandle/封送，不能将managed指针强转id或重新引入TLS分流；Native safe-close必须有后端证据。

## 首批基础实现范围与历史证据

已经迁移：

- include/NMMethodTranslator.h、src/MethodFinder/NMMethodTranslator.mm：沿用原翻译算法，只调整公开NM命名空间/路径；一个实现，没有ZN兼容别名。私有词典由tools/generate_dictionary.py从3000词条JSON确定生成，许可在resources。
- include/NMRuntimeActionFormat.h：原wire magic/version/64-byte layout；src/Configuration/NMRuntimeActionCodec.c提供唯一checked ordinal编解码，0自动/1..128序号，不是稳定对象身份，拒绝无效flag组合。
- src/NMCore.c：当前API版本3，没有自动初始化、UI或Hook。

设计先于迁移记录在docs/decisions/0001-foundation-migration.md。首批库完全不依赖原仓库、Theos、Dobby或旧UI；固定原仓库checkout只用于审计与回归test。

尚未集成：菜单、搜索Renderer、真实IL2CPP Invoke/Receiver/Chain与Native Capture/Hook adapter、Static/Runtime生成业务。不能拿NewMyMenuCore.dylib替换旧开发端。

## 构建/测试/实际CI

Linux：`make test-portable`；macOS：`make test-macos`；原实现回归：`make test-parity SOURCE_BASELINE=/path/to/mymenu`；ARM64：固定Xcode16.4/Build16F6，`DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer make core`。SDK必须18.5，deployment14.0。

被编译核心代码HEAD `f385c8a83b9fc41f6af5adcc89c19938f223f944`。
Run https://github.com/a7987083/newmymenu/actions/runs/43638969924 四job全部通过。
实际执行16项Python测试、C codec516组检查、Foundation翻译/1000并发、12000翻译原实现对照、129组wire字节对照、三个迁移源静态分析以及ARM64 core全部严格检查。
Artifact https://github.com/a7987083/newmymenu/actions/runs/43638969924/artifacts/14130499746 。
SHA256 c5047fa72ce5de73c8af5ede0b0bc00d354e95c8526f8932c5716ca670f9baee。
详细导出/依赖/签名与ZIP hash见docs/builds/foundation-f385c8a.json；实际下载后核对了bytes/hash/Mach-O/分析plist。签名验证发生在macOS CI，不是在Linux本机。
完整产品编译/运行/回归和iOS设备均未验证。

## 已证实的问题与关键调用链

- 搜索输入→HybridFinder→ClassResults，与方法candidates是不同状态。历史最终Renderer漏Class分流，7216b55已在最终入口修复；不能泛化为所有Swizzle引起空白。
- Invoke预期安装链M52→M50→M48→M47；/0普通/1再进M46/基础入口，/2-/8与typed/1 ByRef在M47独立invoke，绕过ordinal和explicit receiver。固定源真实ObjC交换+受控IL2CPP边界已复现，生产未修复。
- ReceiverCapture旧timeout不带session身份，A完成后B的15秒任务约0.543秒被A旧timer结束，真实dispatch已复现；Dobby是受控替身。
- M462的GCHandle读取/释放范围缺少调用租约；DobbyDestroy没有排空在途调用。真实对象/设备影响未复现。
- SharedSite确实Hook外部MdhpNuX及镜像扫描出的metaclass API，且含样本专用RVA；不能全部当内部UI装饰器删除。见NATIVE_BOUNDARIES.md。
- 当前UI生成直接进C BuildExecutor，不经过旧class-method Builder Swizzle。provider collector吞异常和跨阶段store快照限制尚待业务fixture，见BUILD_BOUNDARIES.md。
- 更正：开发端InstanceSelectionV2本身已有唯一实例auto-bind，不因customer有额外wrapper就认定开发端缺功能。

完整证据在INVOKE_OWNERSHIP、CAPTURE_LIFECYCLE、FINDINGS和CI_EVIDENCE。审计fixture编译结果不能等价真实IL2CPP/游戏/设备行为。

## 下一任务与禁止事项

按ROADMAP先完成Invoke/Receiver闭包，落实InvocationRequest/ReceiverLease/CaptureSession，然后迁移搜索/UI和Native/Build。不得一口气复制ZNUnifiedUI后补丁修复；不得靠丢弃ByRef/混合Build/必要外部诊断来宣称清债；不得将基础core当完整开发端交付。
