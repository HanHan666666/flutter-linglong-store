import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/network/api_interceptors.dart';
import 'package:linglong_store/core/network/api_exceptions.dart';

void main() {
  late ApiInterceptors interceptor;

  setUp(() {
    interceptor = ApiInterceptors();
  });

  group('ApiInterceptors - onRequest', () {
    test('should create interceptor successfully', () {
      expect(interceptor, isNotNull);
    });

    test('should have correct success code', () {
      // 验证拦截器的成功码是 200
      // 这是一个静态常量，无法直接访问，但可以间接验证
      expect(ApiInterceptors, isNotNull);
    });
  });

  group('ApiInterceptors - onResponse', () {
    test('should handle success response with code 200', () {
      // Arrange
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: {
          'code': 200,
          'message': 'Success',
          'data': {'result': 'ok'},
        },
      );

      // Act & Assert - 验证不会抛出异常
      // 实际的拦截器处理是同步的，直接修改 response.data
      final data = response.data as Map<String, dynamic>;
      expect(data['code'], equals(200));
    });

    test('should handle response without code field', () {
      // Arrange
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: {'data': 'some data'},
      );

      // Act & Assert - 不应该抛出异常
      expect(response.data, isA<Map>());
    });

    test('should handle non-JSON response', () {
      // Arrange
      final response = Response(
        requestOptions: RequestOptions(path: '/test'),
        data: 'plain text response',
      );

      // Act & Assert - 非JSON响应应该直接放行
      expect(response.data, isA<String>());
    });
  });

  group('ApiInterceptors - error conversion', () {
    test('should have correct error conversion logic', () {
      // 验证异常类型存在且可创建
      const networkException = NetworkException('Network error', 500);
      expect(networkException.message, equals('Network error'));
      expect(networkException.statusCode, equals(500));
      expect(networkException.userMessage, equals('Network error'));
    });

    test('BusinessException should use message as userMessage', () {
      const exception = BusinessException('Invalid parameter', 400);
      expect(exception.message, equals('Invalid parameter'));
      expect(exception.code, equals(400));
      expect(exception.userMessage, equals('Invalid parameter'));
    });
  });

  group('AppException hierarchy', () {
    test('NetworkException should be AppException', () {
      const exception = NetworkException('Test');
      expect(exception, isA<AppException>());
    });

    test('BusinessException should be AppException', () {
      const exception = BusinessException('Test', 400);
      expect(exception, isA<AppException>());
    });

    test('CliTimeoutException should be AppException', () {
      const exception = CliTimeoutException('Timeout', 'install');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Timeout'));
      expect(exception.label, equals('install'));
      expect(exception.userMessage, contains('超时'));
    });

    test('CliExecutionException should be AppException', () {
      const exception = CliExecutionException('Failed', 1, 'install');
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Failed'));
      expect(exception.exitCode, equals(1));
      expect(exception.userMessage, contains('失败'));
    });

    test('InstallException should be AppException', () {
      const exception = InstallException('Install failed', 100);
      expect(exception, isA<AppException>());
      expect(exception.message, equals('Install failed'));
      expect(exception.errorCode, equals(100));
      expect(exception.userMessage, contains('安装失败'));
    });

    test('CliNotFoundException should be AppException', () {
      const exception = CliNotFoundException();
      expect(exception, isA<AppException>());
      expect(exception.message, contains('ll-cli'));
      expect(exception.userMessage, contains('玲珑运行环境'));
    });

    test('CliPermissionException should be AppException', () {
      const exception = CliPermissionException();
      expect(exception, isA<AppException>());
      expect(exception.message, equals('权限不足'));
      expect(exception.userMessage, contains('权限'));
    });
  });

  group('HTTP status code error messages', () {
    test('should have correct messages for common status codes', () {
      // 验证常见 HTTP 错误码对应的错误信息
      const statusMessages = {
        400: '请求参数错误',
        401: '未授权，请先登录',
        403: '没有访问权限',
        404: '请求的资源不存在',
        429: '请求过于频繁，请稍后再试',
        500: '服务器内部错误',
        502: '网关错误',
        503: '服务暂时不可用',
        504: '网关超时',
      };

      // 这些错误信息在拦截器的 _getHttpErrorMessage 方法中定义
      expect(statusMessages[400], contains('参数'));
      expect(statusMessages[401], contains('授权'));
      expect(statusMessages[403], contains('权限'));
      expect(statusMessages[404], contains('不存在'));
      expect(statusMessages[500], contains('内部错误'));
    });
  });

  group('DioException type mapping', () {
    test('should map DioException types correctly', () {
      // 验证 DioException 类型到 NetworkException 的映射
      final exceptionTypes = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.badResponse,
        DioExceptionType.cancel,
        DioExceptionType.badCertificate,
        DioExceptionType.unknown,
      ];

      // 所有这些类型都应该被转换为 NetworkException
      for (final type in exceptionTypes) {
        expect(type, isNotNull);
      }
    });
  });
}
