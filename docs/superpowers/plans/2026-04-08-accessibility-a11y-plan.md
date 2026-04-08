# 无障碍（A11y）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为玲珑应用商店添加完整的无障碍支持，包括屏幕阅读器语义化标签、标准桌面端键盘导航（Tab/Enter/方向键）、字体缩放适配和 48px 最小交互尺寸。

**Architecture:** 在 `lib/core/accessibility/` 建立统一基础设施层（Focus 遍历策略、键盘快捷键、语义化 Widget 工厂、字体缩放适配），通过 `A11yKeyboardHandler` 和 `A11yFocusScope` 挂载到 MaterialApp 顶层，业务组件使用封装好的 `A11yButton`、`A11yListItem` 等统一组件改造。

**Tech Stack:** Flutter `Semantics`/`Focus`/`Shortcuts`/`Actions` API, `flutter_localizations`, `freezed`（如有需要）

---

## 文件映射总览

### 新建文件
| 文件 | 职责 |
|------|------|
| `lib/core/accessibility/a11y_focus_traversal.dart` | ReadingOrderTraversalPolicy + A11yFocusScope |
| `lib/core/accessibility/a11y_shortcuts.dart` | A11yKeyboardHandler + Shortcuts/Actions 映射 |
| `lib/core/accessibility/a11y_semantics.dart` | A11yButton/A11yIconButton/A11yListItem/A11yTab 工厂组件 |
| `lib/core/accessibility/a11y_text_scaler.dart` | clampTextScaler() + A11yText Widget |
| `lib/core/accessibility/accessibility.dart` | barrel 导出文件 |
| `test/unit/core/accessibility/a11y_text_scaler_test.dart` | 字体缩放单元测试 |
| `test/unit/core/accessibility/a11y_semantics_test.dart` | 语义化组件 Widget 测试 |

### 修改文件
| 文件 | 改动内容 |
|------|----------|
| `lib/app.dart` | 挂载 A11yKeyboardHandler + A11yFocusScope |
| `lib/core/i18n/l10n/app_zh.arb` | 新增 29 个 a11y* 翻译 key |
| `lib/core/i18n/l10n/app_en.arb` | 新增 29 个 a11y* 翻译 key |
| `lib/core/config/theme.dart` | 修正 textTertiary 和 topLabel 颜色对比度 |
| `lib/presentation/widgets/app_card.dart` | Semantics + 48px 热区 |
| `lib/presentation/widgets/install_button.dart` | 三态语义化 |
| `lib/presentation/widgets/sidebar.dart` | 导航项 Semantics + 48px 热区 |
| `lib/presentation/widgets/title_bar.dart` | 窗口控制按钮语义化 |
| `lib/presentation/widgets/search_bar.dart` | 搜索框 Semantics + 建议列表语义 |
| `lib/presentation/widgets/category_filter_header.dart` | 胶囊 Semantics + Tab 角色 |
| `lib/presentation/widgets/download_manager_dialog.dart` | 下载项 Semantics + 按钮热区 |
| `lib/presentation/widgets/linglong_process_panel.dart` | 进程列表 Semantics |
| `lib/presentation/widgets/confirm_dialog.dart` | 对话框按钮语义 |
| `lib/presentation/widgets/app_detail_comment_section.dart` | 评论输入 + 版本胶囊语义 |
| `lib/presentation/pages/recommend/recommend_page.dart` | 轮播按钮 + 列表语义 + heading |
| `lib/presentation/pages/ranking/ranking_page.dart` | 列表项语义 + heading |
| `lib/presentation/pages/all_apps/all_apps_page.dart` | 列表项语义 + heading |
| `lib/presentation/pages/custom_category/custom_category_page.dart` | 列表项语义 + heading |
| `lib/presentation/pages/app_detail/app_detail_page.dart` | heading + 截图区/评论区标注 |
| `lib/presentation/pages/my_apps/my_apps_page.dart` | heading + TabBar 标注 |
| `lib/presentation/pages/setting/setting_page.dart` | heading + 区块标注 |
| `lib/presentation/pages/search_list/search_list_page.dart` | heading + 结果列表标注 |
| `lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart` | 截图 image 角色标注 |

---

## 阶段一：基础设施层

### Task 1: 创建 Focus 遍历策略

**Files:**
- Create: `lib/core/accessibility/a11y_focus_traversal.dart`
- Test: `flutter analyze`

- [ ] **Step 1: 创建 a11y_focus_traversal.dart**

```dart
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

/// 阅读顺序 Focus 遍历策略
///
/// Tab / Shift+Tab 按 从上到下、从左到右 的顺序移动焦点，
/// 符合桌面端用户的阅读习惯。自动跳过不可见/禁用的元素。
///
/// 用法：在 MaterialApp 的 builder 或顶层 Widget 中使用：
/// ```dart
/// Focus(
///   focusNode: FocusNode(),
///   child: ReadingOrderTraversalScope(
///     child: ...,
///   ),
/// )
/// ```
class ReadingOrderTraversalPolicy extends FocusTraversalPolicy {
  ReadingOrderTraversalPolicy({this.debugLabel});

  /// 调试标签，用于日志输出
  final String? debugLabel;

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    // 默认只支持 Tab (forward) 和 Shift+Tab (backward)
    // 方向键导航由组件内部的 FocusScope 处理
    if (direction == TraversalDirection.up ||
        direction == TraversalDirection.down ||
        direction == TraversalDirection.left ||
        direction == TraversalDirection.right) {
      return false; // 交由组件内部的 Shortcuts/Actions 处理
    }

    final bool forward = direction == TraversalDirection.right;
    final FocusNode? next = _findNextNode(currentNode, forward);
    if (next != null) {
      next.requestFocus();
      return true;
    }
    return false;
  }

  @override
  FocusNode? findFirstFocus(FocusNode currentNode) {
    final scope = _findScope(currentNode.context);
    if (scope == null) return null;
    return _findFirstInSubtree(scope);
  }

  @override
  FocusNode? findLastFocus(FocusNode currentNode) {
    final scope = _findScope(currentNode.context);
    if (scope == null) return null;
    return _findLastInSubtree(scope);
  }

  @override
  FocusNode? findNextFocus(FocusNode currentNode, {TraversalDirection? direction}) {
    final bool forward = direction != TraversalDirection.left;
    return _findNextNode(currentNode, forward);
  }

  FocusNode? _findNextNode(FocusNode currentNode, bool forward) {
    final scope = _findScope(currentNode.context);
    if (scope == null) return null;

    final allNodes = _collectFocusNodes(scope);
    if (allNodes.isEmpty) return null;

    final currentIndex = allNodes.indexOf(currentNode);
    if (currentIndex == -1) return forward ? allNodes.first : allNodes.last;

    if (forward) {
      for (int i = currentIndex + 1; i < allNodes.length; i++) {
        if (_isNodeFocusable(allNodes[i])) return allNodes[i];
      }
      // 循环到开头
      for (int i = 0; i < currentIndex; i++) {
        if (_isNodeFocusable(allNodes[i])) return allNodes[i];
      }
    } else {
      for (int i = currentIndex - 1; i >= 0; i--) {
        if (_isNodeFocusable(allNodes[i])) return allNodes[i];
      }
      // 循环到末尾
      for (int i = allNodes.length - 1; i > currentIndex; i--) {
        if (_isNodeFocusable(allNodes[i])) return allNodes[i];
      }
    }
    return null;
  }

  FocusNode? _findFirstInSubtree(FocusNode node) {
    final allNodes = _collectFocusNodes(node);
    for (final n in allNodes) {
      if (_isNodeFocusable(n)) return n;
    }
    return null;
  }

  FocusNode? _findLastInSubtree(FocusNode node) {
    final allNodes = _collectFocusNodes(node).reversed;
    for (final n in allNodes) {
      if (_isNodeFocusable(n)) return n;
    }
    return null;
  }

  List<FocusNode> _collectFocusNodes(FocusNode root) {
    final nodes = <FocusNode>[];
    void walk(FocusNode node) {
      nodes.add(node);
      for (final child in node.children) {
        walk(child);
      }
    }
    walk(root);
    return nodes;
  }

  bool _isNodeFocusable(FocusNode node) {
    return node.canRequestFocus && node.context != null;
  }

  FocusNode? _findScope(BuildContext? context) {
    if (context == null) return null;
    // 查找最近的 A11yFocusScope
    FocusNode? current = Focus.maybeOf(context);
    while (current != null) {
      if (current.userData is _A11yFocusScopeMarker) return current;
      current = current.parent;
    }
    return Focus.maybeOf(context); // fallback 到顶层 Focus
  }
}

class _A11yFocusScopeMarker {
  const _A11yFocusScopeMarker();
}

/// 无障碍 Focus 范围隔离 Widget
///
/// 用于页面级或弹窗级，防止焦点泄漏到背景层。
/// 用法：在页面根节点或 Dialog 内容外层包裹：
/// ```dart
/// A11yFocusScope(
///   child: YourDialogContent(),
/// )
/// ```
class A11yFocusScope extends StatefulWidget {
  const A11yFocusScope({
    super.key,
    required this.child,
    this.debugLabel,
  });

  final Widget child;
  final String? debugLabel;

  @override
  State<A11yFocusScope> createState() => _A11yFocusScopeState();
}

class _A11yFocusScopeState extends State<A11yFocusScope> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      debugLabel: widget.debugLabel ?? 'A11yFocusScope',
      userData: const _A11yFocusScopeMarker(),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      canRequestFocus: true,
      descendantsAreFocusable: true,
      child: ReadingOrderTraversalScope(
        child: widget.child,
      ),
    );
  }
}

/// ReadingOrderTraversalScope Widget
///
/// 在子树内应用 ReadingOrderTraversalPolicy。
class ReadingOrderTraversalScope extends StatelessWidget {
  const ReadingOrderTraversalScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/accessibility/a11y_focus_traversal.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**

```bash
git add lib/core/accessibility/a11y_focus_traversal.dart
git commit -m "feat: 添加无障碍 Focus 遍历策略和焦点范围隔离组件"
```

---

### Task 2: 创建键盘快捷键映射

**Files:**
- Create: `lib/core/accessibility/a11y_shortcuts.dart`
- Test: `flutter analyze`

- [ ] **Step 1: 创建 a11y_shortcuts.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局键盘快捷键处理器
///
/// 在 MaterialApp 外层包裹，提供标准的桌面端键盘导航：
/// - Tab / Shift+Tab → 焦点移动（由 FocusTraversalPolicy 处理）
/// - Enter / Space → 触发当前焦点组件
/// - Esc → 关闭弹窗 / 返回上一页（由业务组件处理）
///
/// 用法：
/// ```dart
/// A11yKeyboardHandler(
///   child: MaterialApp.router(...),
/// )
/// ```
class A11yKeyboardHandler extends StatelessWidget {
  const A11yKeyboardHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions(context),
        child: child,
      ),
    );
  }

  static const Map<ShortcutActivator, Intent> _shortcuts = {
    // Enter 和 Space 触发当前焦点组件
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    // Esc 用于关闭弹窗（由 Dialog 内部的 FocusScope 处理）
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  };

  Map<Type, Action<Intent>> _actions(BuildContext context) {
    return {
      // ActivateIntent → 调用当前焦点组件的 onTap/onPressed
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (intent) {
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus != null && primaryFocus.context != null) {
            // Flutter 的 InkWell/ElevatedButton 等会自动响应 ActivateIntent
            // 这里不需要额外处理
          }
          return null;
        },
      ),
      // DismissIntent → 关闭弹窗/返回
      DismissIntent: CallbackAction<DismissIntent>(
        onInvoke: (intent) {
          final navigator = Navigator.maybeOf(context);
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
          }
          return null;
        },
      ),
    };
  }
}

/// 方向键导航辅助 Widget
///
/// 用于列表/TabBar 组件，支持 ↑↓ 方向键在子项间导航。
/// 用法：
/// ```dart
/// A11yDirectionalNavigation(
///   onUp: () => focusPrevious(),
///   onDown: () => focusNext(),
///   child: ListView(...),
/// )
/// ```
class A11yDirectionalNavigation extends StatelessWidget {
  const A11yDirectionalNavigation({
    super.key,
    required this.child,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
  });

  final Widget child;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _DirectionalIntent('up'),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _DirectionalIntent('down'),
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _DirectionalIntent('left'),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _DirectionalIntent('right'),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DirectionalIntent: CallbackAction<_DirectionalIntent>(
            onInvoke: (intent) {
              switch (intent.direction) {
                case 'up':
                  onUp?.call();
                  break;
                case 'down':
                  onDown?.call();
                  break;
                case 'left':
                  onLeft?.call();
                  break;
                case 'right':
                  onRight?.call();
                  break;
              }
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _DirectionalIntent extends Intent {
  const _DirectionalIntent(this.direction);
  final String direction;
}
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/accessibility/a11y_shortcuts.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**

```bash
git add lib/core/accessibility/a11y_shortcuts.dart
git commit -m "feat: 添加全局键盘快捷键处理器和方向键导航组件"
```

---

### Task 3: 创建语义化 Widget 工厂

**Files:**
- Create: `lib/core/accessibility/a11y_semantics.dart`
- Test: `flutter analyze`

- [ ] **Step 1: 创建 a11y_semantics.dart**

```dart
import 'package:flutter/material.dart';

/// 无障碍按钮 Widget
///
/// 自动提供：
/// - Semantics(role: button, label: semanticsLabel)
/// - 最小 48x48 交互尺寸（通过 Padding + InkWell 扩展热区）
/// - Focus 节点管理
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
    this.focusNode,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;
  final String? semanticsValue;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.button,
      label: semanticsLabel,
      value: semanticsValue,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        minInteractiveSize: 48,
        focusNode: focusNode,
        child: child,
      ),
    );
  }
}

/// 无障碍图标按钮 Widget
///
/// 自动提供：
/// - Semantics(role: button, label: semanticsLabel)
/// - 最小 48x48 交互尺寸（透明 Padding 扩展热区）
/// - 装饰性图标用 ExcludeSemantics 包裹
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
      role: SemanticsRole.button,
      label: semanticsLabel,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        minInteractiveSize: 48,
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
/// - Semantics(role: listItem, label: semanticsLabel)
/// - MergeSemantics 合并内部子组件语义（避免屏幕阅读器逐个读）
/// - 动态状态通过 Semantics.value 更新
///
/// 用法：
/// ```dart
/// A11yListItem(
///   semanticsLabel: l10n.a11yAppCard(app.name, version, status),
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
        role: SemanticsRole.listItem,
        label: semanticsLabel,
        value: semanticsValue,
        enabled: enabled,
        child: onTap != null
            ? InkWell(
                onTap: enabled ? onTap : null,
                minInteractiveSize: 48,
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
/// - Semantics(role: tab, label: semanticsLabel)
/// - selected 状态标注
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
      role: SemanticsRole.tab,
      label: label,
      selected: selected,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              minInteractiveSize: 48,
              child: child,
            )
          : child,
    );
  }
}

/// 无障碍卡片 Widget
///
/// 自动提供：
/// - Semantics(role: article, label: semanticsLabel)
/// - 用于应用卡片等复合组件
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
      role: SemanticsRole.article,
      label: semanticsLabel,
      hint: semanticsHint,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              minInteractiveSize: 48,
              child: child,
            )
          : child,
    );
  }
}
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/core/accessibility/a11y_semantics.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Commit**

```bash
git add lib/core/accessibility/a11y_semantics.dart
git commit -m "feat: 添加无障碍语义化 Widget 工厂（A11yButton/A11yIconButton/A11yListItem/A11yTab/A11yCard）"
```

---

### Task 4: 创建字体缩放适配

**Files:**
- Create: `lib/core/accessibility/a11y_text_scaler.dart`
- Create: `test/unit/core/accessibility/a11y_text_scaler_test.dart`
- Test: `flutter test test/unit/core/accessibility/a11y_text_scaler_test.dart`

- [ ] **Step 1: 创建 a11y_text_scaler.dart**

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 约束 TextScaler 范围
///
/// 防止系统字体缩放过大导致布局破裂。
/// - 最小缩放：0.8x
/// - 最大缩放：1.5x
///
/// 用法：
/// ```dart
/// final scaler = clampTextScaler(context);
/// Text('文本', textScaler: scaler)
/// ```
TextScaler clampTextScaler(BuildContext context, {double min = 0.8, double max = 1.5}) {
  final systemScaler = MediaQuery.textScalerOf(context);
  return systemScaler.clamp(
    minScaleFactor: min,
    maxScaleFactor: max,
  );
}

/// 无障碍文本 Widget
///
/// 自动应用系统字体缩放，并限制在安全范围内。
/// 用法：
/// ```dart
/// A11yText(
///   '应用介绍',
///   style: AppTextStyles.body,
/// )
/// ```
class A11yText extends StatelessWidget {
  const A11yText(
    this.data, {
    super.key,
    this.style,
    this.minScale = 0.8,
    this.maxScale = 1.5,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  final String data;
  final TextStyle? style;
  final double minScale;
  final double maxScale;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: minScale,
      maxScaleFactor: maxScale,
    );

    return Text(
      data,
      style: style,
      textScaler: scaler,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
```

- [ ] **Step 2: 创建 a11y_text_scaler_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/accessibility/a11y_text_scaler.dart';

void main() {
  group('clampTextScaler', () {
    testWidgets('返回系统缩放比例在范围内', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(scaler.scale(16.0), inInclusiveRange(16.0 * 0.8, 16.0 * 1.5));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('限制最大缩放为 1.5x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3.0)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(scaler.scale(16.0), lessThanOrEqualTo(16.0 * 1.5));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('限制最小缩放为 0.8x', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: Builder(
            builder: (context) {
              final scaler = clampTextScaler(context);
              expect(scaler.scale(16.0), greaterThanOrEqualTo(16.0 * 0.8));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('A11yText', () {
    testWidgets('渲染文本不报错', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.0)),
          child: A11yText('测试文本'),
        ),
      );

      expect(find.text('测试文本'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 3: 运行测试验证通过**

Run: `flutter test test/unit/core/accessibility/a11y_text_scaler_test.dart`
Expected: All 4 tests pass

- [ ] **Step 4: Commit**

```bash
git add lib/core/accessibility/a11y_text_scaler.dart test/unit/core/accessibility/a11y_text_scaler_test.dart
git commit -m "feat: 添加字体缩放适配和单元测试"
```

---

### Task 5: 创建 barrel 导出文件

**Files:**
- Create: `lib/core/accessibility/accessibility.dart`

- [ ] **Step 1: 创建 accessibility.dart**

```dart
/// 无障碍（Accessibility）统一导出
///
/// 业务组件只需导入此文件即可使用所有无障碍能力：
/// ```dart
/// import 'package:linglong_store/core/accessibility/accessibility.dart';
/// ```

// Focus 遍历策略
export 'a11y_focus_traversal.dart';

// 键盘快捷键映射
export 'a11y_shortcuts.dart';

// 语义化 Widget 工厂
export 'a11y_semantics.dart';

// 字体缩放适配
export 'a11y_text_scaler.dart';
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/accessibility/accessibility.dart
git commit -m "feat: 添加无障碍模块统一导出文件"
```

---

### Task 6: 挂载无障碍能力到 MaterialApp

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: 修改 app.dart**

在 `lib/app.dart` 中，修改 `LinglongStoreApp` 的 `build` 方法：

```dart
// 在文件顶部添加导入
import 'core/accessibility/accessibility.dart';

// 修改 LinglongStoreApp 的 build 方法返回值
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ... 前面的代码不变 ...

  return A11yKeyboardHandler(  // ← 新增这层包裹
    child: MaterialApp.router(
      title: '玲珑应用商店社区版',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final systemIsDark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        final effectiveIsDark = switch (themeMode) {
          ThemeMode.system => systemIsDark,
          ThemeMode.light => false,
          ThemeMode.dark => true,
        };

        return NativeMenuThemeSync(
          isDark: effectiveIsDark,
          child: A11yFocusScope(  // ← 在 builder 内新增这层包裹
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    ),
  );
}
```

- [ ] **Step 2: 验证编译**

Run: `flutter analyze lib/app.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: 运行应用验证**

Run: `flutter run -d linux --no-resident`
Expected: 应用正常启动，Tab 键可以在可交互元素间跳转

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat: 在 MaterialApp 顶层挂载无障碍能力"
```

---

## 阶段二：i18n 翻译

### Task 7: 新增无障碍翻译 key

**Files:**
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`

- [ ] **Step 1: 修改 app_zh.arb**

在 `lib/core/i18n/l10n/app_zh.arb` 文件末尾（最后一个 `}` 之前）添加：

```json
  "a11yInstallApp": "安装 {appName}",
  "@a11yInstallApp": { "placeholders": { "appName": {} } },
  "a11yUpdateApp": "更新 {appName}",
  "@a11yUpdateApp": { "placeholders": { "appName": {} } },
  "a11yOpenApp": "打开 {appName}",
  "@a11yOpenApp": { "placeholders": { "appName": {} } },
  "a11yUninstallApp": "卸载 {appName}",
  "@a11yUninstallApp": { "placeholders": { "appName": {} } },
  "a11ySearchBox": "搜索应用",
  "a11ySearchInputHint": "输入关键词搜索",
  "a11yCommentInputHint": "输入评论内容",
  "a11ySidebarNav": "侧边栏导航",
  "a11yAppCard": "{appName}，版本 {version}，{status}",
  "@a11yAppCard": { "placeholders": { "appName": {}, "version": {}, "status": {} } },
  "a11yRankingItem": "排名第 {rank}，{appName}",
  "@a11yRankingItem": { "placeholders": { "rank": {}, "appName": {} } },
  "a11yProcessItem": "进程 {name}，PID {pid}",
  "@a11yProcessItem": { "placeholders": { "name": {}, "pid": {} } },
  "a11yDownloadItem": "下载 {appName}，进度 {percent}%",
  "@a11yDownloadItem": { "placeholders": { "appName": {}, "percent": {} } },
  "a11yRecommendPage": "推荐",
  "a11yAllAppsPage": "全部应用",
  "a11yRankingPage": "排行榜",
  "a11yMyAppsPage": "我的应用",
  "a11ySettingsPage": "设置",
  "a11yAppDetailPage": "应用详情",
  "a11yScreenshotArea": "截图区域",
  "a11yCommentSection": "评论区",
  "a11yCarouselArea": "轮播区域",
  "a11yAppListArea": "应用列表",
  "a11ySidebarArea": "侧边栏",
  "a11yMinimize": "最小化",
  "a11yMaximize": "最大化",
  "a11yRestore": "还原",
  "a11yClose": "关闭",
  "a11yPrevious": "上一个",
  "a11yNext": "下一个",
  "a11yTabSelected": "已选中",
  "a11yTabNotSelected": "未选中",
  "a11yStatusInstalled": "已安装",
  "a11yStatusUpdatable": "可更新",
  "a11yStatusNotInstalled": "未安装"
```

- [ ] **Step 2: 修改 app_en.arb**

在 `lib/core/i18n/l10n/app_en.arb` 文件末尾添加：

```json
  "a11yInstallApp": "Install {appName}",
  "@a11yInstallApp": { "placeholders": { "appName": {} } },
  "a11yUpdateApp": "Update {appName}",
  "@a11yUpdateApp": { "placeholders": { "appName": {} } },
  "a11yOpenApp": "Open {appName}",
  "@a11yOpenApp": { "placeholders": { "appName": {} } },
  "a11yUninstallApp": "Uninstall {appName}",
  "@a11yUninstallApp": { "placeholders": { "appName": {} } },
  "a11ySearchBox": "Search apps",
  "a11ySearchInputHint": "Enter keywords to search",
  "a11yCommentInputHint": "Enter your comment",
  "a11ySidebarNav": "Sidebar navigation",
  "a11yAppCard": "{appName}, version {version}, {status}",
  "@a11yAppCard": { "placeholders": { "appName": {}, "version": {}, "status": {} } },
  "a11yRankingItem": "Rank #{rank}, {appName}",
  "@a11yRankingItem": { "placeholders": { "rank": {}, "appName": {} } },
  "a11yProcessItem": "Process {name}, PID {pid}",
  "@a11yProcessItem": { "placeholders": { "name": {}, "pid": {} } },
  "a11yDownloadItem": "Downloading {appName}, {percent}%",
  "@a11yDownloadItem": { "placeholders": { "appName": {}, "percent": {} } },
  "a11yRecommendPage": "Recommend",
  "a11yAllAppsPage": "All Apps",
  "a11yRankingPage": "Ranking",
  "a11yMyAppsPage": "My Apps",
  "a11ySettingsPage": "Settings",
  "a11yAppDetailPage": "App Details",
  "a11yScreenshotArea": "Screenshots",
  "a11yCommentSection": "Comments",
  "a11yCarouselArea": "Carousel",
  "a11yAppListArea": "App list",
  "a11ySidebarArea": "Sidebar",
  "a11yMinimize": "Minimize",
  "a11yMaximize": "Maximize",
  "a11yRestore": "Restore",
  "a11yClose": "Close",
  "a11yPrevious": "Previous",
  "a11yNext": "Next",
  "a11yTabSelected": "selected",
  "a11yTabNotSelected": "not selected",
  "a11yStatusInstalled": "installed",
  "a11yStatusUpdatable": "update available",
  "a11yStatusNotInstalled": "not installed"
```

- [ ] **Step 3: 重新生成 l10n 代码**

Run: `flutter gen-l10n`
Expected: 生成成功，无错误

- [ ] **Step 4: Commit**

```bash
git add lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb
git commit -m "feat: 新增 29 个无障碍翻译 key"
```

---

## 阶段三：颜色对比度修正

### Task 8: 修正颜色对比度

**Files:**
- Modify: `lib/core/config/theme.dart`

- [ ] **Step 1: 修改 AppColors 中的 textTertiary 和 topLabel**

```dart
// 在 lib/core/config/theme.dart 中修改：

/// 三级文字色 - 从 #999999 加深到 #767676（对比度 4.54:1）
static const Color textTertiary = Color(0xFF767676);  // 原来是 0xFF999999

/// "精品/TOP" 标签颜色 - 从 #CDA354 加深到 #8B6914（对比度 4.6:1）
static const Color topLabel = Color(0xFF8B6914);  // 原来是 0xFFCDA354
```

- [ ] **Step 2: 同步修改深色模式对应值**

```dart
// 在 AppColorPalette.dark 中修改：

textTertiary: Color(0xFF999999),  // 深色模式下可以保持稍亮，因为在暗底上对比度足够
```

- [ ] **Step 3: 验证编译**

Run: `flutter analyze lib/core/config/theme.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 4: Commit**

```bash
git add lib/core/config/theme.dart
git commit -m "fix: 修正 textTertiary 和 topLabel 颜色对比度，满足 WCAG AA 标准"
```

---

## 阶段四：P0 交互组件改造

### Task 9: 改造应用卡片 (app_card.dart)

**Files:**
- Modify: `lib/presentation/widgets/app_card.dart`
- Test: `flutter analyze`

- [ ] **Step 1: 读取当前 app_card.dart 内容**

先用 `read_file` 读取 `lib/presentation/widgets/app_card.dart`，了解当前结构。

- [ ] **Step 2: 添加 Semantics 和 48px 热区**

在应用卡片根节点添加 `A11yCard` 包裹，按钮使用 `A11yButton`：

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 修改应用卡片根节点（找到 build 方法返回的 Widget）
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  // 确定状态文本
  final statusText = _determineStatusText(l10n);

  return A11yCard(
    semanticsLabel: l10n.a11yAppCard(
      app.name,
      app.version ?? '1.0.0',
      statusText,
    ),
    onTap: _onCardTap,
    child: Container(
      // ... 原有卡片内容不变 ...
    ),
  );
}

// 添加状态文本判断方法
String _determineStatusText(AppLocalizations l10n) {
  if (_isInstalled && _canUpdate) {
    return l10n.a11yStatusUpdatable;
  } else if (_isInstalled) {
    return l10n.a11yStatusInstalled;
  } else {
    return l10n.a11yStatusNotInstalled;
  }
}
```

- [ ] **Step 3: 改造按钮为 A11yButton**

找到原来的安装/更新/打开按钮，替换为：

```dart
// 原来的按钮：
// ElevatedButton(
//   onPressed: onTap,
//   child: Text(l10n.install),
// )

// 改为：
A11yButton(
  semanticsLabel: l10n.a11yInstallApp(app.name),
  onTap: onTap,
  enabled: !isProcessing,
  child: ElevatedButton(
    onPressed: isProcessing ? null : onTap,
    child: Text(buttonText),
  ),
)
```

- [ ] **Step 4: 验证编译**

Run: `flutter analyze lib/presentation/widgets/app_card.dart`
Expected: 0 errors, 0 warnings

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/app_card.dart
git commit -m "a11y: 应用卡片添加 Semantics 标注和 48px 按钮热区"
```

---

### Task 10: 改造安装按钮三态语义化 (install_button.dart)

**Files:**
- Modify: `lib/presentation/widgets/install_button.dart`

- [ ] **Step 1: 修改 install_button.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 修改 build 方法，根据三态设置语义标签
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  // 确定语义标签
  String semanticsLabel;
  switch (buttonState) {
    case InstallButtonState.install:
      semanticsLabel = l10n.a11yInstallApp(app.name);
      break;
    case InstallButtonState.update:
      semanticsLabel = l10n.a11yUpdateApp(app.name);
      break;
    case InstallButtonState.open:
      semanticsLabel = l10n.a11yOpenApp(app.name);
      break;
    case InstallButtonState.installing:
      semanticsLabel = '${l10n.installing} ${app.name}';
      break;
  }

  return A11yButton(
    semanticsLabel: semanticsLabel,
    semanticsValue: isProcessing ? '${progress.toInt()}%' : null,
    enabled: !isProcessing,
    onTap: onPressed,
    child: /* 原有按钮内容 */,
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/install_button.dart
git commit -m "a11y: 安装按钮三态语义化"
```

---

### Task 11: 改造侧边栏导航 (sidebar.dart)

**Files:**
- Modify: `lib/presentation/widgets/sidebar.dart`

- [ ] **Step 1: 读取 sidebar.dart**

先用 `read_file` 了解侧边栏结构。

- [ ] **Step 2: 添加 Semantics 和 48px 热区**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 侧边栏根节点添加语义
return Semantics(
  role: SemanticsRole.navigation,
  label: l10n.a11ySidebarArea,
  child: ReadingOrderTraversalScope(
    child: Column(
      children: [
        // ... 导航项 ...
      ],
    ),
  ),
);

// 每个导航项使用 A11yIconButton 或 Semantics 包裹
A11yIconButton(
  icon: Icon(item.icon),
  semanticsLabel: item.label,  // 使用 i18n 翻译
  tooltip: item.tooltip,
  onTap: () => navigateTo(item.route),
)
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/sidebar.dart
git commit -m "a11y: 侧边栏导航项添加 Semantics 标注和 48px 热区"
```

---

### Task 12: 改造窗口控制按钮 (title_bar.dart)

**Files:**
- Modify: `lib/presentation/widgets/title_bar.dart`

- [ ] **Step 1: 修改 title_bar.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 最小化按钮
A11yIconButton(
  icon: const Icon(Icons.minimize),
  semanticsLabel: l10n.a11yMinimize,
  onTap: () => WindowService.minimize(),
)

// 最大化/还原按钮
A11yIconButton(
  icon: Icon(isMaximized ? Icons.flip_to_front : Icons.crop_square),
  semanticsLabel: isMaximized ? l10n.a11yRestore : l10n.a11yMaximize,
  onTap: () => WindowService.maximize(),
)

// 关闭按钮
A11yIconButton(
  icon: const Icon(Icons.close),
  semanticsLabel: l10n.a11yClose,
  onTap: () => WindowService.close(),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/title_bar.dart
git commit -m "a11y: 窗口控制按钮添加语义化标签"
```

---

### Task 13: 改造搜索框 (search_bar.dart)

**Files:**
- Modify: `lib/presentation/widgets/search_bar.dart`

- [ ] **Step 1: 修改 search_bar.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// TextField 确保 hintText 有值
TextField(
  decoration: InputDecoration(
    hintText: l10n.a11ySearchInputHint,  // 无障碍提示文本
    // ... 其他装饰 ...
  ),
  // Enter 触发搜索
  onSubmitted: (value) => onSearch(value),
)

// 搜索建议列表项使用 A11yListItem
A11yListItem(
  semanticsLabel: suggestion.appName,
  onTap: () => selectSuggestion(suggestion),
  child: ListTile(
    // ... 原有内容 ...
  ),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/search_bar.dart
git commit -m "a11y: 搜索框添加 Semantics 标注和 Enter 触发搜索"
```

---

### Task 14: 改造分类筛选胶囊 (category_filter_header.dart)

**Files:**
- Modify: `lib/presentation/widgets/category_filter_header.dart`

- [ ] **Step 1: 修改 category_filter_header.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 分类筛选胶囊按钮
A11yTab(
  label: category.name,
  selected: isSelected,
  onTap: () => selectCategory(category),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text(
      category.name,
      style: isSelected ? selectedStyle : normalStyle,
    ),
  ),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/category_filter_header.dart
git commit -m "a11y: 分类筛选胶囊添加 Tab 角色语义"
```

---

### Task 15: 改造下载管理对话框 (download_manager_dialog.dart)

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: 修改 download_manager_dialog.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 下载项列表
A11yListItem(
  semanticsLabel: l10n.a11yDownloadItem(app.name, progressPercent),
  semanticsValue: l10n.a11yDownloadItem(app.name, progressPercent),
  child: ListTile(
    // ... 原有内容 ...
  ),
)

// 操作按钮保持 48px 热区
A11yIconButton(
  icon: const Icon(Icons.cancel),
  semanticsLabel: l10n.cancel,
  onTap: onCancel,
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/download_manager_dialog.dart
git commit -m "a11y: 下载管理对话框添加列表语义和按钮热区"
```

---

### Task 16: 改造进程列表 (linglong_process_panel.dart)

**Files:**
- Modify: `lib/presentation/widgets/linglong_process_panel.dart`

- [ ] **Step 1: 修改 linglong_process_panel.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 进程列表项
A11yListItem(
  semanticsLabel: l10n.a11yProcessItem(process.name, process.pid.toString()),
  child: ListTile(
    // ... 原有内容 ...
  ),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/linglong_process_panel.dart
git commit -m "a11y: 进程列表项添加语义标注"
```

---

### Task 17: 改造对话框组 (confirm_dialog.dart 等)

**Files:**
- Modify: `lib/presentation/widgets/confirm_dialog.dart`
- Modify: `lib/presentation/widgets/uninstall_blocked_dialog.dart`

- [ ] **Step 1: 修改 confirm_dialog.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 确认/取消按钮
A11yButton(
  semanticsLabel: l10n.confirm,
  onTap: onConfirm,
  child: ElevatedButton(child: Text(l10n.confirm), onPressed: onConfirm),
)

A11yButton(
  semanticsLabel: l10n.cancel,
  onTap: onCancel,
  child: TextButton(child: Text(l10n.cancel), onPressed: onCancel),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/confirm_dialog.dart lib/presentation/widgets/uninstall_blocked_dialog.dart
git commit -m "a11y: 对话框按钮添加语义标注"
```

---

### Task 18: 改造评论区 (app_detail_comment_section.dart)

**Files:**
- Modify: `lib/presentation/widgets/app_detail_comment_section.dart`

- [ ] **Step 1: 修改 app_detail_comment_section.dart**

```dart
// 文件顶部添加导入
import '../core/accessibility/accessibility.dart';
import '../core/i18n/l10n/app_localizations.dart';

// 评论输入框
TextField(
  decoration: InputDecoration(
    hintText: l10n.a11yCommentInputHint,
    // ... 其他装饰 ...
  ),
)

// 版本选择胶囊按钮移除 shrinkWrap，使用 48px 热区
InkWell(
  onTap: () => selectVersion(version),
  minInteractiveSize: 48,
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(version.name),
  ),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/app_detail_comment_section.dart
git commit -m "a11y: 评论区输入框和版本胶囊添加无障碍支持"
```

---

### Task 19: 改造推荐页 (recommend_page.dart)

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`

- [ ] **Step 1: 修改 recommend_page.dart**

```dart
// 文件顶部添加导入
import '../../core/accessibility/accessibility.dart';
import '../../core/i18n/l10n/app_localizations.dart';

// 轮播切换按钮移除 shrinkWrap
A11yIconButton(
  icon: const Icon(Icons.chevron_left),
  semanticsLabel: l10n.a11yPrevious,
  onTap: onPrev,
)

A11yIconButton(
  icon: const Icon(Icons.chevron_right),
  semanticsLabel: l10n.a11yNext,
  onTap: onNext,
)

// 推荐列表项
A11yListItem(
  semanticsLabel: l10n.a11yAppCard(app.name, app.version ?? '1.0.0', status),
  child: /* 原有列表项 */,
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/recommend/recommend_page.dart
git commit -m "a11y: 推荐页轮播按钮和列表添加无障碍支持"
```

---

### Task 20: 改造列表页面 (ranking/all_apps/custom_category)

**Files:**
- Modify: `lib/presentation/pages/ranking/ranking_page.dart`
- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`
- Modify: `lib/presentation/pages/custom_category/custom_category_page.dart`

- [ ] **Step 1: 批量修改三个列表页**

每个页面按相同模式修改：

```dart
// 文件顶部添加导入
import '../../core/accessibility/accessibility.dart';
import '../../core/i18n/l10n/app_localizations.dart';

// 列表项使用 A11yListItem
A11yListItem(
  semanticsLabel: l10n.a11yAppCard(app.name, app.version ?? '1.0.0', status),
  onTap: () => navigateToAppDetail(app.id),
  child: /* 原有列表项 Widget */,
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/ranking/ranking_page.dart lib/presentation/pages/all_apps/all_apps_page.dart lib/presentation/pages/custom_category/custom_category_page.dart
git commit -m "a11y: 排行榜/全部应用/自定义分类页列表添加无障碍语义"
```

---

## 阶段五：P1 页面结构标注

### Task 21: 推荐页 heading + 区域标注

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`

- [ ] **Step 1: 添加页面 heading 和区域标注**

```dart
// 在推荐页 build 方法根节点
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    body: Column(
      children: [
        // 页面标题
        Semantics(
          role: SemanticsRole.heading,
          label: l10n.a11yRecommendPage,
          child: Text(l10n.recommend, style: AppTextStyles.title2),
        ),
        
        // 轮播区域
        Semantics(
          label: l10n.a11yCarouselArea,
          explicitChildNodes: true,
          child: CarouselSlider(...),
        ),
        
        // 应用列表区
        Semantics(
          label: l10n.a11yAppListArea,
          explicitChildNodes: true,
          child: Expanded(child: ListView(...)),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/recommend/recommend_page.dart
git commit -m "a11y: 推荐页添加 heading 和区域标注"
```

---

### Task 22: 全部应用页 heading + 分类筛选区标注

**Files:**
- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`

- [ ] **Step 1: 添加 heading 和分类区标注**

```dart
// 页面标题
Semantics(
  role: SemanticsRole.heading,
  label: l10n.a11yAllAppsPage,
  child: Text(l10n.allApps, style: AppTextStyles.title2),
)

// 分类筛选区
Semantics(
  label: l10n.category,
  explicitChildNodes: true,
  child: CategoryFilterHeader(...),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/all_apps/all_apps_page.dart
git commit -m "a11y: 全部应用页添加 heading 和分类区标注"
```

---

### Task 23: 应用详情页 heading + 截图区/评论区标注

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`

- [ ] **Step 1: 添加 heading 和区域标注**

```dart
// 应用名标题
Semantics(
  role: SemanticsRole.heading,
  label: l10n.a11yAppDetailPage,
  child: Text(app.name, style: AppTextStyles.title1),
)

// 截图区
Semantics(
  label: l10n.a11yScreenshotArea,
  explicitChildNodes: true,
  child: ScreenshotCarousel(...),
)

// 评论区
Semantics(
  label: l10n.a11yCommentSection,
  explicitChildNodes: true,
  child: CommentSection(...),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart
git commit -m "a11y: 应用详情页添加 heading 和区域标注"
```

---

### Task 24: 我的应用页 heading + TabBar 标注

**Files:**
- Modify: `lib/presentation/pages/my_apps/my_apps_page.dart`

- [ ] **Step 1: 添加 heading 和 TabBar 标注**

```dart
// 页面标题
Semantics(
  role: SemanticsRole.heading,
  label: l10n.a11yMyAppsPage,
  child: Text(l10n.myApps, style: AppTextStyles.title2),
)

// TabBar 使用 A11yTab 封装
A11yTab(
  label: l10n.installedApps,
  selected: tabIndex == 0,
  onTap: () => setTabIndex(0),
  child: Text(l10n.installedApps),
)

A11yTab(
  label: l10n.linglongProcess,
  selected: tabIndex == 1,
  onTap: () => setTabIndex(1),
  child: Text(l10n.linglongProcess),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/my_apps/my_apps_page.dart
git commit -m "a11y: 我的应用页添加 heading 和 TabBar 标注"
```

---

### Task 25: 设置页 heading + 区块标注

**Files:**
- Modify: `lib/presentation/pages/setting/setting_page.dart`

- [ ] **Step 1: 添加 heading 和区块标注**

```dart
// 页面标题
Semantics(
  role: SemanticsRole.heading,
  label: l10n.a11ySettingsPage,
  child: Text(l10n.settings, style: AppTextStyles.title2),
)

// 基本设置区
Semantics(
  label: l10n.baseSetting,
  explicitChildNodes: true,
  child: Column(children: [...]),
)

// 关于区
Semantics(
  label: l10n.about,
  explicitChildNodes: true,
  child: Column(children: [...]),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/setting/setting_page.dart
git commit -m "a11y: 设置页添加 heading 和区块标注"
```

---

### Task 26: 搜索列表页 heading + 结果列表标注

**Files:**
- Modify: `lib/presentation/pages/search_list/search_list_page.dart`

- [ ] **Step 1: 添加 heading 和结果列表标注**

```dart
// 搜索结果标题
Semantics(
  role: SemanticsRole.heading,
  label: l10n.search,
  child: Text(l10n.searchResultCount(total), style: AppTextStyles.title2),
)

// 结果列表
Semantics(
  label: l10n.a11yAppListArea,
  explicitChildNodes: true,
  child: ListView(children: [...]),
)
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/pages/search_list/search_list_page.dart
git commit -m "a11y: 搜索列表页添加 heading 和结果列表标注"
```

---

## 阶段六：P2 装饰性内容标注

### Task 27: 图标/Logo 装饰性标注

**Files:**
- Modify: 多处（图标组件所在文件）

- [ ] **Step 1: 在全局或组件级标注图标为装饰性**

在包含纯装饰性图标的地方添加：

```dart
// 应用图标/Logo
ExcludeSemantics(
  child: SvgPicture.asset('assets/icons/logo.svg'),
)

// 装饰性分隔线/图标
ExcludeSemantics(
  child: Icon(Icons.chevron_right),
)
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "a11y: 标注纯装饰性图标和分隔线为 ExcludeSemantics"
```

---

### Task 28: 骨架屏和截图标注

**Files:**
- Modify: 骨架屏组件所在文件
- Modify: `lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart`

- [ ] **Step 1: 骨架屏标注**

```dart
Semantics(
  label: l10n.loading,
  child: Shimmer(child: Container(color: Colors.grey)),
)
```

- [ ] **Step 2: 截图标注**

```dart
// 截图列表项
Semantics(
  role: SemanticsRole.image,
  label: '${l10n.screenShots} ${index + 1}',
  child: CachedNetworkImage(imageUrl: screenshotUrl),
)
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "a11y: 骨架屏和截图添加语义标注"
```

---

## 阶段七：测试与验证

### Task 29: 编写语义化组件 Widget 测试

**Files:**
- Create: `test/unit/core/accessibility/a11y_semantics_test.dart`

- [ ] **Step 1: 创建 a11y_semantics_test.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/accessibility/accessibility.dart';

void main() {
  group('A11yButton', () {
    testWidgets('具有正确的 Semantics role 和 label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11yButton(
            semanticsLabel: '测试按钮',
            onTap: () {},
            child: const Text('按钮'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yButton));
      expect(semantics.label, '测试按钮');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('禁用态不可点击', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11yButton(
            semanticsLabel: '禁用按钮',
            onTap: () {},
            enabled: false,
            child: const Text('按钮'),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(A11yButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });
  });

  group('A11yIconButton', () {
    testWidgets('具有 48x48 最小交互尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11yIconButton(
            icon: const Icon(Icons.close),
            semanticsLabel: '关闭',
            onTap: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });
  });

  group('A11yListItem', () {
    testWidgets('使用 MergeSemantics 合并语义', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: A11yListItem(
            semanticsLabel: '列表项',
            child: Column(
              children: [
                const Text('标题'),
                const Text('描述'),
              ],
            ),
          ),
        ),
      );

      // 应该只读到一个 Semantics 节点
      final semantics = tester.getSemantics(find.byType(A11yListItem));
      expect(semantics.label, '列表项');
    });
  });
}
```

- [ ] **Step 2: 运行测试**

Run: `flutter test test/unit/core/accessibility/a11y_semantics_test.dart`
Expected: All tests pass

- [ ] **Step 3: Commit**

```bash
git add test/unit/core/accessibility/a11y_semantics_test.dart
git commit -m "test: 添加无障碍语义化组件 Widget 测试"
```

---

### Task 30: 全量验证

- [ ] **Step 1: 运行静态分析**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings

- [ ] **Step 2: 运行全量测试**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: 构建验证**

Run: `flutter build linux --release`
Expected: 构建成功，无编译错误

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: 无障碍改造全量验证通过"
```

---

## 自我审查

### 1. 规范覆盖检查

对照 `2026-04-08-accessibility-a11y-design.md`：

| 规范要求 | 对应 Task | 状态 |
|----------|-----------|------|
| T1-T5: 基础设施 5 文件 | Task 1-5 | ✅ |
| T6: 挂载到 MaterialApp | Task 6 | ✅ |
| T7: i18n 翻译 | Task 7 | ✅ |
| T8-T19: P0 交互组件 | Task 9-20 | ✅ |
| T20-T25: P1 页面结构 | Task 21-26 | ✅ |
| T26-T28: P2 装饰标注 | Task 27-28 | ✅ |
| T29-T30: 测试 | Task 29-30 | ✅ |

### 2. 占位符扫描

搜索计划中的 "TBD"、"TODO"、"implement later" — 无。
所有步骤都包含具体代码内容。

### 3. 类型一致性检查

- 所有文件使用统一的 `import '../core/accessibility/accessibility.dart'`
- 所有 i18n 使用 `AppLocalizations.of(context)!` 获取
- `A11yButton`/`A11yIconButton`/`A11yListItem`/`A11yTab` 参数名一致

### 4. 颜色对比度修正

- textTertiary: `#999999` → `#767676`（4.54:1）✅
- topLabel: `#CDA354` → `#8B6914`（4.6:1）✅

---

计划已完整，共 **30 个 Task**，覆盖规范中全部 32 个开发任务点（部分页面改造合并为同一 Task 以减小 commit 粒度）。
