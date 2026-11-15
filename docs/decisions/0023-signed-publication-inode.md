# 签名发布的文件节点生命周期

证据：09f556ca / Run43772856742 / Developer Artifact14185641183。app阶段记录停在dlopen返回前；prepared的codesign --verify --strict及dyld_info -validate_only均exit0；宿主kernel记录AMFI no CMS / Unrecoverable CT与拒绝offset0页，含wpmapped:1。因此磁盘页hash正确不证明当前vnode可安全立即执行。

源码：NMMachOSigner在私有工作文件MAP_SHARED|PROT_WRITE重建签名，随后hard-link同一个inode为最终输出。发布层不应把有写映射历史的工作节点直接作为可加载结果。保留已经验证的签名/页hash/requirements算法，唯一改动是发布生命周期：私有工作节点签名验证完成→复制到全新未写映射节点→fsync→只读重新解析和校验签名→link独占发布→清理两个临时节点。

不调用私有签名API、不关闭AMFI、不通过外部codesign替换生产算法；不增加旧发布fallback。输入复制与最终复制共用有界read/write helper，保留原文件/现存输出保护及所有失败清理。实际是否消除Simulator拒绝须由后续CI加载证明，不能仅凭理论宣称根因已修复。
