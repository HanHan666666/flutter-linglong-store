/// 特权 helper 来源信任解析器（docs/51）。
///
/// 返回 true 表示当前运行 bundle 可证明由系统包管理器（dpkg/rpm/pacman）安装，
/// helper 位于 root 属主安装树内、不可被当前用户替换，允许使用特权 helper；
/// 返回 false 表示无法证明来源可信，调用方必须回退普通用户直连路径。
///
/// 解析需要探测包管理器归属（可能启动系统命令），因此是异步；Data 层在任务
/// 启动时解析一次并绑定到该任务；解析失败必须按不可信处理，不得失败开放。
typedef PrivilegedHelperTrustResolver = Future<bool> Function();
