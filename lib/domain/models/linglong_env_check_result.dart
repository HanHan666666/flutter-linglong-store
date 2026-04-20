import 'package:freezed_annotation/freezed_annotation.dart';

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

    /// repo 状态
    @Default(RepoStatus.unknown) RepoStatus repoStatus,

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
    if (llCliVersion == null) return 'll-cli 不可用';
    return '环境异常';
  }
}
