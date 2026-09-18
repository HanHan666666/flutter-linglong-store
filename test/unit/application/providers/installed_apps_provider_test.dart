/// 验证已安装快照刷新契约：成败回报与并发请求守卫。
///
/// 该 Provider 是"更新列表"判定的唯一事实来源，因此这里钉住两条边界：
/// 刷新失败时不得把旧快照伪装成最新事实；并发刷新时先发起的旧快照不得
/// 覆盖后发起的新快照（否则刚更新的版本会被旧版本再次判定为可更新）。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/setting_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:mockito/mockito.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    // 刷新失败分支会写入诊断日志，测试进程需要先初始化日志器。
    await AppLogger.init();
  });

  group('InstalledApps.refresh', () {
    test('刷新成功时回报 true 并落下富化后的新快照', () async {
      final cliRepository = MockLinglongCliRepository();
      final appRepository = MockAppRepository();
      when(
        cliRepository.getInstalledApps(includeBaseService: anyNamed('includeBaseService')),
      ).thenAnswer((_) async => [_installed('2.0.0')]);
      when(
        appRepository.enrichInstalledAppsWithDetails(any),
      ).thenAnswer((invocation) async => _enrich(invocation));

      final container = _createContainer(cliRepository, appRepository);
      addTearDown(container.dispose);

      final refreshed = await container
          .read(installedAppsProvider.notifier)
          .refresh();

      expect(refreshed, isTrue);
      final state = container.read(installedAppsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.apps.single.version, '2.0.0');
      expect(state.apps.single.name, '富化名称');
    });

    test('刷新失败时回报 false 并保留最后一次成功快照', () async {
      final cliRepository = MockLinglongCliRepository();
      final appRepository = MockAppRepository();
      var calls = 0;
      when(
        cliRepository.getInstalledApps(includeBaseService: anyNamed('includeBaseService')),
      ).thenAnswer((_) async {
        calls += 1;
        if (calls == 1) {
          return [_installed('1.0.0')];
        }
        throw Exception('ll-cli 不可用');
      });
      when(
        appRepository.enrichInstalledAppsWithDetails(any),
      ).thenAnswer((invocation) async => _enrich(invocation));

      final container = _createContainer(cliRepository, appRepository);
      addTearDown(container.dispose);

      final notifier = container.read(installedAppsProvider.notifier);
      // 先落下一次成功快照，作为失败后的可见兜底数据。
      expect(await notifier.refresh(), isTrue);

      final refreshed = await notifier.refresh();

      expect(refreshed, isFalse);
      final state = container.read(installedAppsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      // 保留旧快照，但调用方已经从返回值知道它不可信。
      expect(state.apps.single.version, '1.0.0');
    });

    test('旧请求的响应不会覆盖后发起请求的快照', () async {
      final cliRepository = MockLinglongCliRepository();
      final appRepository = MockAppRepository();
      final firstResponse = Completer<List<InstalledApp>>();
      final secondResponse = Completer<List<InstalledApp>>();
      var calls = 0;
      when(
        cliRepository.getInstalledApps(includeBaseService: anyNamed('includeBaseService')),
      ).thenAnswer((_) {
        calls += 1;
        return calls == 1 ? firstResponse.future : secondResponse.future;
      });
      when(
        appRepository.enrichInstalledAppsWithDetails(any),
      ).thenAnswer((invocation) async => _enrich(invocation));

      final container = _createContainer(cliRepository, appRepository);
      addTearDown(container.dispose);

      final notifier = container.read(installedAppsProvider.notifier);
      final firstRefresh = notifier.refresh();
      final secondRefresh = notifier.refresh();

      // 后发起的请求先返回，必须成为最终可见快照。
      secondResponse.complete([_installed('2.0.0')]);
      expect(await secondRefresh, isTrue);
      expect(container.read(installedAppsProvider).apps.single.version, '2.0.0');

      // 先发起的旧请求随后返回，必须被丢弃且不得改写状态。
      firstResponse.complete([_installed('1.0.0')]);
      expect(await firstRefresh, isFalse);
      expect(container.read(installedAppsProvider).apps.single.version, '2.0.0');
    });
  });
}

/// 创建注入了可控仓储替身的隔离容器。
ProviderContainer _createContainer(
  MockLinglongCliRepository cliRepository,
  MockAppRepository appRepository,
) {
  return ProviderContainer(
    overrides: [
      linglongCliRepositoryProvider.overrideWithValue(cliRepository),
      appRepositoryProvider.overrideWithValue(appRepository),
      settingProvider.overrideWith(_TestSetting.new),
    ],
  );
}

/// 构造一个已安装应用快照项。
InstalledApp _installed(String version) {
  return InstalledApp(
    appId: 'org.example.demo',
    name: 'Demo',
    version: version,
  );
}

/// 模拟详情富化：返回带富化名称的列表，用于证明富化结果确实落盘。
List<InstalledApp> _enrich(Invocation invocation) {
  final apps = invocation.positionalArguments.first as List<InstalledApp>;
  return apps
      .map((app) => app.copyWith(name: '富化名称'))
      .toList(growable: false);
}

/// 固定返回默认设置的设置状态替身，避免依赖 SharedPreferences。
class _TestSetting extends Setting {
  @override
  SettingState build() => const SettingState();
}
