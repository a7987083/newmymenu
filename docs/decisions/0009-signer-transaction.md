# 0009 复用Mach-O签名算法与输入保护

源码审计基线7066ede，ZNAdhocMachOSigner.mm的CodeDirectory/SuperBlob/SHA1+SHA256/page hash与自校验算法复用，不重新设计格式。原入口O_RDWR+mmap+ftruncate直接修改输入，失败无法保证输入完整；新公开入口只签名安全临时副本，验证后以link不覆盖发布到新输出，始终不改输入，不覆盖已有输出，失败删除临时文件。

解析边界同时检查segment文件范围加法、command对齐/section容量、重复signature/linkedit与command总长度。既有Mach-O布局签名路径保留；不支持无LC_CODE_SIGNATURE、fat或非ARM64，明确失败不绕过检查。生成的是ad-hoc签名，最终IPA仍需按原模型重新签名；不将它当设备授权签名。

验证使用CI本项目真实ARM64 dylib、独立codesign严格校验，以及损坏header/segment、截断/架构/输出已存在/源symlink等负例。此模块不使用游戏Runtime ABI。
