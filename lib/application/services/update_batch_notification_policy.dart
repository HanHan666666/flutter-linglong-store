/// 把稳定的一键更新批次摘要格式化为系统通知消息。
///
/// 该策略只处理业务摘要、国际化和长度边界，不感知 MethodChannel、桌面环境
/// 或通知服务是否可用，便于其它通知后端复用同一套内容规则。
library;

import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/app_operation_batch.dart';
import '../../domain/models/app_operation_target_snapshot.dart';
import '../../domain/models/system_notification.dart';

/// 一键更新系统通知格式化策略。
class UpdateBatchNotificationPolicy {
  /// 创建无状态通知策略。
  const UpdateBatchNotificationPolicy();

  /// 通知最多直接列出的成功应用数量，避免桌面通知展开成大段日志。
  static const int _maximumListedApps = 6;

  /// 单个应用名称上限，防止异常服务端名称吞掉整个通知正文。
  static const int _maximumAppNameRunes = 48;

  /// 最终标题和正文上限低于平台网关硬限制，为桌面 UI 保留安全余量。
  static const int _maximumTitleRunes = 120;
  static const int _maximumBodyRunes = 512;

  /// 根据批次结果生成一条纯文本通知。
  SystemNotificationMessage format({
    required AppOperationBatch batch,
    required AppOperationBatchSummary summary,
    required AppLocalizations l10n,
  }) {
    final successCount = summary.successfulTargets.length;
    final failedCount = summary.failedTargets.length;
    final cancelledCount = summary.cancelledTargets.length;
    final interruptedCount = summary.interruptedTargets.length;

    final title = switch (successCount) {
      0 => l10n.updateBatchNoSuccessTitle,
      _ when successCount == summary.totalCount =>
        l10n.updateBatchAllSucceededTitle(successCount),
      _ => l10n.updateBatchFinishedTitle,
    };

    final resultSummary = l10n.updateBatchResultSummary(
      successCount,
      failedCount,
      cancelledCount,
      interruptedCount,
    );
    final updatedApps = _formatUpdatedApps(summary.successfulTargets, l10n);
    final body = updatedApps == null
        ? resultSummary
        : '$resultSummary\n$updatedApps';

    return SystemNotificationMessage(
      id: 'update-batch-${batch.id}',
      title: _truncate(title, _maximumTitleRunes),
      body: _truncate(body, _maximumBodyRunes),
      category: 'transfer.complete',
      iconName: 'linglong-store',
    );
  }

  /// 按批次原始顺序列出成功目标，并以本地化模板表达剩余数量。
  String? _formatUpdatedApps(
    List<AppOperationTargetSnapshot> successfulTargets,
    AppLocalizations l10n,
  ) {
    if (successfulTargets.isEmpty) {
      return null;
    }

    final visibleNames = successfulTargets
        .take(_maximumListedApps)
        .map(
          (target) => _truncate(
            target.displayName.trim().isEmpty
                ? target.appId
                : target.displayName.trim(),
            _maximumAppNameRunes,
          ),
        )
        .join(l10n.updateBatchAppNameSeparator);
    final remainingCount = successfulTargets.length - _maximumListedApps;
    if (remainingCount > 0) {
      return l10n.updateBatchUpdatedAppsOverflow(visibleNames, remainingCount);
    }
    return l10n.updateBatchUpdatedApps(visibleNames);
  }

  /// 按 Unicode code point 裁剪，避免在 UTF-16 surrogate pair 中间截断。
  String _truncate(String value, int maximumRunes) {
    final runes = value.runes;
    if (runes.length <= maximumRunes) {
      return value;
    }
    if (maximumRunes <= 1) {
      return '…';
    }
    return '${String.fromCharCodes(runes.take(maximumRunes - 1))}…';
  }
}
