import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/installed_app_diff_report_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../mocks/mock_classes.mocks.dart';

/// 记录型统计仓储 Fake：捕获每轮差量上报内容供断言。
class _RecordingAnalyticsRepository implements AnalyticsRepository {
  final List<(List<InstalledApp> added, List<InstalledApp> removed)> reports =
      [];

  @override
  Future<void> initializeSession() async {}

  @override
  Future<void> reportVisit({
    String? arch,
    String? llVersion,
    String? llBinVersion,
    String? detailMsg,
    String? osVersion,
    String? repoName,
    String? appVersion,
  }) async {}

  @override
  Future<void> reportInstall(String appId, String version, {String? appName}) {
    return Future.value();
  }

  @override
  Future<void> reportUninstall(String appId, String version, {String? appName}) {
    return Future.value();
  }

  @override
  Future<void> reportInstalledAppsDiff({
    required List<InstalledApp> addedItems,
    required List<InstalledApp> removedItems,
  }) async {
    reports.add((addedItems, removedItems));
  }
}

InstalledApp _app(String appId, String version) {
  return InstalledApp(appId: appId, name: appId, version: version);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLinglongCliRepository cliRepository;
  late _RecordingAnalyticsRepository analyticsRepository;

  /// 以零防抖构建服务，检测在下一个事件循环即执行，测试无需真实等待。
  InstalledAppDiffReportService buildService({Duration? pollInterval}) {
    return InstalledAppDiffReportService(
      cliRepository: cliRepository,
      analyticsRepository: analyticsRepository,
      pollInterval: pollInterval ?? const Duration(minutes: 30),
      debounceDelay: Duration.zero,
    );
  }

  /// 等待零防抖 Timer 与异步检测链路跑完。
  Future<void> pumpChecks([int rounds = 4]) async {
    for (var i = 0; i < rounds; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void stubInstalled(List<InstalledApp> apps) {
    when(
      cliRepository.getInstalledApps(includeBaseService: true),
    ).thenAnswer((_) async => apps);
  }

  setUp(() {
    cliRepository = MockLinglongCliRepository();
    analyticsRepository = _RecordingAnalyticsRepository();
  });

  setUpAll(() async {
    // 服务异常分支会走 AppLogger.warning，测试进程需先初始化日志器。
    await AppLogger.init();
  });

  test('启动首轮以全量已安装列表作为基线上报', () async {
    stubInstalled([_app('org.a', '1.0.0'), _app('org.b', '2.0.0')]);
    final service = buildService();

    service.start();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
    final (added, removed) = analyticsRepository.reports.single;
    expect(added.map((a) => a.appId), unorderedEquals(['org.a', 'org.b']));
    expect(removed, isEmpty);
  });

  test('列表无变化时不重复上报', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService();

    service.start();
    await pumpChecks();

    service.scheduleImmediateCheck();
    service.scheduleImmediateCheck();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
  });

  test('外部安装与卸载通过差量捕获', () async {
    var installed = <InstalledApp>[_app('org.a', '1.0.0'), _app('org.b', '1.0.0')];
    stubInstalled(installed);
    final service = buildService();

    service.start();
    await pumpChecks();

    // 模拟商店外途径：新增 org.c、卸载 org.b。
    installed = [_app('org.a', '1.0.0'), _app('org.c', '1.0.0')];
    stubInstalled(installed);
    service.scheduleImmediateCheck();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(2));
    final (added, removed) = analyticsRepository.reports.last;
    expect(added.map((a) => a.appId), ['org.c']);
    expect(removed.map((a) => a.appId), ['org.b']);
  });

  test('应用更新上报为新版本新增且旧版本移除', () async {
    var installed = <InstalledApp>[_app('org.a', '1.0.0')];
    stubInstalled(installed);
    final service = buildService();

    service.start();
    await pumpChecks();

    installed = [_app('org.a', '2.0.0')];
    stubInstalled(installed);
    service.scheduleImmediateCheck();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(2));
    final (added, removed) = analyticsRepository.reports.last;
    expect(added.single.version, '2.0.0');
    expect(removed.single.version, '1.0.0');
  });

  test('ll-cli 异常不影响既有快照且后续轮次可恢复', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService();

    service.start();
    await pumpChecks();

    when(cliRepository.getInstalledApps(includeBaseService: true))
        .thenThrow(Exception('ll-cli failed'));
    service.scheduleImmediateCheck();
    await pumpChecks();

    // 异常轮之后的正常列表仍可与失败前快照正确对比，无重复基线。
    stubInstalled([_app('org.a', '1.0.0'), _app('org.d', '3.0.0')]);
    service.scheduleImmediateCheck();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(2));
    expect(analyticsRepository.reports.last.$1.map((a) => a.appId), ['org.d']);
  });

  test('窗口隐藏暂停轮询，恢复可见后立即补检', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService(pollInterval: const Duration(milliseconds: 20));

    service.start();
    await pumpChecks();
    final callsAfterStart = analyticsRepository.reports.length;

    service.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(analyticsRepository.reports.length, callsAfterStart);

    // 恢复可见触发立即补检（列表未变只刷新快照，不新增上报），
    // 这里通过变更列表验证补检确实执行了。
    stubInstalled([_app('org.a', '1.0.0'), _app('org.e', '1.0.0')]);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpChecks();
    expect(analyticsRepository.reports.length, callsAfterStart + 1);
    expect(
      analyticsRepository.reports.last.$1.map((a) => a.appId),
      ['org.e'],
    );
    service.dispose();
  });

  test('start 重复调用幂等，不产生第二次基线上报', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService();

    service.start();
    service.start();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
  });
}
