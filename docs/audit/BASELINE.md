# 基线与证据边界

核对日期：2026-11-15。原仓库仅 clone/read，没有提交、改 ref、触发工作流或写文件。

## 候选开发端

- Repository: https://github.com/a7987083/mymenu
- Branch: feat/method-finder-p5-detail-copy
- HEAD: 7066edeaf9e47580c89440be670c517280534b69
- main: 7216b5524587f362622d833e3caf1244bbd3fda9
- customer/clean-runtime-rewrite: 92d675e0a5164ae72c7b76e38aea349c4929301d

候选分支相对 main 的源码 diff 涉及翻译、字段复制、类内过滤、滚动恢复、统一 Class Resolver、instanceIndex 的配置和调用传播。因此选择它作为开发端审计候选，并非因为时间最新。尚不能称为全部功能已验证的稳定基线。

12 个远程分支的固定 SHA 和限定到相关源码/工作流的逐文件 diff 统计见 source-inventory.json。audit 分支用于理解历史 Swizzle 清理；refactor 分支用于了解已有设计；build 分支的编码 patch 输入不作为已验证业务源码。customer 分支只参考执行契约，不迁入客户 UI。

## 明确不推定

旧 docs 声称某 CI 成功，只是历史线索。本轮没有据此认定成功。对候选 HEAD 和历史短 SHA 的关联运行查询没有取得可确认的成功运行，不代表此前从未运行。

原工程 Makefile 使用 latest SDK，Theos 和 Homebrew 安装未固定版本；Dobby 固定 5dfc8546954ce3b3198132ab13fddb89ee92cdd7。未来新工程必须固定并记录实际 SDK/compiler，而不是原样复制旧 workflow。

162 个源码/头文件的 SHA256、325 个 Runtime API 文本候选见库存。325 包括注释、头文件及未直接编译文件，不是 Hook 数量。每个候选记录物理行号、内联源段、上下文、是否为 Makefile 直接编译单元。间接 wrapper、运行时 IMP 安装轨迹及全部 selector 最终所有者尚待专项审计，不能宣布完整 Swizzle 审计完成。

本机 Linux：有 Python、GCC、git；没有 clang、xcrun、Apple SDK、Objective-C Foundation Runtime 或 iOS 设备。GitHub CLI 未登录，但连接器可以写新仓库。newmymenu 初查 size=0 且 ls-remote 没有 refs，随后才初始化。该空仓库可安全使用，无覆盖已有业务代码。
