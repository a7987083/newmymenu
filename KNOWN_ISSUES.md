# 当前真实限制

- 完整原开发端功能对等尚未验收。原53项库存描述固定审计时点；新实现和测试边界见docs/REGRESSION.md。禁止用基础库或审计fixture作为最终菜单交付。
- 游戏ABI按要求暂缓：IL2CPP MethodInfo布局、GCHandle宽度/线程/存活、ByRef/结构体、多实例及返回值封送没有目标版本证据；Native Hook/Prepared Hook的ABI桥和安全拆卸尚未接入。不提供raw-pointer保活回退。
- iOS实机未验证：加载、三指呼出、真实游戏搜索、键盘、触摸穿透、旋转、多窗口、前后台和Static执行仍需要最终候选设备验证。Simulator与macOS fixture结果不得标为实机结果。
- SwizzleManager只能管理明确合作域内的调度/writer，不能拦住未知外部dylib的Runtime修改。继承默认拒绝；显式LocalSnapshot留下本地方法槽。外部SharedSite诊断尚未证明全部目标加入合作域，故不自动安装。
- Loaded Static Runtime的镜像pin保持到进程结束；关闭功能恢复行为但不释放可能被在途调用使用的RX代码。不支持强制热卸载。外部重新映射/mprotect、ABA及直接改执行页不在并发证明内。
- 多站点和数值/目标更新不是对任意外部writer或并发读者的全局原子事务；CAS失败尽力回滚，不覆盖第三方后续变化。对齐RW单元更新不写RX页。
- Static构建仅支持明确检查过的thin ARM64布局和load-command allowlist，要求真实header slack、最终对齐LINKEDIT和未加密输入；未知内部引用拒绝。直接branch扫描不证明间接/跨镜像/动态生成引用安全。
- 签名器要求现存LC_CODE_SIGNATURE，拒绝带entitlements输入；ad-hoc输出仍需包级IPA身份/权限重签。expected bytes来源标签不是可信来源认证。
- Finder提供公开元数据类型名，不能据此推导Invoke ABI。RVA/offset反查及原地址级全部详情仍未对等；缓存有界并明确truncated。真实目标Runtime导出/Domain变化需要设备报告验证。
- Foundation JSON不提供重复key词法证明；配置JSON不是签名信任边界。大图像读取/构建的设备峰值内存与耗时未实机测量。
- 本机Linux没有Apple SDK；macOS/iOS构建由固定GitHub CI执行。本机LSan受ptrace阻断，普通C测试与macOS sanitizer结果分开记录。

原源码缺陷的复现/处置仍保留在docs/audit/FINDINGS、INVOKE_OWNERSHIP、CAPTURE_LIFECYCLE和BUILD_BOUNDARIES中。原仓库未修改，旧M47和Capture问题不能以新基础组件通过宣称原生产实现已修复。
