// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InstalledApp _$InstalledAppFromJson(Map<String, dynamic> json) =>
    _InstalledApp(
      appId: json['app_id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      arch: json['arch'] as String?,
      channel: json['channel'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      kind: json['kind'] as String?,
      module: json['module'] as String?,
      runtime: json['runtime'] as String?,
      size: json['size'] as String?,
      repoName: json['repo_name'] as String?,
    );

Map<String, dynamic> _$InstalledAppToJson(_InstalledApp instance) =>
    <String, dynamic>{
      'app_id': instance.appId,
      'name': instance.name,
      'version': instance.version,
      'arch': instance.arch,
      'channel': instance.channel,
      'description': instance.description,
      'icon': instance.icon,
      'kind': instance.kind,
      'module': instance.module,
      'runtime': instance.runtime,
      'size': instance.size,
      'repo_name': instance.repoName,
    };
