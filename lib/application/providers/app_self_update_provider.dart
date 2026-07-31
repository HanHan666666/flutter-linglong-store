/// 应用自更新的依赖装配与唯一运行状态。
///
/// Controller 在应用级 Provider 中持有完整任务生命周期并禁止并发；弹窗关闭、
/// 重建或语言切换都不会创建第二个下载/安装任务。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_self_update.dart';
import '../services/app_self_update_service.dart';
import '../services/version_check_service.dart';
import 'application_dependency_providers.dart';
import 'global_provider.dart';

/// 自更新用例 Provider。
final appSelfUpdateServiceProvider = Provider<AppSelfUpdateService>((ref) {
  return AppSelfUpdateService(
    probe: ref.watch(appInstallationProbeProvider),
    workspaceFactory: ref.watch(appUpdateWorkspaceFactoryProvider),
    installers: ref.watch(appUpdateInstallersProvider),
    currentArch: () => ref.read(globalAppProvider).arch ?? kDefaultRequestArch,
  );
});

/// 应用级自更新状态 Provider。
final appSelfUpdateControllerProvider =
    NotifierProvider<AppSelfUpdateController, AppSelfUpdateState>(
      AppSelfUpdateController.new,
      name: 'appSelfUpdateControllerProvider',
    );

/// 不可变自更新状态。
class AppSelfUpdateState {
  /// 创建空闲状态。
  const AppSelfUpdateState.idle()
    : update = null,
      phase = null,
      progress = 0,
      error = null;

  /// 创建任务状态。
  const AppSelfUpdateState({
    required this.update,
    required this.phase,
    required this.progress,
    this.error,
  });

  /// 当前任务使用的 Release 快照，重试必须复用同一版本和资产集合。
  final VersionCheckResultUpdateAvailable? update;

  /// 当前阶段；空值表示尚未开始。
  final AppSelfUpdatePhase? phase;

  /// 0..1 的整体进度。
  final double progress;

  /// 失败阶段的原始异常，仅用于映射稳定本地化文案。
  final Object? error;

  /// 是否有任务正在运行。
  bool get isRunning => switch (phase) {
    null ||
    AppSelfUpdatePhase.done ||
    AppSelfUpdatePhase.failed ||
    AppSelfUpdatePhase.cancelled => false,
    _ => true,
  };

  /// 是否允许用户安全取消。
  bool get canCancel => switch (phase) {
    AppSelfUpdatePhase.detectingInstallation ||
    AppSelfUpdatePhase.resolvingAsset ||
    AppSelfUpdatePhase.downloading ||
    AppSelfUpdatePhase.verifying => true,
    _ => false,
  };

  /// 是否已经进入可关闭弹窗的终态。
  bool get isTerminal => switch (phase) {
    AppSelfUpdatePhase.done ||
    AppSelfUpdatePhase.failed ||
    AppSelfUpdatePhase.cancelled => true,
    _ => false,
  };
}

/// 自更新状态控制器。
class AppSelfUpdateController extends Notifier<AppSelfUpdateState> {
  AppSelfUpdateCancellation? _activeCancellation;

  @override
  AppSelfUpdateState build() => const AppSelfUpdateState.idle();

  /// 启动一次更新；已有任务运行时保持幂等，不创建并发安装。
  Future<void> start(VersionCheckResultUpdateAvailable update) async {
    if (state.isRunning) {
      return;
    }
    final cancellation = AppSelfUpdateCancellation();
    _activeCancellation = cancellation;
    state = AppSelfUpdateState(
      update: update,
      phase: AppSelfUpdatePhase.detectingInstallation,
      progress: 0,
    );

    try {
      await ref
          .read(appSelfUpdateServiceProvider)
          .performUpdate(
            update: update,
            cancellation: cancellation,
            onProgress: (progress) {
              state = AppSelfUpdateState(
                update: update,
                phase: progress.phase,
                progress: progress.progress.clamp(0, 1),
              );
            },
          );
    } on AppSelfUpdateCancelledException {
      state = AppSelfUpdateState(
        update: update,
        phase: AppSelfUpdatePhase.cancelled,
        progress: state.progress,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[AppSelfUpdateController] 更新任务失败', error, stackTrace);
      state = AppSelfUpdateState(
        update: update,
        phase: AppSelfUpdatePhase.failed,
        progress: state.progress,
        error: error,
      );
    } finally {
      if (identical(_activeCancellation, cancellation)) {
        _activeCancellation = null;
      }
    }
  }

  /// 重试最近一次失败或取消的 Release 快照。
  Future<void> retry() async {
    final update = state.update;
    if (update == null || state.isRunning) {
      return;
    }
    await start(update);
  }

  /// 在系统安装开始前请求协作取消。
  void cancel() {
    if (!state.canCancel) {
      return;
    }
    _activeCancellation?.cancel();
  }

  /// 用户关闭终态弹窗后回到空闲状态。
  void reset() {
    if (!state.isRunning) {
      state = const AppSelfUpdateState.idle();
    }
  }
}
