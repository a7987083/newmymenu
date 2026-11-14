# 离线Mach-O签名模块

来源：固定原仓库7066ede的ZNAdhocMachOSigner.mm，完整文件hash见docs/audit/signer-source.json。复用SHA1/SHA256 CodeDirectory、页哈希、SuperBlob和自校验算法，不复制原工程全局状态或Runtime代码。

## 新入口与输入保护

`NMMachOSigner signedCopyFromPath:toPath:error:`只读打开常规输入，拒绝源symlink；创建输出目录中的独占临时文件，复制并检查源size/mtime/ctime是否变化。原签名算法只操作临时文件。完成内部验证后以不覆盖的link发布新输出；失败清理临时文件，原文件和已有输出不修改。输出保持原文件权限位。

仅支持带LC_CODE_SIGNATURE的thin ARM64/ARM64e；不处理fat/无签名槽或>4GiB。检查load-command对齐/容量/总长度、重复signature/linkedit和segment文件范围，避免整数溢出绕过布局检查。

输入有XML/DER entitlements时明确拒绝：当前组件不负责保留权限与最终IPA身份签名，不能悄悄丢掉它们。输出metadata中的finalPackageResignRequired始终为true。该模块是Build的独立基础设施，不等价整个Static Builder或安装包交付完成。

## 两个真实源码缺陷及修复

1. Run43653327918：原CodeDirectory flags=0、无CMS，内部hash自校验成功，但codesign将它识别为未签名。补CS_ADHOC。Apple原维护源码Security/OSX/libsecurity_codesigning/lib/signer.cpp的ad-hoc路径与xnu/osfmk/kern/cs_blobs.h已交叉核对。
2. Run43653497653：文件哈希已有效，但codesign严格校验指出不满足自身designated requirement。原实现组装证书链要求，与无证书的ad-hoc模式矛盾。改为空requirements集合，由系统根据CodeDirectory cdhash生成ad-hoc指定要求；不再生成虚假的证书身份。

已删除仅用于旧证书要求拼装的ReqAppendBytes/ReqAppendString/AppendBE32及相关常量，没有保留旧备用路径。严格codesign验证与cdhash要求检查始终保留。

## 自动化证据

`make test-signer`在macOS ASan下使用本项目真实iOS ARM64 core作为输入，执行独立`codesign --verify --strict`和指定要求验证；验证源/输出相同、输出已存在、源symlink、截断、错误架构/fat、损坏command count、segment溢出和临时文件清理。随后编译iOS ARM64对象，执行静态分析并要求零diagnostics。

Run43653714734首次通过上述独立签名验证；后续集成构建及entitlements负例状态以PROJECT_STATE和docs/builds报告为准。没有真实设备运行签名产物；不将macOS代码签名校验当iOS加载结果。
