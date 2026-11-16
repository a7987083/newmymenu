# newmymenu

独立 iOS ARM64 开发端重构工程。原仓库 `a7987083/mymenu` 保持只读；固定审计基线为 `feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`，其他分支与关键差异见源码库存。

目前已有独立源码、构建、测试、Actions和自包含开发端 dylib。**完整项目尚未验收，游戏ABI执行适配按用户要求暂缓，iOS实机未验证。** API21源码 `e797351d23fd9166f6653255c7d615fbfdbf7c31` 已通过[五个CI Job](https://github.com/a7987083/newmymenu/actions/runs/43779727851)；Static原生与Simulator实际加载/控制已验证，设备仍未验证。

开发端包含查找、配置、构建、功能、状态五页。Finder使用同一不可变快照计数与渲染，支持类/方法/限定表达式、翻译和原字段复制；配置离线校验/导入导出/保存；Static构建冻结输入并校验地址、原字节与重叠，写新文件、生成owned RX/RW段并签名；功能页只操作已加载预埋Static，不调用游戏Runtime或Native ABI。

- [当前交接与精确构建来源](HANDOFF.md)、[机器状态](PROJECT_STATE.json)、[剩余任务](ROADMAP.md)、[真实限制](KNOWN_ISSUES.md)
- [原53项功能库存（审计时点）](docs/audit/FEATURES.md)、[分支/源码hash](docs/audit/source-inventory.json)、[Swizzle专项](docs/audit/SWIZZLE.md)
- [架构](docs/ARCHITECTURE.md)、[当前回归矩阵](docs/REGRESSION.md)、[方法搜索](docs/METHOD_FINDER.md)
- [配置](docs/CONFIGURATION.md)、[Static构建](docs/STATIC_PATCH.md)、[加载后控制](docs/STATIC_RUNTIME.md)、[Swizzle契约](docs/SWIZZLE_MANAGER.md)

Linux运行`make test-portable`。macOS使用固定Xcode16.4/Build16F6、iOS SDK18.5、deployment14.0：

```sh
export DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer
make core
make developer-menu
```

产物分别是`build/core/NewMyMenuCore.dylib`和`build/developer-menu/NewMyMenuDeveloper.dylib`。开发端自包含，只注入后者，不需要再注入Core。完整CI命令见`.github/workflows/audit.yml`；macOS真实Objective-C Runtime与ARM64原生fixture、iOS18.5 Simulator各自记录，均不能替代实机验证。签名为ad-hoc，不是完整IPA身份/权限签名。

历史DeviceProbe、审计fixture和Foundation-only artifact均不是最终开发端交付。当前整合候选已完成适用CI与下载哈希核对；交付来源见HANDOFF.md，实机验收见docs/DEVICE_ACCEPTANCE.md。
