import 'package:dio/dio.dart';

/// 统一错误分级
sealed class AppException implements Exception {
  const AppException();

  /// 错误信息
  String get message;

  /// 用户可见信息
  String get userMessage;
}

/// 网络错误（用户可修复）
class NetworkException extends AppException {
  const NetworkException(this.message, [this.statusCode]);

  @override
  final String message;
  final int? statusCode;

  @override
  String get userMessage {
    if (message.isEmpty) {
      return '网络连接失败，请检查网络设置';
    }
    if (statusCode == null && message == '网络连接失败') {
      return '网络连接失败，请检查网络设置';
    }
    return message;
  }
}

/// 业务错误（服务端返回）
class BusinessException extends AppException {
  const BusinessException(this.message, this.code);

  @override
  final String message;
  final int code;

  @override
  String get userMessage => message;
}

/// CLI 执行超时
class CliTimeoutException extends AppException {
  const CliTimeoutException(this.message, this.label);

  @override
  final String message;
  final String label;

  @override
  String get userMessage => '命令执行超时：$label';
}

/// CLI 执行失败
class CliExecutionException extends AppException {
  const CliExecutionException(this.message, this.exitCode, this.label);

  @override
  final String message;
  final int exitCode;
  final String label;

  @override
  String get userMessage => '命令执行失败：$label';
}

/// 安装错误（含错误码）
class InstallException extends AppException {
  const InstallException(this.message, this.errorCode);

  @override
  final String message;
  final int errorCode;

  @override
  String get userMessage => '安装失败：$message';
}

/// CLI 命令不存在异常
class CliNotFoundException extends AppException {
  const CliNotFoundException([this.message = 'll-cli 命令未找到']);

  @override
  final String message;

  @override
  String get userMessage => '未安装 ll-cli，请先安装玲珑运行环境';
}

/// CLI 权限不足异常
class CliPermissionException extends AppException {
  const CliPermissionException([this.message = '权限不足']);

  @override
  final String message;

  @override
  String get userMessage => '权限不足，请检查用户权限';
}

/// 卸载失败异常
///
/// 当 ll-cli uninstall 命令执行失败时抛出，包括：
/// - PKExec 授权被取消
/// - 应用不存在
/// - 其他执行错误
class UninstallException extends AppException {
  const UninstallException(this.message, {this.appId, this.exitCode});

  /// 应用 ID
  final String? appId;

  /// 退出码（如果有）
  final int? exitCode;

  @override
  final String message;

  @override
  String get userMessage => '卸载失败：$message';
}

/// 将底层异常转换为用户可见文案
String presentAppError(Object error) {
  if (error is AppException) {
    return error.userMessage;
  }

  if (error is DioException) {
    final nestedError = error.error;
    if (nestedError is AppException) {
      return nestedError.userMessage;
    }

    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }

    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }

  return error.toString();
}
