# 路线与验收

1. 进行中：补齐53项功能真实调用链、传递依赖及弱锚点；确认全部必要 Swizzle target/selector/types/顺序/最终IMP。验收：没有把库存当已完成审计。
2. 完成审计后定稿设计：UI单Renderer、ReceiverLease、必要外部Swizzle管理器、Native teardown策略。
3. 按模块迁移：先独立模型/翻译/ABI与fixture，再发现/搜索/Invoke，再UI，再Hook/Build。每模块单独编译测试提交，不复制整个旧工程。
4. CI：实际执行Runtime实验；业务迁移后增加对应fixture和ARM64产品构建。审计夹具不计产品构建成功。
5. 功能对照回归与最终技术债审计；实机验证由真实设备完成，未执行不填通过。
6. 生成匹配源码HEAD的最终dylib、SHA256、依赖/签名/符号报告及Release。
