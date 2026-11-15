# Static混合控件的配置边界

当前Backend的definition已经逐条保存control/valueType，真实Runtime fixture把Switch/Number/Slider混在一个镜像验证；但NMOfflineBuildRequest把全局选择应用到每个候选，NMPatchImport丢弃行级控件字段，使UI无法生成同一镜像的混合控件。这个ABI独立缺口必须补齐。

唯一候选模型增加可继承的control/valueType。通用JSON接受control/controlType与valueType/staticValueType的明确数字枚举或既有规范英文名；缺省保留-1作为“使用构建默认”，显式Auto=0与继承不同。避免把泛用type字段猜作控件。已知字段非法/矛盾立即失败。

Review schema3保存说明与这两个字段；schema1/2仅在唯一入口一次升级到同一模型，输出始终3，无旧执行器。构建UI顶部选择只作为默认值；显式行级配置优先。review显示每条实际控件/类型，用户核对后才允许生成。物理规划/数值发射复用现有单一实现。

验收：继承与覆盖、Auto/缺省区别、bool/范围/未知名/矛盾拒绝、v1/v2迁移保留review来源、同镜像混合控件API/生成UI测试。Runtime/Native混合执行provider仍属暂缓游戏ABI范围，不能混称已完成。
