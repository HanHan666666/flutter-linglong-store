import '../models/error_solution.dart';

/// 安装错误解决方案仓储接口。
///
/// 每次调用都必须访问后端，不允许实现本地缓存或本地匹配规则，确保规则的
/// 上线、下线和脚本更新即时生效。
abstract interface class ErrorSolutionRepository {
  /// 使用 ll-cli 原始 [message] 和当前 [language] 查询唯一解决方案。
  ///
  /// 未命中时返回 `null`；网络、协议或后端配置错误必须抛出异常，由展示层
  /// 区分“暂无方案”和“查询失败”。
  Future<ErrorSolution?> find({
    required String message,
    required String language,
  });
}
