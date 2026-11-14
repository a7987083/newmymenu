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
