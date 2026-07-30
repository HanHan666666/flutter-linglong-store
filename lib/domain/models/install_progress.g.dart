// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstallProgress _$InstallProgressFromJson(Map<String, dynamic> json) =>
    _InstallProgress(
      appId: json['appId'] as String,
      eventType:
          $enumDecodeNullable(
            _$InstallProgressEventTypeEnumMap,
            json['eventType'],
          ) ??
          InstallProgressEventType.message,
      status: $enumDecode(_$InstallStatusEnumMap, json['status']),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      messageCode: $enumDecodeNullable(
        _$AppOperationMessageCodeEnumMap,
        json['messageCode'],
      ),
      rawMessage: json['rawMessage'] as String?,
      outputLine: json['outputLine'] as String?,
      error: json['error'] as String?,
      errorCode: (json['errorCode'] as num?)?.toInt(),
      errorDetail: json['errorDetail'] as String?,
      failure: json['failure'] == null
          ? null
          : AppOperationFailure.fromJson(
              json['failure'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$InstallProgressToJson(_InstallProgress instance) =>
    <String, dynamic>{
      'appId': instance.appId,
      'eventType': _$InstallProgressEventTypeEnumMap[instance.eventType]!,
      'status': _$InstallStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'message': instance.message,
      'messageCode': _$AppOperationMessageCodeEnumMap[instance.messageCode],
      'rawMessage': instance.rawMessage,
      'outputLine': instance.outputLine,
      'error': instance.error,
      'errorCode': instance.errorCode,
      'errorDetail': instance.errorDetail,
      'failure': instance.failure,
    };

const _$InstallProgressEventTypeEnumMap = {
  InstallProgressEventType.progress: 'progress',
  InstallProgressEventType.message: 'message',
  InstallProgressEventType.error: 'error',
  InstallProgressEventType.cancelled: 'cancelled',
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
