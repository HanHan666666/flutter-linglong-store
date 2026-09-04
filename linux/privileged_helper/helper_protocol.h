// 特权 helper 协议层：NDJSON 请求解析与事件编码（docs/47 §6）。
//
// 本文件只做纯数据转换与校验，不做任何 IO；主循环与任务执行器通过这里的
// 类型安全接口交互，保证「先校验、后建子进程」的顺序（§11 第 7 条）。
// 校验失败分为两类：致命错误（invalidRequest/protocolMismatch，必须关闭通道）
// 与可恢复错误（busy/notRunning，仅拒绝当前请求）。
#ifndef LINGLONG_STORE_HELPER_PROTOCOL_H_
#define LINGLONG_STORE_HELPER_PROTOCOL_H_

#include <string>
#include <vector>

namespace helper {

/// GUI 请求类型白名单（§5.1）。枚举值不落盘、不跨版本，仅进程内使用。
enum class RequestType {
  kStart,
  kCancel,
  kShutdown,
};

/// start 请求的业务操作。协议名 update 对应 ll-cli 子命令 upgrade（§5.1）。
enum class HelperOperation {
  kInstall,
  kUpdate,
};

/// 解析后的类型化请求。字段只在 type 对应的场景下有效。
struct HelperRequest {
  RequestType type = RequestType::kShutdown;
  std::string requestId;
  HelperOperation operation = HelperOperation::kInstall;
  std::string appId;
  std::string version;
  bool force = false;
};

/// 请求解析结果分类。
enum class ParseStatus {
  /// 解析成功，request 字段有效。
  kOk,
  /// 致命协议错误：发送 error 事件后必须退出（invalidRequest/protocolMismatch）。
  kFatal,
};

/// 单条请求的解析结果。kFatal 时 error_code/error_message 供 error 事件使用。
struct ParseResult {
  ParseStatus status = ParseStatus::kOk;
  HelperRequest request;
  std::string errorCode;
  std::string errorMessage;
};

/// requestId 合法字符集：ASCII 字母、数字、`.`、`_`、`-`，长度 1~128 字节（§6.3）。
bool isValidRequestId(const std::string& value);

/// appId 合法字符集：ASCII 字母、数字、`.`、`_`、`-`，长度 1~255 字节，
/// 天然排除 `/`、`:`、空白与控制字符（§6.3）。
bool isValidAppId(const std::string& value);

/// version 合法字符集：ASCII 字母、数字、`.`、`_`、`+`、`~`、`-`，1~128 字节。
bool isValidVersion(const std::string& value);

/// 解析一行 NDJSON 请求。
///
/// 严格按 §6.2/§6.3 校验：v 必须是整数 1；未知 type、字段类型错误、多余字段、
/// 非法字符集与超长字段一律 kFatal(invalidRequest)。JSON 本身解析失败同样致命。
ParseResult parseRequestLine(const std::string& line);

/// 编码 ready 事件：helper 已通过 §7 全部启动检查。
std::string encodeReady();

/// 编码 started 事件：ll-cli 子进程已创建；pid 仅作诊断字段，客户端不得保存。
std::string encodeStarted(const std::string& requestId, int pid);

/// 编码 output 事件：一行 ll-cli 原始输出，stream 为 true 表示 stderr。
std::string encodeOutput(const std::string& requestId, bool stderrStream,
                         const std::string& line);

/// 编码 cancelAccepted 事件：SIGTERM 已发出或任务正处于退出过程。
std::string encodeCancelAccepted(const std::string& requestId);

/// 编码 exited 事件：子进程已被 waitpid 真实回收。
std::string encodeExited(const std::string& requestId, int exitCode,
                         bool cancelRequested);

/// 编码 error 事件。requestId 为 nullptr 时省略该字段（会话级错误）。
std::string encodeError(const std::string* requestId, const char* code,
                        const std::string& message, bool fatal);

/// error.code 稳定值（§6.4），供主循环与测试共享。
inline constexpr char kErrorCodeInvalidRequest[] = "invalidRequest";
inline constexpr char kErrorCodeProtocolMismatch[] = "protocolMismatch";
inline constexpr char kErrorCodeBusy[] = "busy";
inline constexpr char kErrorCodeNotRunning[] = "notRunning";
inline constexpr char kErrorCodeSpawnFailed[] = "spawnFailed";
inline constexpr char kErrorCodeOutputTooLarge[] = "outputTooLarge";
inline constexpr char kErrorCodeInternal[] = "internal";

}  // namespace helper

#endif  // LINGLONG_STORE_HELPER_PROTOCOL_H_
