import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'api_interceptors.dart';

/// API 客户端
///
/// 封装 Dio 实例，提供统一的 HTTP 请求能力。
/// 包括拦截器配置、日志记录和错误处理。
class ApiClient {
  ApiClient._();

  /// 单例 Dio 实例
  static Dio? _instance;

  static bool get isInitialized => _instance != null;

  static Dio get instance {
    getLocale ??= _defaultLocaleGetter;
    _instance ??= _createDio();
    return _instance!;
  }

  /// 当前语言获取回调
  ///
  /// 用于在拦截器中注入 Accept-Language 请求头。
  /// 在应用初始化时设置此回调。
  static String Function()? getLocale;

  /// 初始化 Dio 实例
  ///
  /// 必须在应用启动时调用，配置基础选项和拦截器。
  /// [localeGetter] 用于获取当前语言设置，用于注入请求头。
  static void init({String Function()? localeGetter}) {
    getLocale = localeGetter ?? getLocale ?? _defaultLocaleGetter;
    _instance ??= _createDio();
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(
          seconds: AppConfig.defaultTimeoutSeconds,
        ),
        receiveTimeout: const Duration(
          seconds: AppConfig.defaultTimeoutSeconds,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(ApiInterceptors());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => AppLogger.debug('[DIO] $obj'),
        ),
      );
    }

    AppLogger.info(
      'ApiClient initialized with baseUrl: ${AppConfig.apiBaseUrl}',
    );
    return dio;
  }

  static String _defaultLocaleGetter() {
    final locale = PlatformDispatcher.instance.locale.languageCode;
    return locale.isEmpty ? 'zh' : locale;
  }
}
