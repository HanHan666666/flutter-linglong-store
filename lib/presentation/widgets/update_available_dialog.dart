import 'package:flutter/material.dart';

import '../../application/services/version_check_service.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 检测到新版本弹窗。
///
/// 只提示有更新，平铺展示 GitHub / Gitee 两个链接（点击查看更新日志），
/// 并提供「立即更新」主按钮与「取消」。链接打开与更新动作均通过回调注入，
/// 便于测试与替换实现。
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.update,
    required this.onOpenUrl,
    required this.onUpdateNow,
  });

  final VersionCheckResultUpdateAvailable update;

  /// 打开外部链接（由调用方提供 url_launcher 实现）。
  final void Function(String url) onOpenUrl;

  /// 点击「立即更新」后的动作（由调用方打开更新流程弹窗）。
  final VoidCallback onUpdateNow;

  /// GitHub 发布页（查看更新日志）。
  static const String githubReleaseUrl =
      'https://github.com/HanHan666666/flutter-linglong-store/releases/latest';

  /// Gitee 发布页（查看更新日志）。
  static const String giteeReleaseUrl =
      'https://gitee.com/hanplus/flutter-linglong-store/releases/latest';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.checkUpdate),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.newVersionFound(update.latestVersion, update.currentVersion),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // GitHub / Gitee 链接平铺，点击可查看更新日志。
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => onOpenUrl(githubReleaseUrl),
                icon: const Icon(Icons.code, size: 18),
                label: const Text('GitHub'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => onOpenUrl(giteeReleaseUrl),
                icon: const Icon(Icons.code_outlined, size: 18),
                label: const Text('Gitee'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: onUpdateNow,
          icon: const Icon(Icons.system_update_alt, size: 18),
          label: Text(l10n.updateNow),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
