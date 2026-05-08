import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../logging/app_logger.dart';
import '../storage/app_data_directory_migration.dart';

enum LinuxRendererMode { software, hardware }

enum LinuxRendererPreference { auto, software, hardware }

enum LinuxRendererDecisionSource {
  environment,
  userPreference,
  cpuFallback,
  defaultMode,
}

extension LinuxRendererModeValue on LinuxRendererMode {
  String get value => switch (this) {
    LinuxRendererMode.software => 'software',
    LinuxRendererMode.hardware => 'hardware',
  };
}

extension LinuxRendererPreferenceValue on LinuxRendererPreference {
  String get value => switch (this) {
    LinuxRendererPreference.auto => 'auto',
    LinuxRendererPreference.software => 'software',
    LinuxRendererPreference.hardware => 'hardware',
  };
}

extension LinuxRendererDecisionSourceValue on LinuxRendererDecisionSource {
  String get value => switch (this) {
    LinuxRendererDecisionSource.environment => 'environment',
    LinuxRendererDecisionSource.userPreference => 'userPreference',
    LinuxRendererDecisionSource.cpuFallback => 'cpuFallback',
    LinuxRendererDecisionSource.defaultMode => 'default',
  };
}

LinuxRendererMode parseLinuxRendererMode(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'software':
      return LinuxRendererMode.software;
    default:
      return LinuxRendererMode.hardware;
  }
}

LinuxRendererPreference parseLinuxRendererPreference(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'software':
      return LinuxRendererPreference.software;
    case 'hardware':
      return LinuxRendererPreference.hardware;
    default:
      return LinuxRendererPreference.auto;
  }
}

LinuxRendererDecisionSource parseLinuxRendererDecisionSource(String? value) {
  switch ((value ?? '').trim()) {
    case 'environment':
      return LinuxRendererDecisionSource.environment;
    case 'userPreference':
      return LinuxRendererDecisionSource.userPreference;
    case 'cpuFallback':
      return LinuxRendererDecisionSource.cpuFallback;
    default:
      return LinuxRendererDecisionSource.defaultMode;
  }
}

class LinuxRendererRuntimeState {
  const LinuxRendererRuntimeState({
    required this.currentMode,
    required this.decisionSource,
    required this.isCpuWhitelisted,
    required this.cpuVendor,
    required this.cpuModel,
    required this.environmentValue,
  });

  final LinuxRendererMode currentMode;
  final LinuxRendererDecisionSource decisionSource;
  final bool isCpuWhitelisted;
  final String cpuVendor;
  final String cpuModel;
  final String? environmentValue;

  bool get isSoftware => currentMode == LinuxRendererMode.software;

  bool get isEnvironmentLocked =>
      decisionSource == LinuxRendererDecisionSource.environment &&
      (environmentValue?.isNotEmpty ?? false);

  factory LinuxRendererRuntimeState.fromMap(Map<Object?, Object?> map) {
    return LinuxRendererRuntimeState(
      currentMode: parseLinuxRendererMode(map['currentMode']?.toString()),
      decisionSource: parseLinuxRendererDecisionSource(
        map['decisionSource']?.toString(),
      ),
      isCpuWhitelisted: map['isCpuWhitelisted'] == true,
      cpuVendor: map['cpuVendor']?.toString() ?? '',
      cpuModel: map['cpuModel']?.toString() ?? '',
      environmentValue: map['environmentValue']?.toString(),
    );
  }

  factory LinuxRendererRuntimeState.fallback() {
    final environmentValue = Platform.environment['FLUTTER_LINUX_RENDERER'];
    final isEnvironmentLocked =
        environmentValue != null && environmentValue.trim().isNotEmpty;
    return LinuxRendererRuntimeState(
      currentMode: parseLinuxRendererMode(environmentValue),
      decisionSource: isEnvironmentLocked
          ? LinuxRendererDecisionSource.environment
          : LinuxRendererDecisionSource.defaultMode,
      isCpuWhitelisted: true,
      cpuVendor: '',
      cpuModel: '',
      environmentValue: environmentValue,
    );
  }
}

class LinuxRendererRecoveryInfo {
  const LinuxRendererRecoveryInfo({
    required this.dataDirectoryPath,
    required this.deleteDataDirectoryCommand,
  });

  final String? dataDirectoryPath;
  final String? deleteDataDirectoryCommand;

  bool get isAvailable =>
      dataDirectoryPath != null && deleteDataDirectoryCommand != null;
}

class LinuxRendererService {
  LinuxRendererService({
    MethodChannel? channel,
    String? configFilePathOverride,
    String? dataDirectoryPathOverride,
  }) : _channel =
           channel ?? const MethodChannel('org.linglong_store/linux_renderer'),
       _configFilePathOverride = configFilePathOverride,
       _dataDirectoryPathOverride = dataDirectoryPathOverride;

  static const String configDirectoryName = 'startup';
  static const String configFileName = 'renderer_preferences.ini';
  static const String _configSectionHeader = '[renderer]';
  static const String _preferredModeKey = 'preferred_mode';

  final MethodChannel _channel;
  final String? _configFilePathOverride;
  final String? _dataDirectoryPathOverride;

  LinuxRendererPreference loadPersistedPreferenceSync() {
    final configFilePath = _resolveConfigFilePath();
    if (configFilePath == null) {
      return LinuxRendererPreference.auto;
    }

    final file = File(configFilePath);
    if (!file.existsSync()) {
      return LinuxRendererPreference.auto;
    }

    try {
      final content = file.readAsStringSync();
      return _parseConfigContent(content);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to read renderer preference config',
        error,
        stackTrace,
      );
      return LinuxRendererPreference.auto;
    }
  }

  Future<void> savePreferredMode(LinuxRendererPreference preference) async {
    final configFilePath = _resolveConfigFilePath();
    if (configFilePath == null) {
      throw StateError('Unable to resolve renderer config file path.');
    }

    final file = File(configFilePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(_serializeConfigContent(preference));
  }

  Future<LinuxRendererRuntimeState> getRuntimeState() async {
    if (!Platform.isLinux) {
      return LinuxRendererRuntimeState.fallback();
    }

    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getRendererRuntimeState',
      );
      if (result == null) {
        return LinuxRendererRuntimeState.fallback();
      }
      return LinuxRendererRuntimeState.fromMap(result);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to query Linux renderer runtime state',
        error,
        stackTrace,
      );
      return LinuxRendererRuntimeState.fallback();
    }
  }

  LinuxRendererRecoveryInfo buildRecoveryInfo() {
    final dataDirectoryPath =
        _dataDirectoryPathOverride ??
        AppDataDirectoryMigration.resolveCurrentDataDirectoryPath();
    if (dataDirectoryPath == null || dataDirectoryPath.isEmpty) {
      return const LinuxRendererRecoveryInfo(
        dataDirectoryPath: null,
        deleteDataDirectoryCommand: null,
      );
    }

    final deleteCommand = "rm -rf -- ${shellQuote(dataDirectoryPath)}";
    return LinuxRendererRecoveryInfo(
      dataDirectoryPath: dataDirectoryPath,
      deleteDataDirectoryCommand: deleteCommand,
    );
  }

  bool resolveNextLaunchUsesSoftwareRendering({
    required LinuxRendererRuntimeState runtimeState,
    required LinuxRendererPreference preference,
  }) {
    if (runtimeState.isEnvironmentLocked) {
      return runtimeState.isSoftware;
    }

    return switch (preference) {
      LinuxRendererPreference.auto => !runtimeState.isCpuWhitelisted,
      LinuxRendererPreference.software => true,
      LinuxRendererPreference.hardware => false,
    };
  }

  String? resolveConfigFilePathForDebug() => _resolveConfigFilePath();

  LinuxRendererPreference _parseConfigContent(String content) {
    for (final rawLine in const LineSplitter().convert(content)) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('[')) {
        continue;
      }
      if (!line.startsWith('$_preferredModeKey=')) {
        continue;
      }

      final value = line.substring('$_preferredModeKey='.length);
      return parseLinuxRendererPreference(value);
    }

    return LinuxRendererPreference.auto;
  }

  String _serializeConfigContent(LinuxRendererPreference preference) {
    return <String>[
      '# Linux renderer preference for startup-time Linux runner decisions.',
      _configSectionHeader,
      '$_preferredModeKey=${preference.value}',
      '',
    ].join('\n');
  }

  String? _resolveConfigFilePath() {
    if (_configFilePathOverride != null) {
      return _configFilePathOverride;
    }

    final currentDataDirectoryPath =
        AppDataDirectoryMigration.resolveCurrentDataDirectoryPath();
    if (currentDataDirectoryPath == null ||
        currentDataDirectoryPath.isEmpty) {
      return null;
    }

    return [
      currentDataDirectoryPath,
      configDirectoryName,
      configFileName,
    ].join(Platform.pathSeparator);
  }
}

String shellQuote(String value) {
  if (value.isEmpty) {
    return "''";
  }

  return "'${value.replaceAll("'", "'\"'\"'")}'";
}
