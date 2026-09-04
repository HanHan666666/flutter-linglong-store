// 特权 helper 的 ll-cli 子进程管理（docs/47 §7/§9.3）。
//
// 只用 fork/execv 构造固定 argv，绝不经由 shell；子进程环境从空白白名单
// 构造，stdin 接 /dev/null，stdout/stderr 由 helper 捕获。父死亡信号在
// fork 后、exec 前于子进程内设置，并复查父 PID 封住竞态（§9.3）。
#ifndef LINGLONG_STORE_HELPER_PROCESS_H_
#define LINGLONG_STORE_HELPER_PROCESS_H_

#include <sys/types.h>

#include <string>
#include <vector>

namespace helper {

/// helper 管理的一个 ll-cli 子进程。
class ChildProcess {
 public:
  ChildProcess() = default;
  ChildProcess(const ChildProcess&) = delete;
  ChildProcess& operator=(const ChildProcess&) = delete;

  ~ChildProcess();

  /// 子进程 PID；未启动时无效。
  pid_t pid = -1;

  /// 子进程 stdout/stderr 的读取端（close-on-exec 已解除，由 helper 持有）。
  int stdoutFd = -1;
  int stderrFd = -1;

  /// fork/execv 启动子进程。
  ///
  /// [argv] 已通过白名单构造，argv[0] 固定为 /usr/bin/ll-cli；
  /// [env] 为 KEY=VALUE 白名单环境；工作目录固定为 `/`。
  /// 启动成功返回 true；exec 失败通过内部 exec-fail 管道在首次收割时暴露。
  bool spawn(const std::vector<std::string>& argv,
             const std::vector<std::string>& env);

  /// 向精确子进程发送信号。只作用于自己创建的 PID（§11 第 8 条）。
  void sendSignal(int sig);

  /// 非阻塞收割：子进程已退出时返回 true 并写入退出码，同时关闭残留管道。
  /// exec 失败（127 经 exec-fail 管道确认）时 [execFailed] 置 true。
  bool tryReap(int& exitCode, bool& execFailed);

  /// 阻塞收割并写入退出码，最长等待 [timeoutMs]；超时返回 false（进程仍在）。
  bool waitReap(int& exitCode, int timeoutMs);

  /// 关闭全部持有的管道描述符（子进程退出后调用；重复调用安全）。
  void closeFds();

 private:
  /// exec 失败通知管道；exec 成功时写端被 CLOEXEC 自动关闭，读端永无可读。
  int execFailFd_ = -1;
  bool reaped_ = false;
};

/// 构造 ll-cli 的白名单环境（§7）：
/// LC_ALL/LANG=C.UTF-8、固定 PATH，以及 getpwuid(0) 的 root HOME/USER/LOGNAME。
/// 不透传 helper/GUI 继承的任何其他变量。
std::vector<std::string> buildChildEnvironment();

}  // namespace helper

#endif  // LINGLONG_STORE_HELPER_PROCESS_H_
