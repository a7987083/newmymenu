# newmymenu

独立 iOS ARM64 开发端重构工程，目前处于源码审计、基础模块及只读 Runtime/UI 验证阶段，**尚未实现原开发端功能对等，也没有最终菜单 dylib**。

原仓库保持只读。候选开发端：`a7987083/mymenu feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`。

- [基线与证据边界](docs/audit/BASELINE.md)
- [53项功能清单](docs/audit/FEATURES.md)
- [关键发现](docs/audit/FINDINGS.md)
- [Invoke实际所有权与接收器复现](docs/audit/INVOKE_OWNERSHIP.md)
- [Capture生命周期复现](docs/audit/CAPTURE_LIFECYCLE.md)
- [Build有效入口边界](docs/audit/BUILD_BOUNDARIES.md)
- [Swizzle安装索引与边界](docs/audit/SWIZZLE.md)
- [实际CI实验报告](docs/audit/CI_EVIDENCE.md)
- [架构草案](docs/ARCHITECTURE.md)
- [机器可读源码库存](docs/audit/source-inventory.json)
- [交接](HANDOFF.md)

本机审计测试：`python3 -m unittest discover -s tests -v`。
重建源码库存：固定源仓库 checkout 后运行 `python3 tools/source_audit.py /path/to/mymenu --output docs/audit/source-inventory.json`。

Actions 的 macOS job 用真实 Objective-C Runtime 运行独立实验，然后以 Xcode16.4/iOS18.5 编译并签名 ARM64 **审计夹具**。该 dylib 不是菜单，不能作为功能产品注入测试。实验不会验证目标游戏 IL2CPP 或 UIKit 行为。

首批实现：`NMMethodTranslator`（离线翻译）与`NMRuntimeActionFormat/Codec`（原wire布局及checked ordinal codec）。独立构建：`make core`；本地可移植测试：`make test-portable`；macOS Foundation测试：`make test-macos`。与固定源比对：`make test-parity SOURCE_BASELINE=/path/to/mymenu`。

`NewMyMenuCore.dylib`仅为基础模块库，没有菜单、搜索、真实IL2CPP Invoke、Native Hook或生成业务入口，不能替代旧开发端。模块设计与迁移边界见[0001](docs/decisions/0001-foundation-migration.md)。

首批核心代码`f385c8a`已通过[CI](https://github.com/a7987083/newmymenu/actions/runs/43638969924)，构建报告见[foundation-f385c8a.json](docs/builds/foundation-f385c8a.json)。[核心库Artifact](https://github.com/a7987083/newmymenu/actions/runs/43638969924/artifacts/14130499746)仅含基础模块，不是完整开发端。

API2已新增[显式调用与Capture生命周期组件](docs/audit/EXECUTION_CORE.md)：统一receiver scope、immutable request和token/ack会话。代码`ae7f607`已通过[CI](https://github.com/a7987083/newmymenu/actions/runs/43643448325)；[API2核心Artifact](https://github.com/a7987083/newmymenu/actions/runs/43643448325/artifacts/14133306387)仍不包含菜单或真实IL2CPP/Dobby adapter。


当前可实测的是 **只读 DeviceProbe**，不是完整开发端：类搜索、类内方法签名和报告导出。源码 `4d9231c7` 已通过 [五个CI job](https://github.com/a7987083/newmymenu/actions/runs/43647531696)，[下载Artifact](https://github.com/a7987083/newmymenu/actions/runs/43647531696/artifacts/14133719131)，[设备测试说明](docs/DEVICE_VALIDATION.md)，[机器构建报告](docs/builds/device-probe-4d9231c7.json)。真实游戏/设备行为未验证。
