import 'package:flutter/material.dart';

import '../../core/accessibility/a11y_focus_traversal.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 用户体验计划采集信息说明弹窗。
///
/// 配合设置页「用户体验计划」开关使用：开关旁的感叹号按钮打开本弹窗，
/// 向用户说明加入了计划后会收集哪些信息。文案只描述「收集了什么」，
/// 不解释技术实现；整体语气正向温和，强调可控可退出，降低用户抵触。
class UserExperienceProgramDialog extends StatelessWidget {
  const UserExperienceProgramDialog({super.key});

  /// 打开说明弹窗。
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UserExperienceProgramDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.userExperienceProgram),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      content: A11yFocusScope(
        debugLabel: 'UserExperienceProgramDialog',
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.userExperienceProgramDialogIntro),
              const SizedBox(height: 12),
              // 每个采集项一行；前置装饰图标对语义无意义，必须排除朗读。
              _InfoItem(text: l10n.userExperienceProgramDialogItemIdentity),
              _InfoItem(text: l10n.userExperienceProgramDialogItemSystem),
              _InfoItem(text: l10n.userExperienceProgramDialogItemApps),
              _InfoItem(text: l10n.userExperienceProgramDialogItemNetwork),
              const SizedBox(height: 12),
              Text(l10n.userExperienceProgramDialogFooter),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// 单条采集信息行：装饰性圆点 + 文本。
class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 7),
              child: _Dot(color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// 6px 装饰圆点；固定小尺寸自绘，避免引入整颗 Icon 字形的开销。
class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 6,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
