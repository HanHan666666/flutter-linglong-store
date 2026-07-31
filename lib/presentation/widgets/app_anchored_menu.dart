/// 应用级桌面锚点菜单。
///
/// 该文件统一承载按钮菜单和设置字段菜单的弹层、尺寸与无障碍规则，避免页面使用
/// 带路由动画的旧式弹出菜单，也避免各业务入口重复实现 Overlay 行为。
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/config/theme.dart';

/// 锚点构建器可使用的轻量控制句柄。
///
/// 句柄只暴露触发控件需要的开关状态和焦点，不允许业务层直接操作 Flutter 的
/// `MenuController`，从而把弹层生命周期保持在公共组件内部。
class AppAnchoredMenuHandle {
  /// 创建一个只在当前锚点构建周期内使用的菜单句柄。
  const AppAnchoredMenuHandle({
    required this.toggle,
    required this.isOpen,
    required this.focusNode,
  });

  /// 在打开和关闭之间切换菜单。
  final VoidCallback toggle;

  /// 当前菜单是否已经显示。
  final bool isOpen;

  /// 触发控件使用的焦点节点，菜单关闭后由 Flutter 恢复焦点。
  final FocusNode focusNode;
}

/// 构建锚点触发控件的回调。
typedef AppAnchoredMenuBuilder =
    Widget Function(BuildContext context, AppAnchoredMenuHandle handle);

/// 锚点菜单中的结构化条目基类。
///
/// 页面只能声明动作或分隔线，具体 Widget、尺寸和状态样式由公共组件统一生成。
sealed class AppAnchoredMenuEntry<T> {
  /// 创建一个结构化菜单条目。
  const AppAnchoredMenuEntry();
}

/// 可选择的锚点菜单动作。
class AppAnchoredMenuItem<T> extends AppAnchoredMenuEntry<T> {
  /// 创建一个类型安全的菜单动作。
  const AppAnchoredMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.selected,
    this.semanticsLabel,
    this.key,
  });

  /// 选择后返回给业务调用方的动作值。
  final T value;

  /// 菜单内展示的本地化文案。
  final String label;

  /// 可选的装饰图标。
  final IconData? icon;

  /// 动作当前是否允许执行。
  final bool enabled;

  /// 动作是否代表当前选择；非单选菜单保持为空，不暴露多余的选择语义。
  final bool? selected;

  /// 覆盖默认文案的屏幕阅读器标签。
  final String? semanticsLabel;

  /// 供测试或业务定位单个菜单项的稳定标识。
  final Key? key;
}

/// 锚点菜单中的视觉分隔线。
class AppAnchoredMenuDivider<T> extends AppAnchoredMenuEntry<T> {
  /// 创建不参与焦点和选择的菜单分隔线。
  const AppAnchoredMenuDivider();
}

/// 无路由展开动画的应用级锚点菜单。
///
/// 组件基于 Material 3 `MenuAnchor`，复用 SDK 的边缘避让、键盘导航和焦点恢复，
/// 同时把菜单尺寸限制在桌面窗口内。业务回调由 `MenuItemButton` 在弹层关闭后的
/// post-frame 阶段触发，Locale 切换等根组件重建不会留下旧 Overlay。
class AppAnchoredMenu<T> extends StatefulWidget {
  /// 创建一个由调用方自定义触发控件的锚点菜单。
  const AppAnchoredMenu({
    required this.entries,
    required this.onSelected,
    required this.builder,
    super.key,
    this.menuWidth,
    this.minimumMenuWidth = 160,
    this.maximumMenuWidth = 360,
    this.maximumMenuHeight = 320,
    this.alignment = AlignmentDirectional.topEnd,
    this.alignmentOffset = const Offset(0, 4),
  }) : assert(minimumMenuWidth > 0),
       assert(maximumMenuWidth >= minimumMenuWidth),
       assert(maximumMenuHeight > 0),
       assert(menuWidth == null || menuWidth > 0);

  /// 按显示顺序排列的动作与分隔线。
  final List<AppAnchoredMenuEntry<T>> entries;

  /// 菜单动作被选择后的业务回调。
  final ValueChanged<T> onSelected;

  /// 构建作为菜单定位基准的触发控件。
  final AppAnchoredMenuBuilder builder;

  /// 需要与锚点等宽时使用的固定菜单宽度。
  final double? menuWidth;

  /// 未指定固定宽度时菜单允许使用的最小宽度。
  final double minimumMenuWidth;

  /// 菜单允许使用的最大宽度，避免长文案越过窗口边缘。
  final double maximumMenuWidth;

  /// 菜单最大高度，语言数量增加后由 SDK 在此范围内滚动。
  final double maximumMenuHeight;

  /// 菜单相对锚点的方向对齐方式。
  final AlignmentGeometry alignment;

  /// 菜单与锚点之间的视觉间距。
  final Offset alignmentOffset;

  /// 创建负责持有锚点焦点资源的局部状态。
  @override
  State<AppAnchoredMenu<T>> createState() => _AppAnchoredMenuState<T>();
}

/// 管理单个锚点菜单的焦点生命周期和结构化条目渲染。
class _AppAnchoredMenuState<T> extends State<AppAnchoredMenu<T>> {
  /// 锚点和菜单之间共享的焦点节点。
  final FocusNode _anchorFocusNode = FocusNode(
    debugLabel: 'app-anchored-menu-anchor',
  );

  /// 释放不会进入全局状态的锚点焦点资源。
  @override
  void dispose() {
    _anchorFocusNode.dispose();
    super.dispose();
  }

  /// 构建受统一宽高约束的无动画 Overlay 菜单。
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fixedWidth = widget.menuWidth;
    final minimumWidth = fixedWidth ?? widget.minimumMenuWidth;
    final maximumWidth = fixedWidth ?? widget.maximumMenuWidth;

    return MenuAnchor(
      childFocusNode: _anchorFocusNode,
      useRootOverlay: true,
      clipBehavior: Clip.antiAlias,
      alignmentOffset: widget.alignmentOffset,
      style: MenuStyle(
        alignment: widget.alignment,
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.surfaceContainerLow,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        minimumSize: WidgetStatePropertyAll(Size(minimumWidth, 0)),
        fixedSize: fixedWidth == null
            ? null
            : WidgetStatePropertyAll(Size.fromWidth(fixedWidth)),
        maximumSize: WidgetStatePropertyAll(
          Size(maximumWidth, widget.maximumMenuHeight),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        ),
      ),
      menuChildren: [
        for (final entry in widget.entries) _buildEntry(context, entry),
      ],
      builder: (context, controller, child) {
        return widget.builder(
          context,
          AppAnchoredMenuHandle(
            isOpen: controller.isOpen,
            focusNode: _anchorFocusNode,
            toggle: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
      },
    );
  }

  /// 把结构化条目转换为统一样式的 Material 菜单内容。
  Widget _buildEntry(BuildContext context, AppAnchoredMenuEntry<T> entry) {
    return switch (entry) {
      AppAnchoredMenuDivider<T>() => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      AppAnchoredMenuItem<T>() => _buildMenuItem(context, entry),
    };
  }

  /// 构建可聚焦、可禁用并支持选中语义的菜单动作。
  Widget _buildMenuItem(BuildContext context, AppAnchoredMenuItem<T> item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: item.selected,
      enabled: item.enabled,
      child: MenuItemButton(
        key: item.key,
        semanticsLabel: item.semanticsLabel ?? item.label,
        onPressed: item.enabled ? () => widget.onSelected(item.value) : null,
        leadingIcon: item.icon == null
            ? null
            : ExcludeSemantics(child: Icon(item.icon, size: 20)),
        closeOnActivate: true,
        trailingIcon: item.selected == true
            ? Icon(Icons.check_rounded, size: 20, color: colorScheme.primary)
            : null,
        style: MenuItemButton.styleFrom(
          minimumSize: Size(widget.menuWidth ?? widget.minimumMenuWidth, 48),
          maximumSize: Size(
            widget.menuWidth ?? widget.maximumMenuWidth,
            double.infinity,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: AlignmentDirectional.centerStart,
          animationDuration: Duration.zero,
        ),
        child: Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// 使用标准三点图标作为触发控件的锚点菜单。
///
/// 页面只需传入本地化 Tooltip、语义标签和结构化动作，不再重复 48px 交互尺寸、
/// 焦点接线和菜单开关逻辑。
class AppAnchoredMenuButton<T> extends StatelessWidget {
  /// 创建一个标准桌面三点菜单按钮。
  const AppAnchoredMenuButton({
    required this.entries,
    required this.onSelected,
    required this.tooltip,
    required this.semanticsLabel,
    super.key,
    this.buttonKey,
    this.enabled = true,
    this.icon = Icons.more_vert,
  });

  /// 按显示顺序排列的菜单动作与分隔线。
  final List<AppAnchoredMenuEntry<T>> entries;

  /// 菜单动作被选择后的业务回调。
  final ValueChanged<T> onSelected;

  /// 鼠标悬停提示。
  final String tooltip;

  /// 屏幕阅读器朗读的按钮用途。
  final String semanticsLabel;

  /// 保持业务入口稳定定位的按钮标识。
  final Key? buttonKey;

  /// 菜单按钮当前是否允许打开。
  final bool enabled;

  /// 触发按钮使用的图标，默认是竖向三点。
  final IconData icon;

  /// 组合公共菜单与符合项目无障碍约定的三点触发按钮。
  @override
  Widget build(BuildContext context) {
    return AppAnchoredMenu<T>(
      entries: entries,
      onSelected: onSelected,
      builder: (context, handle) {
        return A11yIconButton(
          key: buttonKey,
          focusNode: handle.focusNode,
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          semanticsLabel: semanticsLabel,
          enabled: enabled,
          onTap: handle.toggle,
        );
      },
    );
  }
}
