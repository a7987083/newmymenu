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
