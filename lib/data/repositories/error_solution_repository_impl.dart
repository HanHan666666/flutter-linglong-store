import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/error_solution.dart';
import '../../domain/repositories/error_solution_repository.dart';
import '../datasources/remote/app_api_service.dart';
import '../models/error_solution_dto.dart';

/// 安装错误解决方案仓储实现。
///
/// 本实现故意不保存任何查询结果：用户每次点击帮助入口都重新访问后端，使规则
/// 启停和脚本替换不依赖客户端更新，也不受陈旧缓存影响。
class ErrorSolutionRepositoryImpl implements ErrorSolutionRepository {
  /// 使用应用级 API 客户端创建生产仓储。
  ErrorSolutionRepositoryImpl()
    : _apiService = AppApiService(ApiClient.instance);

  /// 注入 API 服务创建可测试仓储。
  @visibleForTesting
  ErrorSolutionRepositoryImpl.withService(this._apiService);

  /// 后端 HTTP 服务。
  final AppApiService _apiService;

  @override
  Future<ErrorSolution?> find({
    required String message,
    required String language,
  }) async {
    try {
      final response = await _apiService.findErrorSolution(
        ErrorSolutionFindRequest(message: message, language: language),
      );
      final body = response.data;
      if (body.code != 200) {
        throw StateError(body.message ?? '错误解决方案查询失败');
      }

      final dto = body.data;
      if (dto == null) {
        return null;
      }
      if (dto.title.isEmpty || dto.markdown.isEmpty) {
        throw const FormatException('错误解决方案缺少标题或 Markdown');
      }

      return ErrorSolution(
        title: dto.title,
        markdown: dto.markdown,
        repairScript: dto.repairScript,
        repairScriptSignature: dto.repairScriptSignature,
      );
    } catch (error, stackTrace) {
      AppLogger.error('查询安装错误解决方案失败', error, stackTrace);
      rethrow;
    }
  }
}
