// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_operation_failure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppOperationFailure _$AppOperationFailureFromJson(Map<String, dynamic> json) =>
    _AppOperationFailure(
      kind: $enumDecode(_$AppOperationFailureKindEnumMap, json['kind']),
      cliCode: (json['cliCode'] as num?)?.toInt(),
      diagnostic: json['diagnostic'] as String?,
      guidanceScenario: $enumDecodeNullable(
        _$LinuxDistributionGuidanceScenarioEnumMap,
        json['guidanceScenario'],
      ),
    );

Map<String, dynamic> _$AppOperationFailureToJson(
  _AppOperationFailure instance,
) => <String, dynamic>{
  'kind': _$AppOperationFailureKindEnumMap[instance.kind]!,
  'cliCode': instance.cliCode,
  'diagnostic': instance.diagnostic,
  'guidanceScenario':
      _$LinuxDistributionGuidanceScenarioEnumMap[instance.guidanceScenario],
};

const _$AppOperationFailureKindEnumMap = {
  AppOperationFailureKind.cli: 'cli',
  AppOperationFailureKind.timeout: 'timeout',
  AppOperationFailureKind.resultUnconfirmed: 'resultUnconfirmed',
  AppOperationFailureKind.streamEndedWithoutTerminal:
      'streamEndedWithoutTerminal',
  AppOperationFailureKind.execution: 'execution',
  AppOperationFailureKind.interrupted: 'interrupted',
};

const _$LinuxDistributionGuidanceScenarioEnumMap = {
  LinuxDistributionGuidanceScenario.envInstallDialog: 'envInstallDialog',
  LinuxDistributionGuidanceScenario.appInstallFailure: 'appInstallFailure',
  LinuxDistributionGuidanceScenario.appUpdateFailure: 'appUpdateFailure',
};
