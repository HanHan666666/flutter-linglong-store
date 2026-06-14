import '../models/linglong_repository_config.dart';

/// 玲珑仓库管理 Repository。
///
/// 所有 `ll-cli repo ...` 调用都必须收敛到这一层，展示层和 Provider
/// 不应直接拼接仓库管理命令，避免命令参数和错误处理在 UI 中分散。
abstract class LinglongRepositoryManagementRepository {
  /// 读取当前仓库配置。
  Future<LinglongRepositoryConfig> getRepositoryConfig();

  /// 添加仓库。
  Future<String> addRepository({
    required String name,
    required String url,
    String? alias,
  });

  /// 更新仓库 URL。
  Future<String> updateRepository({
    required String aliasOrName,
    required String url,
  });

  /// 删除仓库。
  Future<String> removeRepository(String aliasOrName);

  /// 设置默认仓库。
  Future<String> setDefaultRepository(String aliasOrName);

  /// 设置仓库优先级。
  Future<String> setRepositoryPriority(String aliasOrName, int priority);

  /// 启用或禁用仓库镜像。
  Future<String> setRepositoryMirror(
    String aliasOrName, {
    required bool enabled,
  });
}
