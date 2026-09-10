# 无障碍与屏幕阅读器开发指南

> 本文件是 `AGENTS.md`「无障碍与屏幕阅读器（Accessibility）」章节的完整版：核心模块清单、开发约定细则（含示例代码）与测试要求。
> 日常开发只需遵守 AGENTS.md 中的硬性约定清单；需要具体写法与测试细节时查阅本文件。

本项目已建立完整的无障碍支持体系，位于 `lib/core/accessibility/`。**所有页面和组件开发必须遵循以下约定。**

## 核心模块

| 模块 | 文件 | 职责 |
|------|------|------|
| `A11yButton` | `a11y_semantics.dart` | 无障碍按钮，自动提供 `Semantics(button: true)` + 最小 48×48 交互尺寸 |
| `A11yIconButton` | `a11y_semantics.dart` | 无障碍图标按钮，内部图标用 `ExcludeSemantics` 包裹 |
| `A11yListItem` | `a11y_semantics.dart` | 无障碍列表项，使用 `MergeSemantics` 合并内部子组件语义 |
| `A11yTab` | `a11y_semantics.dart` | 无障碍 Tab，支持 `selected` 状态标注 + 48px 高度 |
| `A11yCard` | `a11y_semantics.dart` | 无障碍卡片，支持 `label` 和 `hint` 语义 |
| `A11yFocusScope` | `a11y_focus_traversal.dart` | 焦点范围隔离，防止焦点泄漏到背景层 |
| `ReadingOrderTraversalPolicy` | `a11y_focus_traversal.dart` | Tab 遍历策略：从上到下、从左到右 |
| `A11yKeyboardHandler` | `a11y_shortcuts.dart` | 全局键盘快捷键（Enter/Space 激活、Escape 关闭） |
| `A11yDirectionalNavigation` | `a11y_shortcuts.dart` | 方向键导航 wrapper，用于列表/TabBar 等 |
| `A11yText` / `clampTextScaler` | `a11y_text_scaler.dart` | 无障碍文本，字体缩放限制在 0.8x ~ 1.5x 安全范围 |

## 开发约定

### 1. 装饰性图标必须排除语义

所有纯装饰性图标（默认图标、错误图标、加载图标等）必须用 `ExcludeSemantics` 包裹，避免屏幕阅读器朗读无意义内容：

```dart
// ✅ 正确
ExcludeSemantics(
  child: Icon(Icons.apps, size: size * 0.5),
)

// ❌ 错误：屏幕阅读器会朗读 "apps icon"
Icon(Icons.apps, size: size * 0.5),
```

### 2. 骨架屏/加载状态必须标注

骨架屏和加载 shimmer 必须使用 `Semantics(label: l10n.loading)` 包裹，让屏幕阅读器知道当前处于加载状态：

```dart
Semantics(
  label: l10n.loading,
  child: Shimmer.fromColors(...),
)
```

### 3. 列表/网格区域必须标注

列表和网格容器必须使用 `Semantics` 标注区域用途，使用 `l10n.a11yAppListArea` 等语义标签：

```dart
Semantics(
  label: l10n.a11yAppListArea,
  child: CustomScrollView(...),
)
```

### 4. 错误信息必须支持复制和无障碍

错误信息展示时必须：

- 使用 `Tooltip` 悬浮显示完整内容
- 提供蓝色「复制」按钮（`TextButton`），支持 Tab 聚焦和 Enter/Space 激活
- 使用 `Semantics` 标注按钮用途，屏幕阅读器可正确识别

### 5. 按钮/卡片/列表项使用无障碍组件

新建可交互组件时，优先使用 `A11yButton`、`A11yIconButton`、`A11yListItem`、`A11yTab`、`A11yCard` 等封装，不要手写缺失 `Semantics` 的交互控件。

### 6. 焦点隔离

页面级或弹窗级组件必须使用 `A11yFocusScope` 包裹，防止焦点泄漏到背景层。KeepAlive 页面隐藏时必须使用 `ExcludeFocus` 移出焦点树（见 `KeepAlivePageWrapper` 约定）。

### 7. 字体缩放

文本组件不要硬编码 `textScaler`，使用系统默认缩放。如需自定义上限，使用 `clampTextScaler(context, max: 1.5)` 限制在安全范围。

### 8. 多语言无障碍标签

所有 `Semantics.label` 必须使用 `l10n` 国际化，不要硬编码中文/英文字符串。`l10n` 文件位于 `lib/core/i18n/l10n/`，以 `a11y` 前缀命名（如 `a11yInstallApp`、`a11yAppListArea`、`a11yClose`）。

## 测试要求

无障碍组件必须通过 Widget 测试，覆盖：

- **语义标志**：`Semantics.label` / `Semantics.value` / `Semantics.hint` 正确
- **语义类型**：`SemanticsFlag.isButton`、`SemanticsFlag.isSelected`、`SemanticsFlag.hasEnabledState`/`isEnabled` 正确
- **交互尺寸**：按钮/Tab 最小 48×48 或 48px 高度
- **交互行为**：`enabled: false` 时不可点击，`onTap` 回调正确触发
- **合并语义**：`MergeSemantics` 内部子节点被正确合并

测试文件位于 `test/unit/core/accessibility/a11y_semantics_test.dart`。
