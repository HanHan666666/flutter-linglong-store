/// 已忽略更新管理弹窗。
///
/// 弹窗只呈现持久化状态并触发统一恢复服务；列表使用有界 builder，
/// 确保记录较多时仍保持稳定布局和较低构建开销。
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/ignored_updates_provider.dart';
import '../../application/services/ignored_update_service.dart';
import '../../core/accessibility/a11y_focus_traversal.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/ignored_update.dart';
import 'app_icon.dart';

/// 显示已忽略更新管理弹窗。
Future<void> showIgnoredUpdatesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const A11yFocusScope(
      debugLabel: 'IgnoredUpdatesDialog',
      child: IgnoredUpdatesDialog(),
    ),
  );
}

/// 已忽略更新管理弹窗。
class IgnoredUpdatesDialog extends ConsumerStatefulWidget {
  /// 创建管理弹窗。
  const IgnoredUpdatesDialog({super.key});

  @override
  ConsumerState<IgnoredUpdatesDialog> createState() =>
      _IgnoredUpdatesDialogState();
}

/// 管理弹窗状态，行级记录正在恢复的应用，避免阻塞其他条目。
class _IgnoredUpdatesDialogState extends ConsumerState<IgnoredUpdatesDialog> {
  /// 当前正在恢复更新提醒的 appId 集合。
  final Set<String> _restoringAppIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final records = ref.watch(ignoredUpdatesProvider).records;
    // 明确约束滚动区域高度，保留 builder 的惰性布局能力；短列表也不留大块空白。
    final listHeight = math.min(440.0, records.length * 80.0);

    return AlertDialog(
      title: Text(l10n.ignoredUpdatesTitle),
      content: SizedBox(
        width: 560,
        child: records.isEmpty
            ? _buildEmptyState(context, l10n)
            : SizedBox(
                height: listHeight,
                child: ListView.separated(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _buildRecordRow(context, l10n, record);
                  },
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: context.appColors.borderSecondary,
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  /// 构建无记录时的简洁空态。
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.ignoredUpdatesEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.ignoredUpdatesEmptyDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单条忽略记录及其恢复入口。
  Widget _buildRecordRow(
    BuildContext context,
    AppLocalizations l10n,
    IgnoredUpdate record,
  ) {
    final isRestoring = _restoringAppIds.contains(record.appId);
    final displayedVersion = record.ignoredVersion.isEmpty
        ? l10n.unknown
        : record.ignoredVersion;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          ExcludeSemantics(
            child: AppIcon(
              iconUrl: record.icon,
              size: 40,
              borderRadius: AppRadius.sm,
              appName: record.appName,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              label: l10n.a11yIgnoredUpdateItem(
                record.appName,
                record.appId,
                displayedVersion,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    record.appId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.ignoredVersion(displayedVersion),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            enabled: !isRestoring,
            label: l10n.a11yRestoreAppUpdates(record.appName),
            onTap: isRestoring ? null : () => unawaited(_restoreRecord(record)),
            excludeSemantics: true,
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: isRestoring
                  ? null
                  : () => unawaited(_restoreRecord(record)),
              child: isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.restoreUpdateNotifications),
            ),
          ),
        ],
      ),
    );
  }

  /// 恢复单条记录，并根据持久化与刷新结果给出准确反馈。
  Future<void> _restoreRecord(IgnoredUpdate record) async {
    if (_restoringAppIds.contains(record.appId)) {
      return;
    }
    setState(() => _restoringAppIds.add(record.appId));

    final result = await ref
        .read(ignoredUpdateServiceProvider)
        .restore(record.appId);

    if (!mounted) {
      return;
    }
    setState(() => _restoringAppIds.remove(record.appId));

    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case RestoreIgnoredUpdateResult.success:
        showAppNotification(context, l10n.restoreUpdateSuccess(record.appName));
        break;
      case RestoreIgnoredUpdateResult.persistenceFailed:
        showAppError(context, l10n.restoreUpdateFailed);
        break;
      case RestoreIgnoredUpdateResult.refreshFailed:
        showAppWarning(context, l10n.restoreUpdateRefreshFailed);
        break;
    }
  }
}
