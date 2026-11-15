# 独立Static代码Payload

不先接旧workspace/文件写入，先验证V3的fragment/thunk机器码。私有layout置换和64/128-byte metadata ABI直接复用固定源并仅重命名，hash见audit/static-code-source.json。单一有界relocator完成PC-relative处理；same-site多逻辑只写canonical selectedTarget，所有variant仍保留独立onRVA。

NMStaticCodePayload生成私有code/metadata/sitePatches，明确preferred VA放置位置、输入hash、固定nonce可复现。失败不输出半成品，不写文件或宿主内存。置换仍做完整验证，由O(n²)改为线性seen检查。metadata selectedTarget初始0，表示OFF；ON由后续受控RW写入实际运行地址。写入前必须由owned-segment allocator证明放置区域安全，payload本身不能代替文件布局验证。

首先仅fixture编译新Payload，真实macOS ARM64分配RW缓冲→生成→改为RX→执行原返回7、共享ON返回42/99→1000次恢复，另拒绝地址重叠。该测试是宿主CPU实际执行，不是iOS实机。通过后才接生产core与文件流水线。最终菜单/typed value cell/Runtime混合仍未完成，不得把此payload当最终dylib。
