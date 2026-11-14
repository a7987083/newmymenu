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

## Execution/Capture基础契约

- 先记录0002设计，新增NMInvocationRequest、NMReceiverLease、NMInvocationCoordinator，以及带token/安装确认/安全关闭确认的CaptureSessionManager。
- 所有arity/ByRef共用同一receiver入口；scope必须在原调用线程同步执行一次，拒绝迟到/重复/跨线程/空receiver；后端异常明确失败。
- Capture旧事件/cancel/timer均绑定session；install未ack不复用，close失败保留ownership并允许retry。未ack后端不能强制释放。
- 增加真实Foundation对象存活、1000并发调用、旧timeout隔离及install/close失败fixture；尚待macOS CI，不预填通过。
- core API提升为2；增加的基础接口尚未连接IL2CPP/Dobby或旧UI，不宣称原游戏已修复。

- 初轮Execution/Capture CI Run43643039478（cd93060）四job通过：新Foundation契约/并发/真实对象存活与timer测试执行，ARM64 API2核心库通过15项精确导出、依赖/签名检查。
- 自审新增关闭失败资源保留、retry成功释放及manager正常关闭后解除自持有的具体生命周期断言；这些新增断言等待下一CI，不以初轮结果冒充通过。

- 加强后ae7f607 / Run43643448325四job通过，真实Foundation资源/manager释放断言通过，16项Python和原翻译/wire回归持续通过。
- 已下载Artifact14133306387，校验API2 dylib与ZIP哈希、Mach-O，6个静态分析plist无diagnostics。报告写入docs/builds/execution-ae7f607.json。
- 仅确认新契约组件，不将结果归为真实IL2CPP GCHandle、Dobby关闭屏障、旧UI或设备修复。

## Runtime元数据与实机Probe

- 先记录0003边界；新增同一镜像所有者绑定、thread current/attach/finally-detach、配对typename分配/释放、有限类扫描与完整身份方法展开。
- 描述符只存Foundation身份，不跨调用缓存Class/Method裸指针；Runtime变更/歧义/不完整导出明确拒绝。GCHandle/runtime_invoke只报告导出，不调用。
- 新增自包含UIKit只读验证版：独立透明touch-through host、可拖动面板、类/方法列表、字段复制与JSON报告导出。没有复制旧UI或安装Swizzle/Dobby。
- Core API3加入Discovery；新增受控C API fixture和独立Probe构建/签名/导出/依赖检查。当前未编译/运行，等待CI，设备未验证。

- 首轮Probe CI Run43646420886在Discovery内部header的NSDictionary report参数缺少nullability处失败，后续编译/实机均未认定通过；补齐NS_ASSUME_NONNULL，不放宽警告。
- Probe列表改用iOS14+ UIListContentConfiguration；fixture类型加独立前缀，避免与ObjC Runtime的Method类型冲突；列表事件检查当前快照边界。

- Run 43646718511: corrected fixture integer-to-pointer width via uintptr_t; explicitly linked CoreGraphics for CGPointZero/CGRectZero used by probe UI. Strict checks remain enabled.

- Probe host now supports the UIApplicationDelegate window lifecycle when no UIScene exists, covering pre-scene Unity hosts without deprecated global windows enumeration. Device behavior remains unverified.

- Run 43647062960: probe dylib build/strict verification passed, discovery fixture crashed at runtime. Enabled AddressSanitizer/debug symbols for discovery fixture to locate the first invalid access; no test skipped.
