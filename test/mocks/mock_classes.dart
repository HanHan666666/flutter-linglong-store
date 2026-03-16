import 'dart:async';

import 'package:mockito/annotations.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/running_app.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/repositories/app_repository.dart';
import 'package:linglong_store/domain/repositories/linglong_cli_repository.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/core/storage/cache_service.dart';
import 'package:linglong_store/data/datasources/remote/app_api_service.dart';

/// Mock 类定义
///
/// 运行 build_runner 生成具体的 Mock 实现:
/// ```bash
/// flutter pub run build_runner build --delete-conflicting-outputs
/// ```
@GenerateMocks([
  AppRepository,
  LinglongCliRepository,
  AnalyticsRepository,
  ApiClient,
  PreferencesService,
  CacheService,
  AppApiService,
])
void main() {}

/// Mock CLI 输出结果
class MockCliOutput {
  const MockCliOutput({
    required this.stdout,
    required this.stderr,
    required this.success,
    required this.statusCode,
  });

  final String stdout;
  final String stderr;
  final bool success;
  final int statusCode;

  /// 成功的 CLI 输出
  static MockCliOutput successOutput(String stdout) => MockCliOutput(
        stdout: stdout,
        stderr: '',
        success: true,
        statusCode: 0,
      );

  /// 失败的 CLI 输出
  static MockCliOutput failureOutput(String stderr, [int statusCode = 1]) =>
      MockCliOutput(
        stdout: '',
        stderr: stderr,
        success: false,
        statusCode: statusCode,
      );
}

/// Mock 安装进度流
class MockInstallProgressStream {
  final List<InstallProgress> _progressList;
  int _index = 0;

  MockInstallProgressStream(this._progressList);

  /// 创建一个模拟的安装进度流
  ///
  /// [appId] 应用 ID
  /// [stages] 各阶段进度百分比列表
  static MockInstallProgressStream create(
    String appId, {
    List<double> stages = const [0.0, 0.25, 0.5, 0.75, 1.0],
  }) {
    return MockInstallProgressStream(
      stages.map((progress) => InstallProgress(
        appId: appId,
        status: progress < 1.0 ? InstallStatus.installing : InstallStatus.success,
        progress: progress,
        message: _getProgressMessage(progress),
      )).toList(),
    );
  }

  static String _getProgressMessage(double progress) {
    if (progress < 0.3) return 'Downloading...';
    if (progress < 0.6) return 'Installing...';
    if (progress < 1.0) return 'Finishing...';
    return 'Complete';
  }

  InstallProgress? next() {
    if (_index < _progressList.length) {
      return _progressList[_index++];
    }
    return null;
  }

  Stream<InstallProgress> asStream() async* {
    for (final progress in _progressList) {
      yield progress;
    }
  }
}

/// 测试数据构建器 - InstalledApp
class InstalledAppBuilder {
  String _appId = 'com.example.test';
  String _name = 'Test App';
  String _version = '1.0.0';
  String? _arch;
  String? _channel;
  String? _description;
  String? _icon;
  String? _kind;
  String? _module;
  String? _runtime;
  String? _size;
  String? _repoName;

  InstalledAppBuilder withAppId(String appId) {
    _appId = appId;
    return this;
  }

  InstalledAppBuilder withName(String name) {
    _name = name;
    return this;
  }

  InstalledAppBuilder withVersion(String version) {
    _version = version;
    return this;
  }

  InstalledAppBuilder withIcon(String icon) {
    _icon = icon;
    return this;
  }

  InstalledAppBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  InstalledAppBuilder withSize(String size) {
    _size = size;
    return this;
  }

  InstalledAppBuilder withArch(String arch) {
    _arch = arch;
    return this;
  }

  InstalledAppBuilder withChannel(String channel) {
    _channel = channel;
    return this;
  }

  InstalledAppBuilder withKind(String kind) {
    _kind = kind;
    return this;
  }

  InstalledAppBuilder withModule(String module) {
    _module = module;
    return this;
  }

  InstalledAppBuilder withRuntime(String runtime) {
    _runtime = runtime;
    return this;
  }

  InstalledAppBuilder withRepoName(String repoName) {
    _repoName = repoName;
    return this;
  }

  InstalledApp build() {
    return InstalledApp(
      appId: _appId,
      name: _name,
      version: _version,
      arch: _arch,
      channel: _channel,
      description: _description ?? 'Test app description',
      icon: _icon ?? 'https://example.com/icon.png',
      kind: _kind,
      module: _module,
      runtime: _runtime,
      size: _size ?? '10.5 MB',
      repoName: _repoName ?? 'community',
    );
  }
}

/// 测试数据构建器 - RunningApp
class RunningAppBuilder {
  String _appId = 'com.example.test';
  String _name = 'Test App';
  int _pid = 12345;
  String? _icon;

  RunningAppBuilder withAppId(String appId) {
    _appId = appId;
    return this;
  }

  RunningAppBuilder withName(String name) {
    _name = name;
    return this;
  }

  RunningAppBuilder withPid(int pid) {
    _pid = pid;
    return this;
  }

  RunningAppBuilder withIcon(String icon) {
    _icon = icon;
    return this;
  }

  RunningApp build() {
    return RunningApp(
      appId: _appId,
      name: _name,
      pid: _pid,
      icon: _icon,
    );
  }
}