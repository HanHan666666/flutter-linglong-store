// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linux_distribution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinuxDistribution _$LinuxDistributionFromJson(Map<String, dynamic> json) =>
    _LinuxDistribution(
      id:
          $enumDecodeNullable(_$LinuxDistributionIdEnumMap, json['id']) ??
          LinuxDistributionId.unknown,
      displayName: json['displayName'] as String? ?? '',
      capabilities:
          (json['capabilities'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$LinuxDistributionCapabilityEnumMap, e))
              .toList() ??
          const <LinuxDistributionCapability>[],
    );

Map<String, dynamic> _$LinuxDistributionToJson(_LinuxDistribution instance) =>
    <String, dynamic>{
      'id': _$LinuxDistributionIdEnumMap[instance.id]!,
      'displayName': instance.displayName,
      'capabilities': instance.capabilities
          .map((e) => _$LinuxDistributionCapabilityEnumMap[e]!)
          .toList(),
    };

const _$LinuxDistributionIdEnumMap = {
  LinuxDistributionId.unknown: 'unknown',
  LinuxDistributionId.uos: 'uos',
};

const _$LinuxDistributionCapabilityEnumMap = {
  LinuxDistributionCapability.envInstallGuidance: 'envInstallGuidance',
  LinuxDistributionCapability.envInstallRequiresDeveloperMode:
      'envInstallRequiresDeveloperMode',
  LinuxDistributionCapability.envInstallRequiresRootPrivilege:
      'envInstallRequiresRootPrivilege',
  LinuxDistributionCapability.appInstallFailureGuidance:
      'appInstallFailureGuidance',
  LinuxDistributionCapability.appUpdateFailureGuidance:
      'appUpdateFailureGuidance',
};
