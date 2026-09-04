// 特权 root helper 主程序（docs/47 §7/§9）。
//
// 运行形态：由 GUI 通过 `pkexec --disable-internal-agent <helper>` 启动，
// 以 root 身份在同一进程内串行启动 /usr/bin/ll-cli；GUI 与 helper 之间
// 只使用继承的父子 stdin/stdout NDJSON 通道，不监听任何 Socket。
//
// 生命周期约束（§9.3）：
// - stdin EOF、SIGTERM/SIGINT、空闲 5 分钟 → 协作取消当前任务后退出；
// - GUI 被杀时依赖 PR_SET_PDEATHSIG 与 stdin EOF 双路径收尾；
// - helper 自身崩溃时，ll-cli 子进程自身的父死亡信号兜底回收。

#include <fcntl.h>
#include <poll.h>
#include <pwd.h>
#include <signal.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <string>
#include <vector>

#include "helper_process.h"
#include "helper_protocol.h"
#include "helper_task_runner.h"

namespace {

/// 单条 GUI 请求上限（§6.2）。
constexpr size_t kMaxRequestLineBytes = 16 * 1024;
/// 单行 ll-cli 输出上限（§6.2）。
constexpr size_t kMaxOutputLineBytes = 1024 * 1024;
/// 空闲退出窗口（§9.2）。
constexpr int kIdleTimeoutMs = 5 * 60 * 1000;
/// 双侧输出管道 EOF 后等待 waitpid 可收割的轮询间隔。
constexpr int kAwaitReapPollMs = 200;

/// 启动检查失败的退出码段，便于 GUI 日志区分诊断（§13.3 真机验收）。
constexpr int kExitNotRoot = 10;
constexpr int kExitBadPkexecUid = 11;
constexpr int kExitBadLlCli = 12;
constexpr int kExitBadStdio = 13;

/// 信号自管管道：handler 只做 write，主循环在 poll 中统一消费（异步信号安全）。
int gSignalPipe[2] = {-1, -1};

void handleStopSignal(int) {
  const uint8_t flag = 1;
  const ssize_t written = write(gSignalPipe[1], &flag, 1);
  (void)written;
}

/// 有上限的按行分帧器：一次喂数据，返回完整行；单行超限置 overflow。
class LineAssembler {
 public:
  explicit LineAssembler(size_t maxBytes) : maxBytes_(maxBytes) {}

  /// 喂入一次 read 的原始数据，返回切分出的完整行（不含换行符）。
  std::vector<std::string> feed(const char* data, size_t length) {
    std::vector<std::string> lines;
    for (size_t i = 0; i < length; ++i) {
      if (data[i] == '\n') {
        flushLine(lines);
        continue;
      }
      buffer_.push_back(data[i]);
      if (buffer_.size() > maxBytes_) {
        overflow_ = true;
      }
    }
    return lines;
  }

  /// 流结束时取出未带换行的尾部数据（可能为空）。
  std::string takeRemainder() {
    std::vector<std::string> lines;
    flushLine(lines);
    return lines.empty() ? std::string() : std::move(lines.front());
  }

  bool overflow() const { return overflow_; }

 private:
  void flushLine(std::vector<std::string>& lines) {
    if (buffer_.size() > maxBytes_) {
      overflow_ = true;
    }
    lines.push_back(std::move(buffer_));
    buffer_.clear();
  }

  size_t maxBytes_;
  std::string buffer_;
  bool overflow_ = false;
};

/// 单调时钟毫秒：空闲计时不受系统时间跳变影响。
int64_t nowMs() {
  struct timespec ts {};
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return static_cast<int64_t>(ts.tv_sec) * 1000 + ts.tv_nsec / 1000000;
}

bool isFifo(int fd) {
  struct stat st {};
  return fstat(fd, &st) == 0 && S_ISFIFO(st.st_mode);
}

/// §7 启动检查 2：PKEXEC_UID 必须存在且是合法普通用户。
bool checkPkexecUid() {
  const char* raw = getenv("PKEXEC_UID");
  if (raw == nullptr || *raw == '\0') {
    return false;
  }
  // 只接受纯数字，排除 "0"、"1x"、负数与溢出写法。
  for (const char* p = raw; *p != '\0'; ++p) {
    if (*p < '0' || *p > '9') {
      return false;
    }
  }
  errno = 0;
  char* end = nullptr;
  const unsigned long value = strtoul(raw, &end, 10);
  if (errno != 0 || end == nullptr || *end != '\0' || value == 0 ||
      value > 0xFFFFFFFFUL) {
    return false;
  }
  // 必须是真实存在的非 root 账户，拒绝凭空 UID 与手工直跑场景。
  return getpwuid(static_cast<uid_t>(value)) != nullptr;
}

/// §7 启动检查 3：/usr/bin/ll-cli 是普通文件且不允许 group/other 写入。
bool checkLlCliBinary() {
  struct stat st {};
  if (stat("/usr/bin/ll-cli", &st) != 0 || !S_ISREG(st.st_mode)) {
    return false;
  }
  return (st.st_mode & (S_IWGRP | S_IWOTH)) == 0;
}

/// 会话状态：一次只允许一个 ll-cli 子进程（§8.1）。
struct HelperSession {
  helper::ChildProcess child;
  helper::HelperTaskRunner runner;
  bool childStdoutOpen = false;
  bool childStderrOpen = false;
  int64_t idleSinceMs = 0;
};

/// 写一行协议事件到 stdout；GUI 已断开（EPIPE）时返回 false，由调用方决定
/// 是否继续。写失败不置错误文案，避免把正常断开误报为故障。
bool writeEventLine(const std::string& line) {
  size_t offset = 0;
  while (offset < line.size()) {
    const ssize_t written =
        write(STDOUT_FILENO, line.data() + offset, line.size() - offset);
    if (written < 0) {
      if (errno == EINTR) {
        continue;
      }
      return false;
    }
    offset += static_cast<size_t>(written);
  }
  return true;
}

/// 收割当前子进程并发送终态事件（exited 或 spawnFailed），回到 idle。
void reapCurrentTask(HelperSession& session, LineAssembler& stdoutLines,
                     LineAssembler& stderrLines) {
  const std::string requestId = session.runner.currentRequestId();
  int exitCode = -1;
  bool execFailed = false;
  if (!session.child.tryReap(exitCode, execFailed)) {
    // 正常路径下管道 EOF 与进程退出几乎同时发生；双关闭但未退出时由
    // 主循环短轮询重试，这里不再阻塞。
    fprintf(stderr, "helper: reap pending for %s\n", requestId.c_str());
    return;
  }
  fprintf(stderr, "helper: reaped %s code=%d execFailed=%d\n",
          requestId.c_str(), exitCode, execFailed ? 1 : 0);
  if (execFailed) {
    // exec 失败：任务从未真正启动，按 spawnFailed 汇报且不发送 exited。
    writeEventLine(helper::encodeError(&requestId,
                                       helper::kErrorCodeSpawnFailed,
                                       "failed to exec /usr/bin/ll-cli",
                                       false));
  } else {
    writeEventLine(
        helper::encodeExited(requestId, exitCode, session.runner.cancelRequested()));
  }
  session.runner.finishCurrent();
  stdoutLines = LineAssembler(kMaxOutputLineBytes);
  stderrLines = LineAssembler(kMaxOutputLineBytes);
  session.idleSinceMs = nowMs();
}

/// 终止当前任务并等待回收；5 秒协作窗口后 SIGKILL（§8）。
/// 该路径用于收尾（GUI 离开/信号/致命错误），结果无人接收，不发事件。
void terminateCurrentTask(HelperSession& session) {
  if (session.runner.isIdle()) {
    return;
  }
  int exitCode = 0;
  bool execFailed = false;
  if (!session.child.tryReap(exitCode, execFailed)) {
    session.child.sendSignal(SIGTERM);
    if (!session.child.waitReap(exitCode, 5000)) {
      session.child.sendSignal(SIGKILL);
      session.child.waitReap(exitCode, 2000);
    }
  }
  session.runner.finishCurrent();
}

}  // namespace

int main() {
  // 忽略 SIGPIPE：stdout 写向已退出的 GUI 时按写失败处理，而不是被信号杀死。
  signal(SIGPIPE, SIG_IGN);

  // ---- §7 启动检查：任一失败都在建立业务会话前退出，不降级执行 ----
  if (geteuid() != 0) {
    fprintf(stderr, "helper: refusing to run as non-root\n");
    return kExitNotRoot;
  }
  if (!checkPkexecUid()) {
    fprintf(stderr, "helper: PKEXEC_UID missing or invalid\n");
    return kExitBadPkexecUid;
  }
  if (!checkLlCliBinary()) {
    fprintf(stderr,
            "helper: /usr/bin/ll-cli missing or writable by group/other\n");
    return kExitBadLlCli;
  }
  if (!isFifo(STDIN_FILENO) || !isFifo(STDOUT_FILENO)) {
    fprintf(stderr, "helper: stdin/stdout must be pipes\n");
    return kExitBadStdio;
  }
  // 父进程（pkexec 中继）已退出时 getppid 变为 1：立即退出，避免孤儿 helper
  // 持有 root 会话（§9.3）。
  if (getppid() == 1) {
    fprintf(stderr, "helper: parent already exited\n");
    return kExitBadStdio;
  }
  prctl(PR_SET_PDEATHSIG, SIGTERM);
  if (getppid() == 1) {
    // prctl 与父进程退出存在竞态，设置后必须复查（§9.3）。
    fprintf(stderr, "helper: parent exited during setup\n");
    return kExitBadStdio;
  }

  if (pipe(gSignalPipe) != 0) {
    fprintf(stderr, "helper: signal pipe creation failed\n");
    return kExitBadStdio;
  }
  fcntl(gSignalPipe[0], F_SETFD, FD_CLOEXEC);
  fcntl(gSignalPipe[1], F_SETFD, FD_CLOEXEC);
  struct sigaction action {};
  action.sa_handler = handleStopSignal;
  sigemptyset(&action.sa_mask);
  sigaction(SIGTERM, &action, nullptr);
  sigaction(SIGINT, &action, nullptr);

  HelperSession session;
  LineAssembler requestLines(kMaxRequestLineBytes);
  LineAssembler childStdoutLines(kMaxOutputLineBytes);
  LineAssembler childStderrLines(kMaxOutputLineBytes);
  bool stdinOpen = true;

  if (!writeEventLine(helper::encodeReady())) {
    fprintf(stderr, "helper: ready write failed\n");
    return kExitBadStdio;
  }
  session.idleSinceMs = nowMs();
  const std::vector<std::string> childEnv = helper::buildChildEnvironment();

  bool stopping = false;
  while (!stopping) {
    // ---- 双侧管道已关闭但尚未收割：短轮询等待 waitpid 可回收 ----
    if (!session.runner.isIdle() && !session.childStdoutOpen &&
        !session.childStderrOpen) {
      reapCurrentTask(session, childStdoutLines, childStderrLines);
    }

    struct pollfd fds[5];
    nfds_t fdCount = 0;
    const auto addFd = [&fds, &fdCount](int fd, short events) {
      fds[fdCount].fd = fd;
      fds[fdCount].events = events;
      fds[fdCount].revents = 0;
      ++fdCount;
    };
    if (stdinOpen) {
      addFd(STDIN_FILENO, POLLIN);
    }
    addFd(gSignalPipe[0], POLLIN);
    if (!session.runner.isIdle()) {
      if (session.childStdoutOpen) {
        addFd(session.child.stdoutFd, POLLIN);
      }
      if (session.childStderrOpen) {
        addFd(session.child.stderrFd, POLLIN);
      }
    }

    // 空闲按剩余窗口阻塞；等待收割按短轮询；其余（任务运行）无限阻塞。
    int timeoutMs = -1;
    if (session.runner.isIdle()) {
      const int64_t remaining =
          kIdleTimeoutMs - (nowMs() - session.idleSinceMs);
      timeoutMs = remaining > 0 ? static_cast<int>(remaining) : 0;
    } else if (!session.childStdoutOpen && !session.childStderrOpen) {
      timeoutMs = kAwaitReapPollMs;
    }
    const int readyCount = poll(fds, fdCount, timeoutMs);
    if (readyCount < 0 && errno != EINTR) {
      fprintf(stderr, "helper: poll error, stopping\n");
      stopping = true;
      break;
    }

    const auto wasReady = [&fds, fdCount](int fd) {
      for (nfds_t i = 0; i < fdCount; ++i) {
        if (fds[i].fd == fd) {
          return fds[i].revents != 0;
        }
      }
      return false;
    };

    // ---- 空闲超时（§9.2）：任务耗时计入活跃期，不占空闲窗口 ----
    if (session.runner.isIdle() &&
        nowMs() - session.idleSinceMs >= kIdleTimeoutMs) {
      fprintf(stderr, "helper: idle timeout, stopping\n");
      stopping = true;
      break;
    }

    // ---- 停止信号：停止接收请求，进入收尾 ----
    if (wasReady(gSignalPipe[0])) {
      fprintf(stderr, "helper: stop signal, stopping\n");
      stopping = true;
      break;
    }

    // ---- 子进程输出：逐行转发为 output 事件 ----
    if (!session.runner.isIdle() && !stopping) {
      const std::string requestId = session.runner.currentRequestId();
      char chunk[4096];
      const auto drainChild = [&](int fd, bool isStderr,
                                  LineAssembler& assembler, bool& open) {
        if (!open || !wasReady(fd)) {
          return;
        }
        const ssize_t n = read(fd, chunk, sizeof(chunk));
        if (n <= 0) {
          // EOF：转发不带换行的尾部数据后关闭本侧。
          open = false;
          const std::string tail = assembler.takeRemainder();
          if (!tail.empty()) {
            writeEventLine(helper::encodeOutput(requestId, isStderr, tail));
          }
          return;
        }
        for (const std::string& line : assembler.feed(chunk, n)) {
          writeEventLine(helper::encodeOutput(requestId, isStderr, line));
        }
        if (assembler.overflow()) {
          // §6.2：单行超 1 MiB 属传输失败，终止任务后退出。
          writeEventLine(helper::encodeError(
              &requestId, helper::kErrorCodeOutputTooLarge,
              "ll-cli output line exceeds 1 MiB", true));
          terminateCurrentTask(session);
          stopping = true;
        }
      };
      drainChild(session.child.stdoutFd, false, childStdoutLines,
                 session.childStdoutOpen);
      drainChild(session.child.stderrFd, true, childStderrLines,
                 session.childStderrOpen);
      // 单侧 EOF 不收割；双侧 EOF 由下一轮循环顶部的 reap 统一处理。
    }

    // ---- GUI 请求 ----
    if (stdinOpen && !stopping && wasReady(STDIN_FILENO)) {
      char chunk[4096];
      const ssize_t n = read(STDIN_FILENO, chunk, sizeof(chunk));
      if (n <= 0) {
        // stdin EOF：GUI 已离开，停止接收请求并收尾（§9.3）。
        stdinOpen = false;
        fprintf(stderr, "helper: stdin EOF, stopping\n");
        stopping = true;
        break;
      }
      for (std::string& rawLine : requestLines.feed(chunk, n)) {
        if (!rawLine.empty() && rawLine.back() == '\r') {
          rawLine.pop_back();
        }
        const helper::ParseResult parsed = helper::parseRequestLine(rawLine);
        if (parsed.status == helper::ParseStatus::kFatal) {
          writeEventLine(helper::encodeError(nullptr, parsed.errorCode.c_str(),
                                             parsed.errorMessage, true));
          stopping = true;
          break;
        }
        switch (parsed.request.type) {
          case helper::RequestType::kStart: {
            if (!session.runner.isIdle()) {
              // §8.1：串行约束的最后防线，仅拒绝本请求，会话继续。
              writeEventLine(
                  helper::encodeError(&parsed.request.requestId,
                                      helper::kErrorCodeBusy,
                                      "another task is running", false));
              break;
            }
            helper::TaskSpec spec;
            spec.requestId = parsed.request.requestId;
            spec.operation = parsed.request.operation;
            spec.appId = parsed.request.appId;
            spec.version = parsed.request.version;
            spec.force = parsed.request.force;
            const std::vector<std::string> argv =
                helper::HelperTaskRunner::buildArgv(spec);
            if (!session.child.spawn(argv, childEnv)) {
              writeEventLine(
                  helper::encodeError(&spec.requestId,
                                      helper::kErrorCodeSpawnFailed,
                                      "fork failed", false));
              break;
            }
            session.childStdoutOpen = true;
            session.childStderrOpen = true;
            childStdoutLines = LineAssembler(kMaxOutputLineBytes);
            childStderrLines = LineAssembler(kMaxOutputLineBytes);
            session.runner.begin(std::move(spec));
            writeEventLine(
                helper::encodeStarted(session.runner.currentRequestId(),
                                      static_cast<int>(session.child.pid)));
            break;
          }
          case helper::RequestType::kCancel: {
            if (session.runner.decideCancel(parsed.request.requestId) ==
                helper::CancelDecision::kNotRunning) {
              writeEventLine(
                  helper::encodeError(&parsed.request.requestId,
                                      helper::kErrorCodeNotRunning,
                                      "no matching running task", false));
              break;
            }
            // 只允许 SIGTERM 协作取消（§8.2）：ll-cli 的 handler 会触发 daemon
            // Task.Cancel()，绝不直接杀 daemon。
            session.child.sendSignal(SIGTERM);
            session.runner.markCancelRequested();
            writeEventLine(
                helper::encodeCancelAccepted(parsed.request.requestId));
            break;
          }
          case helper::RequestType::kShutdown: {
            // shutdown 只在空闲时生效；任务运行中忽略（GUI 按空闲窗口调用）。
            if (session.runner.isIdle()) {
              stopping = true;
            } else {
              fprintf(stderr, "helper: shutdown ignored while task running\n");
            }
            break;
          }
        }
        if (stopping) {
          break;
        }
      }
      if (requestLines.overflow()) {
        writeEventLine(
            helper::encodeError(nullptr, helper::kErrorCodeInvalidRequest,
                                "request line exceeds 16 KiB", true));
        stopping = true;
      }
    }
  }

  // ---- 收尾：协作取消当前任务后退出（§9.3）----
  terminateCurrentTask(session);
  return 0;
}
