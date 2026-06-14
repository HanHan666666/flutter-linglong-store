import 'linglong_env_check_result.dart';

/// 玲珑仓库配置快照。
///
/// `ll-cli --json repo show` 当前会返回 defaultRepo、repos 和 version。
/// 这里单独建模配置容器，仓库条目继续复用环境检测已有的 LinglongRepoInfo，
/// 避免仓库字段在环境检测和仓库管理两套模型里漂移。
class LinglongRepositoryConfig {
  const LinglongRepositoryConfig({
    this.defaultRepo,
    this.version,
    this.repos = const <LinglongRepoInfo>[],
  });

  final String? defaultRepo;
  final int? version;
  final List<LinglongRepoInfo> repos;

  bool get isEmpty => repos.isEmpty;
}
