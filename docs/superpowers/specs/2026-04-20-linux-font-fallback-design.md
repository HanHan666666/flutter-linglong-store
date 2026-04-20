# Linux 中文字体 Fallback 修复设计

## 背景

用户反馈在 UOS 1070 上安装 `deb` 包后，Flutter 商店界面中的中文文本出现缺字或方框，而同机浏览器中的中文显示正常。

当前仓库的 Linux 桌面主题存在两个与该现象高度相关的事实：

1. `AppTheme` 直接覆盖了整套 `ThemeData.textTheme`，并大量在组件主题中直接使用 `AppTextStyles`。
2. 打包产物当前只声明基础 GTK 运行依赖，没有任何 CJK 字体存在性兜底。

旧版 Rust/Tauri 商店运行在浏览器字体栈上，最终会落到 `sans-serif` 与系统字体回退；Flutter Linux 则更依赖引擎与宿主系统的字体发现结果，因此在发行版字体集合不完整时更容易暴露缺字问题。

## 目标

1. 在不引入内置字体资源的前提下，为 Linux 桌面主题显式声明稳定的中文字体 fallback。
2. 统一覆盖 `ThemeData.textTheme` 与所有直接从 `AppTextStyles` 派生的组件主题文本样式。
3. 为后续打包层字体兜底保留清晰边界，避免把系统发行版问题继续下沉到页面级组件。
4. 增加回归测试，锁定全局主题文本样式必须携带显式 fallback。

## 非目标

1. 本次不修改 `deb/rpm/appimage` 的包依赖，不引入新的系统字体包要求。
2. 不内置 `otf/ttf/ttc` 中文字体资源，不扩大安装包体积。
3. 不重做字体语义映射，不调整字号、字重、间距或组件布局。
4. 不把页面级 `Text` 全量替换为局部 `style`，仍保持主题统一入口。

## 现状分析

### 1. 当前主题没有显式 CJK fallback

`lib/core/config/theme/app_theme.dart` 中：

1. `ThemeData.textTheme` 直接使用 `AppTextStyles.textTheme`。
2. `AppBarTheme.titleTextStyle`、`InputDecorationTheme.hintStyle`、`TabBarThemeData.labelStyle`、`SnackBarThemeData.contentTextStyle` 等位置直接从 `AppTextStyles` 派生。

这意味着即便 Flutter 默认文本路径能命中系统字体，组件级样式仍可能落回缺少中文字形的默认字体选择。

### 2. 问题更可能出现在发布包环境

当前信息显示问题发生在客户安装的 `deb` 包中，尚未确认 `flutter run -d linux` 是否同样复现。该现象说明根因可能同时涉及：

1. Flutter Linux 端的字体选择与 fallback 顺序。
2. 目标机系统字体集合差异。
3. 发布环境与开发环境字体可见性差异。

但在没有目标机复现条件的前提下，优先修正主题统一入口是改动面最小、收益最高且风险最低的第一步。

## 方案比较

### 方案 A：仅调整打包依赖或要求系统安装中文字体

做法：

1. 在 `deb/rpm` 中增加 CJK 字体依赖。
2. 保持当前主题代码不变。

优点：

1. 能直接解决“目标机缺字体”的一部分场景。
2. 不动 Flutter UI 层代码。

缺点：

1. 仍然把主题层字体选择交给 Flutter 默认行为，不够可控。
2. 对 AppImage 和其他分发形式收益有限。
3. 无法解释“同机浏览器正常、Flutter 异常”的主题层差异。

结论：本次不采用，作为后续兜底选项。

### 方案 B：在全局主题层显式声明 Linux 常见中文 fallback

做法：

1. 在 `AppTheme` 中定义统一的 CJK fallback 字体列表。
2. 将 fallback 应用到 `textTheme` 的所有语义样式。
3. 将 fallback 同步应用到所有直接由 `AppTextStyles` 派生的组件主题文本样式。

优点：

1. 改动集中，入口清晰。
2. 不依赖单个发行版的默认字体解析顺序。
3. 与现有架构一致，能覆盖大多数文本渲染路径。
4. 适合通过单元测试稳定锁定。

缺点：

1. 仍要求目标机至少存在列表中的某一种中文字体，否则只能继续落到系统默认 fallback。
2. 需要同步检查浅色和深色主题中所有直接派生的文本样式。

结论：采用本方案。

### 方案 C：内置中文字体文件并全局指定自定义字体

做法：

1. 将思源黑体或 Noto CJK 打包进应用资源。
2. 在 `pubspec.yaml` 中注册并在全局主题指定。

优点：

1. 渲染结果最稳定。
2. 几乎不受目标机字体差异影响。

缺点：

1. 包体显著增大。
2. 增加字体授权、升级、子集化与多字重维护成本。
3. 对桌面端当前问题而言属于过重方案。

结论：本次不采用。

## 选型

采用方案 B：在 `AppTheme` 统一声明并应用 Linux 中文字体 fallback。

推荐的 fallback 顺序：

1. `Noto Sans CJK SC`
2. `Source Han Sans SC`
3. `WenQuanYi Micro Hei`
4. `WenQuanYi Zen Hei`
5. `Noto Color Emoji`

说明：

1. 前四项覆盖常见 Linux CJK 字体发行版组合。
2. `Noto Color Emoji` 用于补全 emoji，不承担中文主字体角色。
3. 仍保留 Flutter/系统的最终默认 fallback，避免把字体列表写死成唯一来源。

## 设计细节

### 1. 统一入口

在 `lib/core/config/theme/app_theme.dart` 内新增私有 helper：

1. 统一维护 fallback 字体列表。
2. 为单个 `TextStyle` 应用 `fontFamilyFallback`。
3. 为 `TextTheme` 全量应用 `fontFamilyFallback`。

这样既能覆盖 `textTheme`，又能覆盖 `AppBarTheme`、`TabBarThemeData`、`SnackBarThemeData` 等直接派生样式，避免页面层自行复制 fallback 逻辑。

### 2. 保持现有字号语义不变

本次只补全 `fontFamilyFallback`，不修改：

1. `AppTextStyles` 的字号与字重定义。
2. `ThemeData` 的颜色、间距、圆角、按钮尺寸。
3. 任意页面级组件的布局结构。

这样可以把风险控制在“字体选择策略修复”，避免混入无关视觉回归。

### 3. 测试策略

在 `test/unit/core/config/app_theme_test.dart` 新增单元测试，验证：

1. `AppTheme.lightTheme.textTheme.bodyMedium` 包含预期 fallback 列表。
2. `AppTheme.darkTheme.textTheme.bodyMedium` 包含预期 fallback 列表。
3. `AppTheme.lightTheme.appBarTheme.titleTextStyle` 也携带相同 fallback，确保组件主题不是漏网之鱼。

## 影响范围

### 直接修改

1. `lib/core/config/theme/app_theme.dart`
2. `test/unit/core/config/app_theme_test.dart`
3. `AGENTS.md`
4. `docs/superpowers/specs/2026-04-20-linux-font-fallback-design.md`
5. `docs/superpowers/plans/2026-04-20-linux-font-fallback.md`

### 间接收益

1. 所有使用 `Theme.of(context).textTheme` 的页面文本。
2. 所有使用 `AppTheme` 中组件主题派生样式的组件。
3. 后续 Linux 发行版兼容排查具备统一入口。

## 风险与缓解

### 风险 1：目标机没有列表中的任一中文字体

缓解：

1. 本次保留系统默认 fallback 作为最后兜底。
2. 如果客户机仍异常，再进入打包依赖或运行时字体检查方案。

### 风险 2：个别组件使用自定义 `TextStyle` 且未走主题

缓解：

1. 本次先覆盖主题统一入口和组件主题。
2. 若问题仍存在，再根据客户截图反查个别页面的局部 `TextStyle`。

### 风险 3：字体切换导致少量行高视觉差异

缓解：

1. 不调整字号和组件高度。
2. 先通过现有主题单元测试与 targeted analyze/test 验证，再由客户机回归确认。

## 验证口径

代码侧验证：

1. `flutter test test/unit/core/config/app_theme_test.dart`
2. `flutter analyze lib/core/config/theme/app_theme.dart test/unit/core/config/app_theme_test.dart`

业务侧验证：

1. 在目标 Linux 环境打开启动页、设置页、弹窗、按钮、Tab 等常见文本区域。
2. 确认中文不再缺字，英文和 emoji 未退化。

## 后续扩展

如果主题层 fallback 修复后，客户的 `deb` 包仍然缺字，则第二阶段再单独设计：

1. `deb/rpm` 的 CJK 字体依赖补齐。
2. AppImage 启动时的字体可见性与 `fontconfig` 环境检查。
3. 运行时诊断日志输出当前命中的字体信息。
