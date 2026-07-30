// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linglong_env_check_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinglongEnvCheckResult _$LinglongEnvCheckResultFromJson(
  Map<String, dynamic> json,
) => _LinglongEnvCheckResult(
  isOk: json['isOk'] as bool,
  warningMessage: json['warningMessage'] as String?,
  llCliVersion: json['llCliVersion'] as String?,
  llBinVersion: json['llBinVersion'] as String?,
  arch: json['arch'] as String?,
  osVersion: json['osVersion'] as String?,
  glibcVersion: json['glibcVersion'] as String?,
  kernelInfo: json['kernelInfo'] as String?,
  detailMsg: json['detailMsg'] as String?,
  repoName: json['repoName'] as String?,
  repos:
      (json['repos'] as List<dynamic>?)
          ?.map((e) => LinglongRepoInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LinglongRepoInfo>[],
  isContainer: json['isContainer'] as bool? ?? false,
  distribution: json['distribution'] == null
      ? const LinuxDistribution()
      : LinuxDistribution.fromJson(
          json['distribution'] as Map<String, dynamic>,
        ),
  repoStatus:
      $enumDecodeNullable(_$RepoStatusEnumMap, json['repoStatus']) ??
      RepoStatus.unknown,
  failedCommand: json['failedCommand'] as String?,
  failedCommandExitCode: (json['failedCommandExitCode'] as num?)?.toInt(),
  recoveryAction: $enumDecodeNullable(
    _$LinglongEnvRecoveryActionEnumMap,
    json['recoveryAction'],
  ),
  errorMessage: json['errorMessage'] as String?,
  errorDetail: json['errorDetail'] as String?,
  checkedAt: (json['checkedAt'] as num).toInt(),
);

Map<String, dynamic> _$LinglongEnvCheckResultToJson(
  _LinglongEnvCheckResult instance,
) => <String, dynamic>{
  'isOk': instance.isOk,
  'warningMessage': instance.warningMessage,
  'llCliVersion': instance.llCliVersion,
  'llBinVersion': instance.llBinVersion,
  'arch': instance.arch,
  'osVersion': instance.osVersion,
  'glibcVersion': instance.glibcVersion,
  'kernelInfo': instance.kernelInfo,
  'detailMsg': instance.detailMsg,
  'repoName': instance.repoName,
  'repos': instance.repos,
  'isContainer': instance.isContainer,
  'distribution': instance.distribution,
  'repoStatus': _$RepoStatusEnumMap[instance.repoStatus]!,
  'failedCommand': instance.failedCommand,
  'failedCommandExitCode': instance.failedCommandExitCode,
  'recoveryAction': _$LinglongEnvRecoveryActionEnumMap[instance.recoveryAction],
  'errorMessage': instance.errorMessage,
  'errorDetail': instance.errorDetail,
  'checkedAt': instance.checkedAt,
};

const _$RepoStatusEnumMap = {
  RepoStatus.unknown: 'unknown',
  RepoStatus.ok: 'ok',
  RepoStatus.notConfigured: 'notConfigured',
  RepoStatus.misconfigured: 'misconfigured',
  RepoStatus.unavailable: 'unavailable',
};

const _$LinglongEnvRecoveryActionEnumMap = {
  LinglongEnvRecoveryAction.restartPackageManagerService:
      'restartPackageManagerService',
};

_LinglongRepoInfo _$LinglongRepoInfoFromJson(Map<String, dynamic> json) =>
    _LinglongRepoInfo(
      name: json['name'] as String,
      url: json['url'] as String,
      alias: json['alias'] as String?,
      priority: json['priority'] as String?,
    );

Map<String, dynamic> _$LinglongRepoInfoToJson(_LinglongRepoInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'alias': instance.alias,
      'priority': instance.priority,
    };
