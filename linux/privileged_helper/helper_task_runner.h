// 特权 helper 串行任务状态机（docs/47 §8.1）。
//
// 只维护 idle/running(requestId) 两种任务状态，并把类型化请求转换成固定
// argv 模板；不负责 fork/exec 与信号发送（见 helper_process）。拆分的目的是
// 让“白名单 argv 构造”和“串行/busy 判定”可以独立单测（§13.2）。
#ifndef LINGLONG_STORE_HELPER_TASK_RUNNER_H_
#define LINGLONG_STORE_HELPER_TASK_RUNNER_H_

#include <string>
#include <vector>

#include "helper_protocol.h"

namespace helper {

/// 一个待执行任务的类型化描述（已通过协议校验）。
struct TaskSpec {
  std::string requestId;
  HelperOperation operation = HelperOperation::kInstall;
  std::string appId;
  std::string version;
  bool force = false;
};

/// cancel 请求的判定结果。
enum class CancelDecision {
  /// requestId 命中当前任务，调用方应发送 SIGTERM。
  kAccepted,
  /// 没有运行中的任务或 requestId 不匹配。
  kNotRunning,
};

/// 串行任务状态机。所有方法同步、无 IO，可重入判定。
class HelperTaskRunner {
 public:
  /// 按白名单模板构造 ll-cli argv（§7）。
  ///
  /// update 请求映射为 `upgrade` 子命令（§5.1）；install 仅在显式 version 时
  /// 拼 `appId/version`，force 只对 install 追加 `--force`。请求内容不可能
  /// 出现在模板的其他位置。
  static std::vector<std::string> buildArgv(const TaskSpec& spec);

  HelperTaskRunner() = default;

  /// 当前是否空闲（可接受新 start）。
  bool isIdle() const { return current_.empty(); }

  /// 当前运行中任务的 requestId；空闲时为空。
  const std::string& currentRequestId() const { return current_; }

  /// 登记新任务。调用方必须先确认 isIdle()（否则属于协议层 busy 缺陷）。
  void begin(TaskSpec spec);

  /// cancel 判定：只有“自己创建且仍登记为 current”的任务可被取消（§6.4）。
  CancelDecision decideCancel(const std::string& requestId) const;

  /// 标记当前任务已请求取消（收到 cancelAccepted 后调用）。
  void markCancelRequested() { cancelRequested_ = true; }

  /// 是否已对当前任务请求过取消（exited 事件需要携带该事实）。
  bool cancelRequested() const { return cancelRequested_; }

  /// 当前任务的完整描述。
  const TaskSpec& currentSpec() const { return spec_; }

  /// 子进程被真实回收后清空状态，回到 idle。
  void finishCurrent();

 private:
  std::string current_;
  TaskSpec spec_;
  bool cancelRequested_ = false;
};

}  // namespace helper

#endif  // LINGLONG_STORE_HELPER_TASK_RUNNER_H_
