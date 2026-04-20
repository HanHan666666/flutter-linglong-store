import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/installed_apps_provider.dart';
import 'package:linglong_store/application/providers/launch_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/application/providers/update_apps_provider.dart';
import 'package:linglong_store/core/di/repository_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/repositories/analytics_repository.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('LaunchStep', () {
    test('should have correct enum values', () {
      expect(LaunchStep.values.length, equals(6));
      expect(LaunchStep.values, contains(LaunchStep.environmentCheck));
      expect(LaunchStep.values, contains(LaunchStep.installedAppsInit));
      expect(LaunchStep.values, contains(LaunchStep.updateCheck));
      expect(LaunchStep.values, contains(LaunchStep.queueRecovery));
      expect(LaunchStep.values, contains(LaunchStep.completed));
      expect(LaunchStep.values, contains(LaunchStep.error));
    });

    test('should have correct order', () {
      expect(LaunchStep.environmentCheck.index, equals(0));
      expect(LaunchStep.installedAppsInit.index, equals(1));
      expect(LaunchStep.updateCheck.index, equals(2));
      expect(LaunchStep.queueRecovery.index, equals(3));
      expect(LaunchStep.completed.index, equals(4));
      expect(LaunchStep.error.index, equals(5));
    });
  });

  group('LaunchStepInfo', () {
    test('should create LaunchStepInfo with required fields', () {
      const info = LaunchStepInfo(
        step: LaunchStep.environmentCheck,
        message: 'Checking environment...',
      );

      expect(info.step, equals(LaunchStep.environmentCheck));
      expect(info.message, equals('Checking environment...'));
      expect(info.error, isNull);
    });

    test('should create LaunchStepInfo with error', () {
      const info = LaunchStepInfo(
        step: LaunchStep.error,
        message: 'Launch failed',
        error: 'Environment check failed',
      );

      expect(info.step, equals(LaunchStep.error));
      expect(info.message, equals('Launch failed'));
      expect(info.error, equals('Environment check failed'));
    });

    test('should copyWith correctly', () {
      const info = LaunchStepInfo(
        step: LaunchStep.environmentCheck,
        message: 'Checking...',
      );

      final newInfo = info.copyWith(
        step: LaunchStep.installedAppsInit,
        message: 'Loading apps...',
      );

      expect(newInfo.step, equals(LaunchStep.installedAppsInit));
      expect(newInfo.message, equals('Loading apps...'));
      expect(newInfo.error, isNull);
    });

    test('should copyWith with error', () {
      const info = LaunchStepInfo(
        step: LaunchStep.environmentCheck,
        message: 'Checking...',
      );

      final newInfo = info.copyWith(
        step: LaunchStep.error,
        message: 'Failed',
        error: 'Something went wrong',
      );

      expect(newInfo.step, equals(LaunchStep.error));
      expect(newInfo.error, equals('Something went wrong'));
    });
  });

  group('LaunchState', () {
    test('should create state with default values', () {
      const state = LaunchState();

      expect(state.currentStep, equals(LaunchStep.environmentCheck));
      expect(state.progress, equals(0.0));
      expect(state.isCompleted, isFalse);
      expect(state.hasError, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.installedAppsCount, equals(0));
      expect(state.pendingTasksCount, equals(0));
    });

    test('should create state with custom values', () {
      const stepInfo = LaunchStepInfo(
        step: LaunchStep.installedAppsInit,
        message: 'Loading apps...',
      );

      const state = LaunchState(
        currentStep: LaunchStep.installedAppsInit,
        progress: 0.5,
        stepInfo: stepInfo,
        isCompleted: false,
        hasError: false,
        errorMessage: null,
        installedAppsCount: 10,
        pendingTasksCount: 2,
      );

      expect(state.currentStep, equals(LaunchStep.installedAppsInit));
      expect(state.progress, equals(0.5));
      expect(state.stepInfo.message, equals('Loading apps...'));
      expect(state.installedAppsCount, equals(10));
      expect(state.pendingTasksCount, equals(2));
    });

    test('should calculate totalProgress correctly at start', () {
      const state = LaunchState(
        currentStep: LaunchStep.environmentCheck,
        progress: 0.0,
      );

      // Total progress should be 0 at start
      expect(state.totalProgress, equals(0.0));
    });

    test('should calculate totalProgress correctly at completion', () {
      const state = LaunchState(isCompleted: true);

      expect(state.totalProgress, equals(1.0));
    });

    test(
      'should calculate totalProgress correctly for environment check step',
      () {
        const state = LaunchState(
          currentStep: LaunchStep.environmentCheck,
          progress: 0.5,
        );

        // Environment check weight is 0.3, progress is 0.5
        // totalProgress = 0.3 * 0.5 = 0.15
        expect(state.totalProgress, closeTo(0.15, 0.01));
      },
    );

    test(
      'should calculate totalProgress correctly for installed apps init step',
      () {
        const state = LaunchState(
          currentStep: LaunchStep.installedAppsInit,
          progress: 0.5,
        );

        // Previous steps: 0.3 (environment check)
        // Current step: 0.5 * 0.5 = 0.25
        // totalProgress = 0.3 + 0.25 = 0.55
        expect(state.totalProgress, closeTo(0.55, 0.01));
      },
    );

    test('should calculate totalProgress correctly for update check step', () {
      const state = LaunchState(
        currentStep: LaunchStep.updateCheck,
        progress: 0.5,
      );

      // Previous steps: 0.3 + 0.5 = 0.8
      // Current step: 0.1 * 0.5 = 0.05
      // totalProgress = 0.8 + 0.05 = 0.85
      expect(state.totalProgress, closeTo(0.85, 0.01));
    });

    test(
      'should calculate totalProgress correctly for queue recovery step',
      () {
        const state = LaunchState(
          currentStep: LaunchStep.queueRecovery,
          progress: 0.5,
        );

        // Previous steps: 0.3 + 0.5 + 0.1 = 0.9
        // Current step: 0.1 * 0.5 = 0.05
        // totalProgress = 0.9 + 0.05 = 0.95
        expect(state.totalProgress, closeTo(0.95, 0.01));
      },
    );

    test('should return progress when has error', () {
      const state = LaunchState(
        currentStep: LaunchStep.installedAppsInit,
        progress: 0.5,
        hasError: true,
      );

      // When has error, totalProgress should return current progress
      expect(state.totalProgress, equals(0.5));
    });

    test('should copyWith correctly', () {
      const state = LaunchState();

      final newState = state.copyWith(
        currentStep: LaunchStep.installedAppsInit,
        progress: 0.5,
        installedAppsCount: 10,
      );

      expect(newState.currentStep, equals(LaunchStep.installedAppsInit));
      expect(newState.progress, equals(0.5));
      expect(newState.installedAppsCount, equals(10));
      expect(newState.isCompleted, isFalse);
    });

    test('should clear error with clearError flag', () {
      const state = LaunchState(hasError: true, errorMessage: 'Test error');

      final newState = state.copyWith(
        currentStep: LaunchStep.environmentCheck,
        clearError: true,
      );

      expect(newState.hasError, isFalse);
      expect(newState.errorMessage, isNull);
    });

    test('should preserve hasError when not clearing', () {
      const state = LaunchState(hasError: true, errorMessage: 'Test error');

      final newState = state.copyWith(progress: 0.5);

      expect(newState.hasError, isTrue);
      expect(newState.errorMessage, equals('Test error'));
    });
  });

  group('LaunchState step weights', () {
    test('should have correct step weights', () {
      expect(LaunchState.stepWeights[LaunchStep.environmentCheck], equals(0.3));
      expect(
        LaunchState.stepWeights[LaunchStep.installedAppsInit],
        equals(0.5),
      );
      expect(LaunchState.stepWeights[LaunchStep.updateCheck], equals(0.1));
      expect(LaunchState.stepWeights[LaunchStep.queueRecovery], equals(0.1));
      expect(LaunchState.stepWeights[LaunchStep.completed], equals(0.0));
      expect(LaunchState.stepWeights[LaunchStep.error], equals(0.0));
    });

    test('step weights should sum to 1.0', () {
      final totalWeight = LaunchState.stepWeights.values.fold(
        0.0,
        (sum, weight) => sum + weight,
      );
      expect(totalWeight, equals(1.0));
    });
  });

  group('LaunchState progress transitions', () {
    test('should transition through all steps correctly', () {
      var state = const LaunchState();

      // Environment check
      state = state.copyWith(
        currentStep: LaunchStep.environmentCheck,
        progress: 1.0,
      );
      expect(state.currentStep, equals(LaunchStep.environmentCheck));
      expect(state.totalProgress, closeTo(0.3, 0.01));

      // Installed apps init
      state = state.copyWith(
        currentStep: LaunchStep.installedAppsInit,
        progress: 1.0,
        installedAppsCount: 5,
      );
      expect(state.currentStep, equals(LaunchStep.installedAppsInit));
      expect(state.totalProgress, closeTo(0.8, 0.01));

      // Update check
      state = state.copyWith(
        currentStep: LaunchStep.updateCheck,
        progress: 1.0,
      );
      expect(state.currentStep, equals(LaunchStep.updateCheck));
      expect(state.totalProgress, closeTo(0.9, 0.01));

      // Queue recovery
      state = state.copyWith(
        currentStep: LaunchStep.queueRecovery,
        progress: 1.0,
        pendingTasksCount: 2,
      );
      expect(state.currentStep, equals(LaunchStep.queueRecovery));
      expect(state.totalProgress, closeTo(1.0, 0.01));

      // Completed
      state = state.copyWith(
        currentStep: LaunchStep.completed,
        isCompleted: true,
      );
      expect(state.isCompleted, isTrue);
      expect(state.totalProgress, equals(1.0));
    });

    test('should handle error state', () {
      var state = const LaunchState();

      state = state.copyWith(
        currentStep: LaunchStep.error,
        hasError: true,
        errorMessage: 'Environment check failed',
      );

      expect(state.hasError, isTrue);
      expect(state.errorMessage, equals('Environment check failed'));
      expect(state.currentStep, equals(LaunchStep.error));
    });
  });

  group('LaunchSequence environment flow', () {
    test(
      'continues startup when environment result is warning-only success',
      () async {
        final container = ProviderContainer(
          overrides: [
            globalAppProvider.overrideWith(
              () => _TestGlobalApp(
                const GlobalAppState(
                  userPreferences: UserPreferences(autoCheckUpdate: true),
                ),
              ),
            ),
            linglongEnvProvider.overrideWith(
              () => _TestLinglongEnv(
                const LinglongEnvCheckResult(
                  isOk: true,
                  warningMessage: '版本过低',
                  llCliVersion: '1.8.2',
                  repoStatus: RepoStatus.ok,
                  checkedAt: 1,
                ),
              ),
            ),
            installedAppsProvider.overrideWith(
              () => _TestInstalledApps(
                apps: const [
                  InstalledApp(
                    appId: 'org.example.demo',
                    name: 'Demo',
                    version: '1.0.0',
                  ),
                ],
              ),
            ),
            updateAppsProvider.overrideWith(() => _TestUpdateApps()),
            installQueueProvider.overrideWith(() => _TestInstallQueue()),
            analyticsRepositoryProvider.overrideWithValue(
              const _NoopAnalyticsRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(launchSequenceProvider.notifier).runSequence();

        final state = container.read(launchSequenceProvider);
        expect(state.isCompleted, isTrue);
        expect(state.hasError, isFalse);
        expect(state.currentStep, LaunchStep.completed);
      },
    );

    test(
      'stops startup when environment result is a blocking failure',
      () async {
        final container = ProviderContainer(
          overrides: [
            globalAppProvider.overrideWith(
              () => _TestGlobalApp(
                const GlobalAppState(
                  userPreferences: UserPreferences(autoCheckUpdate: true),
                ),
              ),
            ),
            linglongEnvProvider.overrideWith(
              () => _TestLinglongEnv(
                const LinglongEnvCheckResult(
                  isOk: false,
                  errorMessage: '未检测到玲珑仓库配置，请检查环境',
                  repoStatus: RepoStatus.notConfigured,
                  checkedAt: 1,
                ),
              ),
            ),
            installedAppsProvider.overrideWith(
              () => _TestInstalledApps(
                apps: const [
                  InstalledApp(
                    appId: 'org.example.demo',
                    name: 'Demo',
                    version: '1.0.0',
                  ),
                ],
              ),
            ),
            updateAppsProvider.overrideWith(() => _TestUpdateApps()),
            installQueueProvider.overrideWith(() => _TestInstallQueue()),
            analyticsRepositoryProvider.overrideWithValue(
              const _NoopAnalyticsRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(launchSequenceProvider.notifier).runSequence();

        final state = container.read(launchSequenceProvider);
        expect(state.isCompleted, isFalse);
        expect(state.hasError, isTrue);
        expect(state.currentStep, LaunchStep.environmentCheck);
        expect(state.errorMessage, '未检测到玲珑仓库配置，请检查环境');
      },
    );
  });
}

class _TestLinglongEnv extends LinglongEnv {
  _TestLinglongEnv(this._result);

  final LinglongEnvCheckResult _result;

  @override
  LinglongEnvState build() => const LinglongEnvState();

  @override
  Future<LinglongEnvCheckResult> checkEnvironment() async {
    state = state.copyWith(
      checkState: LinglongEnvCheckState.success,
      result: _result,
    );
    return _result;
  }
}

class _TestGlobalApp extends GlobalApp {
  _TestGlobalApp(this._initialState);

  final GlobalAppState _initialState;

  @override
  GlobalAppState build() => _initialState;
}

class _TestInstalledApps extends InstalledApps {
  _TestInstalledApps({required this.apps});

  final List<InstalledApp> apps;

  @override
  InstalledAppsState build() => const InstalledAppsState();

  @override
  Future<void> refresh() async {
    state = InstalledAppsState(apps: apps);
  }
}

class _TestUpdateApps extends UpdateApps {
  @override
  UpdateAppsState build() => const UpdateAppsState();

  @override
  Future<void> checkUpdates() async {
    state = const UpdateAppsState();
  }
}

class _TestInstallQueue extends InstallQueue {
  @override
  InstallQueueState build() => const InstallQueueState();

  @override
  Future<void> checkRecovery(List<String> installedAppIds) async {}
}

class _NoopAnalyticsRepository implements AnalyticsRepository {
  const _NoopAnalyticsRepository();

  @override
  Future<void> reportInstall(
    String appId,
    String version, {
    String? appName,
  }) async {}

  @override
  Future<void> reportUninstall(
    String appId,
    String version, {
    String? appName,
  }) async {}

  @override
  Future<void> reportVisit({
    String? arch,
    String? llVersion,
    String? osVersion,
    String? repoName,
    String? appVersion,
  }) async {}
}
