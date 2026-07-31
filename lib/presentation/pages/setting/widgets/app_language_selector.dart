/// 设置页折叠式语言选择器。
///
/// 该文件只负责 Locale 列表的展示与选择，语言来源仍由 ARB 生成结果统一驱动；
/// 菜单定位、焦点和尺寸规则复用应用级锚点菜单，避免设置页持有弹层状态。
library;

import 'package:flutter/material.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/i18n/app_locale.dart';
import '../../../widgets/app_anchored_menu.dart';

/// 在固定高度设置卡片中展示当前语言，并按需展开完整语言列表。
class AppLanguageSelector extends StatelessWidget {
  /// 创建由 ARB 支持列表驱动的语言选择器。
  const AppLanguageSelector({
    required this.currentLocale,
    required this.locales,
    required this.label,
    required this.onSelected,
    super.key,
  }) : assert(locales.length > 0);

  /// 当前已经生效的应用语言。
  final Locale currentLocale;

  /// 可选择的正式发布语言，调用方应传入 `selectableAppLocales`。
  final List<Locale> locales;

  /// 来自 ARB 的字段标题，同时用于 Tooltip 和屏幕阅读器。
  final String label;

  /// 用户选择新语言后的业务回调。
  final ValueChanged<Locale> onSelected;

  /// 构建不随语言数量增长页面高度的锚点选择字段。
  @override
  Widget build(BuildContext context) {
    final currentLanguageName = appLanguageSelfName(currentLocale);

    // 与其他设置 Card 的默认 4px margin 保持一致，同时让 MenuAnchor 的锚点
    // 只覆盖真实卡片范围，固定宽度菜单不会把外侧留白计算进去。
    return Padding(
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final menuWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : null;
          return AppAnchoredMenu<Locale>(
            key: const ValueKey('language-selector-menu'),
            menuWidth: menuWidth,
            entries: [
              for (final locale in locales)
                AppAnchoredMenuItem<Locale>(
                  key: ValueKey('language-option-${locale.toLanguageTag()}'),
                  value: locale,
                  label: appLanguageSelfName(locale),
                  selected: _isSameLanguage(locale, currentLocale),
                ),
            ],
            onSelected: onSelected,
            builder: (context, handle) {
              return Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Semantics(
                  button: true,
                  label: label,
                  value: currentLanguageName,
                  expanded: handle.isOpen,
                  excludeSemantics: true,
                  child: InkWell(
                    key: const ValueKey('language-selector-trigger'),
                    focusNode: handle.focusNode,
                    onTap: handle.toggle,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                currentLanguageName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              handle.isOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 当前产品按 language code 选择资源，保持与应用 Locale 解析规则一致。
  bool _isSameLanguage(Locale first, Locale second) {
    return first.languageCode == second.languageCode;
  }
}
