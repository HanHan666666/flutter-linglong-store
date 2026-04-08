# 无障碍（Accessibility / A11y）设计规范

> 创建日期：2026-04-08
> 状态：待实施
> 目标：支持屏幕阅读器用户、键盘导航用户、大字显示用户的完整使用体验

---

## 1. 背景与动机

当前项目在无障碍设计方面存在以下问题：

| 问题 | 严重程度 | 影响范围 |
|------|----------|----------|
| 完全没有 `Semantics` 标注 | 🔴 P0 | 全部页面，屏幕阅读器无法识别 |
| 键盘导航支持极弱（仅截图预览有 KeyboardListener） | 🔴 P0 | 桌面端核心体验，Tab/Enter 无法操作 |
| 点击目标尺寸过小（4 处 `shrinkWrap`） | 🟠 P1 | 按钮/卡片，不满足 48x48 最小交互标准 |
| 字体缩放未适配 | 🟠 P1 | 所有文字，系统字体放大时可能布局破裂 |
| 部分颜色对比度不足（textTertiary `#999999` on 白底 ≈ 2.85:1） | 🟡 P2 | 标签/次要文字 |
| Web 语义树未启用 | 🟡 P2 | Web 端（如构建） |

### 目标用户群体
- 依赖屏幕阅读器（如 Linux `orca`）的视障用户
- 习惯键盘操作的桌面端用户（Tab 跳转 + Enter 触发）
- 需要大字体显示的老年/低视力用户

---

## 2. 方案选型

### 2.1 键盘导航方案

选择 **标准桌面端键盘导航**：
- **Tab / Shift+Tab** — 焦点在可交互元素间按阅读顺序（上→下、左→右）移动
- **Enter / Space** — 触发当前焦点组件
- **↑ / ↓ 方向键** — 列表项、TabBar 间导航
- **← / → 方向键** — 轮播、截图预览翻页
- **Esc** — 关闭弹窗 / 返回上一页

### 2.2 整体改造策略

选择 **方案一：全局统一基础设施 + 逐页面改造**

理由：
- 项目架构清晰（Presentation → Application → Domain → Data），无障碍作为平台级能力应在 Core 层统一提供
- 复用性高，后续新页面自动继承无障碍能力
- 符合 AGENTS.md 中"统一入口"、"复用现有 hooks/store"约定

### 2.3 点击区域改造策略

选择 **方案 B：保留视觉紧凑感，透明扩展热区到 48x48**

```dart
// 用 Padding + InkWell 扩展热区，视觉元素保持原大小
Padding(
  padding: const EdgeInsets.all(8.0),  // 透明扩展区域
  child: InkWell(
    onTap: onTap,
    minInteractiveSize: 48,            // 保证 48x48 点击区域
    child: SizedBox(
      width: 32,  height: 32,          // 视觉尺寸保持不变
      child: child,
    ),
  ),
)
```

### 2.4 i18n 策略

所有 `Semantics(label: ...)` 文本必须通过 `AppLocalizations` 获取，不能硬编码中文。

在 `app_localizations_zh.arb` / `app_localizations_en.arb` 中新增 `a11y*` 前缀 key，业务侧使用 `l10n.a11yInstallApp(app.name)` 调用。

---

## 3. 基础设施架构

### 3.1 文件结构

```
lib/core/accessibility/
├── a11y_focus_traversal.dart    # 全局 Focus 遍历策略
├── a11y_shortcuts.dart          # 键盘快捷键 + Actions 映射
├── a11y_semantics.dart          # 语义化 Widget 工厂
├── a11y_text_scaler.dart        # 字体缩放适配
└── accessibility.dart           # 统一导出 barrel 文件
```

### 3.2 `a11y_focus_traversal.dart` — 全局 Focus 遍历策略

职责：定义 Tab/Shift+Tab 的焦点移动顺序。

```dart
/// ReadingOrderTraversalPolicy
/// - 从上到下、从左到右（符合桌面端阅读习惯）
/// - 自动跳过隐藏/禁用元素
/// - 在列表组件中使用 OrderedTraversalPolicy

/// A11yFocusScope Widget
/// - 页面级使用，隔离焦点范围
/// - 避免弹窗焦点泄漏到背景层
```

### 3.3 `a11y_shortcuts.dart` — 键盘快捷键映射

职责：统一注册键盘快捷键。

| 快捷键 | 行为 | 作用范围 |
|--------|------|----------|
| Tab / Shift+Tab | 焦点移动 | 全局（由 FocusTraversalPolicy 处理） |
| Enter / Space | 触发当前组件 | 全局 |
| ↑ / ↓ | 列表项/TabBar 导航 | 列表/TabBar 组件内 |
| ← / → | 轮播/截图预览翻页 | 轮播/预览组件内 |
| Esc | 关闭弹窗/返回 | 弹窗/全屏组件内 |

```dart
/// A11yKeyboardHandler Widget
/// - 包裹在 MaterialApp 外层
/// - 使用 Shortcuts + Actions 机制
/// - 不覆盖业务已有的自定义快捷键（通过 FocusScope 分层隔离）
```

### 3.4 `a11y_semantics.dart` — 语义化 Widget 工厂

提供统一封装的无障碍组件：

| 封装组件 | 角色 | 内部处理 |
|----------|------|----------|
| `A11yButton` | `SemanticsRole.button` | 48px 热区 + label + Focus |
| `A11yListItem` | `SemanticsRole.listItem` | MergeSemantics + value 状态 |
| `A11yCard` | `SemanticsRole.article` | label + 标签描述 |
| `A11yIconButton` | `SemanticsRole.button` | tooltip + 48px 热区 + icon 装饰性排除 |
| `A11yTab` | `SemanticsRole.tab` | selected 状态 + label |

每个封装组件内部处理：
- `Semantics(role: SemanticsRole.xxx, label: semanticsLabel)` — 语义标签
- `minInteractiveSize: 48` — 最小交互尺寸
- `Focus` 节点管理 — 焦点高亮（可选 onFocusChange 回调）
- 装饰性图标/分隔线用 `ExcludeSemantics` 包裹

### 3.5 `a11y_text_scaler.dart` — 字体缩放适配

职责：确保系统字体放大时布局不破裂。

```dart
/// clampTextScaler() helper
/// - 约束缩放范围 0.8x ~ 1.5x
/// - 防止极端缩放导致布局溢出

/// A11yText Widget
/// - 自动应用 textScaler
/// - 使用 MediaQuery.textScalerOf(context) 获取系统缩放比例
```

### 3.6 挂载方式（修改 `app.dart`）

```dart
// 在 MaterialApp 外层包裹
return A11yKeyboardHandler(
  child: MaterialApp.router(
    builder: (context, child) {
      return A11yFocusScope(
        child: child ?? const SizedBox.shrink(),
      );
    },
    // ... 其余不变
  ),
);
```

---

## 4. Semantics 标注详细清单

### 4.1 P0：交互组件（必须改造）

#### 按钮类（role: button）

| 组件 | 涉及文件 | 语义化规则 |
|------|----------|-----------|
| 安装/更新/打开按钮 | `app_card.dart`, `install_button.dart` | `label: l10n.a11yInstallApp(app.name)` |
| 窗口控制按钮 | `title_bar.dart` | `label: l10n.a11yMinimize / a11yMaximize / a11yClose` |
| 侧边栏导航按钮 | `sidebar.dart` | `label: l10n.a11yRecommend / a11yAllApps / ...` |
| 设置/下载管理按钮 | `setting_page.dart`, `download_manager_dialog.dart` | `label: l10n.settings / l10n.downloadManagement` |
| 对话框按钮 | `confirm_dialog.dart`, `uninstall_blocked_dialog.dart` | `label: l10n.confirm / l10n.cancel` |

**改造方式**：统一使用 `A11yIconButton` 封装。

#### 列表项类（role: listItem）

| 组件 | 涉及文件 | 语义化规则 |
|------|----------|-----------|
| 应用卡片 | `app_card.dart` | `label: l10n.a11yAppCard(app.name, version, status)` |
| 排行榜项 | `ranking_page.dart` | `label: l10n.a11yRankingItem(rank, app.name)` |
| 下载项 | `download_manager_dialog.dart` | `label: l10n.a11yDownloadItem(app.name, percent)` |
| 进程列表项 | `linglong_process_panel.dart` | `label: l10n.a11yProcessItem(name, pid)` |
| 搜索结果项 | `search_list_page.dart` | `label: app.name + 描述` |

**改造方式**：
- 使用 `A11yListItem` 封装
- 每个列表项用 `MergeSemantics` 合并内部子组件语义
- 动态状态（下载进度、安装状态）通过 `Semantics.value` 实时更新

#### 输入框类（role: textField）

| 组件 | 涉及文件 | 语义化规则 |
|------|----------|-----------|
| 搜索框 | `search_bar.dart`, `title_bar.dart` | `hintText: l10n.a11ySearchInputHint` |
| 评论区输入框 | `app_detail_comment_section.dart` | `hintText: l10n.a11yCommentInputHint` |

**改造方式**：`TextField` 本身自带语义，确保 `decoration.hintText` 有值，外层补充说明。

#### Tab / 分类筛选（role: tab）

| 组件 | 涉及文件 | 语义化规则 |
|------|----------|-----------|
| 主 TabBar | `my_apps_page.dart` | `label: l10n.installedApps / l10n.runningProcesses` |
| 分类筛选胶囊 | `category_filter_header.dart` | `label: 分类名 + 选中态` |
| 详情页 Tab | `app_detail_page.dart` | `label: l10n.detail / l10n.comments` |

**改造方式**：使用 `A11yTab` 封装，选中态通过 `Semantics(selected: true)` 标注。

### 4.2 P1：页面级语义结构

#### 页面标题（heading 层级）

每个页面顶层用 `Semantics(role: SemanticsRole.heading)` 标注：

| 页面 | 标注内容 |
|------|----------|
| 推荐页 | `l10n.a11yRecommendPage` |
| 全部应用 | `l10n.a11yAllAppsPage` |
| 排行榜 | `l10n.a11yRankingPage` |
| 我的应用 | `l10n.a11yMyAppsPage` |
| 应用详情 | `l10n.a11yAppDetailPage` |
| 设置页 | `l10n.a11ySettingsPage` |
| 搜索列表 | `l10n.search` |
| 更新管理 | `l10n.updates` |

#### 区域分隔（landmark）

用 `Semantics` 标注页面内大区块：

| 区域 | 标注内容 |
|------|----------|
| 轮播区（推荐页） | `l10n.a11yCarouselArea` |
| 应用列表区（所有列表页） | `l10n.a11yAppListArea` |
| 评论区（详情页） | `l10n.a11yCommentSection` |
| 截图区（详情页） | `l10n.a11yScreenshotArea` |
| 侧边栏（全局） | `l10n.a11ySidebarArea` |

### 4.3 P2：装饰性内容标注

| 组件 | 标注方式 |
|------|----------|
| 图标/Logo | `ExcludeSemantics`（纯装饰） |
| 分隔线 | `ExcludeSemantics` 或 `Semantics(label: '分隔线')` |
| 骨架屏 | `Semantics(label: '加载中')` |
| 截图 | `Semantics(role: SemanticsRole.image, label: '截图 N')` |

---

## 5. i18n 翻译清单

以下 key 需在 `app_localizations_zh.arb` 和 `app_localizations_en.arb` 中新增：

```json
{
  "a11yInstallApp": "安装 {appName}",
  "a11yUpdateApp": "更新 {appName}",
  "a11yOpenApp": "打开 {appName}",
  "a11yUninstallApp": "卸载 {appName}",
  "a11ySearchBox": "搜索应用",
  "a11ySearchInputHint": "输入关键词搜索",
  "a11yCommentInputHint": "输入评论内容",
  "a11ySidebarNav": "侧边栏导航",
  "a11yAppCard": "{appName}，版本 {version}，{status}",
  "a11yRankingItem": "排名第 {rank}，{appName}",
  "a11yProcessItem": "进程 {name}，PID {pid}",
  "a11yDownloadItem": "下载 {appName}，进度 {percent}%",
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
}
```

---

## 6. 点击区域改造清单

### 类型 A：`MaterialTapTargetSize.shrinkWrap`（4 处，必须改造）

| 文件 | 行号 | 组件 |
|------|------|------|
| `recommend_page.dart` | 620 | 推荐页 banner 左右切换按钮 |
| `app_card.dart` | 249, 268 | 应用卡片安装/更新/打开按钮 |
| `app_detail_comment_section.dart` | 302 | 评论区版本选择胶囊按钮 |

### 类型 B：`shrinkWrap: true` 列表（8 处，保持不动）

`shrinkWrap: true` 本身不影响无障碍，只控制列表是否收缩内容。在子列表已知高度时是性能优化。保持原样，在子组件层面改造无障碍。

---

## 7. 颜色对比度修正

| 颜色 | 当前值 | 对比度 | 问题 | 修正建议 |
|------|--------|--------|------|----------|
| textTertiary | `#999999` on `#FFFFFF` | 2.85:1 | ❌ 低于 4.5:1 | 加深到 `#767676`（4.54:1） |
| topLabel | `#CDA354` on `#FFFFFF` | 2.1:1 | ❌ 严重不足 | 加深到 `#8B6914`（4.6:1），或增大字号到 14px+（按大字标准 3:1 也需 3.0:1） |

> 注意：修正颜色后需验证深色模式下的对应值，保持同等对比度。

---

## 8. 测试验证策略

### 8.1 单元测试（覆盖基础设施）

| 测试文件 | 测试内容 |
|----------|----------|
| `a11y_focus_traversal_test.dart` | Focus 顺序是否正确，禁用元素是否跳过 |
| `a11y_text_scaler_test.dart` | `clampTextScaler()` 边界值（0.5x, 1.0x, 1.5x, 2.0x） |
| `a11y_semantics_test.dart` | `A11yButton` / `A11yListItem` 是否正确包裹 `Semantics` |

### 8.2 Widget 测试（覆盖关键交互组件）

| 测试文件 | 测试内容 |
|----------|----------|
| `app_card_a11y_test.dart` | 卡片是否有 Semantics label，按钮是否 48px 热区 |
| `sidebar_a11y_test.dart` | 侧边栏导航项是否可 Tab 到达 |
| `search_bar_a11y_test.dart` | 搜索框是否有 hintText，Enter 是否触发搜索 |

### 8.3 手动验证（核心流程）

使用 Linux `orca` 屏幕阅读器或 Flutter DevTools Semantics Inspector：

| 验证场景 | 预期行为 |
|----------|----------|
| Tab 键导航 | 焦点按 上→下、左→右 顺序移动，不跳过交互元素 |
| Enter/Space 触发 | 按钮/列表项可被 Enter 或 Space 激活 |
| 方向键列表导航 | 应用列表、TabBar 可用 ↑↓ 切换 |
| Esc 关闭弹窗 | 对话框、截图预览可用 Esc 关闭 |
| 屏幕阅读器朗读 | 应用卡片读出完整信息（名称+版本+状态），不是零散文字 |
| 字体放大 | 系统字体调到最大时，布局不破裂、文字不裁剪 |

---

## 9. 开发任务清单

### 阶段一：基础设施（6 个任务）
- [ ] **T1**: 创建 `lib/core/accessibility/a11y_focus_traversal.dart` — 全局 Focus 遍历策略
- [ ] **T2**: 创建 `lib/core/accessibility/a11y_shortcuts.dart` — 键盘快捷键 + Actions
- [ ] **T3**: 创建 `lib/core/accessibility/a11y_semantics.dart` — 语义化 Widget 工厂
- [ ] **T4**: 创建 `lib/core/accessibility/a11y_text_scaler.dart` — 字体缩放适配
- [ ] **T5**: 创建 `lib/core/accessibility/accessibility.dart` — barrel 导出文件
- [ ] **T6**: 修改 `app.dart` / `main.dart` 挂载无障碍能力

### 阶段二：i18n 翻译（1 个任务）
- [ ] **T7**: 在 `app_localizations_zh.arb` / `app_localizations_en.arb` 新增所有 a11y key

### 阶段三：P0 交互组件改造（12 个任务）
- [ ] **T8**: `app_card.dart` — 应用卡片 Semantics + 48px 按钮热区
- [ ] **T9**: `install_button.dart` — 安装按钮三态语义化
- [ ] **T10**: `sidebar.dart` — 侧边栏导航项 Semantics + Tooltip + 48px 热区
- [ ] **T11**: `title_bar.dart` — 窗口控制按钮（最小化/最大化/关闭）语义化
- [ ] **T12**: `search_bar.dart` — 搜索框 Semantics + Enter 触发 + 建议列表项语义
- [ ] **T13**: `category_filter_header.dart` — 分类筛选胶囊 Semantics + Tab 角色
- [ ] **T14**: `download_manager_dialog.dart` — 下载项列表 Semantics + 操作按钮热区
- [ ] **T15**: `linglong_process_panel.dart` — 进程列表项 Semantics + 右键菜单可访问
- [ ] **T16**: `confirm_dialog.dart` / 对话框组 — 确认/卸载拦截对话框按钮语义
- [ ] **T17**: `app_detail_comment_section.dart` — 评论输入框 + 版本选择胶囊语义
- [ ] **T18**: `recommend_page.dart` — 轮播按钮 + 推荐列表项语义
- [ ] **T19**: `ranking_page.dart` / `all_apps_page.dart` / `custom_category_page.dart` — 列表项语义

### 阶段四：P1 页面结构标注（6 个任务）
- [ ] **T20**: 推荐页 — heading + 区域标注（轮播/列表）
- [ ] **T21**: 全部应用页 — heading + 分类筛选区标注
- [ ] **T22**: 应用详情页 — heading（应用名）+ 截图区/评论区标注
- [ ] **T23**: 我的应用页 — heading + TabBar 标注
- [ ] **T24**: 设置页 — heading + 各设置区块标注
- [ ] **T25**: 搜索列表页 — heading + 结果列表标注

### 阶段五：P2 装饰性内容标注（3 个任务）
- [ ] **T26**: 图标/Logo — `ExcludeSemantics` 标记为装饰性
- [ ] **T27**: 分隔线/骨架屏 — 标注为装饰或提供简要说明
- [ ] **T28**: 截图列表 — 标注为 `SemanticsRole.image` + 描述

### 阶段六：测试与验证（4 个任务）
- [ ] **T29**: 编写基础设施单元测试
- [ ] **T30**: 编写关键组件 Widget 测试
- [ ] **T31**: 手动验证 Tab/Enter/方向键 导航全流程
- [ ] **T32**: 手动验证屏幕阅读器朗读 + 字体放大布局

---

## 10. 设计原则

1. **不破坏现有视觉一致性** — 所有交互改造不改变 UI 像素级外观
2. **i18n 优先** — 所有语义化文本走 `AppLocalizations`，禁止硬编码
3. **统一封装** — 通过 `A11yButton` / `A11yListItem` 等工厂组件复用
4. **分层隔离** — 基础设施不侵入业务逻辑，业务代码按需引入
5. **可验证** — 每个改造点都有对应的测试或手动验证方法
