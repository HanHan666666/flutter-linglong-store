import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/installed_app_diff_report_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 构建携带完整匹配字段的应用，模拟真实 ll-cli 输出（arch/module/channel 等）。
InstalledApp _fullApp(String appId, String version) {
  return InstalledApp(
    appId: appId,
    name: appId,
    version: version,
    arch: 'x86_64',
    module: 'runtime',
    channel: 'stable',
    kind: 'app',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLinglongCliRepository cliRepository;
  late _RecordingAnalyticsRepository analyticsRepository;

  /// 以零防抖构建服务，检测在下一个事件循环即执行，测试无需真实等待。
  ///
  /// 默认注入空基线加载器（返回 null），模拟首次运行无历史基线的场景，
  /// 同时避免测试依赖 PreferencesService。需要持久化基线的测试请显式传入
  /// [baselineLoader] / [baselineSaver]。
  InstalledAppDiffReportService buildService({
    Duration? pollInterval,
    Future<List<InstalledApp>?> Function()? baselineLoader,
    Future<void> Function(List<InstalledApp>)? baselineSaver,
  }) {
    return InstalledAppDiffReportService(
      cliRepository: cliRepository,
      analyticsRepository: analyticsRepository,
      pollInterval: pollInterval ?? const Duration(minutes: 30),
      debounceDelay: Duration.zero,
      baselineLoader: baselineLoader ?? () async => null,
      baselineSaver: baselineSaver ?? (_) async {},
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
    SharedPreferences.setMockInitialValues({});
    cliRepository = MockLinglongCliRepository();
    analyticsRepository = _RecordingAnalyticsRepository();
  });

  setUpAll(() async {
    // 服务异常分支会走 AppLogger.warning，测试进程需先初始化日志器。
    await AppLogger.init();
  });

  test('首次运行（无历史基线）以全量已安装列表作为基线上报', () async {
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

  test('用户体验计划关闭时暂停检测与轮询，重开后恢复并补全基线', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService(pollInterval: const Duration(milliseconds: 20));

    // 启动后立即关闭计划：首轮基线检测被防抖取消。
    service.start();
    service.setReportingEnabled(false);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(analyticsRepository.reports, isEmpty);

    // 关闭期间轮询也不执行：窗口恢复可见同样不应触发检测。
    service.didChangeAppLifecycleState(AppLifecycleState.hidden);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(analyticsRepository.reports, isEmpty);

    // 重新开启后立即补检，快照仍为空 → 全量基线上报。
    stubInstalled([_app('org.a', '1.0.0'), _app('org.f', '1.0.0')]);
    service.setReportingEnabled(true);
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
    final (added, removed) = analyticsRepository.reports.single;
    expect(added.map((a) => a.appId), unorderedEquals(['org.a', 'org.f']));
    expect(removed, isEmpty);
  });

  test('start 前已关闭计划时不执行首轮检测', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService();

    service.setReportingEnabled(false);
    service.start();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, isEmpty);
  });

  // -------------------------------------------------------------------
  // 持久化基线相关测试
  // -------------------------------------------------------------------

  test('有历史基线时重启只上报差值，不重复计数', () async {
    // 模拟上一次会话已持久化的基线：org.a 和 org.b 已经记录过。
    final storage = [_app('org.a', '1.0.0'), _app('org.b', '2.0.0')];
    stubInstalled([
      _app('org.a', '1.0.0'),
      _app('org.b', '2.0.0'),
      _app('org.c', '1.0.0'),
    ]);

    final service = buildService(
      baselineLoader: () async => storage,
    );

    service.start();
    await pumpChecks();
    service.dispose();

    // 只应上报新增的 org.c，已在基线中的 org.a/org.b 不计入。
    expect(analyticsRepository.reports, hasLength(1));
    final (added, removed) = analyticsRepository.reports.single;
    expect(added.map((a) => a.appId), ['org.c']);
    expect(removed, isEmpty);
  });

  test('持久化基线在每次检测后更新写入完整对象', () async {
    final storedBaseline = <InstalledApp>[_app('org.a', '1.0.0')];
    var savedBaseline = <InstalledApp>[];

    stubInstalled([_app('org.a', '1.0.0'), _app('org.b', '2.0.0')]);
    final service = buildService(
      baselineLoader: () async => storedBaseline,
      baselineSaver: (apps) async {
        savedBaseline = apps;
      },
    );

    service.start();
    await pumpChecks();

    // 写入的基线应包含当前所有应用的完整对象。
    expect(savedBaseline.map((a) => _identity(a)), unorderedEquals([
      'org.a@1.0.0',
      'org.b@2.0.0',
    ]));
    service.dispose();
  });

  test('重启后卸载的应用出现在 removedItems 中且字段完整', () async {
    // 上次基线有三个应用，本次只剩两个（org.b 被卸载）。
    // 基线使用完整字段对象，验证卸载记录上报时字段不丢失。
    final storage = [
      _fullApp('org.a', '1.0.0'),
      _fullApp('org.b', '2.0.0'),
      _fullApp('org.c', '1.0.0'),
    ];
    stubInstalled([_fullApp('org.a', '1.0.0'), _fullApp('org.c', '1.0.0')]);

    final service = buildService(
      baselineLoader: () async => storage,
    );

    service.start();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
    final (added, removed) = analyticsRepository.reports.single;
    expect(added, isEmpty);
    expect(removed.map((a) => a.appId), ['org.b']);
    // 卸载记录应携带完整字段（appId/name/version/arch/module/channel 等），
    // 保证服务端按非空字段匹配主表不会失败。
    expect(removed.single.arch, 'x86_64');
    expect(removed.single.module, 'runtime');
    expect(removed.single.channel, 'stable');
  });

  test('持久化基线中已有的应用，重启后更新仍正确报旧版本移除+新版本新增', () async {
    final storage = [_app('org.a', '1.0.0')];
    stubInstalled([_app('org.a', '2.0.0')]);

    final service = buildService(
      baselineLoader: () async => storage,
    );

    service.start();
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports, hasLength(1));
    final (added, removed) = analyticsRepository.reports.single;
    expect(added.single.version, '2.0.0');
    expect(removed.single.version, '1.0.0');
  });

  test('基线加载失败时回退为空基线，不阻断检测', () async {
    stubInstalled([_app('org.a', '1.0.0')]);
    final service = buildService(
      baselineLoader: () async => throw Exception('storage error'),
    );

    service.start();
    await pumpChecks();
    service.dispose();

    // 加载失败 → 空基线兜底 → 全量作为 added 上报（与首次运行一致）。
    expect(analyticsRepository.reports, hasLength(1));
    final (added, _) = analyticsRepository.reports.single;
    expect(added.map((a) => a.appId), ['org.a']);
  });

  test('体验计划关闭后再开启，基于持久化基线对比差值', () async {
    // 启动时基线已有 org.a，关闭计划期间外部安装了 org.b。
    final storage = [_app('org.a', '1.0.0')];
    stubInstalled([_app('org.a', '1.0.0')]);

    final service = buildService(
      baselineLoader: () async => storage,
    );

    service.start();
    await pumpChecks();
    final startReports = analyticsRepository.reports.length;

    // 关闭计划
    service.setReportingEnabled(false);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // 关闭期间外部安装 org.b
    stubInstalled([_app('org.a', '1.0.0'), _app('org.b', '1.0.0')]);

    // 重新开启：应只报 org.b，不应全量重新计数
    service.setReportingEnabled(true);
    await pumpChecks();
    service.dispose();

    expect(analyticsRepository.reports.length, startReports + 1);
    final (added, removed) = analyticsRepository.reports.last;
    expect(added.map((a) => a.appId), ['org.b']);
    expect(removed, isEmpty);
  });

  test('默认持久化实现逐条容错：单条损坏 JSON 被跳过，正常条目仍用于对比', () async {
    // 直接通过默认 loader/saver 验证持久化往返与容错。
    // 该测试是唯一使用静态 PreferencesService 的用例，因此在本测试内完成
    // mock 初始化，避免与其它测试注入的 loader/saver 及 mock 重设相互干扰。
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();

    final baseline = [
      _app('org.a', '1.0.0'),
      _app('org.b', '2.0.0'),
    ];
    await InstalledAppDiffReportService.defaultBaselineSaver(baseline);

    // 直接在底层存储中追加一条损坏 JSON（模拟存储脏数据）。
    final rawList = PreferencesService.getStringList(
          'installed_diff_baseline_objects',
        ) ??
        <String>[];
    rawList.add('not-valid-json{{{');
    await PreferencesService.setStringList(
      'installed_diff_baseline_objects',
      rawList,
    );

    final loaded = await InstalledAppDiffReportService.defaultBaselineLoader();
    expect(loaded, isNotNull);
    expect(loaded!.map((a) => a.appId), ['org.a', 'org.b']);
  });
}

/// 生成测试用的差量身份键，便于断言存储内容。
String _identity(InstalledApp app) => '${app.appId}@${app.version}';
