// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'running_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RunningApp _$RunningAppFromJson(Map<String, dynamic> json) => _RunningApp(
  id: json['id'] as String,
  appId: json['appId'] as String,
  name: json['name'] as String,
  version: json['version'] as String,
  arch: json['arch'] as String,
  channel: json['channel'] as String,
  source: json['source'] as String,
  pid: (json['pid'] as num).toInt(),
  containerId: json['containerId'] as String,
  icon: json['icon'] as String?,
);

Map<String, dynamic> _$RunningAppToJson(_RunningApp instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appId': instance.appId,
      'name': instance.name,
      'version': instance.version,
      'arch': instance.arch,
      'channel': instance.channel,
      'source': instance.source,
      'pid': instance.pid,
      'containerId': instance.containerId,
      'icon': instance.icon,
    };
