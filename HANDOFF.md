# 独立交接

## 基线

源仓库 https://github.com/a7987083/mymenu 仅只读。
候选 `feat/method-finder-p5-detail-copy@7066edeaf9e47580c89440be670c517280534b69`；不是已确认全部稳定的基线。
原 main `7216b5524587f362622d833e3caf1244bbd3fda9`；customer `92d675e0a5164ae72c7b76e38aea349c4929301d`。
新仓库 https://github.com/a7987083/newmymenu 分支 main。当前源码精确HEAD用 `git rev-parse HEAD`，CI产物名含源SHA。不可在同一commit的文件内自引用未知最终commit SHA。

## 当前架构/代码

尚未迁移业务；架构草案见 docs/ARCHITECTURE.md。没有生产SwizzleManager。
`tools/source_audit.py` 固定源码库存；`docs/audit/features.json` 53项功能/回归状态；`source-inventory.json` 原源码SHA与文本候选。
关键调用链和根因见 FINDINGS.md，包括 ClassResults 与 candidates 数据源分流、M462 handle并发范围、Native slot teardown。
真实Runtime实验位于 tests/runtime_audit_fixture.m，验证通用Runtime语义，不是目标菜单。

## 构建/测试

Linux：`python3 -m unittest discover -s tests -v`，当前6项通过，另已重建核对固定源SHA/162文件hash/API位置。
macOS：workflow完整命令是唯一权威，Xcode16.4/iOS18.5，14.0 deployment target；审计fixture已在1db15a2通过真实Runtime执行、ARM64编译、签名与依赖检查；Run43632322407，详见docs/audit/CI_EVIDENCE.md。后续源码仍须核对对应SHA。
审计fixture运行：clang ARC/Foundation后执行；iOS fixture仅编译/检查/签名，不运行。
Artifact名 `runtime-audit-fixture-NOT-PRODUCT-<sha>`。该产物不是最终开发端dylib。

## 状态/限制

未实机验证；未产品回归；未生产构建；完整源码审计仍进行中。不要在未完成Swizzle用途和依赖审计时复制整个ZNUnifiedUI或按文件名宣布功能完成。

## 下一任务

优先为325个文本候选补充：剔除注释/未编译来源、展开Swap wrapper调用、建立Class/SEL/types/原IMP/安装顺序/覆盖关系。特别核对最终Renderer及Invoke多层装饰的真实可达链。
补齐53项弱锚点和Build/Native传递依赖；读取固定Dobby源码确认destroy是否排空在途trampoline。完成专项审计后再定稿和迁移业务。
真实iOS回归需要设备，但此时仍有大量可由源码和CI推进的工作，不应提前宣称设备是唯一阻塞。

补充：swizzle_audit.py已建立47wrapper/124函数/164调用索引，不等价实际Hook数量。固定Dobby的DobbyDestroy没有调用排空；不释放entry，不能误称trampoline已被它释放。详见SWIZZLE.md和F04。

## Invoke专项新增证据

INVOKE_OWNERSHIP.md包含实际5层selector链。CI Run43633875936以原M47完整实现及原基础入口隔离复现了receiver契约绕过：/2-/8和typed/1 ByRef绕过ordinal/explicit receiver；不是生产修复。
CaptureSession旧timer会跨会话的假设已写原实现复现fixture，运行状态必须核对CI，不能预填通过。
下步不要在M47内部再加一个隐藏TLS补丁；新执行入口必须先建立ReceiverLease/InvocationRequest，再交给共享marshaller后端。
