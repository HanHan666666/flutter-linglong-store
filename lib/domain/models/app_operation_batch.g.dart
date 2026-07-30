// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_operation_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppOperationBatch _$AppOperationBatchFromJson(
  Map<String, dynamic> json,
) => _AppOperationBatch(
  id: json['id'] as String,
  kind:
      $enumDecodeNullable(_$AppOperationBatchKindEnumMap, json['kind']) ??
      AppOperationBatchKind.updateAll,
  taskIds: (json['taskIds'] as List<dynamic>).map((e) => e as String).toList(),
  targets: (json['targets'] as List<dynamic>)
      .map(
        (e) => AppOperationTargetSnapshot.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  createdAt: (json['createdAt'] as num).toInt(),
  finishedAt: (json['finishedAt'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$AppOperationBatchStatusEnumMap, json['status']) ??
      AppOperationBatchStatus.active,
  notificationState:
      $enumDecodeNullable(
        _$AppOperationNotificationStateEnumMap,
        json['notificationState'],
      ) ??
      AppOperationNotificationState.notRequested,
);

Map<String, dynamic> _$AppOperationBatchToJson(_AppOperationBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$AppOperationBatchKindEnumMap[instance.kind]!,
      'taskIds': instance.taskIds,
      'targets': instance.targets,
      'createdAt': instance.createdAt,
      'finishedAt': instance.finishedAt,
      'status': _$AppOperationBatchStatusEnumMap[instance.status]!,
      'notificationState':
          _$AppOperationNotificationStateEnumMap[instance.notificationState]!,
    };

const _$AppOperationBatchKindEnumMap = {
  AppOperationBatchKind.updateAll: 'updateAll',
};

const _$AppOperationBatchStatusEnumMap = {
  AppOperationBatchStatus.active: 'active',
  AppOperationBatchStatus.completed: 'completed',
};

const _$AppOperationNotificationStateEnumMap = {
  AppOperationNotificationState.notRequested: 'notRequested',
  AppOperationNotificationState.pending: 'pending',
  AppOperationNotificationState.submitted: 'submitted',
  AppOperationNotificationState.suppressed: 'suppressed',
  AppOperationNotificationState.unavailable: 'unavailable',
  AppOperationNotificationState.failed: 'failed',
};

_AppOperationEffect _$AppOperationEffectFromJson(Map<String, dynamic> json) =>
    _AppOperationEffect(
      id: json['id'] as String,
      type: $enumDecode(_$AppOperationEffectTypeEnumMap, json['type']),
      aggregateId: json['aggregateId'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: (json['lastAttemptAt'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppOperationEffectToJson(_AppOperationEffect instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AppOperationEffectTypeEnumMap[instance.type]!,
      'aggregateId': instance.aggregateId,
      'createdAt': instance.createdAt,
      'attemptCount': instance.attemptCount,
      'lastAttemptAt': instance.lastAttemptAt,
    };

const _$AppOperationEffectTypeEnumMap = {
  AppOperationEffectType.taskSucceeded: 'taskSucceeded',
  AppOperationEffectType.updateBatchCompleted: 'updateBatchCompleted',
};
