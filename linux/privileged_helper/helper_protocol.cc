// 特权 helper 协议实现：请求解析与事件编码。
//
// 设计约束（docs/47 §6.2）：
// - 解析固定使用 vendored nlohmann/json，不手写通用 JSON 解析器；
// - 每种消息类型只接受白名单内的键，多余键一律拒绝，防止客户端夹带
//   executable/argv/环境变量等越权字段；
// - 所有校验在返回 kOk 前完成，主循环拿到 kOk 才允许创建子进程。

#include "helper_protocol.h"

#include <nlohmann/json.hpp>

#include <algorithm>
#include <cstring>
#include <utility>

namespace helper {

namespace {

using Json = nlohmann::json;

/// 单条请求的最大 UTF-8 字节数（§6.2）。主循环按行分帧时已保证不超限，
/// 这里再独立校验一次，保证纯函数自身可测。
constexpr size_t kMaxRequestBytes = 16 * 1024;

/// error.message 的截断上限，防止把超长诊断写进协议或日志（§11 第 12 条）。
constexpr size_t kMaxMessageBytes = 256;

/// 校验 value 全部由 [A-Za-z0-9._+-~] 的指定子集组成。
bool allBytesInCharset(const std::string& value, const char* allowed) {
  for (unsigned char c : value) {
    if (std::strchr(allowed, static_cast<char>(c)) == nullptr) {
      return false;
    }
  }
  return true;
}

bool hasOnlyBytes(const std::string& value, const char* allowed) {
  return !value.empty() && allBytesInCharset(value, allowed);
}

/// 截断 UTF-8 字符串到上限字节，避免在多字节序列中间截断产生非法 UTF-8。
std::string truncateUtf8(const std::string& value, size_t maxBytes) {
  if (value.size() <= maxBytes) {
    return value;
  }
  size_t end = maxBytes;
  // 向前回退到合法 UTF-8 序列边界： continuation 字节是 10xxxxxx。
  while (end > 0 && (static_cast<unsigned char>(value[end]) & 0xC0) == 0x80) {
    --end;
  }
  return value.substr(0, end);
}

/// 单条消息允许的键集合比较；多余键是越权信号，必须致命拒绝。
bool hasExtraKeys(const Json& obj, std::initializer_list<const char*> allowed) {
  for (const auto& entry : obj.items()) {
    const std::string& key = entry.key();
    if (std::find_if(allowed.begin(), allowed.end(),
                     [&](const char* k) { return key == k; }) ==
        allowed.end()) {
      return true;
    }
  }
  return false;
}

ParseResult fatalRequest(std::string code, std::string message) {
  ParseResult result;
  result.status = ParseStatus::kFatal;
  result.errorCode = std::move(code);
  result.errorMessage = std::move(message);
  return result;
}

/// 解析 start 消息体（requestId/operation/appId/version/force，§6.3）。
ParseResult parseStart(const Json& obj) {
  if (hasExtraKeys(obj, {"v", "type", "requestId", "operation", "appId",
                         "version", "force"})) {
    return fatalRequest(kErrorCodeInvalidRequest, "start: unknown field");
  }
  if (!obj.contains("requestId") || !obj["requestId"].is_string() ||
      !obj.contains("operation") || !obj["operation"].is_string() ||
      !obj.contains("appId") || !obj["appId"].is_string()) {
    return fatalRequest(kErrorCodeInvalidRequest,
                        "start: missing or non-string required field");
  }
  // force 对 install 是必需字段（§6.3 矩阵），对 update 必须缺失。
  const bool hasForce = obj.contains("force");
  const bool hasVersion = obj.contains("version");

  HelperRequest request;
  request.type = RequestType::kStart;
  request.requestId = obj["requestId"].get<std::string>();
  const std::string operation = obj["operation"].get<std::string>();
  if (operation == "install") {
    request.operation = HelperOperation::kInstall;
  } else if (operation == "update") {
    request.operation = HelperOperation::kUpdate;
  } else {
    return fatalRequest(kErrorCodeInvalidRequest, "start: unknown operation");
  }
  request.appId = obj["appId"].get<std::string>();

  if (!isValidRequestId(request.requestId)) {
    return fatalRequest(kErrorCodeInvalidRequest, "start: invalid requestId");
  }
  if (!isValidAppId(request.appId)) {
    return fatalRequest(kErrorCodeInvalidRequest, "start: invalid appId");
  }

  if (request.operation == HelperOperation::kUpdate) {
    // update 不接受 version/force（§6.3），版本语义只属于 install。
    if (hasVersion || hasForce) {
      return fatalRequest(kErrorCodeInvalidRequest,
                          "start: update must not carry version or force");
    }
    request.force = false;
    return ParseResult{ParseStatus::kOk, request, "", ""};
  }

  if (!hasForce || !obj["force"].is_boolean()) {
    return fatalRequest(kErrorCodeInvalidRequest,
                        "start: install requires boolean force");
  }
  request.force = obj["force"].get<bool>();
  if (hasVersion) {
    if (!obj["version"].is_string()) {
      return fatalRequest(kErrorCodeInvalidRequest,
                          "start: version must be a string");
    }
    request.version = obj["version"].get<std::string>();
    if (!isValidVersion(request.version)) {
      return fatalRequest(kErrorCodeInvalidRequest, "start: invalid version");
    }
  }
  return ParseResult{ParseStatus::kOk, request, "", ""};
}

/// 解析 cancel 消息体（仅 requestId）。
ParseResult parseCancel(const Json& obj) {
  if (hasExtraKeys(obj, {"v", "type", "requestId"})) {
    return fatalRequest(kErrorCodeInvalidRequest, "cancel: unknown field");
  }
  if (!obj.contains("requestId") || !obj["requestId"].is_string()) {
    return fatalRequest(kErrorCodeInvalidRequest,
                        "cancel: missing or non-string requestId");
  }
  HelperRequest request;
  request.type = RequestType::kCancel;
  request.requestId = obj["requestId"].get<std::string>();
  if (!isValidRequestId(request.requestId)) {
    return fatalRequest(kErrorCodeInvalidRequest, "cancel: invalid requestId");
  }
  return ParseResult{ParseStatus::kOk, request, "", ""};
}

}  // namespace

bool isValidRequestId(const std::string& value) {
  return value.size() >= 1 && value.size() <= 128 &&
         hasOnlyBytes(value, "abcdefghijklmnopqrstuvwxyz"
                             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                             "0123456789._-");
}

bool isValidAppId(const std::string& value) {
  return value.size() >= 1 && value.size() <= 255 &&
         hasOnlyBytes(value, "abcdefghijklmnopqrstuvwxyz"
                             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                             "0123456789._-");
}

bool isValidVersion(const std::string& value) {
  return value.size() >= 1 && value.size() <= 128 &&
         hasOnlyBytes(value, "abcdefghijklmnopqrstuvwxyz"
                             "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                             "0123456789._+-~");
}

ParseResult parseRequestLine(const std::string& line) {
  if (line.size() > kMaxRequestBytes) {
    return fatalRequest(kErrorCodeInvalidRequest, "request frame too large");
  }
  Json obj = Json::parse(line, nullptr, false);
  if (obj.is_discarded()) {
    return fatalRequest(kErrorCodeInvalidRequest, "malformed JSON");
  }
  if (!obj.is_object()) {
    return fatalRequest(kErrorCodeInvalidRequest, "request is not an object");
  }
  if (!obj.contains("v") || !obj["v"].is_number_integer()) {
    return fatalRequest(kErrorCodeProtocolMismatch,
                        "missing or non-integer protocol version");
  }
  const int version = obj["v"].get<int>();
  if (version != 1) {
    return fatalRequest(kErrorCodeProtocolMismatch, "unsupported protocol");
  }
  if (!obj.contains("type") || !obj["type"].is_string()) {
    return fatalRequest(kErrorCodeInvalidRequest,
                        "missing or non-string message type");
  }
  const std::string type = obj["type"].get<std::string>();
  if (type == "start") {
    return parseStart(obj);
  }
  if (type == "cancel") {
    return parseCancel(obj);
  }
  if (type == "shutdown") {
    if (hasExtraKeys(obj, {"v", "type"})) {
      return fatalRequest(kErrorCodeInvalidRequest, "shutdown: unknown field");
    }
    HelperRequest request;
    request.type = RequestType::kShutdown;
    return ParseResult{ParseStatus::kOk, request, "", ""};
  }
  return fatalRequest(kErrorCodeInvalidRequest, "unknown message type");
}

std::string encodeReady() {
  return Json{{"v", 1}, {"type", "ready"}}.dump() + "\n";
}

std::string encodeStarted(const std::string& requestId, int pid) {
  return Json{{"v", 1},
              {"type", "started"},
              {"requestId", requestId},
              {"pid", pid}}
      .dump() +
      "\n";
}

std::string encodeOutput(const std::string& requestId, bool stderrStream,
                         const std::string& line) {
  return Json{{"v", 1},
              {"type", "output"},
              {"requestId", requestId},
              {"stream", stderrStream ? "stderr" : "stdout"},
              {"line", line}}
      .dump() +
      "\n";
}

std::string encodeCancelAccepted(const std::string& requestId) {
  return Json{{"v", 1}, {"type", "cancelAccepted"}, {"requestId", requestId}}
      .dump() +
      "\n";
}

std::string encodeExited(const std::string& requestId, int exitCode,
                         bool cancelRequested) {
  return Json{{"v", 1},
              {"type", "exited"},
              {"requestId", requestId},
              {"exitCode", exitCode},
              {"cancelRequested", cancelRequested}}
      .dump() +
      "\n";
}

std::string encodeError(const std::string* requestId, const char* code,
                        const std::string& message, bool fatal) {
  Json obj{{"v", 1},
           {"type", "error"},
           {"code", code},
           {"message", truncateUtf8(message, kMaxMessageBytes)},
           {"fatal", fatal}};
  if (requestId != nullptr) {
    obj["requestId"] = *requestId;
  }
  return obj.dump() + "\n";
}

}  // namespace helper
