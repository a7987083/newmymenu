# newmymenu

独立 iOS ARM64 开发端重构工程，目前处于源码审计阶段，**尚未实现原开发端功能对等，也没有最终菜单 dylib**。

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
