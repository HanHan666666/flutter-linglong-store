/// 特权 helper NDJSON 协议 DTO 与有界编解码（docs/47 §6）。
///
/// 与 C++ 端 `helper_protocol.cc` 保持同一套字符集与帧上限规则；客户端在
/// 发送前先做本地校验，保证“非法请求永远到不了 helper”，helper 端校验
/// 仍是权威防线。
library;

import 'dart:convert';

import 'privileged_helper_exception.dart';

/// 单条 GUI 请求的最大 UTF-8 字节数（§6.2）。
const int kPrivilegedHelperMaxRequestBytes = 16 * 1024;

/// 单条 ll-cli 输出行的最大 UTF-8 字节数（§6.2）。
const int kPrivilegedHelperMaxOutputBytes = 1024 * 1024;

/// helper → GUI 事件帧的解码上限：单行输出加协议信封的开销。
const int kPrivilegedHelperMaxEventBytes =
    kPrivilegedHelperMaxOutputBytes + 4 * 1024;

/// 协议版本，首版固定为 1（§6.2）。
const int kPrivilegedHelperProtocolVersion = 1;

/// start 请求的业务操作；`update` 是商店业务名，helper 侧映射 `upgrade`。
enum PrivilegedHelperOperation { install, update }

/// helper error 事件的稳定 code 值（§6.4）。
abstract final class PrivilegedHelperErrorCodes {
  static const String invalidRequest = 'invalidRequest';
  static const String protocolMismatch = 'protocolMismatch';
  static const String busy = 'busy';
  static const String notRunning = 'notRunning';
  static const String spawnFailed = 'spawnFailed';
  static const String outputTooLarge = 'outputTooLarge';
  static const String internal = 'internal';
}

/// 校验 requestId 字符集：ASCII 字母、数字、`.`、`_`、`-`，1~128 字节（§6.3）。
bool isValidPrivilegedHelperRequestId(String value) {
  final bytes = value.codeUnits;
  if (bytes.isEmpty || bytes.length > 128) {
    return false;
  }
  return bytes.every(_isRequestIdByte);
}

/// 校验 appId 字符集：同 requestId 字符集，1~255 字节，天然排除路径字符。
bool isValidPrivilegedHelperAppId(String value) {
  final bytes = value.codeUnits;
  if (bytes.isEmpty || bytes.length > 255) {
    return false;
  }
  return bytes.every(_isRequestIdByte);
}

/// 校验 version 字符集：额外允许 `+`、`~`，1~128 字节。
bool isValidPrivilegedHelperVersion(String value) {
  final bytes = value.codeUnits;
  if (bytes.isEmpty || bytes.length > 128) {
    return false;
  }
  return bytes.every(
    (b) => _isRequestIdByte(b) || b == 0x2B /* + */ || b == 0x7E /* ~ */,
  );
}

bool _isRequestIdByte(int b) {
  return (b >= 0x30 && b <= 0x39) || // 0-9
      (b >= 0x41 && b <= 0x5A) || // A-Z
      (b >= 0x61 && b <= 0x7A) || // a-z
      b == 0x2E /* . */ ||
      b == 0x5F /* _ */ ||
      b == 0x2D /* - */;
}

// ---------------------------------------------------------------------------
// GUI 请求
// ---------------------------------------------------------------------------

/// 类型化 GUI 请求基类；实现类持有全部字段校验逻辑。
sealed class PrivilegedHelperRequest {
  const PrivilegedHelperRequest();

  /// 编码为 NDJSON 行（含结尾换行）。
  ///
  /// 字段不合法或帧超限时抛 [PrivilegedHelperProtocolException]，调用方
  /// 不得发送半成品帧。
  String encode();
}

/// 启动一个在线安装或更新任务。
class PrivilegedHelperStartRequest extends PrivilegedHelperRequest {
  const PrivilegedHelperStartRequest({
    required this.requestId,
    required this.operation,
    required this.appId,
    this.version,
    required this.force,
  });

  final String requestId;
  final PrivilegedHelperOperation operation;
  final String appId;
  final String? version;
  final bool force;

  @override
  String encode() {
    // 本地校验与 helper 端保持一致：任何非法字段在发送前直接失败。
    if (!isValidPrivilegedHelperRequestId(requestId)) {
      throw const PrivilegedHelperProtocolException('invalid requestId for helper');
    }
    if (!isValidPrivilegedHelperAppId(appId)) {
      throw const PrivilegedHelperProtocolException('invalid appId for helper');
    }
    if (operation == PrivilegedHelperOperation.update &&
        (version != null || force)) {
      // update 不得携带 version/force（§6.3）。
      throw const PrivilegedHelperProtocolException(
        'update request must not carry version or force',
      );
    }
    final effectiveVersion = version;
    if (effectiveVersion != null &&
        !isValidPrivilegedHelperVersion(effectiveVersion)) {
      throw const PrivilegedHelperProtocolException('invalid version for helper');
    }
    final line = jsonEncode(<String, Object?>{
      'v': kPrivilegedHelperProtocolVersion,
      'type': 'start',
      'requestId': requestId,
      'operation': operation == PrivilegedHelperOperation.install
          ? 'install'
          : 'update',
      'appId': appId,
      if (operation == PrivilegedHelperOperation.install) ...<String, Object?>{
        // install 必带 force；update 的 force 由 helper 端拒绝。
        'force': force,
        'version': ?effectiveVersion,
      },
    });
    return _terminateFrame(line);
  }
}

/// 取消同 ID 的当前任务（§8.2：SIGTERM 协作取消，无第二次授权）。
class PrivilegedHelperCancelRequest extends PrivilegedHelperRequest {
  const PrivilegedHelperCancelRequest({required this.requestId});

  final String requestId;

  @override
  String encode() {
    if (!isValidPrivilegedHelperRequestId(requestId)) {
      throw const PrivilegedHelperProtocolException('invalid requestId for helper');
    }
    return _terminateFrame(
      jsonEncode(<String, Object?>{
        'v': kPrivilegedHelperProtocolVersion,
        'type': 'cancel',
        'requestId': requestId,
      }),
    );
  }
}

/// 请求 helper 空闲时正常退出。
class PrivilegedHelperShutdownRequest extends PrivilegedHelperRequest {
  const PrivilegedHelperShutdownRequest();

  @override
  String encode() {
    return _terminateFrame(
      jsonEncode(<String, Object?>{
        'v': kPrivilegedHelperProtocolVersion,
        'type': 'shutdown',
      }),
    );
  }
}

String _terminateFrame(String line) {
  if (utf8.encode(line).length > kPrivilegedHelperMaxRequestBytes) {
    throw const PrivilegedHelperProtocolException(
      'request frame exceeds 16 KiB',
    );
  }
  return '$line\n';
}

// ---------------------------------------------------------------------------
// helper 事件
// ---------------------------------------------------------------------------

/// helper 事件基类。
sealed class PrivilegedHelperEvent {
  const PrivilegedHelperEvent();
}

/// helper 已通过启动检查，可以接收 start（§7）。
class PrivilegedHelperReadyEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperReadyEvent({required this.version});

  final int version;
}

/// ll-cli 子进程已创建；pid 仅作诊断，禁止作为取消凭据（§6.4）。
class PrivilegedHelperStartedEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperStartedEvent({
    required this.requestId,
    required this.operation,
    this.pid,
  });

  final String requestId;
  final PrivilegedHelperOperation operation;
  final int? pid;
}

/// 一行原始 ll-cli 输出；内容仍交由现有 CliOutputParser 解析（§6.4）。
class PrivilegedHelperOutputEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperOutputEvent({
    required this.requestId,
    required this.isStderr,
    required this.line,
  });

  final String requestId;
  final bool isStderr;
  final String line;
}

/// SIGTERM 已发出或任务正处于退出过程；不代表取消一定成功（§8.2）。
class PrivilegedHelperCancelAcceptedEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperCancelAcceptedEvent({required this.requestId});

  final String requestId;
}

/// 子进程已被真实回收；最终业务状态由输出解析与安装前后快照决定。
class PrivilegedHelperExitedEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperExitedEvent({
    required this.requestId,
    required this.exitCode,
    required this.cancelRequested,
  });

  final String requestId;
  final int exitCode;
  final bool cancelRequested;
}

/// 请求、启动、协议或 helper 运行错误（§6.4）。
class PrivilegedHelperErrorEvent extends PrivilegedHelperEvent {
  const PrivilegedHelperErrorEvent({
    required this.requestId,
    required this.code,
    required this.message,
    required this.fatal,
  });

  final String? requestId;
  final String code;
  final String message;
  final bool fatal;
}

/// 解码一行 helper 事件（不含换行符）。
///
/// 帧超限、非 JSON、版本不符、字段类型错误或未知 type 一律抛
/// [PrivilegedHelperProtocolException]；客户端按致命会话错误处理。
PrivilegedHelperEvent decodePrivilegedHelperEvent(String line) {
  if (utf8.encode(line).length > kPrivilegedHelperMaxEventBytes) {
    throw const PrivilegedHelperProtocolException('event frame too large');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(line);
  } catch (error) {
    throw PrivilegedHelperProtocolException('malformed helper event: $error');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const PrivilegedHelperProtocolException('helper event is not object');
  }
  final version = decoded['v'];
  if (version is! int || version != kPrivilegedHelperProtocolVersion) {
    throw const PrivilegedHelperProtocolException(
      'helper protocol version mismatch',
      code: PrivilegedHelperErrorCodes.protocolMismatch,
    );
  }
  switch (decoded['type']) {
    case 'ready':
      return PrivilegedHelperReadyEvent(version: version);
    case 'started':
      return PrivilegedHelperStartedEvent(
        requestId: _requiredString(decoded, 'requestId'),
        operation: PrivilegedHelperOperation.install,
        pid: decoded['pid'] is int ? decoded['pid'] as int : null,
      );
    case 'output':
      return PrivilegedHelperOutputEvent(
        requestId: _requiredString(decoded, 'requestId'),
        isStderr: decoded['stream'] == 'stderr',
        line: _requiredString(decoded, 'line'),
      );
    case 'cancelAccepted':
      return PrivilegedHelperCancelAcceptedEvent(
        requestId: _requiredString(decoded, 'requestId'),
      );
    case 'exited':
      return PrivilegedHelperExitedEvent(
        requestId: _requiredString(decoded, 'requestId'),
        exitCode: _requiredInt(decoded, 'exitCode'),
        cancelRequested: decoded['cancelRequested'] == true,
      );
    case 'error':
      final rawRequestId = decoded['requestId'];
      return PrivilegedHelperErrorEvent(
        requestId: rawRequestId is String ? rawRequestId : null,
        code: _requiredString(decoded, 'code'),
        message: _requiredString(decoded, 'message'),
        fatal: decoded['fatal'] == true,
      );
    default:
      throw const PrivilegedHelperProtocolException('unknown helper event');
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw PrivilegedHelperProtocolException('helper event field $key missing');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw PrivilegedHelperProtocolException('helper event field $key missing');
  }
  return value;
}
