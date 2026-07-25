import '../../domain/models/error_solution.dart';
import '../../domain/repositories/error_solution_repository.dart';

/// 安装错误解决方案查询服务。
///
/// 该服务是下载管理与仓储之间的单一业务入口，集中维护 message 的选择规则，
/// 避免当前任务卡片和历史记录卡片各自拼接查询参数。
class ErrorSolutionLookupService {
  /// 创建查询服务。
  const ErrorSolutionLookupService({
    required ErrorSolutionRepository repository,
  }) : _repository = repository;

  /// 错误解决方案仓储。
  final ErrorSolutionRepository _repository;

  /// 查询当前失败任务的解决方案。
  ///
  /// [message] 必须来自 ll-cli 原始 message；不在客户端做匹配、裁剪或大小写转换。
  Future<ErrorSolution?> find({
    required String message,
    required String language,
  }) {
    return _repository.find(message: message, language: language);
  }
}
