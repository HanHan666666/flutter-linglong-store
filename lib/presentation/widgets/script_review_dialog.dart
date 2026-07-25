import 'package:flutter/material.dart';

import '../../core/accessibility/a11y_focus_traversal.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'copyable_command_block.dart';

/// 特权脚本全文审计对话框。
///
/// 对话框展示的 [script] 会原样传给执行服务；UI 不做 trim、换行转换或重新拼接，
/// 保证用户看到、签名验证和最终落盘的是同一份文本。
class ScriptReviewDialog extends StatelessWidget {
  /// 创建脚本审计对话框。
  const ScriptReviewDialog({super.key, required this.script});

  /// 即将执行的精确脚本文本。
  final String script;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appColors = context.appColors;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.xl,
      ),
      child: A11yFocusScope(
        debugLabel: 'ScriptReviewDialog',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 560,
            maxWidth: 780,
            minHeight: 440,
            maxHeight: 680,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.scriptReviewTitle ?? '审计一键修复脚本',
                  style: context.appTextStyles.title3.copyWith(
                    color: appColors.textPrimary,
                    fontWeight: context.appFontWeight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: appColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: appColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: appColors.warning,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n?.scriptReviewWarning ??
                              '下面是即将以管理员权限执行的完整脚本。请确认内容可信且符合预期后再继续。',
                          style: context.appTextStyles.bodyMedium.copyWith(
                            color: appColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    child: CopyableCommandBlock(
                      command: script,
                      semanticLabel:
                          l10n?.scriptReviewSemanticLabel ?? '即将执行的完整修复脚本',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n?.cancel ?? '取消'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      key: const Key('executeRepairScriptButton'),
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const ExcludeSemantics(
                        child: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      label: Text(l10n?.executeRepairScript ?? '确认并执行'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 打开脚本全文审计对话框。
Future<bool> showScriptReviewDialog(
  BuildContext context, {
  required String script,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => ScriptReviewDialog(script: script),
      ) ??
      false;
}
