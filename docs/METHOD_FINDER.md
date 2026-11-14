# Method Finder迁移状态与证据边界

## 当前实现调用链

Class/Method模式与输入→唯一runQuery→Discovery.scanQuery(methods flag)→同Runtime/Domain/thread scope→不可变类或方法值快照→主线程NMFinderSession generation检查→唯一table renderer。

类展开不新建Resolver：methodsForClass重新按assembly/namespace/class/fullType定位；其方法签名和全局关键词结果都经过NMDLCopyMethod。方法结果含classIdentity、原始method、parameterTypes、returnType、static和signature，没有MethodInfo/IMP地址缓存。

详情经NMMethodPresentation.fieldsForMethod生成label/value/copyable；复制handler捕获value，不能复制带label或翻译的格式串。Class是原始simple name，Type是qualified type；Return/Arg保留Runtime返回的type string（含&），不推断结构布局或调用ABI。翻译直接复用NMMethodTranslator和原3000词典，只影响subtitle/翻译字段。

## 原行为与迁移矩阵

| 能力 | 原基线7066ede源码行为 | 新版本范围 | 证据与设备边界 |
|---|---|---|---|
| 类搜索 | V3 exact/prefix/suffix/contains排序 | 大小写/重音不敏感contains，同一快照计数 | 受控C API fixture；完整排序对等未迁移 |
| 方法搜索 | 表达式解析、精确方法名/参数个数、限定assembly/namespace/class、RVA反查 | 新增全局方法名contains关键词，显式bounded/truncated | 不宣称替代旧表达式/RVA能力 |
| 模式切换 | 旧UI多wrapper | 单UISegmentedControl→同一scan/renderer | UIKit设备未验证 |
| 方法签名 | ABI元数据/分类/地址等详情 | 公开元数据API复制参数/返回名、static、owner | 只是类型描述，非Invoke ABI支持 |
| 本地翻译 | 原Translator/3000词典 | 直接复用，原方法身份不改变 | 既有12000对照；字段测试 |
| 单字段复制 | P5 label/value/copyable | Assembly/Namespace/Class/Type/Method/翻译/Signature/Return/Dispatch/各Arg | Foundation字段测试；剪贴板设备待验 |
| 未知原生地址 | 可解析RVA/Pointer等 | 不猜偏移、不生成伪地址；暂不提供此入口 | 待成熟Resolver/address模块迁移 |
| 返回类列表 | 旧页面状态恢复 | 同一类快照/report/offset缓存返回 | Foundation/ASan已通过；UIKit待验 |
| 缓存刷新 | 原analysis cache/global关联状态 | 最近一份类页面缓存，新query/Runtime刷新失效 | 非完整索引缓存 |
| 取消 | 原token/取消UX | 旧completion generation拒绝；扫描2秒/数量边界 | 无显式用户取消按钮，仍待迁移 |

本阶段没有Swizzle，没有旧UI备用执行路径。旧源保留在只读基线用于审计/对照，不进入新产品链接。

## 验收命令

`make test-discovery`：受控原生C函数表（不是目标Runtime），覆盖两种搜索、类型复制、边界、线程/finally、分配释放及错误。

`make test-finder`：主线程状态、快照不可变、过期提交拒绝、返回和刷新失效。

`make test-presentation`：复用词典、原字段复制、ByRef文字保留、空值/占位符禁止复制、不伪造地址。

三个fixture使用ASan；Probe UI/state/presentation均执行静态分析并以plist diagnostics gate判定。完整开发端与实机功能回归不能由这些测试替代。

## API5后续补齐

NamedExpression原算法与10020输入结果/错误已对照；Expression入口支持assembly/namespace/class/exact method/arity，非零delta拒绝进入VM。类结果已按exact/prefix/suffix/contains做有界候选排名，晚到exact/limit-one回归通过。前文表格描述API4迁移时点，完整RVA/offset地址查询、显式取消与真实设备回归仍待完成。
