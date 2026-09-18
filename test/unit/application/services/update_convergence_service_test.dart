/// 验证更新成功后的已安装快照收敛确认策略。
///
/// 该服务决定"更新列表是否允许重算"，因此这里覆盖三种真实现象：列表延迟
/// 收敛（F1）、快照刷新失败（F2）、刷新正常但列表始终为旧版本；同时钉住
/// 边界语义——空目标与缺少 expectedVersion 的历史任务不得触发多余刷新。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/services/update_convergence_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

void main() {
  setUpAll(() async {
    // 收敛成功/失败都会写入诊断日志，测试进程需要先初始化日志器。
    await AppLogger.init();
  });

  group('UpdateConvergenceService', () {
    test('首次快照即可见目标版本时立即确认收敛', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('2.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isTrue);
      expect(result.attempts, 1);
      expect(result.unconfirmedTargets, isEmpty);
      expect(installed.refreshCalls, 1);
    });

    test('列表延迟收敛时重试到目标版本出现为止', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('1.0.0')]),
        _SnapshotStep([_app('2.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isTrue);
      expect(result.attempts, 2);
      expect(result.reasonCode, 'confirmed');
      expect(installed.refreshCalls, 2);
    });

    test('刷新失败后恢复时不猜测成功，按实际快照确认', () async {
      final installed = ScriptedInstalledApps([
        const _SnapshotStep.failure(),
        const _SnapshotStep.failure(),
        _SnapshotStep([_app('2.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isTrue);
      expect(result.attempts, 3);
      // 过程出现过刷新失败，但目标版本最终可见，仍属于确认成功。
      expect(result.refreshFailed, isTrue);
      expect(installed.refreshCalls, 3);
    });

    test('刷新始终失败时报告 refreshFailed 且不确认收敛', () async {
      final installed = ScriptedInstalledApps([
        const _SnapshotStep.failure(),
        const _SnapshotStep.failure(),
        const _SnapshotStep.failure(),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isFalse);
      expect(result.attempts, 3);
      expect(result.refreshFailed, isTrue);
      expect(result.reasonCode, 'refreshFailed');
      expect(result.unconfirmedTargets.single.appId, 'org.example.demo');
    });

    test('刷新成功但列表始终为旧版本时报告 listStale', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('1.0.0')]),
        _SnapshotStep([_app('1.0.0')]),
        _SnapshotStep([_app('1.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isFalse);
      expect(result.attempts, 3);
      expect(result.refreshFailed, isFalse);
      expect(result.reasonCode, 'listStale');
      expect(installed.refreshCalls, 3);
    });

    test('空目标集合无需刷新直接确认', () async {
      final installed = ScriptedInstalledApps([_SnapshotStep([_app('1.0.0')])]);

      final result = await _verifier(installed).verify(const []);

      expect(result.confirmed, isTrue);
      expect(result.attempts, 0);
      expect(installed.refreshCalls, 0);
    });

    test('缺少 expectedVersion 的历史任务不参与判定', () async {
      final installed = ScriptedInstalledApps([_SnapshotStep([_app('1.0.0')])]);

      final result = await _verifier(
        installed,
      ).verify([_target(expectedVersion: null)]);

      expect(result.confirmed, isTrue);
      expect(result.attempts, 0);
      expect(installed.refreshCalls, 0);
    });

    test('多目标中任一未收敛时整体不确认并报告该目标', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('1.0.0'), _app('3.0.0', appId: 'org.example.other')]),
      ]);
      final converged = _target(appId: 'org.example.other', expectedVersion: '3.0.0');

      final result = await _verifier(
        installed,
      ).verify([_target(), converged]);

      expect(result.confirmed, isFalse);
      expect(result.unconfirmedTargets, hasLength(1));
      expect(result.unconfirmedTargets.single.appId, 'org.example.demo');
      expect(installed.refreshCalls, 3);
    });

    test('身份歧义（同应用多实例）时不确认收敛', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('1.0.0'), _app('2.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(result.confirmed, isFalse);
      expect(result.reasonCode, 'listStale');
    });

    test('按最大尝试次数停止重试，不做无界轮询', () async {
      final installed = ScriptedInstalledApps([
        _SnapshotStep([_app('1.0.0')]),
      ]);

      final result = await _verifier(installed).verify([_target()]);

      expect(installed.refreshCalls, 3);
      expect(result.attempts, 3);
    });
  });
}

/// 构造带目标版本期望的更新目标快照。
AppOperationTargetSnapshot _target({
  String appId = 'org.example.demo',
  String? expectedVersion = '2.0.0',
}) {
  return AppOperationTargetSnapshot(
    appId: appId,
    displayName: 'Demo',
    installedVersion: '1.0.0',
    expectedVersion: expectedVersion,
  );
}

/// 构造已安装实例快照项。
InstalledApp _app(String version, {String appId = 'org.example.demo'}) {
  return InstalledApp(appId: appId, name: 'Demo', version: version);
}

/// 使用脚本化快照构建待验证服务，重试间隔归零以保持测试快速。
UpdateConvergenceVerifier _verifier(InstalledApps installed) {
  final container = ProviderContainer(
    overrides: [
      installedAppsProvider.overrideWith(() => installed),
      updateConvergenceVerifierProvider.overrideWith(
        (ref) => UpdateConvergenceService(ref, retryDelay: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(updateConvergenceVerifierProvider);
}

/// 一次脚本化快照步骤：正常返回指定列表，或模拟刷新失败。
class _SnapshotStep {
  /// 构造正常返回的快照步骤。
  const _SnapshotStep(this.apps) : failure = false;

  /// 构造模拟刷新失败的步骤。
  const _SnapshotStep.failure() : apps = const [], failure = true;

  /// 该次刷新后可见的已安装列表。
  final List<InstalledApp> apps;

  /// 该次刷新是否失败。
  final bool failure;
}

/// 按脚本逐步返回快照的已安装列表替身。
///
/// 超出脚本长度后重复最后一步，用于验证"始终未收敛"时的有界重试行为。
class ScriptedInstalledApps extends InstalledApps {
  ScriptedInstalledApps(this._steps)
    : assert(_steps.isNotEmpty, '脚本至少需要一步');

  final List<_SnapshotStep> _steps;

  /// 实际被请求刷新的次数。
  int refreshCalls = 0;

  @override
  InstalledAppsState build() => const InstalledAppsState();

  @override
  Future<bool> refresh() async {
    final index = refreshCalls < _steps.length
        ? refreshCalls
        : _steps.length - 1;
    final step = _steps[index];
    refreshCalls += 1;

    if (step.failure) {
      // 失败时保留旧快照，与真实 Provider 的降级行为一致。
      state = state.copyWith(isLoading: false, error: '模拟刷新失败');
      return false;
    }

    state = InstalledAppsState(apps: step.apps);
    return true;
  }
}
