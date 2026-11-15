# Owned-segment图像与chained starts

沿用原V3在__LINKEDIT前分配RX/RW自有segment及真实header slack门槛，拒绝code cave/zero-fill或重复预埋。NMStaticBinaryImage消费冻结图像/hash相同的plan，生成内存副本；不覆盖源或发布未签名结果。Mach-O基础布局仍来自唯一NMMachOReadLayout；offset修改采用显式command allowlist和大小/原payload范围检查，未知命令拒绝，避免旧V3默认略过未知offset。

重要差异：两个新segment插在__LINKEDIT前时，不能只移动load commands却不更新chained starts。Apple dyld的MachOFile.cpp检查VM/file顺序，MachOAnalyzer.cpp验证startsInfo.seg_count与segment index。原V3源码只有linkedit offset移动，没有相应starts table扩展；当前新模块重建表，新增两个无fixup条目并平移相对starts偏移/后续imports/symbols偏移。保留原segment offset及链编码。重建blob和原signature复制到LINKEDIT尾部，更新其commands/大小，再由既有签名器重建签名；旧blob是不可达原始输入数据，不作为备用路径执行。

当前支持原starts count为完整segment数或省略尾部LINKEDIT，其他形式明确拒绝。__LINKEDIT须最后VM/file segment，16KiB对齐、原signature为最后payload；header slack至少304字节。输入256MiB/输出512MiB，payload另有预算。未知load command、未支持chained格式/entitlements等仍明确拒绝，不删检查促成构建。

独立验证：实际iOS ARM64 core作为输入→plan→owned image→既有signer→codesign --verify --strict及Apple dyld_info -validate_only；还独立检查new segment顺序/权限、starts count及source hash。真实生成代码执行由上一fixture在macOS ARM64验证，不等于iOS已加载生成文件。

官方源码核对（仅格式证据，非目标设备执行）：https://github.com/apple-oss-distributions/dyld/blob/main/common/MachOFile.cpp （validSegments/order）；https://github.com/apple-oss-distributions/dyld/blob/main/common/MachOAnalyzer.cpp （validChainedFixups/seg_count）；https://github.com/apple-oss-distributions/dyld/blob/main/other-tools/dyld_info.cpp （validate_only）。最终是否通过以固定Xcode16.4自带工具的实际CI结果为准。
