# 已知限制与未验证项

- 游戏ABI执行暂缓：实例枚举、实际Invoke/ByRef、Native Hook和Prepared桥接、三域混合未接入验收。离线配置与执行协议测试不代表游戏功能可用。
- iOS实机未验证。Simulator仅程序化UIKit fixture；实际复制点击、键盘逐字输入、三指/拖动、旋转、前后台和多窗口仍待验收。
- 仅支持新格式owned Static预埋；拒绝旧__ZN和早期API18/19目录，不能叠加旧预埋。无已加载匹配镜像时功能页为空是明确状态。
- Mach-O修改受header slack、load-command白名单、地址/原字节/迁移范围约束；不保证未知间接/跨镜像引用可迁移。拒绝不支持输入，不绕过校验。
- ad-hoc签名不替代完整IPA签名/权限；AMFI共享写映射发布根因已修复并通过Simulator加载，但各种真实宿主环境未验证。
- Swizzle仅能管理协作域；不能承诺未知外部dylib任意交换后的安全恢复。Static进程期pin不支持任意卸载；不承诺外部remap/mprotect、ABA或跨多site全局线性事务。
- JSON重复键的词法层检测、大镜像设备内存/性能、不同macOS runner间逐位可复现仍有限制，不能宣称零技术债。
