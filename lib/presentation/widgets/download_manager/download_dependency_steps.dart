/// 下载管理器中依赖处理记录的只读展示。
///
/// 这里只渲染父任务已观察到的包身份，不持有进度状态，也不把依赖伪装成独立任务。
library;

import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/install_task.dart';

/// 将当前和此前观察到的依赖处理步骤附在父任务卡片下。
class DownloadDependencySteps extends StatelessWidget {
  /// 使用任务中的不可变观察事实构建记录区。
  const DownloadDependencySteps({required this.task, super.key});

  /// 父应用任务；依赖不会拥有自己的任务对象。
  final InstallTask task;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.cardBackground.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderSecondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dependencyProcessingSteps,
              style: context.appTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // 父任务是唯一滚动容器；短列表在同一滚动面板中按需构建。
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.observedDependencyIds.length,
              itemBuilder: (context, index) {
                final packageId = task.observedDependencyIds[index];
                final isActive = packageId == task.activeDependencyId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          isActive ? Icons.sync : Icons.history,
                          size: 14,
                          color: isActive ? accent : colors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Tooltip(
                          message: packageId,
                          child: Text(
                            packageId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.appTextStyles.caption.copyWith(
                              color: isActive
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isActive
                            ? l10n.dependencyCurrentlyProcessing
                            : l10n.dependencyPreviouslyProcessed,
                        style: context.appTextStyles.tiny.copyWith(
                          color: isActive ? accent : colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
