// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_operation_target_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppOperationTargetSnapshot _$AppOperationTargetSnapshotFromJson(
  Map<String, dynamic> json,
) => _AppOperationTargetSnapshot(
  appId: json['appId'] as String,
  displayName: json['displayName'] as String,
  icon: json['icon'] as String?,
  arch: json['arch'] as String?,
  channel: json['channel'] as String?,
  module: json['module'] as String?,
  repoName: json['repoName'] as String?,
  installedVersion: json['installedVersion'] as String?,
  expectedVersion: json['expectedVersion'] as String?,
  requestedInstallVersion: json['requestedInstallVersion'] as String?,
);

Map<String, dynamic> _$AppOperationTargetSnapshotToJson(
  _AppOperationTargetSnapshot instance,
) => <String, dynamic>{
  'appId': instance.appId,
  'displayName': instance.displayName,
  'icon': instance.icon,
  'arch': instance.arch,
  'channel': instance.channel,
  'module': instance.module,
  'repoName': instance.repoName,
  'installedVersion': instance.installedVersion,
  'expectedVersion': instance.expectedVersion,
  'requestedInstallVersion': instance.requestedInstallVersion,
};
