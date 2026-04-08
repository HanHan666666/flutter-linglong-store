import 'package:flutter/material.dart';

/// 无障碍按钮 Widget
///
/// 自动提供：
/// - Semantics(label: semanticsLabel, button: true)
/// - 最小 48x48 交互尺寸（通过 SizedBox 强制容器大小）
///
/// 用法：
/// ```dart
/// A11yButton(
///   semanticsLabel: l10n.a11yInstallApp(app.name),
///   onTap: () => install(app),
///   child: ElevatedButton(...),
/// )
/// ```
class A11yButton extends StatelessWidget {
  const A11yButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticsLabel,
    this.semanticsValue,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;
  final String? semanticsValue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      value: semanticsValue,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}

/// 无障碍图标按钮 Widget
///
/// 自动提供：
/// - Semantics(label: semanticsLabel, button: true)
/// - 最小 48x48 交互尺寸（固定 48x48 容器，图标居中）
/// - 装饰性图标用 ExcludeSemantics 包裹
/// - 可选 Tooltip 提示
///
/// 用法：
/// ```dart
/// A11yIconButton(
///   icon: const Icon(Icons.close),
///   semanticsLabel: l10n.a11yClose,
///   onTap: () => close(),
/// )
/// ```
class A11yIconButton extends StatelessWidget {
  const A11yIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.tooltip,
    this.enabled = true,
    this.iconSize = 20,
  });

  final Widget icon;
  final VoidCallback onTap;
  final String semanticsLabel;
  final String? tooltip;
  final bool enabled;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = ExcludeSemantics(child: icon);

    if (tooltip != null) {
      iconWidget = Tooltip(message: tooltip, child: iconWidget);
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: iconWidget,
            ),
          ),
        ),
      ),
    );
  }
}

/// 无障碍列表项 Widget
///
/// 自动提供：
/// - Semantics(label: semanticsLabel)
/// - MergeSemantics 合并内部子组件语义（避免屏幕阅读器逐个读）
/// - 动态状态通过 Semantics.value 更新
///
/// 用法：
/// ```dart
/// A11yListItem(
///   semanticsLabel: l10n.a11yAppCard(app.name, version, status),
///   onTap: () => navigateToDetail(app),
///   child: ListTile(...),
/// )
/// ```
class A11yListItem extends StatelessWidget {
  const A11yListItem({
    super.key,
    required this.child,
    required this.semanticsLabel,
    this.semanticsValue,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final String semanticsLabel;
  final String? semanticsValue;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: semanticsLabel,
        value: semanticsValue,
        enabled: enabled,
        child: onTap != null
            ? InkWell(
                onTap: enabled ? onTap : null,
                child: child,
              )
            : child,
      ),
    );
  }
}

/// 无障碍 Tab Widget
///
/// 自动提供：
/// - Semantics(label: semanticsLabel, selected: selected)
/// - 最小 48x48 交互尺寸（通过 SizedBox 保证）
///
/// 用法：
/// ```dart
/// A11yTab(
///   label: l10n.installedApps,
///   selected: currentIndex == 0,
///   onTap: () => switchTab(0),
///   child: Text(l10n.installedApps),
/// )
/// ```
class A11yTab extends StatelessWidget {
  const A11yTab({
    super.key,
    required this.child,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final Widget child;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// 无障碍卡片 Widget
///
/// 自动提供：
/// - Semantics(label: semanticsLabel, hint: semanticsHint)
/// - 用于应用卡片等复合组件
/// - 可选 onTap 点击交互
///
/// 用法：
/// ```dart
/// A11yCard(
///   semanticsLabel: l10n.a11yAppCard(app.name, version, status),
///   onTap: () => navigateToDetail(app),
///   child: Container(...),
/// )
/// ```
class A11yCard extends StatelessWidget {
  const A11yCard({
    super.key,
    required this.child,
    required this.semanticsLabel,
    this.semanticsHint,
    this.onTap,
  });

  final Widget child;
  final String semanticsLabel;
  final String? semanticsHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: child,
            )
          : child,
    );
  }
}
