// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    _UserPreferences(
      autoCheckUpdate: json['autoCheckUpdate'] as bool? ?? true,
      showBetaApps: json['showBetaApps'] as bool? ?? false,
      showSystemApps: json['showSystemApps'] as bool? ?? false,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      autoCreateShortcut: json['autoCreateShortcut'] as bool? ?? true,
      downloadConcurrency: (json['downloadConcurrency'] as num?)?.toInt() ?? 3,
      autoRunAfterInstall: json['autoRunAfterInstall'] as bool? ?? false,
      compactMode: json['compactMode'] as bool? ?? false,
      fontScaleFactor:
          (json['fontScaleFactor'] as num?)?.toDouble() ??
          kDefaultUserFontScaleFactor,
      fontWeightAdjustment:
          $enumDecodeNullable(
            _$AppFontWeightAdjustmentEnumMap,
            json['fontWeightAdjustment'],
          ) ??
          AppFontWeightAdjustment.normal,
      customCategories:
          (json['customCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserPreferencesToJson(_UserPreferences instance) =>
    <String, dynamic>{
      'autoCheckUpdate': instance.autoCheckUpdate,
      'showBetaApps': instance.showBetaApps,
      'showSystemApps': instance.showSystemApps,
      'enableNotifications': instance.enableNotifications,
      'autoCreateShortcut': instance.autoCreateShortcut,
      'downloadConcurrency': instance.downloadConcurrency,
      'autoRunAfterInstall': instance.autoRunAfterInstall,
      'compactMode': instance.compactMode,
      'fontScaleFactor': instance.fontScaleFactor,
      'fontWeightAdjustment':
          _$AppFontWeightAdjustmentEnumMap[instance.fontWeightAdjustment]!,
      'customCategories': instance.customCategories,
    };

const _$AppFontWeightAdjustmentEnumMap = {
  AppFontWeightAdjustment.lighter: 'lighter',
  AppFontWeightAdjustment.normal: 'normal',
  AppFontWeightAdjustment.bolder: 'bolder',
};
