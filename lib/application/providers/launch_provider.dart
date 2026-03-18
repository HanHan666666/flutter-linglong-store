import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/di/providers.dart';
import '../../core/logging/app_logger.dart';
import 'installed_apps_provider.dart';
import 'linglong_env_provider.dart';

part 'launch_provider.g.dart';

/// 启动步骤枚举
enum LaunchStep {
  /// 环境检测
  environmentCheck,

  /// 已安装应用初始化
  installedAppsInit,

  /// 更新检查
  updateCheck,

  /// 安装队列恢复
  queueRecovery,

  /// 完成
  completed,

  /// 错误
  error,
}

/// 启动步骤信息
class LaunchStepInfo {
  const LaunchStepInfo({required this.step, required this.message, this.error});

  final LaunchStep step;
  final String message;
  final String? error;

  LaunchStepInfo copyWith({LaunchStep? step, String? message, String? error}) {
    return LaunchStepInfo(
      step: step ?? this.step,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

/// 启动状态
class LaunchState {
  const LaunchState({
    this.currentStep = LaunchStep.environmentCheck,
    this.progress = 0.0,
    this.stepInfo = const LaunchStepInfo(
      step: LaunchStep.environmentCheck,
      message: '正在检测环境...',
    ),
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
    this.installedAppsCount = 0,
    this.pendingTasksCount = 0,
  });

  /// 当前步骤
  final LaunchStep currentStep;

  /// 进度 (0.0 - 1.0)
  final double progress;

  /// 步骤信息
  final LaunchStepInfo stepInfo;

  /// 是否完成
  final bool isCompleted;

  /// 是否有错误
  final bool hasError;

  /// 错误信息
  final String? errorMessage;

  /// 已安装应用数量
  final int installedAppsCount;

  /// 待处理任务数量
  final int pendingTasksCount;

  /// 获取步骤进度权重
  static const Map<LaunchStep, double> stepWeights = {
    LaunchStep.environmentCheck: 0.3,
    LaunchStep.installedAppsInit: 0.5,
    LaunchStep.updateCheck: 0.1,
    LaunchStep.queueRecovery: 0.1,
    LaunchStep.completed: 0.0,
    LaunchStep.error: 0.0,
  };

  /// 计算当前总进度
  double get totalProgress {
    if (isCompleted) return 1.0;
    if (hasError) return progress;

    double total = 0.0;
    const steps = LaunchStep.values;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i] == currentStep) {
        total += stepWeights[currentStep]! * progress;
        break;
      }
      total += stepWeights[steps[i]] ?? 0;
    }

    return total.clamp(0.0, 1.0);
  }

  LaunchState copyWith({
    LaunchStep? currentStep,
    double? progress,
    LaunchStepInfo? stepInfo,
    bool? isCompleted,
    bool? hasError,
    String? errorMessage,
    int? installedAppsCount,
    int? pendingTasksCount,
    bool clearError = false,
  }) {
    return LaunchState(
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      stepInfo: stepInfo ?? this.stepInfo,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: clearError ? false : (hasError ?? this.hasError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      installedAppsCount: installedAppsCount ?? this.installedAppsCount,
      pendingTasksCount: pendingTasksCount ?? this.pendingTasksCount,
    );
  }
}

/// 启动序列 Provider
///
/// 管理应用启动时的初始化序列：
/// 1. 环境检测 - 检查 ll-cli 是否可用
/// 2. 已安装应用初始化 - 加载已安装应用列表
/// 3. 更新检查 - 检查应用更新
/// 4. 安装队列恢复 - 恢复未完成的安装任务
/// 5. 完成后跳转到主页
@Riverpod(keepAlive: true)
class LaunchSequence extends _$LaunchSequence {
  @override
  LaunchState build() {
    return const LaunchState();
  }

  /// 环境检测状态
  LinglongEnvCheckState _envCheckState = LinglongEnvCheckState.initial;

  /// 获取环境检测状态
  LinglongEnvCheckState get envCheckState => _envCheckState;

  /// 执行启动序列
  Future<void> runSequence() async {
    AppLogger.info('Starting launch sequence...');

    try {
      // Step 1: 环境检测
      final envOk = await _checkEnvironment();

      // 如果环境异常，停止启动序列，由 UI 显示对话框
      if (!envOk) {
        AppLogger.warning('Environment check failed, waiting for user action');
        return;
      }

      // Step 2: 已安装应用初始化
      await _initInstalledApps();

      // Step 3: 更新检查
      await _checkUpdates();

      // Step 4: 安装队列恢复
      await _recoverQueue();

      // 完成
      _complete();
    } catch (e, s) {
      AppLogger.error('Launch sequence failed', e, s);
      _setError(e.toString());
    }
  }

  /// 环境检测
  ///
  /// 返回是否通过检测
  Future<bool> _checkEnvironment() async {
    state = state.copyWith(
      currentStep: LaunchStep.environmentCheck,
      stepInfo: const LaunchStepInfo(
        step: LaunchStep.environmentCheck,
        message: '正在检测环境...',
      ),
      progress: 0.0,
    );

    _envCheckState = LinglongEnvCheckState.checking;

    try {
      // 使用 LinglongEnvProvider 进行环境检测
      final envResult = await ref
          .read(linglongEnvProvider.notifier)
          .checkEnvironment();

      // 更新状态
      _envCheckState = envResult.isOk
          ? LinglongEnvCheckState.success
          : LinglongEnvCheckState.failed;

      if (!envResult.isOk) {
        // 环境异常，设置错误状态但允许 UI 处理
        state = state.copyWith(
          progress: 1.0,
          stepInfo: LaunchStepInfo(
            step: LaunchStep.environmentCheck,
            message: envResult.errorMessage ?? '环境检测失败',
            error: envResult.errorDetail,
          ),
          hasError: true,
          errorMessage: envResult.errorMessage,
        );
        return false;
      }

      // 解析版本信息
      final versionOutput = envResult.llCliVersion ?? '未知版本';
      AppLogger.info('ll-cli version: $versionOutput');

      // 更新进度
      state = state.copyWith(
        progress: 0.5,
        stepInfo: LaunchStepInfo(
          step: LaunchStep.environmentCheck,
          message: '检测到 ll-cli: $versionOutput',
        ),
      );

      // 获取更多环境信息
      await _fetchEnvironmentInfo();

      state = state.copyWith(progress: 1.0);
      AppLogger.info('Environment check completed');
      return true;
    } catch (e) {
      _envCheckState = LinglongEnvCheckState.failed;
      throw Exception('环境检测失败: ${e.toString()}');
    }
  }

  /// 继续启动序列（环境问题解决后）
  ///
  /// 在用户处理环境问题后继续启动流程
  Future<void> continueAfterEnvCheck() async {
    if (_envCheckState != LinglongEnvCheckState.success) {
      // 重新检测环境
      final envOk = await _checkEnvironment();
      if (!envOk) {
        return;
      }
    }

    // 清除错误状态
    state = state.copyWith(hasError: false, clearError: true);

    // 继续后续步骤
    try {
      // Step 2: 已安装应用初始化
      await _initInstalledApps();

      // Step 3: 更新检查
      await _checkUpdates();

      // Step 4: 安装队列恢复
      await _recoverQueue();

      // 完成
      _complete();
    } catch (e, s) {
      AppLogger.error('Launch sequence failed', e, s);
      _setError(e.toString());
    }
  }

  /// 获取环境信息
  Future<void> _fetchEnvironmentInfo() async {
    try {
      // 获取系统架构
      final archResult = await Process.run('uname', ['-m']);
      if (archResult.exitCode == 0) {
        final arch = archResult.stdout.toString().trim();
        ref.read(globalAppProvider.notifier).setArch(arch);
      }

      // 获取操作系统版本
      final osResult = await Process.run('lsb_release', ['-d']);
      if (osResult.exitCode == 0) {
        final osInfo = osResult.stdout.toString();
        final match = RegExp(r'Description:\s*(.+)').firstMatch(osInfo);
        if (match != null) {
          ref
              .read(globalAppProvider.notifier)
              .setOsVersion(match.group(1)!.trim());
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch environment info: $e');
    }
  }

  /// 初始化已安装应用
  Future<void> _initInstalledApps() async {
    state = state.copyWith(
      currentStep: LaunchStep.installedAppsInit,
      stepInfo: const LaunchStepInfo(
        step: LaunchStep.installedAppsInit,
        message: '正在加载已安装应用...',
      ),
      progress: 0.0,
    );

    try {
      // 刷新已安装应用列表
      await ref.read(installedAppsProvider.notifier).refresh();

      final apps = ref.read(installedAppsProvider).apps;
      state = state.copyWith(
        progress: 1.0,
        installedAppsCount: apps.length,
        stepInfo: LaunchStepInfo(
          step: LaunchStep.installedAppsInit,
          message: '已加载 ${apps.length} 个已安装应用',
        ),
      );

      AppLogger.info('Installed apps initialized: ${apps.length} apps');
    } catch (e) {
      AppLogger.warning('Failed to load installed apps: $e');
      // 不抛出异常，允许继续
      state = state.copyWith(progress: 1.0);
    }
  }

  /// 检查更新
  Future<void> _checkUpdates() async {
    state = state.copyWith(
      currentStep: LaunchStep.updateCheck,
      stepInfo: const LaunchStepInfo(
        step: LaunchStep.updateCheck,
        message: '正在检查更新...',
      ),
      progress: 0.0,
    );

    try {
      // 检查是否启用自动更新检查
      final autoCheck = ref
          .read(globalAppProvider)
          .userPreferences
          .autoCheckUpdate;
      if (!autoCheck) {
        state = state.copyWith(
          progress: 1.0,
          stepInfo: const LaunchStepInfo(
            step: LaunchStep.updateCheck,
            message: '已跳过更新检查',
          ),
        );
        return;
      }

      // 调用更新检查：从远程获取最新版本信息与已安装版本对比
      await ref.read(updateAppsProvider.notifier).checkUpdates();

      final updateCount = ref.read(updateAppsProvider).count;
      state = state.copyWith(
        progress: 1.0,
        stepInfo: LaunchStepInfo(
          step: LaunchStep.updateCheck,
          message: updateCount > 0 ? '发现 $updateCount 个可用更新' : '已是最新版本',
        ),
      );

      AppLogger.info('Update check completed: $updateCount updates found');
    } catch (e) {
      AppLogger.warning('Failed to check updates: $e');
      // 不抛出异常，允许继续
      state = state.copyWith(progress: 1.0);
    }
  }

  /// 恢复安装队列
  Future<void> _recoverQueue() async {
    state = state.copyWith(
      currentStep: LaunchStep.queueRecovery,
      stepInfo: const LaunchStepInfo(
        step: LaunchStep.queueRecovery,
        message: '正在恢复安装队列...',
      ),
      progress: 0.0,
    );

    try {
      final installQueue = ref.read(installQueueProvider.notifier);

      // 获取已安装应用 ID 列表
      final installedApps = ref.read(installedAppsProvider).apps;
      final installedIds = installedApps.map((app) => app.appId).toList();

      // 检查崩溃恢复
      await installQueue.checkRecovery(installedIds);

      // 获取待处理任务数量
      final pendingCount = ref.read(installQueueProvider).queue.length;

      state = state.copyWith(
        progress: 1.0,
        pendingTasksCount: pendingCount,
        stepInfo: LaunchStepInfo(
          step: LaunchStep.queueRecovery,
          message: pendingCount > 0 ? '发现 $pendingCount 个待安装任务' : '安装队列已就绪',
        ),
      );

      AppLogger.info('Queue recovery completed: $pendingCount pending tasks');
    } catch (e) {
      AppLogger.warning('Failed to recover queue: $e');
      // 不抛出异常，允许继续
      state = state.copyWith(progress: 1.0);
    }
  }

  /// 完成启动序列
  void _complete() {
    state = state.copyWith(
      currentStep: LaunchStep.completed,
      isCompleted: true,
      progress: 1.0,
      stepInfo: const LaunchStepInfo(
        step: LaunchStep.completed,
        message: '启动完成',
      ),
    );

    AppLogger.info('Launch sequence completed');

    // 异步上报启动访问记录（fire-and-forget，失败不影响应用）
    _reportStartupVisit();
  }

  /// 上报启动访问记录（携带设备/环境信息）
  void _reportStartupVisit() {
    final globalApp = ref.read(globalAppProvider);
    ref
        .read(analyticsRepositoryProvider)
        .reportVisit(
          arch: globalApp.arch,
          llVersion: globalApp.llVersion,
          llBinVersion: globalApp.llBinVersion,
          osVersion: globalApp.osVersion,
          repoName: globalApp.repoName,
          appVersion: globalApp.appVersion,
        );
  }

  /// 设置错误
  void _setError(String message) {
    state = state.copyWith(
      currentStep: LaunchStep.error,
      hasError: true,
      errorMessage: message,
      stepInfo: LaunchStepInfo(
        step: LaunchStep.error,
        message: '启动失败',
        error: message,
      ),
    );
  }

  /// 重试启动序列
  Future<void> retry() async {
    state = const LaunchState();
    await runSequence();
  }

  /// 跳过当前步骤（仅用于错误恢复）
  void skipCurrentStep() {
    final nextSteps = {
      LaunchStep.environmentCheck: LaunchStep.installedAppsInit,
      LaunchStep.installedAppsInit: LaunchStep.updateCheck,
      LaunchStep.updateCheck: LaunchStep.queueRecovery,
      LaunchStep.queueRecovery: LaunchStep.completed,
      LaunchStep.error: LaunchStep.environmentCheck,
      LaunchStep.completed: LaunchStep.completed,
    };

    final nextStep = nextSteps[state.currentStep] ?? LaunchStep.completed;
    state = state.copyWith(
      currentStep: nextStep,
      hasError: false,
      clearError: true,
      progress: 0.0,
    );

    if (nextStep != LaunchStep.completed) {
      // 继续执行下一步
      _continueFromStep(nextStep);
    }
  }

  /// 从指定步骤继续
  Future<void> _continueFromStep(LaunchStep step) async {
    switch (step) {
      case LaunchStep.environmentCheck:
        await _checkEnvironment();
        break;
      case LaunchStep.installedAppsInit:
        await _initInstalledApps();
        break;
      case LaunchStep.updateCheck:
        await _checkUpdates();
        break;
      case LaunchStep.queueRecovery:
        await _recoverQueue();
        break;
      case LaunchStep.completed:
      case LaunchStep.error:
        break;
    }

    if (state.currentStep != LaunchStep.completed &&
        state.currentStep != LaunchStep.error) {
      final nextSteps = {
        LaunchStep.environmentCheck: LaunchStep.installedAppsInit,
        LaunchStep.installedAppsInit: LaunchStep.updateCheck,
        LaunchStep.updateCheck: LaunchStep.queueRecovery,
        LaunchStep.queueRecovery: LaunchStep.completed,
      };

      final nextStep = nextSteps[state.currentStep];
      if (nextStep != null) {
        state = state.copyWith(currentStep: nextStep, progress: 0.0);
        await _continueFromStep(nextStep);
      }
    }
  }
}

/// 便捷访问 Provider

/// 是否启动完成
@riverpod
bool isLaunchCompleted(Ref ref) {
  return ref.watch(launchSequenceProvider).isCompleted;
}

/// 启动是否有错误
@riverpod
bool hasLaunchError(Ref ref) {
  return ref.watch(launchSequenceProvider).hasError;
}

/// 当前启动进度
@riverpod
double launchProgress(Ref ref) {
  return ref.watch(launchSequenceProvider).totalProgress;
}

/// 当前启动步骤
@riverpod
LaunchStep currentLaunchStep(Ref ref) {
  return ref.watch(launchSequenceProvider).currentStep;
}
