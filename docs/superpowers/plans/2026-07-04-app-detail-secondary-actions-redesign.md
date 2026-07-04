# 应用详情页次级操作区重设计实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将应用详情页头部次级操作区改为三个圆形图标按钮，默认只显示图标，鼠标悬浮时单个按钮向右展开为圆角胶囊并显示文字。

**Architecture:** 新增可复用的 `ExpandableIconButton` 组件负责单个按钮的展开动画；改造 `AppDetailSecondaryActions` 统一排列三个次级操作；改造 `AppDetailHeroHeader` 移除独立分享按钮，将分享回调透传给次级操作区。

**Tech Stack:** Flutter, Material 3, Riverpod（仅用于页面层状态透传，本改动不新增 Provider）

---

## 文件结构

| 文件 | 职责 | 变更 |
|------|------|------|
| `lib/presentation/widgets/expandable_icon_button.dart` | 单个图标展开按钮：默认圆形图标，悬浮向右展开显示文字 | 新增 |
| `lib/presentation/widgets/app_detail_secondary_actions.dart` | 详情页次级操作区：排列三个 `ExpandableIconButton` | 修改 |
| `lib/presentation/widgets/app_detail_hero_header.dart` | 头部操作面板：移除独立分享按钮，透传 `onShare` | 修改 |
| `test/widget/widgets/expandable_icon_button_test.dart` | `ExpandableIconButton` 的默认态、悬浮态、点击、无障碍测试 | 新增 |
| `test/widget/widgets/app_detail_secondary_actions_test.dart` | 次级操作区可见性、三个按钮渲染、回调测试 | 新增/修改 |

---

## Task 1: 创建 `ExpandableIconButton` 组件

**Files:**
- Create: `lib/presentation/widgets/expandable_icon_button.dart`

**实现要点：**

- 使用 `StatefulWidget`，局部状态管理 `_isHovered`。
- 默认态：宽高 `40×40`，圆形，透明背景或 `surfaceContainerLowest`，`outlineVariant` 边框。
- 悬浮态：高度保持 `40`，水平内边距 `12`，圆角 `StadiumBorder`，背景使用 `primaryContainer.withOpacity(0.5)` 或 `surfaceContainerHighest`。
- 动画：
  - 宽度：使用 `AnimatedContainer`，时长 `200ms`，曲线 `Curves.easeInOut`。
  - 文字：使用 `AnimatedOpacity`，时长 `150ms`，延迟 `50ms`（避免容器还没展开就显示文字）。
- 图标始终显示在左侧；文字从右侧淡入。
- 使用 `MouseRegion` 触发悬浮。
- 键盘聚焦时也要展开文字（通过 `Focus` + `WidgetState` 或手动处理 `onFocusChange`）。
- 无障碍：`Semantics(button: true, label: label)`，图标 `ExcludeSemantics`，外层 `Tooltip`。

**参考代码结构：**

```dart
import 'package:flutter/material.dart';

import '../../core/accessibility/a11y_semantics.dart';

/// 可展开图标按钮。
///
/// 默认只显示圆形图标按钮，鼠标悬浮或键盘聚焦时向右平滑展开为圆角胶囊，
/// 显示图标 + 文字标签。用于桌面端空间受限但需要明确语义的操作区。
class ExpandableIconButton extends StatefulWidget {
  const ExpandableIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.foregroundColor,
    this.semanticsLabel,
    super.key,
  });

  /// 按钮图标。
  final IconData icon;

  /// 展开后显示的文字标签。
  final String label;

  /// 点击回调。
  final VoidCallback onTap;

  /// 图标颜色，为空时使用主题 onSurfaceVariant。
  final Color? iconColor;

  /// 文字颜色，为空时使用主题 onSurface。
  final Color? foregroundColor;

  /// 无障碍语义标签，为空时使用 [label]。
  final String? semanticsLabel;

  @override
  State<ExpandableIconButton> createState() => _ExpandableIconButtonState();
}

class _ExpandableIconButtonState extends State<ExpandableIconButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = widget.iconColor ?? theme.colorScheme.onSurfaceVariant;
    final effectiveForegroundColor = widget.foregroundColor ?? theme.colorScheme.onSurface;
    final label = widget.label;

    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isExpanded = true),
          onExit: (_) => setState(() => _isExpanded = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 40,
            padding: _isExpanded
                ? const EdgeInsets.symmetric(horizontal: 12)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: _isExpanded
                  ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                  : theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: ExcludeSemantics(
                        child: Icon(
                          widget.icon,
                          size: 20,
                          color: effectiveIconColor,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _isExpanded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: effectiveForegroundColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 1: 创建 `ExpandableIconButton` 组件**
- [ ] **Step 2: 运行 `flutter analyze` 检查新增文件无错误**

---

## Task 2: 改造 `AppDetailSecondaryActions`

**Files:**
- Modify: `lib/presentation/widgets/app_detail_secondary_actions.dart`

**实现要点：**

- 新增 `onShare` 参数。
- 移除现有的 `OutlinedButton.icon` 实现。
- 使用 `Row` 包裹三个 `ExpandableIconButton`：
  - 创建桌面快捷方式：`Icons.shortcut_outlined`
  - 卸载：`Icons.delete_outline_rounded`，`iconColor: theme.colorScheme.error`
  - 分享：`Icons.share_outlined`
- 保持 `isVisible` 控制整体显隐。
- 保持 `buttonHeight = 48` 不再使用，改为 `ExpandableIconButton` 内部固定 `40`。
- 三个按钮之间间距 `8`。

**参考代码结构：**

```dart
import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import 'expandable_icon_button.dart';

/// 详情页主操作右侧的次级操作区。
///
/// 只在当前应用存在本地安装实例时展示，避免未安装态暴露无效入口。
/// 默认以圆形图标按钮排列，悬浮时单个按钮展开显示文字。
class AppDetailSecondaryActions extends StatelessWidget {
  const AppDetailSecondaryActions({
    required this.isVisible,
    required this.onCreateShortcut,
    required this.onUninstall,
    required this.onShare,
    super.key,
  });

  /// 是否展示次级操作区。
  final bool isVisible;

  /// 创建桌面快捷方式回调。
  final VoidCallback onCreateShortcut;

  /// 卸载回调。
  final VoidCallback onUninstall;

  /// 分享回调。
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpandableIconButton(
          icon: Icons.shortcut_outlined,
          label: l10n.createDesktopShortcut,
          onTap: onCreateShortcut,
        ),
        const SizedBox(width: 8),
        ExpandableIconButton(
          icon: Icons.delete_outline_rounded,
          label: l10n.uninstall,
          onTap: onUninstall,
          iconColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.error,
        ),
        const SizedBox(width: 8),
        ExpandableIconButton(
          icon: Icons.share_outlined,
          label: l10n.shareLink,
          onTap: onShare,
        ),
      ],
    );
  }
}
```

- [ ] **Step 1: 修改 `AppDetailSecondaryActions` 使用 `ExpandableIconButton`**
- [ ] **Step 2: 运行 `flutter analyze` 检查无错误**

---

## Task 3: 改造 `AppDetailHeroHeader`

**Files:**
- Modify: `lib/presentation/widgets/app_detail_hero_header.dart`

**实现要点：**

- 在构造函数中新增 `required this.onShare`（如果之前没有的话，检查当前代码发现已有 `onShare`，直接使用）。
- 移除 `_buildShareButton` 方法。
- 修改 `_buildActionPanel`：
  - 主按钮下方只放 `AppDetailSecondaryActions`。
  - 将 `onShare` 透传给 `AppDetailSecondaryActions`。
- 保持 `Wrap` 布局以支持窄屏换行。

**需要修改的代码段：**

```dart
Wrap(
  alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: 8,
  runSpacing: 8,
  children: [
    AppDetailSecondaryActions(
      isVisible: showInstalledActions,
      onCreateShortcut: onCreateShortcut,
      onUninstall: onUninstall,
      onShare: onShare,
    ),
  ],
),
```

- [ ] **Step 1: 移除 `_buildShareButton` 并改造 `_buildActionPanel`**
- [ ] **Step 2: 运行 `flutter analyze` 检查无错误**

---

## Task 4: 更新 `AppDetailPage` 调用

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`

**实现要点：**

- 检查 `AppDetailHeroHeader` 的调用是否已传入 `onShare`。
- 当前代码已传入 `onShare: () => _shareApp(context, app)`，无需修改。
- 确认 `AppDetailSecondaryActions` 的新增 `onShare` 参数不会导致编译错误。

- [ ] **Step 1: 检查并确认 `AppDetailPage` 调用正确**
- [ ] **Step 2: 运行 `flutter analyze` 检查无错误**

---

## Task 5: 编写 Widget 测试

**Files:**
- Create: `test/widget/widgets/expandable_icon_button_test.dart`
- Create/Modify: `test/widget/widgets/app_detail_secondary_actions_test.dart`

### 5.1 `ExpandableIconButton` 测试

**测试点：**

- 默认态只渲染图标，不渲染文字。
- 悬浮后渲染文字。
- 点击触发 `onTap`。
- 自定义图标颜色生效。
- 无障碍语义标签正确。

**参考测试代码：**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_linglong_store/presentation/widgets/expandable_icon_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpandableIconButton', () {
    testWidgets('默认态只显示图标，不显示文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share,
              label: '分享',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.text('分享'), findsNothing);
    });

    testWidgets('悬浮后显示文字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share,
              label: '分享',
              onTap: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(ExpandableIconButton)));
      await tester.pumpAndSettle();

      expect(find.text('分享'), findsOneWidget);
    });

    testWidgets('点击触发 onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpandableIconButton(
              icon: Icons.share,
              label: '分享',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ExpandableIconButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
```

### 5.2 `AppDetailSecondaryActions` 测试

**测试点：**

- `isVisible == false` 时不渲染任何按钮。
- `isVisible == true` 时渲染三个 `ExpandableIconButton`。
- 三个按钮分别触发对应回调。
- 卸载按钮使用错误色图标。

- [ ] **Step 1: 编写 `ExpandableIconButton` 测试**
- [ ] **Step 2: 编写/更新 `AppDetailSecondaryActions` 测试**
- [ ] **Step 3: 运行 `flutter test test/widget/widgets/expandable_icon_button_test.dart test/widget/widgets/app_detail_secondary_actions_test.dart`**

---

## Task 6: 集成验证

**Files:**
- All modified files

- [ ] **Step 1: 运行 `flutter analyze` 全项目检查，确保 0 error / 0 warning**
- [ ] **Step 2: 运行 `flutter test test/widget/widgets/expandable_icon_button_test.dart test/widget/widgets/app_detail_secondary_actions_test.dart`**
- [ ] **Step 3: 在 Linux 桌面运行 `flutter run -d linux`，进入应用详情页验证悬浮展开效果**
- [ ] **Step 4: 提交代码**

```bash
git add lib/presentation/widgets/expandable_icon_button.dart \
        lib/presentation/widgets/app_detail_secondary_actions.dart \
        lib/presentation/widgets/app_detail_hero_header.dart \
        test/widget/widgets/expandable_icon_button_test.dart \
        test/widget/widgets/app_detail_secondary_actions_test.dart \
        docs/superpowers/specs/2026-07-04-app-detail-secondary-actions-redesign.md \
        docs/superpowers/plans/2026-07-04-app-detail-secondary-actions-redesign.md
git commit -m "feat: 应用详情页次级操作区改为悬浮展开图标按钮"
```

---

## 自我审查

### Spec 覆盖检查

| Spec 要求 | 对应 Task |
|-----------|----------|
| 三个圆形图标按钮默认只显示图标 | Task 1, Task 2 |
| 单个按钮向右展开显示文字 | Task 1 |
| 动画时长 200ms，曲线 easeInOut | Task 1 |
| 其他按钮不被推开 | Task 1（Row + 单个按钮独立展开） |
| 无障碍语义、Tooltip | Task 1 |
| 卸载按钮使用错误色图标 | Task 2 |
| 分享按钮移入次级操作区 | Task 2, Task 3 |
| 响应式布局 | Task 3（保留 Wrap） |
| Widget 测试 | Task 5 |

### Placeholder 扫描

- 无 TBD/TODO。
- 所有代码片段完整。
- 所有文件路径明确。

### 类型一致性

- `ExpandableIconButton` 参数名与 `AppDetailSecondaryActions` 中调用一致。
- `onShare` 回调类型为 `VoidCallback`，与现有 `AppDetailHeroHeader` 一致。
