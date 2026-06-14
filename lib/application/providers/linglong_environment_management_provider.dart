import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../data/repositories/linglong_cli_repository_impl.dart';
import '../../domain/models/install_queue_state.dart';
import '../../domain/models/linglong_environment_management.dart';
import '../../domain/models/linglong_repository_config.dart';
import '../../domain/repositories/linglong_repository_management_repository.dart';
import '../services/linglong_environment_management_service.dart';
import 'install_queue_provider.dart';
import 'linglong_env_provider.dart';

enum LinglongEnvironmentManagementStatus {
  idle,
  loading,
  ready,
  applying,
  failed,
}

class LinglongEnvironmentManagementState {
  const LinglongEnvironmentManagementState({
    this.status = LinglongEnvironmentManagementStatus.idle,
    this.analysis,
    this.repositoryConfig,
    this.activeAction,
    this.repairResult,
    this.errorMessage,
  });

  final LinglongEnvironmentManagementStatus status;
  final LinglongEnvironmentAnalysis? analysis;
  final LinglongRepositoryConfig? repositoryConfig;
  final LinglongEnvironmentRepairAction? activeAction;
  final LinglongEnvironmentRepairResult? repairResult;
  final String? errorMessage;

  bool get isBusy =>
      status == LinglongEnvironmentManagementStatus.loading ||
      status == LinglongEnvironmentManagementStatus.applying;

  LinglongEnvironmentManagementState copyWith({
    LinglongEnvironmentManagementStatus? status,
    LinglongEnvironmentAnalysis? analysis,
    LinglongRepositoryConfig? repositoryConfig,
    LinglongEnvironmentRepairAction? activeAction,
    LinglongEnvironmentRepairResult? repairResult,
    String? errorMessage,
    bool clearActiveAction = false,
    bool clearError = false,
    bool clearRepairResult = false,
  }) {
    return LinglongEnvironmentManagementState(
      status: status ?? this.status,
      analysis: analysis ?? this.analysis,
      repositoryConfig: repositoryConfig ?? this.repositoryConfig,
      activeAction: clearActiveAction
          ? null
          : (activeAction ?? this.activeAction),
      repairResult: clearRepairResult
          ? null
          : (repairResult ?? this.repairResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final linglongRepositoryManagementRepositoryProvider =
    Provider<LinglongRepositoryManagementRepository>((ref) {
      final messages = ref.watch(installMessagesProvider);
      return LinglongCliRepositoryImpl(messages);
    });

final linglongEnvironmentManagementServiceProvider =
    Provider<LinglongEnvironmentManagementService>((ref) {
      return LinglongEnvironmentManagementService(
        executor: ref.watch(shellCommandExecutorProvider),
        environmentService: ref.watch(linglongEnvironmentServiceProvider),
      );
    });

final linglongEnvironmentManagementProvider =
    NotifierProvider<
      LinglongEnvironmentManagement,
      LinglongEnvironmentManagementState
    >(
      LinglongEnvironmentManagement.new,
      name: 'linglongEnvironmentManagementProvider',
    );

class LinglongEnvironmentManagement
    extends Notifier<LinglongEnvironmentManagementState> {
  @override
  LinglongEnvironmentManagementState build() {
    return const LinglongEnvironmentManagementState();
  }

  Future<void> load() async {
    state = state.copyWith(
      status: LinglongEnvironmentManagementStatus.loading,
      clearError: true,
    );

    try {
      final analysis = await ref
          .read(linglongEnvironmentManagementServiceProvider)
          .analyzeEnvironment();
      final repositoryConfig = await ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .getRepositoryConfig();

      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.ready,
        analysis: analysis,
        repositoryConfig: repositoryConfig,
        clearActiveAction: true,
        clearError: true,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[LinglongEnvManagement] 加载环境管理状态失败', error, stackTrace);
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.failed,
        errorMessage: _formatError(error),
        clearActiveAction: true,
      );
    }
  }

  Future<void> refreshRepositoryConfig() async {
    try {
      final repositoryConfig = await ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .getRepositoryConfig();
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.ready,
        repositoryConfig: repositoryConfig,
        clearActiveAction: true,
        clearError: true,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[LinglongEnvManagement] 刷新仓库配置失败', error, stackTrace);
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.failed,
        errorMessage: _formatError(error),
        clearActiveAction: true,
      );
    }
  }

  Future<LinglongEnvironmentRepairResult> repairOstreeRepository() {
    return _runRepairAction(
      LinglongEnvironmentRepairAction.ostreeFsckDelete,
      () => ref
          .read(linglongEnvironmentManagementServiceProvider)
          .repairOstreeRepository(),
    );
  }

  Future<LinglongEnvironmentRepairResult> moveLinglongStorage(
    String targetPath,
  ) async {
    final blockedResult = _buildStorageMoveBlockedResult(
      ref.read(installQueueProvider),
    );
    if (blockedResult != null) {
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.failed,
        activeAction: LinglongEnvironmentRepairAction.moveStorageRoot,
        repairResult: blockedResult,
        errorMessage: blockedResult.message,
      );
      return blockedResult;
    }

    return _runRepairAction(
      LinglongEnvironmentRepairAction.moveStorageRoot,
      () => ref
          .read(linglongEnvironmentManagementServiceProvider)
          .moveLinglongStorage(targetPath),
    );
  }

  LinglongEnvironmentRepairResult? _buildStorageMoveBlockedResult(
    InstallQueueState installQueue,
  ) {
    if (!installQueue.hasActiveTasks()) return null;

    final currentTask = installQueue.currentTask;
    final activeName = currentTask == null
        ? null
        : (currentTask.appName.isNotEmpty
              ? currentTask.appName
              : currentTask.appId);
    final message = activeName == null
        ? '下载管理中仍有安装或更新任务，请等待完成或取消任务后再移动玲珑保存位置。'
        : '当前正在处理「$activeName」，请等待完成或取消任务后再移动玲珑保存位置。';

    // 保存位置迁移会整体操作 /var/lib/linglong，必须避免与 ll-cli 安装队列并发。
    return LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.moveStorageRoot,
      success: false,
      message: message,
    );
  }

  Future<String> addRepository({
    required String name,
    required String url,
    String? alias,
  }) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .addRepository(name: name, url: url, alias: alias),
    );
  }

  Future<String> updateRepository({
    required String aliasOrName,
    required String url,
  }) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .updateRepository(aliasOrName: aliasOrName, url: url),
    );
  }

  Future<String> removeRepository(String aliasOrName) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .removeRepository(aliasOrName),
    );
  }

  Future<String> setDefaultRepository(String aliasOrName) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .setDefaultRepository(aliasOrName),
    );
  }

  Future<String> setRepositoryPriority(String aliasOrName, int priority) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .setRepositoryPriority(aliasOrName, priority),
    );
  }

  Future<String> setRepositoryMirror(
    String aliasOrName, {
    required bool enabled,
  }) {
    return _runRepositoryMutation(
      () => ref
          .read(linglongRepositoryManagementRepositoryProvider)
          .setRepositoryMirror(aliasOrName, enabled: enabled),
    );
  }

  Future<LinglongEnvironmentRepairResult> _runRepairAction(
    LinglongEnvironmentRepairAction action,
    Future<LinglongEnvironmentRepairResult> Function() operation,
  ) async {
    state = state.copyWith(
      status: LinglongEnvironmentManagementStatus.applying,
      activeAction: action,
      clearError: true,
      clearRepairResult: true,
    );

    try {
      final result = await operation();
      state = state.copyWith(repairResult: result);
      await load();
      state = state.copyWith(repairResult: result);
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        '[LinglongEnvManagement] 修复动作执行失败: $action',
        error,
        stackTrace,
      );
      final result = LinglongEnvironmentRepairResult(
        action: action,
        success: false,
        message: _formatError(error),
      );
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.failed,
        activeAction: action,
        repairResult: result,
        errorMessage: result.message,
      );
      return result;
    }
  }

  Future<String> _runRepositoryMutation(
    Future<String> Function() operation,
  ) async {
    state = state.copyWith(
      status: LinglongEnvironmentManagementStatus.applying,
      clearError: true,
    );

    try {
      final output = await operation();
      await refreshRepositoryConfig();
      return output;
    } catch (error, stackTrace) {
      AppLogger.error('[LinglongEnvManagement] 仓库配置变更失败', error, stackTrace);
      state = state.copyWith(
        status: LinglongEnvironmentManagementStatus.failed,
        errorMessage: _formatError(error),
        clearActiveAction: true,
      );
      rethrow;
    }
  }

  String _formatError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }
}
