# 字体大小与字重偏好设计

## 背景

商店需要默认遵守系统字体大小与粗体设置，同时允许用户进行轻量手动微调，且不能破坏现有主题、无障碍和页面排版稳定性。

## 方案

采用 **系统基线 + 用户增量** 的全局方案：

- 字号：`MediaQuery.textScaler` × `UserPreferences.fontScaleFactor`
- 字重：语义基础字重 + 系统粗体增量 + 用户字重增量

这样不需要额外维护“是否跟随系统”的双模式状态，也能始终继承系统无障碍设置。

## 数据来源

全局偏好存储在 `lib/application/providers/global_provider.dart` 的 `UserPreferences`：

- `fontScaleFactor`
- `fontWeightAdjustment`

设置页通过 `globalAppProvider.notifier` 更新，不经过 `settingProvider`。

## 应用链路

### 1. 字号

`lib/app.dart` 在应用根部重写 `MediaQuery`，通过 `composeTextScaler()` 将系统缩放与用户倍率组合，并限制在安全区间 `0.8x ~ 1.5x`。

### 2. 字重

`lib/core/config/theme/app_typography.dart` 提供：

- `AppFontWeightAdjustment`
- `resolveAppFontWeight()`

`lib/core/config/theme/app_text_styles.dart` 通过 `AppTypographyStyles` ThemeExtension 暴露动态排版，并提供：

- `context.appTextStyles`
- `context.appFontWeight()`

页面和组件应优先使用这两个入口，而不是手写固定 `fontWeight`。

### 3. 主题

`lib/core/config/theme/app_theme.dart` 的 `buildLightTheme()` / `buildDarkTheme()` 会根据当前用户偏好和系统粗体状态重新生成动态 `TextTheme`。

## 设置页交互

`lib/presentation/pages/setting/setting_page.dart` 新增：

- 字号滑杆：`85% ~ 130%`
- 字重分段选择：`更细 / 标准 / 更粗`

文案位于 `lib/core/i18n/l10n/app_zh.arb` 与 `app_en.arb`。

## 约定

1. 新页面/组件若需要强调字重，使用 `context.appFontWeight(FontWeight.xxx)`。
2. 新文本样式优先基于 `context.appTextStyles` 派生。
3. 不要再新增独立的字体偏好存储入口。
4. 不要在页面局部绕过根部 `MediaQuery` 自行叠加字号倍率。

## 验证

本功能已通过：

- 定向静态分析（本次改动涉及文件）
- 偏好恢复测试
- 字号组合/钳制测试
- 动态主题测试
- 设置页 / 推荐页 / 我的应用 / 搜索页 / 更新页 / 详情页 / 卡片 / 安装按钮 / 评论区相关测试
