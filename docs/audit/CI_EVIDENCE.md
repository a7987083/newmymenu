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

## 第二轮：e0d897c，已实际通过

Run https://github.com/a7987083/newmymenu/actions/runs/43632817583 ，两个job均success。
source-audit增加固定原仓库checkout，6项测试通过，并重建匹配HEAD、全部文件hash和Runtime API位置。
Runtime实验、ARM64fixture、签名与依赖检查再次成功，dylib SHA256与第一轮一致。
Artifact https://github.com/a7987083/newmymenu/actions/runs/43632817583/artifacts/14128049232 ，ZIP SHA256 `9bd7ebfa1f549bc7d6f16caf88a5c8b439c793a750fc01b816d3d0e7077a51b1`。
后续仅审计文档/状态记录提交不改变测试或fixture源码，不冒充该HEAD也执行过CI。

## Invoke/Capture专项复现

首次Run43633742775，ecc83b0：编译失败，首个真实错误是原格式头两个static inline编解码helper未使用（Werror）。后续2386068增加0..128编码往返测试，未放宽检查；Run43633875936通过M47实例契约隔离复现。

综合Run https://github.com/a7987083/newmymenu/actions/runs/43634163884 ，source `10efd671cbe0c5ca22ffb31aef71fbaaed4cc67e`，3个job全部success：

- source-audit：9项测试、固定源hash/API库存复现。
- runtime-audit：真实ObjC基础实验及ARM64审计fixture编译/签名检查。
- invoke-contract-audit：完整M47源码与原入口编译并运行；ReceiverCapture原实现编译并运行真实dispatch timer，实际复现旧timeout结束新会话。

日志关键输出：
```
REPRO indexed arity=2 byRef=0 requested=B actual=A baseCalls=0 enumCalls=0
REPRO explicit arity=1 byRef=1 requested=B actual=A
REPRO session A=0.5s completed; session B=15s wrongly ended by A stale timeout after 0.543s
```

证据Artifact https://github.com/a7987083/newmymenu/actions/runs/43634163884/artifacts/14129835094 ，ZIP SHA256 `d3057638be7370b0e325942f968f8bde5bf0849427581e3ca754c67a46c086f6`。
包含hash provenance、生成源、macOS可执行文件和原始结果文本；不是产品dylib。IL2CPP/Dobby边界明确使用替身，未在真实游戏或iOS设备运行。
