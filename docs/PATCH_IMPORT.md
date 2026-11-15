# Patch 候选导入

入口 include/NMPatchImport.h，唯一实现 src/Configuration/NMPatchImport.m。只负责候选解析，不发现文件、不计算目标地址、不写入Mach-O。documentFromJSONData 全部成功才发布不可变 candidates/warnings；requiresBinaryValidation 始终为真。

保留旧字段别名、上下文继承、十六进制分隔符及弱候选发现。显式地址/字节非法、矛盾别名或任一非法同级条目整份拒绝，禁止返回半套结果。地址拒绝bool、小数、负数和溢出；字节数组必须为0至255整数。不同标题的同址定义保留，物理写入去重应由后续计划层处理。

前导零沿用旧octal/hex-fallback解释，但addressInterpretation和requiresReview明确保留；弱候选confidence=0.55。标准格式newmymenu.patch-candidates/schemaVersion=1往返不能清掉这些review标记。所有候选仍需目标二进制验证，这些字段不是信任或执行授权。

4MiB输入及标准化输出预算、深度64、节点65536、最多4096候选；扩展父级长字符串前检查累积预算。拒绝authoring/manifest文档误入本解析域。

验证：make test-patch-import；make test-patch-import-audit SOURCE_BASELINE=/path/to/fixed-source。后者提取hash固定原纯函数，已真实复现负数绕回、bool/小数强转、无效显式兄弟遗漏、前导零和弱候选；不把旧workspace对候选的后续验证误写为自动无验证应用。

尚未完成目标文件选择、RVA/VA/file offset解析、原字节核对、重叠冲突计划、事务式Mach-O写入及最终UI。iOS运行未验证。
