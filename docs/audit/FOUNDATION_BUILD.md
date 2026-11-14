# 首轮基础模块构建与根因

固定业务代码cd7d6b8，CI Run43638600632。

已实际通过：15项Python测试、C codec执行、Foundation翻译及1000次并发cache、129组wire entry字节对照、12000组词条变体与原实现对照。

## 第一个真实异常

工作流用`xcodebuild -version | head -n 1`检查版本，head提前关闭pipe，xcodebuild产生NSFileHandleOperationException Broken pipe。命令替换外层test只看到首行成功，异常没有成为该step退出码。这是新CI脚本缺陷，已移除pipe，改完整输出写file并核对Xcode16.4/Build16F6。不是SDK/编译器升级。

## ARM64验证失败

随后make core确实完成编译与ad-hoc签名，但verify_core拒绝CoreFoundation额外依赖，Run失败。

已下载artifact14130663520直接检查真实对象与成品：

- NMMethodTranslator.o包含undefined `___CFConstantStringClassReference`。
- NewMyMenuCore.dylib中该符号绑定dylib ordinal4，恰为CoreFoundation。
- 依赖为Foundation、CoreFoundation、libc++、libSystem、libobjc；没有Dobby/Theos/原mymenu依赖。

所以不是未知第三方库混入，而是常量NSString所用Apple系统符号的真实链接来源。白名单精确加入CoreFoundation路径，保留其他依赖拒绝检查，新增此已观察依赖的正例，原libdobby负例保留。未把所有framework或@rpath放行。

同时去掉新脚本多余且deprecated的`-undefined error`参数；dynamiclib链接器默认仍拒绝未解析符号，不启用dynamic_lookup或suppress。

## 证据边界

首轮Foundation/wire回归已运行通过；首轮dylib不是已通过全部检查的交付物。修复后的完整静态分析、Mach-O/exports/signature/SHA验收必须以新Run为准。
