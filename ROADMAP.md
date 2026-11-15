# 后续工作与验收

1. 完成API19 loaded Static Runtime及UI集成CI。真实ARM64 fixture必须通过owner栈恢复、同组同站点、精确U64、浮点、Slider、冲突、元数据变化和并发调用；Simulator必须实际加载预埋库并由UI改变返回值。不能只以编译成功验收。
2. 复核Simulator截图、焦点/键盘与页面布局；补适用的Finder/功能状态及窗口生命周期回归。真实iOS旋转、多窗口、前后台和加载不由Simulator静态截图代替。
3. 对新仓库做最终技术债复审：单一执行入口、状态所有者、未使用路径、ABI/IMP转换、锁/重入/镜像与对象生命周期、失败释放。删除有证据的废代码，不把必要但未迁移的能力当无用代码。
4. 汇总回归矩阵和源码/二进制/CI一致性报告，整理Release候选、Artifact、SHA256、Mach-O/依赖/签名及设备验证单。用户只收最终整合候选，不收阶段产物。
5. 游戏ABI工作保持暂缓：待用户恢复范围后，以同版本真实二进制和运行证据接入IL2CPP Invoke/GCHandle、ByRef/复杂结构、多实例执行和Native/Prepared Hook；不猜MethodInfo布局或把DobbyDestroy当在途排空证明。

已完成的基础与离线模块包括翻译、ordinal codec、显式执行/捕获契约、只读元数据、Finder状态与呈现、Manifest、配置、签名、地址/重定位/物理计划、Static emission与事务式离线发布、统一SwizzleManager。每项证据以docs/builds、实际Git/CI为准；“组件通过”不能升级为原53项功能全部对等。
