// 特权 helper 子进程管理实现。

#include "helper_process.h"

#include <fcntl.h>
#include <poll.h>
#include <pwd.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/wait.h>
#include <unistd.h>

#include <cerrno>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>

namespace helper {

namespace {

/// 把 C++ 字符串数组转换为 execv 需要的 char* 数组（末尾 nullptr 终止）。
std::unique_ptr<char*[]> toCStringArray(const std::vector<std::string>& items) {
  auto array = std::make_unique<char*[]>(items.size() + 1);
  for (size_t i = 0; i < items.size(); ++i) {
    array[i] = const_cast<char*>(items[i].c_str());
  }
  array[items.size()] = nullptr;
  return array;
}

/// 关闭 [from, to) 区间内除 [keep] 外的描述符，防止控制通道泄漏给 ll-cli。
void closeRangeExcept(int from, int to, int keep) {
  for (int fd = from; fd < to; ++fd) {
    if (fd != keep) {
      close(fd);
    }
  }
}

}  // namespace

std::vector<std::string> buildChildEnvironment() {
  std::vector<std::string> env;
  env.reserve(7);
  env.emplace_back("LC_ALL=C.UTF-8");
  env.emplace_back("LANG=C.UTF-8");
  env.emplace_back("PATH=/usr/sbin:/usr/bin:/sbin:/bin");
  // root 的 HOME/USER/LOGNAME 取自账户数据库，而不是继承调用方环境（§7）。
  if (const passwd* root = getpwuid(0)) {
    env.push_back(std::string("HOME=") +
                  (root->pw_dir != nullptr ? root->pw_dir : "/root"));
    env.push_back(std::string("USER=") +
                  (root->pw_name != nullptr ? root->pw_name : "root"));
    env.push_back(std::string("LOGNAME=") +
                  (root->pw_name != nullptr ? root->pw_name : "root"));
  }
  return env;
}

bool ChildProcess::spawn(const std::vector<std::string>& argv,
                         const std::vector<std::string>& env) {
  // 初始化为 -1：pipe() 失败时其余组的值未定义，统一按“无效则跳过”兜底。
  int stdoutPipe[2] = {-1, -1};
  int stderrPipe[2] = {-1, -1};
  int execFailPipe[2] = {-1, -1};
  if (pipe(stdoutPipe) != 0 || pipe(stderrPipe) != 0 ||
      pipe(execFailPipe) != 0) {
    for (int fd :
         {stdoutPipe[0], stdoutPipe[1], stderrPipe[0], stderrPipe[1],
          execFailPipe[0], execFailPipe[1]}) {
      if (fd >= 0) {
        close(fd);
      }
    }
    return false;
  }

  const pid_t parentPid = getpid();
  const pid_t child = fork();
  if (child < 0) {
    for (int fd :
         {stdoutPipe[0], stdoutPipe[1], stderrPipe[0], stderrPipe[1],
          execFailPipe[0], execFailPipe[1]}) {
      close(fd);
    }
    return false;
  }
  if (child == 0) {
    // ---- 子进程：设置父死亡信号并封住“父进程先退出、子进程后设置”竞态 ----
    prctl(PR_SET_PDEATHSIG, SIGTERM);
    if (getppid() != parentPid) {
      _exit(126);
    }
    // exec 失败通知写端带 CLOEXEC：exec 成功时自动关闭（读端读到 EOF），
    // exec 失败时仍打开，可以写入失败标志。
    fcntl(execFailPipe[1], F_SETFD, FD_CLOEXEC);

    const int devnull = open("/dev/null", O_RDONLY);
    // ll-cli stdin 固定接 /dev/null，绝不继承 helper 的控制通道（§6.1）。
    if (devnull < 0 || dup2(devnull, STDIN_FILENO) < 0 ||
        dup2(stdoutPipe[1], STDOUT_FILENO) < 0 ||
        dup2(stderrPipe[1], STDERR_FILENO) < 0) {
      _exit(127);
    }
    close(devnull);
    close(stdoutPipe[0]);
    close(stderrPipe[0]);
    close(execFailPipe[0]);
    closeRangeExcept(3, 1024, execFailPipe[1]);
    if (chdir("/") != 0) {
      _exit(127);
    }
    auto argvArray = toCStringArray(argv);
    auto envArray = toCStringArray(env);
    execv(argv[0].c_str(), argvArray.get());
    // exec 失败：写标志通知父进程（收割时把 127 判定为 spawnFailed）。
    const uint8_t flag = 1;
    const ssize_t written = write(execFailPipe[1], &flag, 1);
    (void)written;
    _exit(127);
  }

  // ---- 父进程 ----
  close(stdoutPipe[1]);
  close(stderrPipe[1]);
  close(execFailPipe[1]);
  pid = child;
  stdoutFd = stdoutPipe[0];
  stderrFd = stderrPipe[0];
  execFailFd_ = execFailPipe[0];
  return true;
}

void ChildProcess::sendSignal(int sig) {
  if (pid > 0) {
    kill(pid, sig);
  }
}

bool ChildProcess::tryReap(int& exitCode, bool& execFailed) {
  execFailed = false;
  if (reaped_ || pid <= 0) {
    return false;
  }
  int status = 0;
  const pid_t result = waitpid(pid, &status, WNOHANG);
  if (result == 0) {
    return false;
  }
  if (result < 0) {
    if (errno == EINTR) {
      return false;
    }
    // ECHILD：已被其他路径收割（不应发生），按未知退出收尾避免主循环悬挂。
    reaped_ = true;
    closeFds();
    exitCode = -1;
    return true;
  }
  reaped_ = true;
  if (WIFEXITED(status)) {
    exitCode = WEXITSTATUS(status);
  } else if (WIFSIGNALED(status)) {
    // 信号终止统一映射为 128+signo，与 shell 惯例一致；GUI 只透传该值。
    exitCode = 128 + WTERMSIG(status);
  } else {
    exitCode = -1;
  }
  // exec 失败确认：写标志说明 execv 从未成功，127 不是 ll-cli 的真实退出码。
  if (exitCode == 127) {
    uint8_t flag = 0;
    execFailed = (read(execFailFd_, &flag, 1) == 1 && flag == 1);
  }
  closeFds();
  return true;
}

bool ChildProcess::waitReap(int& exitCode, int timeoutMs) {
  // SIGTERM 后的协作退出窗口：轮询 waitpid，超时由调用方升级 SIGKILL（§8）。
  const int stepMs = 50;
  for (int waited = 0; waited < timeoutMs; waited += stepMs) {
    bool execFailed = false;
    if (tryReap(exitCode, execFailed)) {
      return true;
    }
    poll(nullptr, 0, stepMs);
  }
  return false;
}

void ChildProcess::closeFds() {
  for (int* fd : {&stdoutFd, &stderrFd, &execFailFd_}) {
    if (*fd >= 0) {
      close(*fd);
      *fd = -1;
    }
  }
}

ChildProcess::~ChildProcess() {
  // 兜底：未收割的子进程按 5 秒协作窗口收尾后强杀回收（§8/§9.3）。
  if (!reaped_ && pid > 0) {
    int exitCode = 0;
    bool execFailed = false;
    if (!tryReap(exitCode, execFailed)) {
      sendSignal(SIGTERM);
      if (!waitReap(exitCode, 5000)) {
        sendSignal(SIGKILL);
        waitReap(exitCode, 2000);
      }
    }
  }
  closeFds();
}

}  // namespace helper
