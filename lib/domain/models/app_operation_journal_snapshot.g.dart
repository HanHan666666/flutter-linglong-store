// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_operation_journal_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppOperationJournalSnapshot _$AppOperationJournalSnapshotFromJson(
  Map<String, dynamic> json,
) => _AppOperationJournalSnapshot(
  schemaVersion:
      (json['schemaVersion'] as num?)?.toInt() ??
      currentAppOperationJournalSchemaVersion,
  pendingTasks:
      (json['pendingTasks'] as List<dynamic>?)
          ?.map((e) => InstallTask.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InstallTask>[],
  currentTask: json['currentTask'] == null
      ? null
      : InstallTask.fromJson(json['currentTask'] as Map<String, dynamic>),
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => InstallTask.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <InstallTask>[],
  batches:
      (json['batches'] as List<dynamic>?)
          ?.map((e) => AppOperationBatch.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AppOperationBatch>[],
  outbox:
      (json['outbox'] as List<dynamic>?)
          ?.map((e) => AppOperationEffect.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AppOperationEffect>[],
);

Map<String, dynamic> _$AppOperationJournalSnapshotToJson(
  _AppOperationJournalSnapshot instance,
) => <String, dynamic>{
  'schemaVersion': instance.schemaVersion,
  'pendingTasks': instance.pendingTasks,
  'currentTask': instance.currentTask,
  'history': instance.history,
  'batches': instance.batches,
  'outbox': instance.outbox,
};
