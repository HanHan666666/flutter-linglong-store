import 'package:dio/dio.dart';

import '../logging/app_logger.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// API 请求/响应拦截器
///
/// 统一处理：
/// - 请求头注入（Accept-Language）
/// - 响应数据校验与提取
/// - 错误转换（DioException -> AppException）
class ApiInterceptors extends Interceptor {
  /// 成功响应码
  static const int _successCode = 200;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 注入 Accept-Language 请求头
    final locale = ApiClient.getLocale?.call();
    if (locale != null && locale.isNotEmpty) {
      options.headers['Accept-Language'] = locale;
    }

    AppLogger.debug(
      'Request: ${options.method} ${options.uri}\n'
      'Headers: ${options.headers}',
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    // 检查响应是否为预期的 JSON 格式
    if (data is! Map<String, dynamic>) {
      // 非 JSON 响应（如文件下载），直接放行
      handler.next(response);
      return;
    }

    // 检查业务响应码
    final code = data['code'];
    if (code == null) {
      // 响应格式不符合预期，记录警告后放行
      AppLogger.warning('Response missing "code" field: $data');
      handler.next(response);
      return;
    }

    // 业务错误码，转换为异常
    if (code != _successCode) {
      final message = data['message']?.toString() ?? '未知错误';
      AppLogger.warning('Business error: code=$code, message=$message');

      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: BusinessException(message, code as int),
        ),
      );
      return;
    }

    // 成功响应保持原始包结构，由 Retrofit DTO 在服务层统一反序列化。
    // 否则像 `data` 为 List 的接口会在 generated client 中被错误地当作 Map 解析。
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 如果已经是业务异常，直接传递
    if (err.error is AppException) {
      handler.next(err);
      return;
    }

    // 根据 DioException 类型转换为对应的 AppException
    final appException = _convertToAppException(err);

    AppLogger.error(
      'Request error: ${err.type}',
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
      ),
    );

    // 创建新的 DioException，携带转换后的 AppException
    handler.next(
      err.copyWith(error: appException),
    );
  }

  /// 将 DioException 转换为 AppException
  AppException _convertToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          '请求超时',
          err.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          '网络连接失败',
          err.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _getHttpErrorMessage(statusCode);
        return NetworkException(message, statusCode);

      case DioExceptionType.cancel:
        return const NetworkException('请求已取消');

      case DioExceptionType.badCertificate:
        return const NetworkException('证书验证失败');

      case DioExceptionType.unknown:
        // 尝试从响应体提取错误信息
        final responseData = err.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          return NetworkException(
            responseData['message'].toString(),
            err.response?.statusCode,
          );
        }
        return NetworkException(
          err.message ?? '网络请求失败',
          err.response?.statusCode,
        );
    }
  }

  /// 根据 HTTP 状态码获取错误信息
  String _getHttpErrorMessage(int? statusCode) {
    if (statusCode == null) return '服务器响应异常';

    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请先登录';
      case 403:
        return '没有访问权限';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 429:
        return '请求过于频繁，请稍后再试';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂时不可用';
      case 504:
        return '网关超时';
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return '客户端请求错误 ($statusCode)';
        }
        if (statusCode >= 500) {
          return '服务器错误 ($statusCode)';
        }
        return '网络请求失败 ($statusCode)';
    }
  }
}
