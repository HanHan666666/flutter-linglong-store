/// 下载管理工作面板公共入口和 Provider 容器。
///
/// 该文件只聚合安装队列、当前语言、发行版和网速状态，并组合标题、概览、
/// 任务内容与底栏。任务卡局部状态和各区域布局位于独立组件。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_dependency_providers.dart'
    show linglongCliRepositoryProvider;
import '../../application/providers/install_queue_provider.dart';
import '../../application/providers/linglong_env_provider.dart';
import '../../application/providers/network_speed_provider.dart';
import '../../core/config/theme.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/linux_distribution.dart';
import 'download_manager/download_manager_footer.dart';
import 'download_manager/download_manager_header.dart';
import 'download_manager/download_manager_overview.dart';
import 'download_manager/download_manager_task_content.dart';
import 'download_manager/download_task_view_data.dart';

/// 以轻工作面板形式展示安装队列和安装历史。
class DownloadManagerDialog extends ConsumerWidget {
  /// 创建下载管理工作面板。
  const DownloadManagerDialog({super.key});

  static const double _dialogWidth = 640;
  static const double _dialogMinHeight = 480;
  static const double _dialogMaxHeight = 620;
  static const double _dialogRadius = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(installQueueProvider);
    final messages = ref.watch(installMessagesProvider);
    final distribution = ref.watch(
      linglongEnvProvider.select(
        (state) => state.result?.distribution ?? LinuxDistribution.unknown,
      ),
    );
    final systemSpeed = ref.watch(networkSpeedProvider).formatted;
    final appColors = context.appColors;

    DownloadTaskViewData resolveTask(InstallTask task) {
      return DownloadTaskViewData(
        task: task,
        statusMessage: messages.messageForTask(
          task,
          distribution: distribution,
        ),
        errorMessage: task.isFailed
            ? messages.errorMessageForTask(task, distribution: distribution)
            : null,
      );
    }

    final currentTask = queueState.currentTask == null
        ? null
        : resolveTask(queueState.currentTask!);
    final queuedTasks = queueState.queue
        .map(resolveTask)
        .toList(growable: false);
    final historyTasks = queueState.history
        .map(resolveTask)
        .toList(growable: false);
    final resolvedSpeed = queueState.currentTask?.cliSpeed ?? systemSpeed;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.xl,
      ),
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              MediaQuery.sizeOf(context).height - AppSpacing.x5l;
          final dialogHeight = availableHeight
              .clamp(_dialogMinHeight, _dialogMaxHeight)
              .toDouble();

          return SizedBox(
            width: _dialogWidth,
            height: dialogHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: appColors.surface,
                borderRadius: BorderRadius.circular(_dialogRadius),
                border: Border.all(color: appColors.borderSecondary),
                boxShadow: AppShadows.modal,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_dialogRadius),
                child: Column(
                  children: [
                    DownloadManagerHeader(
                      hasHistory: queueState.history.isNotEmpty,
                      onClearHistory: () {
                        ref.read(installQueueProvider.notifier).clearHistory();
                      },
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    DownloadManagerOverview(
                      activeCount: queueState.currentTask == null ? 0 : 1,
                      queuedCount: queueState.queue.length,
                      historyCount: queueState.history.length,
                    ),
                    Divider(height: 1, color: appColors.divider),
                    Expanded(
                      child: DownloadManagerTaskContent(
                        currentTask: currentTask,
                        queuedTasks: queuedTasks,
                        historyTasks: historyTasks,
                        currentDownloadSpeed: resolvedSpeed,
                        onCancelCurrent: (task) {
                          ref
                              .read(installQueueProvider.notifier)
                              .cancelTask(task.appId);
                        },
                        onRemoveQueued: (task) {
                          ref
                              .read(installQueueProvider.notifier)
                              .removeQueuedTask(task.id);
                        },
                        onOpenHistory: (task) {
                          ref
                              .read(linglongCliRepositoryProvider)
                              .runApp(task.appId);
                        },
                        onRetryHistory: (task) {
                          ref
                              .read(installQueueProvider.notifier)
                              .retryFailedTask(task.id);
                        },
                        onRemoveHistory: (task) {
                          ref
                              .read(installQueueProvider.notifier)
                              .removeHistoryTask(task.id);
                        },
                      ),
                    ),
                    DownloadManagerFooter(
                      speed: resolvedSpeed,
                      historyCount: queueState.history.length,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 显示下载管理工作面板。
Future<void> showDownloadManagerDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const DownloadManagerDialog(),
  );
}
