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

- Run 43647225475 AddressSanitizer located objc_retain crash in withMetadata:error: returning from ambiguous-class error inside a nested autoreleasepool. Internal NSError** implicit autoreleasing writeback outlived the pool. Changed only the private callback channel to NSError* __strong*: errors are owned before the pool drains; public NSError** contract remains unchanged. Existing ambiguous descriptor case is the regression test, with ASan retained.

- Run 43647368642: controlled metadata fixture including the prior ambiguous-class crash passed under AddressSanitizer. Analyzer exposed 8 nullable NSError channel dereference warnings; guarded writes and added explicit plist-diagnostics CI gates (clang --analyze can exit zero with findings). No warning/check suppressed.

- `4d9231c7` / Run43647531696: 5 jobs全部通过。metadata ASan fixture、旧实现wire129/翻译12000对照、7份core分析和1份UI分析零diagnostics；Core API3与自包含只读DeviceProbe均已构建，ARM64/SDK/依赖/导出/签名/SHA256验证。Artifact下载hash与Mach-O复核通过。未运行UIKit/真实IL2CPP/设备。
- 已交付设备测试文件 `newmymenu-DeviceProbe-4d9231c7-READONLY.dylib`，对应SHA256 `3b0ce6555c45360072257a1c701503fab9dfa9abcd6a7d0d1eb3a0709f93b3bc`；步骤见docs/DEVICE_VALIDATION.md。完整产品、Invoke/Hook/Build回归未验证。

- Finder Probe: replace parallel rows/snapshot/mode/generation ownership with private NMFinderSession. Class return restores the immutable class snapshot/report/scroll without Runtime rescan; fresh searches and Runtime refresh invalidate cache, stale callbacks cannot overwrite newer state. Added Foundation/ASan state regressions and UI/state analysis gates. Build/device status pending.
- User screenshot of 4d9231c7 confirms the panel is visibly loaded on one device; real Runtime exports/class results/method signatures/keyboard/lifecycle not confirmed by this image.

- 05840d7b / Run43649083590: 5 jobs通过；Finder ASan状态测试及现有回归通过，7份core+2份Probe分析零diagnostics；ARM64/导出/依赖/签名通过。Artifact14134789796已下载核对ZIP/dylib SHA及Mach-O。设备行为仍未验证；已提供新版只读dylib和滚动返回测试步骤。

- API4: single Discovery scan loop now supports bounded global method-name substring search; class expansion/global search share one method-signature copy function. UI Class/Method mode and private presentation fields integrate original offline translator and raw single-field copying. Original exact/canonical/RVA grammar and rank parity remain pending; no Invoke or native pointer fallback added. New fixture/ASan/presentation/analysis checks pending CI.

- Detail copy audit: Class now copies the original simple class name, with a separate Type field for the fully qualified type. Namespace/name composition is not silently substituted for raw fields.

- 3115e2b3 / Run43649811591五job通过：API4 Core和自包含Finder已编译；metadata/Finder/presentation ASan fixtures、既有原实现回归通过；7+3份静态分析零诊断；下载ZIP/dylib哈希与Mach-O复核通过。已更新迁移差异矩阵、构建报告、状态与接手文档。完整产品和本轮设备验证未完成。

- Continued without intermediate binary delivery: API5 reuses fixed-source pure named expression parser; qualified assembly/namespace/class/exact method/arity filters feed the existing scan. Nonzero delta explicitly waits for address resolution. Added hash-verified original parser extraction and 10020 input/output/error parity cases under ASan; CI pending.

- Class ranking regression: first-N truncation could discard a later exact class. Reused original exact/prefix/suffix/contains rank in the bounded candidate pool; final sort/limit runs after bounded scan. Added later-exact/limit-one fixture; namespace/type contains remains explicit lower-priority extension.

- 09cae3ce / Run43650787572：五job通过；10020原纯解析器结果/错误对照、qualified owner/arity过滤及晚到exact排名回归通过；8+3分析零诊断。Core/Probe ARM64构建并下载复核哈希/Mach-O，签名在CI验证。按用户要求未分发本轮dylib。记录实际Runtime/ABI证据缺口，完整产品未完成。

- API6: cooperative cancellation via per-request NSProgress; UI cancel immediately invalidates Finder generation, worker checks cancellation before VM/inside scans/type copying/before publish, and always releases owned thread/type resources. Fresh requests clear stale snapshots. Controlled fixture covers pre-entry/mid-scan/type-copy cancellation; state test covers cancelled late result and idle idempotence. Game ABI work remains deferred.

- API7 Manifest: preserve original provider/kind/id/domain/metadata model while freezing metadata and configuration; replace swallowed collector exceptions with explicit errors, reject nil/duplicate/foreign items. Explicit injected provider list replaces hidden registry state. Added strict Manifest-only JSON schema/roundtrip; legacy authoring/Patch import and backend prepare/emit remain pending. ASan fixture and ARM64/analysis pending CI.

- Signing module source migrated from fixed original CodeDirectory/SuperBlob implementation with provenance hash. New signer writes/validates a temporary copy and never overwrites input/existing output. Hardened malformed load-command and segment arithmetic checks; ASan + independent codesign/negative fixture added. Not yet integrated into core; CI pending.

- Run43653327918: signer internal verification passed but independent Apple codesign rejected output as unsigned. CodeDirectory flags were zero despite no CMS identity signature. Compared Apple Security signer.cpp ad-hoc path and cs_blobs.h CS_ADHOC; set the required ad-hoc flag in the shared directory generator. Independent strict verification remains mandatory; root fix pending rerun.

- Run43653497653: ad-hoc flag fixed file recognition/hash validation, exposing a second original defect: certificate-based designated requirement cannot be satisfied by a certificate-free ad-hoc signature. Replaced only certificate requirement assembly with an empty requirements set so Code Signing Services derives ad-hoc identity from cdhash; retained hash algorithms/self-verifier and independent strict codesign check. Added explicit cdhash-derived requirement assertion.

- Run43653714734: reused signer now passes codesign --verify --strict, designated cdhash requirement assertion, ASan negatives/cleanup, ARM64 object compilation and analyzer. Integrated signer into Core API8; added explicit refusal for embedded XML/DER entitlements so unsupported permission preservation is not silently lost. Final integrated CI pending.

- Run43653952155: integrated core/Probe built and analyzed, but permission negative fixture had no entitlement slots after signing a dylib, so the refusal assertion was not testing the intended input. Replaced fixture with an actual iOS ARM64 MH_EXECUTE file and independently assert XML/DER slots exist before testing refusal. No production entitlement check relaxed.

- Run43654155060: integrated API8 core/Probe, strict signing/designated requirement, real embedded-entitlement refusal, ASan failures and regression suite all passed. Post-integration cleanup removes the now-duplicate signer ARM64 object compilation/analyzer from test-signer; formal core build already owns those checks. No required check removed.

- 1aab363a / Run43654350053最终五job通过：API8 ARM64 core/Probe构建、25/26导出与依赖/签名校验通过，10份core+3份UI/state/presentation分析零diagnostics；搜索取消/Manifest/JSON/原解析器等回归与独立codesign/权限拒绝负例通过。Core Artifact14137721557已下载核对ZIP/SHA/Mach-O；源码与产物一致。未发送中间dylib，未宣称完整产品或实机验证。

- SwizzleManager implementation/test fixture: single registry, exact runtime Method ABI checks, original IMP preservation, cooperative read/try-write gate, explicit default inherited rejection/local-snapshot opt-in, duplicate/foreign/parent conflict refusal and bounded diagnostics. No automatic external/game Hook installation. Source and real Runtime ASan tests pending CI; uncoordinated dispatch/foreign writers are explicitly unsupported.

- Run43655309286: first real ObjC Runtime/ASan SwizzleManager fixture passed instance/class/aggregate ABI, original IMP, inheritance, active/reentrant refusal, foreign/parent conflict and receiver release. Core API9 integration now adds manager/token exports, formal ARM64 compile/static analysis. Additional controlled block-IMP rejection and simultaneous instance/metaclass ownership tests retain the same lifecycle contract.

- Swizzle token now pins target/replacement Class and original/replacement IMP images; unmapped/dynamic/block-backed implementations are refused. Precise token/candidate lifetimes defer image release until after the exclusive gate unlocks, including failed installation. No block/free or image-unload fallback introduced.

- Swizzle fixture evidence strengthened: every parallel scope must return success and an atomic counter proves all 1000 method calls ran (not merely dispatch attempts). Added 128 active-target/129th rejection boundary, complete cleanup and bounded diagnostic churn tests. Production implementation unchanged.

- Pre-install target validation now rejects non-Class and already-metaclass inputs before object_getClass conversion, avoiding accidental double-metaclass targeting. Added a real Runtime negative case; no mutation occurs. Variadic methods explicitly remain outside the supported declaration contract because Runtime encodings do not prove ellipsis ABI.

- Run43656315886: API9 full suite passed, including exact 1000 completed calls, 128/129 capacity boundary, cleanup and metaclass-input refusal. Build verifier scope text now describes a modular foundation library rather than obsolete no-Hook/no-Build wording, keeping evidence accurate as ObjC lifecycle/Manifest/signing components are added; no production binary behavior changed.

- 72189bd7 / Run43656577480最终五job通过：API9 core/Probe ARM64构建，29/30导出及依赖/签名验证通过；11份core+3份UI/state/presentation分析零诊断。真实ObjC Runtime/ASan的原IMP/签名/继承/并发/对象/冲突/容量回归及旧测试、独立codesign继续通过。Core Artifact14138715984已下载核对ZIP/dylib SHA与Mach-O。未验证外部宿主/设备，不分发阶段dylib。

- Authoring source audit: old preflight precedes non-transactional writes into separate Runtime/Native stores, so later failures can leave partial imports. New offline document validates/freeze-completes both domains before a single revision-CAS commit; target binding remains explicitly unverified. Original feature identity semantics reused; binary caches stripped with warnings, instanceIndex retained in new format and refused for lossy legacy export. Native template shapes/ID collision handling validated without invoking game code. Fixture/CI pending.

- Run43657953374: offline authoring/store ASan fixture and 10000 original feature-identity parity cases passed. Core API10 integration adds document/snapshot/store exports and production ARM64/static-analysis checks. Added exact unsigned sentinel/ID-wrap and optional codec-field/arity validation cases. Runtime target validation and Patch candidate import remain explicitly pending.

- Configuration identity fields reject embedded NUL before any future C Runtime binding can truncate the intended method/type name. Added a JSON roundtrip negative case; display and argument string values remain unchanged.

- Authoring JSON now bounds depth (64) and node count (65536) before recursive cache stripping and after normalization, in addition to 4 MiB/list limits. Added deep and large-node extension negatives; all failures remain outside the single store commit.

- Patch migration pre-audit adds hash-verified original pure-helper fixture for address/byte numeric coercion, octal interpretation, invalid sibling omission and confidence-0.55 heuristic. Old workspace explicitly retains low-confidence labels/read validation; this fixture does not claim the old UI automatically applies candidates or that new Patch import is implemented. CI pending.

- Patch candidate importer source: strict unsigned/byte validation, contradictory alias errors, preserved inheritance/weak hints and explicit octal review, whole-file failure for bad addressed records, bounded candidate/output expansion, and provenance-preserving normalized JSON. Candidate definitions/paths remain visible; no workspace or binary mutation. First ASan fixture/CI pending.

- 918f0e2 / Run43674986757：Patch候选Foundation/ASan通过，旧纯解析器缺陷fixture真实复现；API10五job通过。
- 873566b 集成Patch为API11；Run43675212392在静态分析发现无format旧JSON向nonnull containsObject:传nil，检查保持失败。42e61ea新增显式空值分支，重跑全部适用CI，不放宽检查。
- 新增离线配置/Patch候选边界文档，更新Static地址迁移前源码检查；未实现或声称生产Patch写入。

- 42e61ea / Run43675322065五job通过：API11 core/Probe ARM64、37/38导出、依赖/签名通过；13份core和3份UI分析零诊断。Core Artifact14145951586已下载复核ZIP/dylib SHA、Mach-O和编译source_head。离线配置与Patch测试/原实现对照通过；未实机验证、未交付阶段dylib。状态与交接同步，最终产品仍未完成。

- API12 Static地址映射源码：基于固定原V3 segment公式分离唯一有界C模块。普通本地fixture和16384组原函数对照通过，真实复现旧span溢出。Linux sanitizer因ptrace/LeakSanitizer环境失败，未标通过；CI保留ASan/UBSan及真实ARM64输入检查。源码待CI验证，不执行Patch写入。

- 5a60d0d首轮API12五job通过；d851ea15新增真实parser的cryptid/section边界用例，Run43678664102五job再次通过。ASan/UBSan、16384组原映射对照/溢出复现、实际ARM64布局输入通过；14份core及3份Probe分析零诊断。Core Artifact14147113395已下载核对ZIP/dylib哈希、39项导出和Mach-O。状态与交接同步；未实际写入Patch、未实机验证、无阶段dylib交付。

- API13源码：不可变Static definition/physical plan，单图像快照/hash，原字节和instruction section验证、同址最大窗口/尾部补齐/variant去重、不同起点冲突及单次direct branch扫描。layout扩展instruction区域避免第二个parser，补section VM/file一致性检查。Linux portable/C地址测试通过；Foundation与ARM64等待CI，不执行文件写入。

- Run43679881569：API13 Probe ARM64编译/分析通过；Foundation计划fixture编译被assert宏中的Objective-C数组字面量逗号阻断。生产代码未放宽检查，测试改用函数封装断言，保留全部用例后重跑。

- 新增256/257逻辑容量边界与hash固定原ZNV3ComposedVariant的独立对照fixture（1000计划/2000变体，显式FileOffset和PreferredVA归一）。仅提取原纯NSData合成函数，不执行原Builder；结果待CI。

- 63f3e06 / Run43679985650五job通过，计划ASan/UBSan与真实ARM64输入通过。3f4c53a8 / Run43680151665加入1000计划/2000原合成结果对照及256/257容量后再次五job通过；15份core及3份Probe分析零诊断，core44/probe45导出/依赖/签名通过。Core Artifact14147852562已下载核对ZIP/dylib哈希、source_head、Mach-O和分析plist。交接/路线/状态同步；尚无emit/write、最终UI或实机验证，未分发阶段dylib。

- ARM64 relocation源码迁移：原字段/范围/terminal算法保留，有界unsigned运算取代负数左移/有符号地址差；PreferredVA用于ADRP，BC.cond明确拒绝。StaticPlan直接branch解码归入同一模块，删除重复实现。Linux普通C的23997个目标保真/边界用例通过；原函数对照、UBSan旧缺陷复现和ARM64构建待CI。

- Run43681820540：ARM64 relocation API14五job通过；23997独立解码目标检查、24000原函数对照、旧负数左移UBSan子进程复现通过。后续加入ADRP encoder和fixture-only StaticCodePayload，复用原布局/格式/fragment/thunk，等待真实ARM64生成代码执行验证；尚未接生产Payload或文件写入。

- Run43682252594：payload测试编译缺少C++ initializer_list头；补显式include，不依赖其他头的偶然包含关系，保留真实执行用例重跑。

- Run43682380848五job通过：真实macOS ARM64生成Dispatch/fragment实际执行OFF=7、shared ON=42/99，1000次切换/恢复和W^X页面通过。继续生产接入Payload与owned-segment图像；审计Apple dyld后补chained starts重建和load-command显式校验，新增真实iOS ARM64输入→签名→dyld_info独立验证，结果待CI。尚未交付或宣称实机。

- Run43682960666：owned图像、重建chained starts、既有签名器、独立codesign/dyld_info验证及宿主真实ARM64切换全部通过，19份分析零诊断。加入离线request/预览/显式review/唯一目录发布；title/group与ID分离，UTF8安全截断，mixed-target拒绝。完整请求/文件发布测试等待CI；不宣称最终UI或设备完成。

- Run43683682500五job通过：离线request完整签名发布、review/cancel/no-overwrite/target拒绝及中文元数据测试通过。将唯一Probe前端迁移为DeveloperMenu四页，接配置store和离线构建request；删除旧Probe源码/构建入口，UI编译/交互等待新CI，游戏ABI仍暂缓。

- Run43684503704五job通过：单一DeveloperMenu四页已实际ARM64编译/签名/静态分析，旧Probe入口删除；UIKit交互仍未验证。增加固定18.5 Simulator App contract、截图和未安装runtime的真实状态记录；将三种目标构建/核心分析收敛为一份显式源清单，并校验实现完整性/对象名唯一。模拟器结果待CI。

- Run43685036578：Core/API16完整构建链及20份分析通过，17项portable检查通过；UI模拟器启动成功但fixture在配置初始草稿处失败。根因为UI对emptyDocument调用禁止空导出的API并忽略nil；改为明确空草稿模板，不放宽空导入/导出清空保护。fixture改用明确非空配置做应用/保存回归，并验证空模板仍被拒绝。新增真实dyld加载准备后macOS ARM64文件的切换/卸载fixture。Core Artifact14149878306已下载核对hash/Mach-O/分析plist，UI结果不伪报通过。

- Run43685791466：真实dyld加载准备后的macOS ARM64文件，OFF=7/ON=42、1000次切换/恢复与卸载通过。Simulator配置应用/拒绝/保存已推进通过，fixture错误地假设document picker一定是最顶层Controller；改为在实际controller树查找并等待存在，失败时保留截图/产物，不删UI断言。Static数值解码沿原算法迁移，Linux普通C覆盖MOVZ/MOVK及512 FP立即数通过；加入固定源对照和sanitizer CI，尚未声明数值控件整合完成。

- Static Number/Slider值单元整合源码：definition显式control/value type，原enum/flag ABI保留；同字节numeric逻辑独立ON片段和RW cell，普通byte变体继续去重。唯一payload requirements驱动owned allocator，删除重复预算计算；UI增加控制/类型选择。新增六种类型实际ARM64执行与隔离/恢复fixture，结果待CI；未声称实际设备数值控件已验证。

- Run43686304743五job通过，Simulator实际完成配置应用/错误拒绝/保存、document picker读取、预览和签名生成、键盘focus/Done、触摸穿透；Artifact14150603385的result.json及截图已下载核对。视觉检查发现选中segment白底白字和弹窗关闭后截图取早；统一选中色、隐藏展开时悬浮按钮，fixture加实际可见性及系统屏幕捕获握手。数值生成采用独立cell并嵌入既有NMBuildManifest完整名称/分组，保留原GeneratedData V1描述表/空ActionHeader契约，未占用reserved。新值单元实际执行结果待CI。

- Run43687721904：numeric/catalog整合在编译阶段暴露strong NSError输出指针不能直接转传autoreleasing参数，改用局部NSError再赋值到collector强输出，保持错误生存期和全部检查；数值实际执行尚未跑到。补回独立三指按住后上下滑呼出/隐藏，使用window手势/Delegate不Swizzle，保留点击悬浮入口；真实三指仍未设备验证。

- 执行环境断开后切换GitHub connector/CI继续，无本地编译能力被伪报。Run43688515706首错为NSError输出空检查；Simulator截图约23秒超过15秒fixture I/O确认。补标准空保护，截图CLI单独限60秒、确认90秒，保留产品交互断言。交接记录最后完整成功546fb05b及未提交Runtime草稿，不把草稿计作完成。

- API19候选：新增进程级NMStaticRuntime及真实ARM64加载fixture，统一prepared Static镜像pin、按物理站点owner-stack、CAS冲突拒绝与typed RW cell更新；值范围转换单一C实现，Slider工厂拒绝非法最大值。Linux portable和普通C值测试通过；本机LSan受ptrace阻断，macOS ASan/UBSan及iOS构建等待CI，不计入已通过。
- Run43768726795首错：iOS18.5公开SDK明确拒绝mach_vm.h。改用现有公开vm_read_overwrite/vm_region_64及对应vm类型，保留内存读取/写权限检查；同步加强源branch、owned RX字节及dispatch模板校验，接入独立Static功能页。等待重跑，不放宽SDK或检查。
- Run43769003422真实ARM64 fixture首错为测试调用NMMachOResolveRange时传NULL输出；该既有API要求两个独立输出。修正fixture及新Runtime校验调用，保持API拒绝规则。新增Simulator实际加载预埋库、UI开关/精确U64输入/恢复断言；补同组共享站点有效状态与整数Slider取整。等待重跑。
- Run43769306253：prepared绑定报Image is not loaded。fixture此前预加载原库以求符号，再加载相同install-name/UUID的预埋副本；不放宽运行时路径身份检查。改为构建时从真实nm符号生成fixture JSON，避免原库先进入dyld；是否解决绑定问题以重跑为准。另补Static键盘高度、逐卡反馈和只读范围检查。
