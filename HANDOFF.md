# newmymenu 当前交接

## 仓库与基线

新仓库 https://github.com/a7987083/newmymenu ，main。当前工作树精确HEAD用`git rev-parse HEAD`；构建报告记录真实被编译代码HEAD，文档更新不能自称重新构建。
源仓库 https://github.com/a7987083/mymenu 只读，未修改远程或历史。
固定候选 `feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`；main7216b55，customer92d675e。所有远程分支SHA与源文件hash在docs/audit/source-inventory.json。

## 当前最新状态：API2

最新被验证代码`ae7f607d2f938bcc29ac545dffcfd09bb15c5292`，Run43643448325四job通过，Artifact14133306387。基础版f385c8a结果作为历史保留，不是最新core。
新增include/NMReceiverLease.h、NMInvocationCoordinator.h、NMCaptureSession.h，对应src/Execution/*.m、src/NativeHook/NMCaptureSession.m。设计见0002，实际语义/测试/限制见EXECUTION_CORE.md，报告docs/builds/execution-ae7f607.json。
`make test-execution`实际运行统一receiver、1000并发、真实对象lease、token/ack session、close失败/retry与资源/manager释放。core API版本2，ARM64签名/依赖/15导出全部通过，6个分析报告无diagnostics。
真实IL2CPP/Dobby/旧UI未接入，完整产品及设备未验证。下一任务是版本明确的managed adapter和显式线程/GCHandle/封送，不能将managed指针强转id或重新引入TLS分流；Native safe-close必须有后端证据。

## 首批基础实现范围与历史证据

已经迁移：

- include/NMMethodTranslator.h、src/MethodFinder/NMMethodTranslator.mm：沿用原翻译算法，只调整公开NM命名空间/路径；一个实现，没有ZN兼容别名。私有词典由tools/generate_dictionary.py从3000词条JSON确定生成，许可在resources。
- include/NMRuntimeActionFormat.h：原wire magic/version/64-byte layout；src/Configuration/NMRuntimeActionCodec.c提供唯一checked ordinal编解码，0自动/1..128序号，不是稳定对象身份，拒绝无效flag组合。
- src/NMCore.c：基础API版本2，没有自动初始化、UI或Hook。

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
