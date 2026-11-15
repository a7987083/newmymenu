# Prepared Static Runtime

入口：NMStaticRuntime.sharedRuntime → refreshLoadedImagesWithError → bindLoadedImageAtPath → setFeature:enabled:value:error:。仅消费本工程生成且已经加载的__NMTEXT/__NMDATA与正式Manifest；没有游戏ABI、IL2CPP调用或Native Hook接入。

一个进程级registry拥有dyld回调、代码镜像pin及最多16个prepared镜像。回调只维护有锁C++清单；绑定使用RTLD_NOLOAD并重新校验身份。镜像pin保持到进程结束；任意业务线程可能正在执行，关闭功能不释放可执行代码，不提供不安全运行时卸载。

单一NSLock串行化受管操作。每个物理站点维护逻辑owner栈，最后启用者生效，关闭栈顶恢复前一owner，全部关闭写0恢复OFF。其他writer不参与本锁；selectedTarget不匹配时拒绝覆盖，CAS失败尽力回滚且不覆盖第三方后续写入。多站点不提供跨外部writer的原子事务保证。外部重新映射、ABA或直接改执行页不在合作域证明内。

数字输入按C locale解析，整数保持精确U64位型；只有显示和Slider范围判断使用double。更新仅对齐RW值单元/目标指针，不写RX页。恢复原始行为不擦除用户上次输入；再次开启沿用当前值。

验证：make test-static-image 后 make test-static-runtime。fixture真实编译、预埋、签名、dlopen、符号调用，检查owner恢复、U64最大值、浮点、Slider、第三方冲突、元数据变更、并发调用。CI未完成前不得标记通过。iOS设备与最终UI未验证。

UI：DeveloperUI/NMStaticControlsView为单一Renderer，使用Runtime快照展示所有者/实际生效/外部冲突；输入与应用在同一卡片，结果反馈按功能ID保留。整数Slider取整，焦点通知交由overlay统一处理键盘可用高度。UI无第二套执行状态。

RW指针CAS避免撕裂和覆盖已观察到的外部变化；生成的普通LDR读路径不提供跨多个站点/值的线性一致性，不能用同一条UI成功提示推导所有并发读者在同一时刻切换。所有可达代码保持pin且不可变，恢复不回收代码。

API20：描述catalog flag必需；full description是唯一文本源，128-byte描述表的120-byte UTF8前缀必须一致。Imported按逻辑patch身份保留独立项，显式group成员按logicalIndex排序，说明取第一成员，与固定原Snapshot行为一致。工厂头/库必须配套。
