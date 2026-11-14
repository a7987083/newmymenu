# 实际变更

## 2026-11-15

- 确认newmymenu是无Git引用的空仓库后初始化，未改原仓库。
- 固定源仓库12分支SHA，建立162文件SHA256和325个Runtime API文本候选库存。
- 建立53项功能入口/迁移回归矩阵、10项关键发现和架构草案；未宣布完整审计完成。
- 实现可重建库存工具和3项审计完整性测试；本机实际运行全部通过。
- 加入真实ObjC Runtime实验源码和固定Xcode16.4/iOS18.5的ARM64审计夹具workflow；CI运行状态另行记录。
- 未迁移业务代码、未删除原功能、未生成最终产品dylib。

- CI Run43632322407的两个job通过；真实Runtime实验执行、ARM64审计fixture编译和签名检查成功；不是产品构建或设备测试。
- 补充47个exchange wrapper、124个mutation/helper函数、164处wrapper调用的源码索引，仍标动态所有权/ABI未验证。
- 实际读取固定DobbyDestroy源码，确认没有在途调用排空；entry安全删除仍是上游FIXME。
- 补齐多个功能具体符号锚点；新增3项解析器边界测试；本机6项通过，并重建匹配源SHA、文件hash和API位置。

- CI Run43632817583在e0d897c通过：6项测试、固定源库存复现、真实Runtime实验及ARM64fixture检查。
- 更正Native lifecycle具体constructor入口，定位UI旋转的bounds轮询路径；补记reconcile事件合并竞争窗口，未作运行复现声明。

## 后续Invoke专项审计

- 新增固定源hash验证的M47完整源码复现生成器与受控IL2CPP边界fixture，真实ObjC交换/入口方法不Mock。
- 首次CI Run43633742775编译失败：原格式头两个static inline helper未使用，Werror拦截；新增编码往返测试修复，没有放宽警告。
- Commit2386068的Run43633875936通过，实际复现/2、/8、/1 ByRef忽略instanceIndex和explicit receiver；/0及普通/1走基础入口。
- 新增ReceiverCapture原实现的真实dispatch/timer复现fixture；Dobby边界使用替身，尚待对应CI确认。
- 建立Invoke selector所有权/职责与重构边界，不修改原仓库，不把隔离复现当生产修复。

- 综合CI Run43634163884三job通过，ReceiverCapture原实现跨会话timeout缺陷实际复现（约0.543秒）；原始日志和生成源码已上传证据Artifact。
- 修正前轮F06：开发端当前已包含唯一实例auto-bind，与customer只是实现位置不同，撤销由wrapper存在差异推导能力差异的表述。
- 核对当前Build UI→C Executor→provider/base/emit/postprocess路径，记录旧class-method Swizzle不在当前UI必经路径、collector错误传播及store快照限制。

## 首批独立基础模块

- 先记录0001模块迁移设计及Native外部诊断Hook边界，未将高风险模块标为审计通过。
- 迁入离线翻译算法、3000词条JSON、许可和确定性生成器；公开类改为NM，不保留ZN兼容别名或第二套算法。
- 复用Action wire常量/64字节结构，公开checked ordinal codec替代不校验范围的inline入口，失败保持output不变、保留非序号flags。
- 新增独立Makefile、ARM64 core构建脚本、Mach-O/依赖/导出/签名/SHA严格校验和Foundation/原实现回归测试。
- 本机15项Python测试与C11 codec执行通过；C++测试首个错误为跨enum直接比较被Werror拦截，修正为显式uint32数值比较后，129组entry字节与原格式相同；没有放宽检查。
- Foundation执行、ARM64核心库编译与对应CI尚待本次提交运行，未实机验证。

- 首轮core CI Run43638600632：Foundation、12000翻译变体、wire对照通过；ARM64编译/签名完成，依赖白名单拒绝CoreFoundation，整体失败。
- 定位更早的CI异常：xcodebuild输出被head截断造成Broken pipe，改为完整输出/精确版本校验，不隐藏退出码。
- 从真实artifact检查CFConstantStringClassReference的dylib ordinal，确认CoreFoundation实际链接来源后加入精确系统路径；仍拒绝未知依赖。增加迁移模块静态分析，去掉deprecated但默认等价的链接参数，没有开启允许未解析符号选项。

- 修复后Run43638969924（源码f385c8a）四job通过：16项测试、12000翻译对照、129组wire字节对照、迁移源静态分析、ARM64 core编译及全部严格检查。
- 实际下载Artifact14130499746，复核ZIP/dylib SHA、Mach-O以及三个静态分析plist无diagnostics。机器报告保存至docs/builds/foundation-f385c8a.json。
- 只声明基础模块成功，完整菜单、执行引擎及iOS实机行为仍未验证。
