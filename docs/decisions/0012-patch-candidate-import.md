# 0012 Patch候选导入，不等价执行授权

原pure helper隔离fixture（93ade23/Run43659488552）已复现：负数字符串转uint64、NSNumber小数/bool转地址、字节数组的同类强制转换、前导零base0八进制、坏显式兄弟条目无报错丢失及0.55弱候选。旧workspace另有低置信度/读取验证阶段，不能声称它没有任何校验。

新模块复用原key归一化/字段别名、target继承、hex分隔和弱候选识别思路，但修复不合法数值与错误传播；多个别名值矛盾明确报错，不依赖dictionary遍历顺序。原八进制/hex回退含义保留在metadata且强制review。任何已识别addressed record非法则全文件失败，不返回半套候选。

候选始终requiresBinaryValidation：不写workspace、不读/写游戏内存，也不当作已验证Static Patch。弱候选及不明上下文保留提示。提取阶段保留所有定义与路径（不因相同bytes丢掉不同标题），物理写入去重/冲突留给后续Build/site owner。own格式newmymenu.patch-candidates/version1保持confidence/review/interpretation往返，避免弱候选序列化后变成高置信度。

4MiB输入/输出预算、64层/65536节点、4096候选，限制字段/JSON路径大小。输出扩张预算逐记录检查，避免继承大标题使小输入膨胀成巨大输出。仅候选解析，UI选择/二进制读取验证/实际Build尚未迁移。
