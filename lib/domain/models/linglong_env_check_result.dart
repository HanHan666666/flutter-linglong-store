import 'package:freezed_annotation/freezed_annotation.dart';

import 'linux_distribution.dart';

part 'linglong_env_check_result.freezed.dart';
part 'linglong_env_check_result.g.dart';

/// 玲珑环境检测结果
@freezed
sealed class LinglongEnvCheckResult with _$LinglongEnvCheckResult {
  const factory LinglongEnvCheckResult({
    /// 是否通过检测
    required bool isOk,

    /// 非阻断警告信息
    String? warningMessage,

    /// ll-cli 版本
    String? llCliVersion,

    /// linglong-bin 版本
    String? llBinVersion,

    /// 系统架构
    String? arch,

    /// 操作系统版本
    String? osVersion,

    /// glibc 版本
    String? glibcVersion,

    /// 内核信息
    String? kernelInfo,

    /// 额外诊断信息
    String? detailMsg,

    /// 默认仓库名
    String? repoName,

    /// 仓库列表
    @Default(<LinglongRepoInfo>[]) List<LinglongRepoInfo> repos,

    /// 是否在容器环境中
    @Default(false) bool isContainer,

    /// 当前 Linux 发行版画像。
    ///
    /// 这是环境检测链路向下游透传“发行版特殊适配”信息的统一出口。
    /// 后续如果新增发行版特殊提示，应继续复用这个字段，
    /// 不要重新在结果模型里增加 `isUos` / `isDeepin` 之类一次性布尔值。
    @Default(LinuxDistribution()) LinuxDistribution distribution,

    /// repo 状态
    @Default(RepoStatus.unknown) RepoStatus repoStatus,

    /// 导致环境检测失败的用户可读命令。
    ///
    /// 该字段用于把“命令执行失败”和“业务数据为空”区分开；
    /// 启动期仓库读取失败时会记录为 `ll-cli --json repo show`，
    /// UI 可据此向用户说明失败的是仓库读取命令，而不是仓库一定没有配置。
    String? failedCommand,

    /// 失败命令退出码。
    ///
    /// 退出码本身不直接决定 UI 文案，但保留它能帮助日志、测试和后续诊断
    /// 精确还原底层命令状态，避免只依赖模糊错误文案。
    int? failedCommandExitCode,

    /// 推荐的环境恢复动作。
    ///
    /// 该字段只表达“当前诊断建议用户执行什么动作”，不携带命令文本；
    /// 具体命令仍由 Application/Service 层受控封装。
    LinglongEnvRecoveryAction? recoveryAction,

    /// 错误消息
    String? errorMessage,

    /// 错误详情
    String? errorDetail,

    /// 检测时间戳
    required int checkedAt,
  }) = _LinglongEnvCheckResult;

  factory LinglongEnvCheckResult.fromJson(Map<String, dynamic> json) =>
      _$LinglongEnvCheckResultFromJson(json);
}

@freezed
sealed class LinglongRepoInfo with _$LinglongRepoInfo {
  const factory LinglongRepoInfo({
    required String name,
    required String url,
    String? alias,
    String? priority,
  }) = _LinglongRepoInfo;

  factory LinglongRepoInfo.fromJson(Map<String, dynamic> json) =>
      _$LinglongRepoInfoFromJson(json);
}

/// Repo 状态枚举
enum RepoStatus {
  /// 未知
  unknown,

  /// 正常
  ok,

  /// 未配置
  notConfigured,

  /// 配置错误
  misconfigured,

  /// 不可用
  unavailable,
}

/// 玲珑环境检测推荐恢复动作。
enum LinglongEnvRecoveryAction {
  /// 重启系统级玲珑包管理器 D-Bus 服务。
  ///
  /// `ll-cli --json repo show` 需要通过该服务读取仓库配置；服务未运行时，
  /// `ll-cli` 本身可能可用，但仓库读取仍会失败。
  restartPackageManagerService,
}

/// LinglongEnvCheckResult 扩展方法
extension LinglongEnvCheckResultX on LinglongEnvCheckResult {
  /// 是否有严重错误（无法继续）
  bool get hasFatalError => !isOk && llCliVersion == null;

  /// 是否可以跳过（部分功能不可用）
  bool get canSkip => !isOk && llCliVersion != null;

  /// 获取状态描述
  String get statusDescription {
    if (isOk && warningMessage != null) return '环境正常（建议升级）';
    if (isOk) return '环境正常';
    if (recoveryAction ==
        LinglongEnvRecoveryAction.restartPackageManagerService) {
      return '仓库配置读取失败';
    }
    if (llCliVersion == null) return 'll-cli 不可用';
    return '环境异常';
  }

  /// 是否建议用户重启玲珑包管理器服务。
  bool get shouldSuggestPackageManagerRestart =>
      recoveryAction == LinglongEnvRecoveryAction.restartPackageManagerService;

  /// 是否存在发行版特殊适配。
  ///
  /// 这个 getter 主要给展示层判断“是否值得渲染额外提示块”，
  /// 具体提示内容仍然要继续走 scenario -> guidance 映射。
  bool get hasDistributionAdaptation => distribution.hasSpecialAdaptation;
}
