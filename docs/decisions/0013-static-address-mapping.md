# Static地址解析先行

先比较原StaticBinaryBuilder及V3离线实现，不复用依赖已加载镜像的AnyImage resolver。来源hash见audit/macho-address-source.json。保留V3的实际__TEXT基址及segment file-backed映射公式，分离到唯一C模块NMMachOAddress.c；去掉生成分支/文件写入/UI/Swizzle依赖。

显式RVA/PreferredVA/FileOffset，禁止猜测和runtime地址；完整非空范围须落在单一file-backed segment。拒绝截断、溢出、重叠VM/file范围、错误section范围、加密镜像及非thin ARM64 executable/dylib/bundle。值类型layout不引用输入内存；解析失败不发布，resolve再次验证调用方layout且输出不变。

原ZNV3RVAToFile的va+length溢出已用hash提取的原函数实际复现；16384组正常输入与原实现一致。不是重写ARM64指令/Static Dispatch算法。新mapper不保证任意映射处可写Patch：header、签名、非指令数据保护与original bytes/逻辑冲突属于后续计划层。当前不修改任何二进制。

Linux本地普通C/C++测试通过；GCC LeakSanitizer在当前受ptrace运行环境退出，不能据此标ASan通过。CI保留ASan+UBSan运行，真实ARM64产物布局作为独立输入；以实际CI结论为准。最终UI及Static写入/混合Build尚未完成。
