# newmymenu 当前交接

## 仓库与基线

新仓库 https://github.com/a7987083/newmymenu ，main。当前工作树精确HEAD用`git rev-parse HEAD`；构建报告记录真实被编译代码HEAD，文档更新不能自称重新构建。
源仓库 https://github.com/a7987083/mymenu 只读，未修改远程或历史。
固定候选 `feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`；main7216b55，customer92d675e。所有远程分支SHA与源文件hash在docs/audit/source-inventory.json。

## 当前最新：Finder单一页面状态与滚动恢复

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
