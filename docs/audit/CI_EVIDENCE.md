# 实际 CI 证据

- Source commit: 1db15a2b9f4a0f7b2b4f598bef953a3d387dd68e
- Run: https://github.com/a7987083/newmymenu/actions/runs/43632322407
- Jobs: source-audit 132561464161 / runtime-audit 132561464441，均 success
- Artifact: https://github.com/a7987083/newmymenu/actions/runs/43632322407/artifacts/14129005845
- Artifact ID: 14129005845；zip SHA256: 6f89374efbb12a7ff965d49d092d14f468824620d2e406e296a3828b0e1d1790

## 已实际运行

Linux：3项审计测试通过。macOS15 ARM64：真实ObjC Runtime fixture执行通过，测试继承Method交换污染父类、局部instance/class override隔离、original IMP、1000次稳定并发调用、ObjC对象释放、block IMP安装与受控同步恢复。

不包括：并发安装/恢复、任意第三方Hook、目标菜单、IL2CPP、UIKit、iOS设备。

## ARM64审计夹具编译与检查

- Xcode16.4 Build16F6；Apple clang17.0.0 clang-1700.0.13.5
- 固定并通过iPhoneOS SDK18.5检查，deployment target14.0
- NewMyMenuRuntimeAuditFixture.dylib：Mach-O64 dylib arm64
- dylib SHA256: `1223bf9df9cedb2eba66d781faab1459ec00e9b18ea8b23829daa89602f70b09`
- exports: `_NewMyMenuRuntimeAuditFixture`
- deps: Foundation.framework、libobjc.A.dylib、libSystem.B.dylib（另有自身LC_ID_DYLIB）
- `codesign --verify --strict --verbose=4`：valid on disk / satisfies its Designated Requirement
- LC_CODE_SIGNATURE存在

**这是审计实验dylib，不是开发端产品，不作为最终交付。没有iOS运行或实机验证。**

## 日志中的非失败项

静态分析收到 `-framework Foundation: linker input unused` 提示，未报告分析错误；不等于整个原工程静态分析通过。runner对固定Actions的Node20发出弃用提示并使用Node24运行，已记录；未随意升级依赖。

后续工具/审计数据更新的CI必须单独核对，不把本Run归到其他HEAD上。
