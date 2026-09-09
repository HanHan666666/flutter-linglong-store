/// 免密安装开关控制器测试（docs/50 §4、§5.2、§10.1）。
///
/// 覆盖：本地缓存解析与回退、首帧不调用特权侧、单飞与确认前置、目标值固定、
/// 授权取消恢复快照、冲突与回读失败的缓存语义、本地保存失败反馈，以及设置
/// 事务期间的队列出队暂停。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/application/providers/polkit_rule_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';
import 'package:linglong_store/domain/repositories/polkit_rule_gateway.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';
import '../../../mocks/mock_classes.mocks.dart';

/// 可编程的 Gateway 替身：记录目标值并支持“阻塞到测试放行”。
class _FakePolkitRuleGateway implements PolkitRuleGateway {
  _FakePolkitRuleGateway({this.result, this.error});

  PolkitRuleTransactionResult? result;
  Object? error;
  final List<bool> requests = <bool>[];

  /// 非空时 apply 会等待该 Completer，用于观察事务进行中的状态。
  Completer<void>? hold;

  /// 提权调用发生时回调，用于断言“先落盘待同步标记再提权”。
  Future<void> Function()? onApply;

  @override
  Future<PolkitRuleTransactionResult> apply({required bool enabled}) async {
    requests.add(enabled);
    final callback = onApply;
    if (callback != null) {
      await callback();
    }
    final gate = hold;
    if (gate != null) {
      await gate.future;
    }
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result!;
  }
}

/// 只让 setString 失败的 SharedPreferences 替身：其余调用转发给内存实现。
///
/// [successfulWrites] 允许前若干次写入成功，用于区分“提权前落盘待同步标记”
/// 与“操作结束后保存最终状态”两个阶段。
class _WriteFailingPreferences implements SharedPreferences {
  _WriteFailingPreferences(this._delegate, {this.successfulWrites = 0});

  final SharedPreferences _delegate;
  int successfulWrites;

  @override
  Future<bool> setString(String key, String value) async {
    if (successfulWrites > 0) {
      successfulWrites -= 1;
      return _delegate.setString(key, value);
    }
    return false;
  }

  @override
  Set<String> getKeys() => _delegate.getKeys();

  @override
  Object? get(String key) => _delegate.get(key);

  @override
  bool? getBool(String key) => _delegate.getBool(key);

  @override
  int? getInt(String key) => _delegate.getInt(key);

  @override
  double? getDouble(String key) => _delegate.getDouble(key);

  @override
  String? getString(String key) => _delegate.getString(key);

  @override
  List<String>? getStringList(String key) => _delegate.getStringList(key);

  @override
  bool containsKey(String key) => _delegate.containsKey(key);

  @override
  Future<bool> setBool(String key, bool value) => _delegate.setBool(key, value);

  @override
  Future<bool> setInt(String key, int value) => _delegate.setInt(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _delegate.setDouble(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _delegate.setStringList(key, value);

  @override
  Future<bool> remove(String key) => _delegate.remove(key);

  /// SharedPreferences 已废弃的提交入口，真实实现为空操作，替身保持一致。
  @override
  Future<bool> commit() async => true;

  @override
  Future<bool> clear() => _delegate.clear();

  @override
  Future<void> reload() => _delegate.reload();
}

/// 测试期间固定中文环境，避免队列读取 locale 时依赖真实平台。
class _FixedGlobalApp extends GlobalApp {
  @override
  GlobalAppState build() {
    return const GlobalAppState(locale: Locale('zh'), isInitialized: true);
  }
}

Future<SharedPreferences> _mockPreferences([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

ProviderContainer _createContainer({
  required _FakePolkitRuleGateway gateway,
  required SharedPreferences prefs,
  MockLinglongCliRepository? cliRepository,
}) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      polkitRuleGatewayProvider.overrideWithValue(gateway),
      appOperationJournalRepositoryProvider.overrideWithValue(
        MemoryAppOperationJournalRepository(),
      ),
      linglongCliRepositoryProvider.overrideWith(
        (ref) => cliRepository ?? MockLinglongCliRepository(),
      ),
      linglongEnvProvider.overrideWithValue(
        const LinglongEnvState(
          checkState: LinglongEnvCheckState.success,
          result: LinglongEnvCheckResult(
            isOk: true,
            distribution: LinuxDistribution.uos,
            checkedAt: 1,
          ),
        ),
      ),
      globalAppProvider.overrideWith(_FixedGlobalApp.new),
    ],
  );
}

/// 轮询等待条件成立（每 10ms 一次，最多 3s）。
Future<bool> _eventually(bool Function() condition) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    if (condition()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return false;
}

PolkitRuleTransactionResult _result({
  required bool requested,
  required PolkitRuleSystemState before,
  required PolkitRuleSystemState after,
  required PolkitRuleOutcome outcome,
  PolkitRuleFailureReason reason = PolkitRuleFailureReason.none,
}) {
  return PolkitRuleTransactionResult(
    requestedEnabled: requested,
    before: before,
    after: after,
    outcome: outcome,
    reason: reason,
  );
}

/// 构造一个能消费安装任务的 CLI 替身（用于观察队列是否恢复出队）。
MockLinglongCliRepository _buildConsumingCliRepository() {
  final repository = MockLinglongCliRepository();
  when(
    repository.installApp(any, version: anyNamed('version'), force: anyNamed('force')),
  ).thenAnswer(
    (_) => Stream<InstallProgress>.value(
      const InstallProgress(
        appId: 'ignored',
        status: InstallStatus.success,
        progress: 100,
      ),
    ),
  );
  return repository;
}

/// 入队一个任务并断言它被消费，证明队列暂停已释放。
Future<void> _expectQueueResumed(
  ProviderContainer container,
  MockLinglongCliRepository cliRepository,
) async {
  container
      .read(installQueueProvider.notifier)
      .enqueueOperation(
        kind: InstallTaskKind.install,
        appId: 'org.example.queued',
        appName: 'Queued',
      );
  final consumed = await _eventually(
    () => container.read(installQueueProvider).history.isNotEmpty,
  );
  expect(consumed, isTrue, reason: '事务结束后必须恢复出队');
  verify(
    cliRepository.installApp(any, version: anyNamed('version'), force: anyNamed('force')),
  ).called(1);
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  test('无缓存时默认关闭、不待同步，且进入页面不调用特权侧', () async {
    final gateway = _FakePolkitRuleGateway();
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final state = container.read(polkitRuleProvider);

    expect(state.enabled, isFalse);
    expect(state.needsSync, isFalse);
    expect(state.phase, PasswordFreeInstallPhase.ready);
    expect(state.usesPasswordFreeCli, isFalse);
    expect(gateway.requests, isEmpty);
  });

  test('缓存损坏或版本不支持时关闭显示并标记待同步', () async {
    for (final raw in <String>['not json', '{"version":2,"enabled":true}']) {
      final container = _createContainer(
        gateway: _FakePolkitRuleGateway(),
        prefs: await _mockPreferences({
          PasswordFreeInstallCache.preferencesKey: raw,
        }),
      );
      addTearDown(container.dispose);

      final state = container.read(polkitRuleProvider);

      expect(state.enabled, isFalse, reason: raw);
      expect(state.needsSync, isTrue, reason: raw);
      expect(state.usesPasswordFreeCli, isFalse, reason: raw);
    }
  });

  test('有效缓存恢复开启且不待同步', () async {
    final container = _createContainer(
      gateway: _FakePolkitRuleGateway(),
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: false)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final state = container.read(polkitRuleProvider);

    expect(state.enabled, isTrue);
    expect(state.needsSync, isFalse);
    expect(state.usesPasswordFreeCli, isTrue);
  });

  test('开启：先落盘待同步标记，再提权一次；成功后清除标记', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final prefs = await _mockPreferences();
    var cacheDuringApply = '';
    gateway.onApply = () async {
      cacheDuringApply =
          prefs.getString(PasswordFreeInstallCache.preferencesKey) ?? '';
    };
    final container = _createContainer(gateway: gateway, prefs: prefs);
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    expect(notifier.beginEnableRequest(), isTrue);
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.enabled);
    expect(gateway.requests, <bool>[true]);
    final marked = PasswordFreeInstallCache.tryParse(cacheDuringApply);
    expect(marked!.needsSync, isTrue, reason: '提权前必须先写入待同步标记');
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue);
    expect(state.needsSync, isFalse);
    expect(state.usesPasswordFreeCli, isTrue);
  });

  test('缓存与真实状态相反时按点击目标同步，不反转系统', () async {
    // 缓存显示关闭、系统实际已开启：点击开启应得到 unchanged 而不是 disable。
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.enabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.unchanged,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.enabled);
    expect(gateway.requests, <bool>[true]);
    expect(container.read(polkitRuleProvider).enabled, isTrue);
  });

  test('关闭不需要风险确认阶段', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: false,
        before: PolkitRuleSystemState.enabled,
        after: PolkitRuleSystemState.disabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: false)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final feedback = await container
        .read(polkitRuleProvider.notifier)
        .applyTarget(enabled: false);

    expect(feedback, PasswordFreeInstallFeedback.disabled);
    expect(container.read(polkitRuleProvider).enabled, isFalse);
  });

  test('开启方向必须先经过确认阶段', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final feedback = await container
        .read(polkitRuleProvider.notifier)
        .applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.none);
    expect(gateway.requests, isEmpty);
  });

  test('确认阶段重复请求被单飞拦截，取消后回到 ready', () async {
    final container = _createContainer(
      gateway: _FakePolkitRuleGateway(),
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);
    final notifier = container.read(polkitRuleProvider.notifier);

    expect(notifier.beginEnableRequest(), isTrue);
    expect(container.read(polkitRuleProvider).phase, PasswordFreeInstallPhase.confirming);
    expect(notifier.beginEnableRequest(), isFalse, reason: '确认阶段不得重复弹框');

    notifier.cancelEnableRequest();

    expect(container.read(polkitRuleProvider).phase, PasswordFreeInstallPhase.ready);
    expect(notifier.beginEnableRequest(), isTrue);
  });

  test('进行中重复提交被单飞拦截，只提权一次', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    )..hold = Completer<void>();
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);
    final notifier = container.read(polkitRuleProvider.notifier);

    notifier.beginEnableRequest();
    final first = notifier.applyTarget(enabled: true);
    expect(container.read(polkitRuleProvider).phase, PasswordFreeInstallPhase.applying);

    final second = await notifier.applyTarget(enabled: true);
    expect(second, PasswordFreeInstallFeedback.none);

    gateway.hold!.complete();
    expect(await first, PasswordFreeInstallFeedback.enabled);
    expect(gateway.requests, <bool>[true]);
  });

  test('授权取消：恢复操作前的缓存与待同步标记', () async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.authorizationCancelled,
        'pkexec authorization dismissed by user',
        exitCode: 126,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: true)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.authorizationCancelled);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue, reason: '不得把系统未修改说成关闭');
    expect(state.needsSync, isTrue, reason: '操作前已有的待同步标记不能被清除');
    expect(state.lastFailureKind, PolkitRuleFailureKind.authorizationCancelled);
  });

  test('授权组件不可用：保留最近状态并给出明确反馈', () async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.authorizationUnavailable,
        'pkexec not found',
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.authorizationUnavailable);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isFalse);
    expect(state.needsSync, isFalse);
  });

  test('规则冲突：不覆盖缓存值但标记待同步', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.conflict,
        after: PolkitRuleSystemState.conflict,
        outcome: PolkitRuleOutcome.conflict,
        reason: PolkitRuleFailureReason.conflict,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: false)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.ruleConflict);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue);
    expect(state.needsSync, isTrue);
    expect(state.usesPasswordFreeCli, isFalse);
  });

  test('写入失败但回读成功：保存实际状态并清除待同步标记', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.disabled,
        outcome: PolkitRuleOutcome.failed,
        reason: PolkitRuleFailureReason.writeFailed,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isFalse);
    // 回读已确定状态且缓存已按实际值写入，按 §4.1 的定义无需再标记待同步。
    expect(state.needsSync, isFalse);
  });

  test('回读失败（after=unknown）才保留最近可靠值并标记待同步', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.unknown,
        outcome: PolkitRuleOutcome.failed,
        reason: PolkitRuleFailureReason.verifyFailed,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: false)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue);
    expect(state.needsSync, isTrue);
  });

  test('上次修改中断后保留待同步标记，不使用免密执行路径', () async {
    final container = _createContainer(
      gateway: _FakePolkitRuleGateway(),
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: true)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final state = container.read(polkitRuleProvider);

    expect(state.enabled, isTrue);
    expect(state.needsSync, isTrue);
    expect(state.usesPasswordFreeCli, isFalse);
  });

  test('超时或结果不可靠：保留最近可靠值并标记待同步', () async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.timeout,
        '提权同步超时',
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences({
        PasswordFreeInstallCache.preferencesKey: jsonEncode(
          const PasswordFreeInstallCache(enabled: true, needsSync: false)
              .toJson(),
        ),
      }),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue);
    expect(state.needsSync, isTrue);
  });

  test('环境不支持：标记待同步并给出专用反馈', () async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.unsupportedEnvironment,
        'rules directory is unavailable',
        exitCode: 65,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.unsupported);
    expect(container.read(polkitRuleProvider).needsSync, isTrue);
  });

  test('系统成功但本地保存失败：显示真实值并提示未保存', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: _WriteFailingPreferences(
        await _mockPreferences(),
        successfulWrites: 1,
      ),
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.cacheSaveFailed);
    expect(container.read(polkitRuleProvider).enabled, isTrue);
  });

  test('设置事务期间暂缓新任务出队，结束后恢复', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    )..hold = Completer<void>();
    final cliRepository = MockLinglongCliRepository();
    when(cliRepository.installApp(any, version: anyNamed('version'), force: anyNamed('force'))).thenAnswer(
      (_) => Stream<InstallProgress>.value(
        const InstallProgress(
          appId: 'ignored',
          status: InstallStatus.success,
          progress: 100,
        ),
      ),
    );
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
      cliRepository: cliRepository,
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final applying = notifier.applyTarget(enabled: true);
    await _eventually(() => gateway.requests.isNotEmpty);

    container
        .read(installQueueProvider.notifier)
        .enqueueOperation(
          kind: InstallTaskKind.install,
          appId: 'org.example.queued',
          appName: 'Queued',
        );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    verifyNever(cliRepository.installApp(any, version: anyNamed('version'), force: anyNamed('force')));

    gateway.hold!.complete();
    await applying;

    final consumed = await _eventually(
      () => container.read(installQueueProvider).history.isNotEmpty,
    );
    expect(consumed, isTrue, reason: '事务结束后必须恢复出队');
    verify(cliRepository.installApp(any, version: anyNamed('version'), force: anyNamed('force'))).called(1);
  });

  test('待同步标记写入失败时不启动修改，并释放队列暂停', () async {
    final gateway = _FakePolkitRuleGateway(
      result: _result(
        requested: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final cliRepository = _buildConsumingCliRepository();
    final container = _createContainer(
      gateway: gateway,
      prefs: _WriteFailingPreferences(await _mockPreferences()),
      cliRepository: cliRepository,
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    expect(gateway.requests, isEmpty, reason: '待同步标记写入失败不得启动系统修改');
    await _expectQueueResumed(container, cliRepository);
  });

  test('提权同步异常结束后仍释放队列暂停', () async {
    final gateway = _FakePolkitRuleGateway(error: StateError('boom'));
    final cliRepository = _buildConsumingCliRepository();
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
      cliRepository: cliRepository,
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    await _expectQueueResumed(container, cliRepository);
  });

  test('取消风险确认不暂停队列', () async {
    final gateway = _FakePolkitRuleGateway();
    final cliRepository = _buildConsumingCliRepository();
    final container = _createContainer(
      gateway: gateway,
      prefs: await _mockPreferences(),
      cliRepository: cliRepository,
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    expect(notifier.beginEnableRequest(), isTrue);
    notifier.cancelEnableRequest();

    expect(gateway.requests, isEmpty);
    await _expectQueueResumed(container, cliRepository);
  });

  test('装配缺失等意外错误也能恢复可交互状态并标记待同步', () async {
    // 不覆盖 polkitRuleGatewayProvider：服务读取端口时抛 StateError，
    // 控制器必须兜底把阶段恢复为 ready，避免开关永久卡在 applying。
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appOperationJournalRepositoryProvider.overrideWithValue(
          MemoryAppOperationJournalRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(polkitRuleProvider.notifier);
    notifier.beginEnableRequest();
    final feedback = await notifier.applyTarget(enabled: true);

    expect(feedback, PasswordFreeInstallFeedback.failed);
    final state = container.read(polkitRuleProvider);
    expect(state.phase, PasswordFreeInstallPhase.ready);
    expect(state.needsSync, isTrue);
    expect(state.lastFailureKind, PolkitRuleFailureKind.unexpected);
  });
}
