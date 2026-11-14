# 只读实机验证：DeviceProbe

此版本是独立 ARM64 dylib，内含 Core API3、IL2CPP 元数据后端和最小验证界面。不是完整开发端，也不调用 managed 方法、GCHandle、Dobby 或修改游戏资源。不要额外注入 NewMyMenuCore.dylib；此文件已经自包含。

## 本轮操作

1. 按你现有的 dylib 注入/重签方式装入一个 Unity IL2CPP 游戏，进入游戏主界面。寻找右上方 `NM 验证` 浮动按钮，点开面板。首次加载、真正 UI 行为尚需设备验证。
2. 点 `检查 Runtime`。若提示 Runtime 未加载，进入玩法后重试；缺少导出时不要改为猜偏移调用，导出错误报告即可。
3. 搜索你在旧 Method Finder 使用的同一类名关键词（例如 `Cheat`，再试 `Player`）。确认状态条数量与可滚动类列表一致，点一个类查看方法及参数/返回类型。点方法复制名称或签名；这一步不执行方法。
4. 类列表向下滚动后点开一个类，再点 `‹ 类列表`，确认回到原位置且不重新扫描。搜索另一关键词或点检查Runtime后，应清除旧缓存。然后测试输入键盘、滚动、拖动按钮/标题栏、收起后的游戏点击、切后台再回来，以及游戏允许的横竖屏。面板跟随宿主窗口，不强行旋转游戏。
5. 在类搜索结果、方法结果或错误出现后分别 `导出报告` 保存 JSON 并回传。也可 `复制报告` 粘贴。报告只保留最近一次操作，因此需要分别保存。附界面截图，说明宿主游戏版本与实际观察；没有按钮或闪退时附 crash log。

## 结果如何判定

| 检查 | 自动化证据范围 | 设备状态 |
|---|---|---|
| 导出绑定/类/方法元数据 | 受控原生 API fixture、静态分析 | 未验证 |
| 同 Runtime 的 typename/free、attach/detach 所有权 | 受控 fixture，含异常/失败 | 未验证 |
| 真实游戏中 Runtime ABI/导出可用 | 不能由 Mock 或 CI 证明 | 未验证 |
| 类数量与卡片、复制、键盘、触摸穿透 | 源码同一不可变 results 快照；UIKit 静态分析 | 未验证 |
| 前后台、旋转、旧式 delegate window、UIScene | 已实现 host 逻辑，未运行 UIKit | 未验证 |
| Invoke/多实例/ByRef、Hook/恢复、Build | Probe 不提供这些入口 | 尚未集成 |

扫描最多返回200项，类扫描有200000项/2秒边界；方法列表最多200项。达到边界会明确显示“扫描受限/结果未完整”，不能将有限扫描当全游戏完整索引。方法展开重新按 assembly/namespace/class/fullType 定位，歧义拒绝。报告包括宿主 bundle/version、系统、Runtime 镜像 UUID/导出、query/results/error 和构建版本；仅本地复制或系统分享，无网络上传。

## 接手验证

固定 Xcode16.4 / 16F6、iOS SDK18.5、最低iOS14.0：

```sh
make test-portable
make test-macos
make test-execution
make test-discovery
make test-finder
make device-probe
```

`test-discovery` 使用 AddressSanitizer 和受控 C 函数表，不等价真实 IL2CPP。`make device-probe` 先独立构建/验证 core，再构建自包含 UI dylib，严格检查 ARM64、安装名、SDK、部署目标、导出、动态依赖、签名与 SHA-256。

最新版本05840d7b；`test-finder`验证Foundation状态，不能证明UIKit实际滚动表现。4d9231c7用户照片仅记录面板显示。


## API4 / 3115e2b3新增验证

替换旧Probe，只注入新单文件。Class模式搜索已知类后检查展开与返回位置；Method模式输入已知方法的部分名字，检查每条结果的所属类、签名和翻译。点方法后分别复制Class、Type、Method、Return、Arg等字段，确认值没有标签/翻译混入原字段；空值不应出现复制入口。分别导出Class和Method结果JSON。此版输入是关键词，不支持旧Class::Method/参数个数/RVA语法；不要把语法查询无结果当Invoke失败。

macOS新增 `make test-presentation`。所有最新UI/剪贴板/真实Runtime行为仍需设备验证。
