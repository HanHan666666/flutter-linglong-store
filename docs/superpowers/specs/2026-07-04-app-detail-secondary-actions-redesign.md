# 应用详情页次级操作区重设计

> 文档版本: 1.0 | 创建日期: 2026-07-04

## 背景

当前 `AppDetailHeroHeader` 的次级操作区使用三个并排的 48px 高 OutlinedButton：

- 「创建桌面快捷方式」
- 「卸载」（红色描边）
- 「分享」（图标按钮）

视觉上存在以下问题：

1. 三个按钮视觉重量相近，缺乏主次层次。
2. 卸载作为危险操作，红色描边在头部过于抢眼。
3. 分享按钮孤立，未与左侧两个文字按钮形成统一面板。

## 目标

- 降低次级操作区视觉噪音，让主按钮（安装/更新/打开）更突出。
- 保持已安装态下「创建桌面快捷方式」「卸载」「分享」三个入口的可达性。
- 增加精致的悬浮展开动效，提升桌面端品质感。

## 设计方案

### 整体布局

```
┌─────────────────────────────────────────────────────────────┐
│ [icon]  应用名                                    [主按钮]   │
│         描述                                      ┌────────┐│
│         版本 · 仓库 · 架构                        │ 图标组 ││
│                                                   └────────┘│
└─────────────────────────────────────────────────────────────┘
```

- 主按钮保持 `InstallButton(size: ButtonSize.hero)`，独立展示。
- 次级操作区改为三个圆形图标按钮横向排列。
- 三个图标按钮默认只显示图标，鼠标悬浮时单个按钮向右平滑展开为圆角胶囊，显示图标 + 文字。

### 图标语义

| 功能 | 默认图标 | 展开后文字 |
|------|---------|-----------|
| 创建桌面快捷方式 | `Icons.shortcut_outlined` | `l10n.createDesktopShortcut` |
| 卸载 | `Icons.delete_outline_rounded` | `l10n.uninstall` |
| 分享 | `Icons.share_outlined` | `l10n.shareLink` |

### 展开行为

- **触发范围**：单个按钮的 `MouseRegion`。
- **展开方向**：向右展开（图标在左，文字从右侧淡入）。
- **动画参数**：
  - 时长：`200ms`
  - 曲线：`Curves.easeInOut`
  - 宽度：从 `40px` 过渡到 `auto`（由内容决定）
  - 文字透明度：从 `0.0` 到 `1.0`，使用 `AnimatedOpacity`
- **其他按钮**：保持原位不动，不被推开。
- **无障碍**：展开后 `Semantics` 标签需包含完整功能说明；未展开时也要提供 `tooltip` 和 `label`。

### 视觉样式

- 默认态：
  - 尺寸：`40×40px` 圆形
  - 背景：`Colors.transparent` 或 `surfaceContainerLowest`（跟随主题）
  - 边框：`1px solid outlineVariant`
  - 图标色：`onSurfaceVariant`
  - 卸载图标色：保持 `error`，但不再使用红色边框和背景
- 悬浮态：
  - 高度保持 `40px`
  - 水平内边距：`12px`
  - 圆角：`StadiumBorder` / `BorderRadius.circular(20)`
  - 背景：`primaryContainer.withOpacity(0.5)` 或 `surfaceContainerHighest`
  - 文字样式：`bodyMedium`，字重 `w500`
  - 卸载文字色：保持 `error`

### 响应式

- 宽屏：次级操作区与主按钮右对齐，位于主按钮下方。
- 窄屏：主按钮与次级操作区整体换行，次级操作区左对齐。
- 展开后的按钮宽度不应导致操作区溢出；若空间不足，优先保证主按钮完整显示。

## 组件拆分

### 新增：`ExpandableIconButton`

位置：`lib/presentation/widgets/expandable_icon_button.dart`

职责：封装单个「图标 → 图标+文字」的展开按钮。

```dart
class ExpandableIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? foregroundColor;
  final String? semanticsLabel;
}
```

### 改造：`AppDetailSecondaryActions`

位置：`lib/presentation/widgets/app_detail_secondary_actions.dart`

职责：

- 只在 `isVisible == true` 时渲染。
- 使用 `Row` 包裹三个 `ExpandableIconButton`。
- 保持现有的 `onCreateShortcut`、`onUninstall` 回调不变。
- 将分享按钮从 `AppDetailHeroHeader` 移入本组件，统一由本组件管理三个次级操作。

### 改造：`AppDetailHeroHeader`

位置：`lib/presentation/widgets/app_detail_hero_header.dart`

变更：

- 移除独立的 `_buildShareButton`。
- `_buildActionPanel` 中主按钮下方只放置 `AppDetailSecondaryActions`。
- 将 `onShare` 回调透传给 `AppDetailSecondaryActions`。

## 数据流与回调

- 不引入新的 Provider 或 Repository 调用。
- 复用现有回调：`onCreateShortcut`、`onUninstall`、`onShare`。
- 展开状态为组件局部 `StatefulWidget` 状态，不提升。

## 无障碍

- 每个按钮必须包裹 `Semantics(button: true, label: ...)`。
- 图标使用 `ExcludeSemantics` 包裹。
- 提供 `Tooltip` 显示完整功能名称。
- 键盘聚焦时（非鼠标悬浮）也显示文字标签，确保屏幕阅读器和键盘用户可识别。

## 测试策略

- 单元/Widget 测试覆盖：
  - 默认态只渲染图标，不渲染文字。
  - 悬浮后渲染文字。
  - 点击触发对应回调。
  - 卸载按钮使用错误色图标。
  - 无障碍语义标签正确。

## 影响范围

| 文件 | 变更类型 |
|------|---------|
| `lib/presentation/widgets/expandable_icon_button.dart` | 新增 |
| `lib/presentation/widgets/app_detail_secondary_actions.dart` | 修改 |
| `lib/presentation/widgets/app_detail_hero_header.dart` | 修改 |
| `test/widget/...` | 新增/修改测试 |

## 不做的范围

- 不改变主按钮 `InstallButton` 的样式和行为。
- 不改变安装/更新状态条。
- 不改变卸载确认弹窗和拦截逻辑。
- 不新增动画包依赖，使用 Flutter 内置 `AnimatedContainer` + `AnimatedOpacity`。
