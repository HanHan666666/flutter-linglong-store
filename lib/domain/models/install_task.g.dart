// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstallTask _$InstallTaskFromJson(Map<String, dynamic> json) => _InstallTask(
  id: json['id'] as String,
  appId: json['appId'] as String,
  appName: json['appName'] as String,
  icon: json['icon'] as String?,
  kind:
      $enumDecodeNullable(_$InstallTaskKindEnumMap, json['kind']) ??
      InstallTaskKind.install,
  batchId: json['batchId'] as String?,
  target: json['target'] == null
      ? null
      : AppOperationTargetSnapshot.fromJson(
          json['target'] as Map<String, dynamic>,
        ),
  version: json['version'] as String?,
  force: json['force'] as bool? ?? false,
  status:
      $enumDecodeNullable(_$InstallStatusEnumMap, json['status']) ??
      InstallStatus.pending,
  progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
  message: json['message'] as String?,
  messageCode: $enumDecodeNullable(
    _$AppOperationMessageCodeEnumMap,
    json['messageCode'],
  ),
  rawMessage: json['rawMessage'] as String?,
  commandOutput: json['commandOutput'] as String? ?? '',
  errorMessage: json['errorMessage'] as String?,
  errorCode: (json['errorCode'] as num?)?.toInt(),
  errorDetail: json['errorDetail'] as String?,
  failure: json['failure'] == null
      ? null
      : AppOperationFailure.fromJson(json['failure'] as Map<String, dynamic>),
  createdAt: (json['createdAt'] as num).toInt(),
  startedAt: (json['startedAt'] as num?)?.toInt(),
  finishedAt: (json['finishedAt'] as num?)?.toInt(),
);

Map<String, dynamic> _$InstallTaskToJson(_InstallTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appId': instance.appId,
      'appName': instance.appName,
      'icon': instance.icon,
      'kind': _$InstallTaskKindEnumMap[instance.kind]!,
      'batchId': instance.batchId,
      'target': instance.target,
      'version': instance.version,
      'force': instance.force,
      'status': _$InstallStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'message': instance.message,
      'messageCode': _$AppOperationMessageCodeEnumMap[instance.messageCode],
      'rawMessage': instance.rawMessage,
      'commandOutput': instance.commandOutput,
      'errorMessage': instance.errorMessage,
      'errorCode': instance.errorCode,
      'errorDetail': instance.errorDetail,
      'failure': instance.failure,
      'createdAt': instance.createdAt,
      'startedAt': instance.startedAt,
      'finishedAt': instance.finishedAt,
    };

const _$InstallTaskKindEnumMap = {
  InstallTaskKind.install: 'install',
  InstallTaskKind.update: 'update',
};

const _$InstallStatusEnumMap = {
  InstallStatus.pending: 'pending',
  InstallStatus.downloading: 'downloading',
  InstallStatus.installing: 'installing',
  InstallStatus.success: 'success',
  InstallStatus.failed: 'failed',
  InstallStatus.cancelled: 'cancelled',
  InstallStatus.interrupted: 'interrupted',
};

const _$AppOperationMessageCodeEnumMap = {
  AppOperationMessageCode.preparing: 'preparing',
  AppOperationMessageCode.starting: 'starting',
  AppOperationMessageCode.installingApplication: 'installingApplication',
  AppOperationMessageCode.installingRuntime: 'installingRuntime',
  AppOperationMessageCode.installingBase: 'installingBase',
  AppOperationMessageCode.downloadingMetadata: 'downloadingMetadata',
  AppOperationMessageCode.downloadingFiles: 'downloadingFiles',
  AppOperationMessageCode.postProcessing: 'postProcessing',
  AppOperationMessageCode.processing: 'processing',
  AppOperationMessageCode.completed: 'completed',
};
