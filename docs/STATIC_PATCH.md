# Static Patch 独立迁移状态

## 已实现的地址组件

include/NMMachOAddress.h / src/Build/NMMachOAddress.c，Core API12。读取thin little-endian ARM64 executable/dylib/bundle的有界segment/section布局，保留原Static Builder V3实际__TEXT基址与segment file-backed映射语义。输入可非对齐，不强制解引用Mach-O结构体。

NMMachOReadLayout发布不引用输入buffer的值快照；NMMachOResolveRange显式接受RVA、Preferred VA或File Offset，检查完整非空跨度，不自动推测地址种类。layout再次校验，输入失败不改变输出。VM/file溢出、重叠、截断、坏section及cryptid非零的加密镜像均拒绝。容量128segments，4096commands，16MiB commands上限。PAGEZERO等无文件数据不能映射为可写字节。

来源及公式复用见docs/audit/macho-address-source.json和决策0013。原函数hash确认后独立编译：16384组正常映射对照；旧va+length溢出确实返回成功，新入口拒绝。make test-macho-address使用ASan/UBSan；tools/generate_address_parity.py只提取原纯函数，不执行旧builder。CI还读取真实构建的ARM64 core作为输入。

地址可映射不等于允许Patch。该组件不修改数据、不更新签名、不判断instruction或重定位安全。

## 下一层必须保留的原业务约束

固定原ZNStaticBinaryBuilderV3.mm:832–905已核对：row.validator的enabled/capturedOriginal长度相等、非空且4字节对齐→RVA完整映射→可执行instruction section→拒绝LINKEDIT→磁盘字节与Live Original一致→逻辑定义按同起点聚合物理最大窗口→重新映射整个窗口→检查内部入分支→不同起点窗口重叠拒绝。

同起点多逻辑定义是Static Dispatch的真实能力，不能用简单“同址字节不同就删一项”替代。后续immutable plan必须保留逻辑到物理映射，明确冲突规则；不能将当前候选parser输出直接当已验证构建输入。原Live Original对照依赖Runtime抓取，ABI独立路径需显式expected bytes来源，来源未确认则拒绝实际写入。

尚未迁移：instruction section/入分支证明、physical dispatch plan、分支/Thunk/静态数据扩展、Static/Runtime/Native混合emit、文件事务发布与最终UI。签名器已有独立验证，但尚不能代表上述生产闭包。游戏ABI暂缓；实机未验证。

## API13 不可变物理计划（组件CI已通过）

include/NMStaticPatchPlan.h / src/Build/NMStaticPatchPlan.m。definition用显式地址种类、expected/replacement等长字节、唯一标识及expected-byte来源标签构建；标签由调用者提供，不代表认证。plan只使用一次冻结的输入图像，校验instruction section/磁盘原字节、聚合同起点最大窗口、保留逻辑映射、补齐原始尾部并去重variant、拒绝不同起点重叠。

地址layout在同一parser收集最多512个有界instruction区域，检查文件与VM偏移关系、执行标志、对齐及非header/非LINKEDIT。没有新增并行Mach-O解析器。只扫描这些区域一次，对B/BL、B.cond、CBZ/CBNZ、TBZ/TBNZ直接目标进行有界符号扩展，二分检查目标是否落入任一物理窗口内部。分支到入口允许，来自窗口内部的分支仍按原策略保守拒绝。

physicalSites、原始字节、变体、logicalToPhysical和definitions均冻结，sourceSHA256绑定完整输入；失败不产生半套计划。requiresRelocationValidation始终为YES：直接分支扫描不是间接跳转、跨镜像引用或运行时生成代码的完整安全证明。该计划没有emit/write入口，不能当作最终二进制或写入授权。

测试覆盖同址短/长窗口、补尾/去重、不同variant、逻辑顺序、原字节不符、重叠、对齐、section VM/file错配、七类直接分支正负偏移/入口允许、容量边界、实际ARM64产物。运行make test-static-plan；完成make core后build/tests/static-plan build/core/NewMyMenuCore.dylib。最终CI/source_head/Artifact以PROJECT_STATE与docs/builds为准。

原算法回归：make test-static-variant-parity SOURCE_BASELINE=/path/to/fixed-source，hash检查后仅提取ZNV3ComposedVariant；1000个最大窗口/短前缀计划共2000个合成结果对照，FileOffset及PreferredVA指向同一位置。原Builder、Runtime或UI均不参与该fixture。该对照证明变体合成语义，不证明旧生成二进制与新生成二进制等价（当前没有新emit）。

3f4c53a8 / Run43680151665五job通过，15份core分析零诊断；计划ASan/UBSan、1000计划/2000原合成结果对照、256/257容量及真实ARM64输入通过。机器证据docs/builds/static-plan-3f4c53a8.json。没有实机或生成二进制回归结果。
