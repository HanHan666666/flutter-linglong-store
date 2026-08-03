# 阿拉伯语本地化与 RTL 布局适配设计

> 文档版本：1.1
> 更新日期：2026-08-03
> 适用范围：Flutter 界面、系统通知、Linux 窗口标题、XDG Desktop Entry、AppStream 元数据、RTL 方向感知布局

## 背景

项目通过 Flutter `gen-l10n` 维护中文（模板）、英文、西班牙语、俄语资源，语言列表完全由 ARB 目录驱动（见 `docs/38-arb-driven-linux-metadata.md`）。本次新增阿拉伯语支持，与俄语（`docs/37`）不同，阿拉伯语是 **RTL（从右到左）** 文字，除翻译外还涉及：

1. MaterialApp 按 locale 自动注入 RTL `Directionality`，但 Presentation 层存在 16 处硬编码 `Alignment.centerLeft/centerRight`、`EdgeInsets.only(left/right)`、`TextAlign.right`，在 RTL 下不会自动镜像。
2. 阿拉伯语 ICU 复数规则为 `zero/one/two/few/many/other` 六类（0→zero、1→one、2→two、3-10→few、11-99→many、其余→other），比俄语四类更复杂。
3. Linux 桌面元数据（启动器名称、摘要、搜索关键词、AppStream 描述）需要提供阿拉伯语版本。
4. 系统字体回退列表仅覆盖 CJK，需要补充阿拉伯语字体以保证字形渲染的确定性。

## 目标

- 提供完整阿拉伯语（标准 MSA，无区域变体，locale 代码 `ar`）翻译，覆盖全部 670 条 ARB 消息与 6 条 Linux 平台元数据。
- 阿拉伯语环境下采用选择性 RTL：内容流与导航关系镜像，窗口管理等物理几何保持平台位置。
- 阿拉伯语复数键语法正确，`0/1/2/3-10/11-99/100+` 均输出正确名词形式。
- 系统有 `Noto Sans Arabic`（或任何阿拉伯字体）时正文渲染稳定，无需捆绑字体。

## 非目标

- 不为后端新增阿拉伯语数据或修改后端接口（`resolveApiLang` 契约不变，ar 界面下后端内容沿用现有回退）。
- 不翻译应用名称、应用简介、标签等后端内容。
- 不翻译 `ll-cli`、systemd、HTTP 或特权脚本返回的原始诊断文本；技术标识（`Linglong`、`ll-cli`、`erofs`、`partial commits`、`bind mount`、`org.deepin.linglong.PackageManager.service` 等）保留原文。
- 不做区域变体拆分（`ar_SA`/`ar_EG` 统一归一为 `ar`）。
- 不引入运行时语言包或第三方翻译服务。

## 方案选择

### 方案 A：完整翻译 + 全部方向性修复（采用）

- 新增 `lib/core/i18n/l10n/app_ar.arb`，由模板 `app_zh.arb` 派生，`@@locale`/`@@linuxDesktopLocale`/`@@appStreamLocale` 均为 `ar`，不设 `@@linuxMetadataFallback`（全局唯一一个在 `app_en.arb`）。
- 26 个带 int 占位符的键中，11 个名词计数语境键按阿拉伯语 CLDR 规则使用六类复数；纯数值显示类（百分比、错误码、等待计数括号等）保持直接插值。
- RTL 修复：内容布局使用 Directional API；Flutter 已声明 `matchTextDirection` 的 Material 图标只保留单一图标，由框架自动镜像。
- `app_theme.dart` 字体回退列表追加 `Noto Sans Arabic`。

### 方案 B：仅翻译 + 最小 RTL 修复

只修 `TextAlign.right`，其余保留。RTL 下部分图标/留白不对称，但功能可用。被否：用户已确认需要完整的 RTL 体验，且方向感知改动在 LTR 下渲染等价，回归风险低。

## RTL 方向性修复清单

### 选择性镜像原则

阿拉伯语界面不是“只把文字设为 RTL”，也不是把屏幕上每个坐标机械翻转。实现按语义分为三类：

1. **内容流与导航关系需要镜像**：标题、列表、表单、侧栏、上一项/下一项、信息区与品牌预览区使用 `start/end`。例如阿拉伯语下“上一张”位于右侧，“下一张”位于左侧。
2. **平台窗口物理几何不镜像**：Linux 自定义标题栏的最小化/最大化/关闭按钮固定在窗口右上角，顺序保持最小化 → 最大化 → 关闭；屏幕坐标驱动的 Overlay 和飞行动画也保持物理坐标。
3. **图标遵循自身语义**：`arrow_forward_ios`、`chevron_left/right` 等 Material 图标已经设置 `matchTextDirection: true`，直接使用即可。禁止再根据 `TextDirection.rtl` 手工替换成反向图标，否则会发生双重镜像。无方向含义的图标和应用 Logo 不镜像。

物理几何例外必须在源码紧邻位置添加 `// ignore: hardcoded_direction - 原因`，不能依赖门禁漏检。

| 文件 | 位置 | 修改 |
|------|------|------|
| `setting_page.dart` | `TextAlign.right` | → `TextAlign.end`（字体缩放百分比值） |
| `my_apps_page.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart` |
| `recommend_page.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（骨架屏标题） |
| `linglong_env_dialog.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（TextButton 内容） |
| `title_bar.dart` | 内容区 | `Alignment.centerLeft`×3 → `centerStart`；`EdgeInsets.only(left:)`×3 → `EdgeInsetsDirectional.only(start:)`；搜索建议保留 `arrow_forward_ios` 并由 Flutter 自动镜像 |
| `app_detail_version_section.dart` | `Alignment.centerRight` | → `AlignmentDirectional.centerEnd`（版本操作区） |
| `app_detail_hero_header.dart` | `Alignment.centerRight` | → `AlignmentDirectional.centerEnd`（日志复制按钮） |
| `install_button.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（进度前景裁剪层，`widthFactor` 逻辑不变，RTL 下进度从右向左增长） |
| `category_filter_header.dart` | 2 处 | `EdgeInsets.only(left/right:)` → `EdgeInsetsDirectional.only(start/end:)` |
| `screenshot_preview_lightbox.dart` | `EdgeInsets.only(right:)` | → `EdgeInsetsDirectional.only(end:)`（缩略图间距） |
| `environment_management_components.dart` | `EdgeInsets.only(right:)` | → `EdgeInsetsDirectional.only(end:)`（错误图标间距） |

明确保留：`app_shell.dart:211`（窗口右下角 content padding，窗口物理几何，Linux 窗口不随 locale 镜像）。

### 2026-08-03 复查完善

| 场景 | 实现约定 |
|------|----------|
| 推荐页轮播、截图灯箱 | 上一项使用 `PositionedDirectional.start`，下一项使用 `PositionedDirectional.end`；图标本身由 Flutter 镜像 |
| 推荐页品牌背景 | 信息区位于 start，品牌图与预览板位于 end，RTL 下两者一起换边，避免遮挡 |
| Linux 自定义标题栏 | 标题栏外层与窗口按钮组明确使用物理 LTR 排列，只固定窗口控制区；内部标题和搜索内容仍继承阿拉伯语 RTL |
| 侧栏角标、对话框标题间距、筛选区 | 统一改为 `PositionedDirectional` / `EdgeInsetsDirectional.fromSTEB` |
| 搜索 Overlay、安装飞行动画 | 坐标来自屏幕 `Rect/Offset`，保留 `Positioned(left:)` 并添加物理几何豁免说明 |

## 动态占位符的 BiDi 隔离

阿拉伯语句子经常混入版本号、URL、路径、应用名、错误信息、PID 和百分比。仅依赖外层 RTL 时，斜杠、括号、冒号和多个占位符可能跨字段重排，因此隔离逻辑直接写在 `app_ar.arb` 中，而不是散落到 Presentation 调用点。

| 内容类型 | 控制字符 | ARB 写法 | 适用示例 |
|----------|----------|----------|----------|
| 已知 LTR 数字/技术短语 | LRI `U+2066` + PDI `U+2069` | `\u2066{count}\u2069` | 数量、百分比、PID、`v1.2.3`、`name=value` |
| 方向未知的动态文本 | FSI `U+2068` + PDI `U+2069` | `\u2068{value}\u2069` | 应用名、路径、URL、错误、搜索词 |

隔离范围应覆盖与值不可分割的标点或前缀，例如百分比写成 `\u2066{percent}%\u2069`，版本写成 `\u2066v{version}\u2069`。ARB 保留可见的 `\u206x` 转义；`gen-l10n` 生成 Dart 后会变为真实控制字符，因此 `l10n.yaml` 只对生成文件豁免相应静态诊断，`arabic_bidi_localizations_test.dart` 负责检查每个直接插值都处于成对 isolate 内。

## 阿拉伯语复数规则

阿拉伯语（CLDR `ar`）对整数 `i`：

| 类别 | 条件 | 例（"应用"） |
|------|------|------|
| zero | i = 0 | لم يتم تحديث أي تطبيق |
| one | i = 1 | تم تحديث تطبيق واحد |
| two | i = 2 | تم تحديث تطبيقين |
| few | 3 ≤ i % 100 ≤ 10 | تم تحديث 5 تطبيقات |
| many | 11 ≤ i % 100 ≤ 99 | تم تحديث 20 تطبيقًا |
| other | 其余 | تم تحديث 100 تطبيقًا |

`flutter gen-l10n` 对非模板语言支持任意复数类别集合（俄语四类已验证），六类一次性通过。所有 plural 表达式以模板中已声明的 int 占位符为选择器（如 `updateBatchUpdatedAppsOverflow` 使用 `remainingCount`，避免引入模板不存在的 `count` 占位符被校验脚本拒绝）。

### 下载次数

`downloadedXTimes` 的 `count` 必须保持 `int`，并在模板元数据中使用 `format: decimalPattern`。`formatDownloadCountText` 只负责过滤空值和非正数，然后把原始整数传给本地化层；禁止在 Dart 中手工插入英文逗号。

- 中文保持“下载 N 次”。
- 英语、西班牙语使用 `one/other`。
- 俄语使用 `one/few/many/other`。
- 阿拉伯语提供 `zero/one/two/few/many/other`，其中 one/two 使用自然语言双数形式，few/many/other 的数字置于 LRI/PDI 中。

## 术语表（关键）

| 中文 | 阿拉伯语 |
|------|---------|
| 安装 / 卸载 / 更新 | تثبيت / إلغاء التثبيت / تحديث |
| 应用商店 | متجر التطبيقات |
| 下载 / 下载量 | تنزيل / عدد التنزيلات |
| 环境检测 / 环境管理 | فحص البيئة / إدارة البيئة |
| 仓库 | المستودع |
| 运行时 / 容器 | بيئة التشغيل / الحاوية |
| 缓存 | ذاكرة التخزين المؤقت |
| 设置 / 语言设置 | الإعدادات / إعدادات اللغة |
| 玲珑应用商店 | متجر تطبيقات Linglong |
| 排行榜 / 我的应用 | الترتيب / تطبيقاتي |

品牌与技术标识（`Linglong`、`ll-cli`、`erofs`、`partial commits`、`bind mount`、`og://appId`、系统服务名）一律保留原文。

## 测试与验证

- 单元测试：`test/unit/core/i18n/app_locale_test.dart` 覆盖 `ar_SA` 归一、语言自称和六类复数代表值；`arabic_bidi_localizations_test.dart` 覆盖版本/URL/路径/数字边界及 ARB 全量 isolate 配对。
- RTL 冒烟测试：`test/widget/widgets/rtl_arabic_smoke_test.dart` 断言 ar locale 下 `Directionality` 为 RTL、阿拉伯语文本渲染、`AlignmentDirectional.centerStart` 在 RTL 下真实镜像到右侧。
- 轮播与窗口测试：推荐页、截图灯箱断言 RTL 下 previous 在右、next 在左；标题栏断言窗口按钮仍在右上角并保持平台顺序。
- 下载次数测试：覆盖阿拉伯语 1/2/5/20/12345，以及英语、西班牙语和俄语代表性复数形式与本地千位格式。
- 设置页测试：现有遍历 `selectableAppLocales` 的用例自动覆盖 `language-option-ar`，无需改动断言。
- 门禁：`verify_localization_resources.dart`（5 locales/670 键一致）→ `gen-l10n` → `flutter analyze` 0 issue → `flutter test` 全量（LTR 下方向感知改动渲染等价，回归为零）。
- 元数据：渲染 Stable/Nightly 后做语言集合校验与 `desktop-file-validate`；`appstreamcli` 在开发机缺失时以渲染脚本内置校验兜底。

## 后续维护注意

1. **模板复数变更警告**：ar 的六类复数依赖 `gen-l10n` 对非模板语言的宽松支持。若将来有人把模板 `app_zh.arb` 的计数键改为 `{count, plural, ...}` 写法，`gen-l10n` 会强制所有语言的复数类别为模板类别的子集，**ar 六类将构建失败**。此时需先确认模板类别集合是否覆盖 ar 的 `zero/one/two/few/many/other`。
2. **语言菜单高度断言是隐性上限**：`test/widget/presentation/pages/setting_page_test.dart` 断言语言菜单最大高度 `<320`。当前 5 种语言（含 ar）为 240px，每新增一种语言（动作项 48px）都要复核该断言，避免第 6 种语言时意外失败。
3. **方向性图标禁止双重处理**：先检查 Flutter `IconData.matchTextDirection`。已自动镜像的图标保留单一 `IconData`；只有未提供自动镜像且确实表达 start/end 的自定义图形才允许按 `Directionality` 处理。
4. **RTL 回归防护**：`verify_directional_layout.dart` 使用 analyzer AST，覆盖多行 `EdgeInsets.only` / `Positioned`、不对称 `EdgeInsets.fromLTRB`、物理 `Alignment` / `TextAlign` 和自动镜像图标的手工 RTL 条件分支。新增物理几何例外必须写明 ignore 原因，并补充 Widget 测试。
5. **动态占位符必须隔离**：向阿拉伯语消息新增直接插值时，数字用 LRI，未知方向文本用 FSI，并运行 ARB 全量 isolate 测试；不要在 Dart 调用点二次包裹。

## 变更记录

- 2026-08-01：新增 `app_ar.arb`（670 键完整翻译）；RTL 方向感知修复 16 处；字体回退追加 `Noto Sans Arabic`；补充单元测试与 RTL 冒烟测试。
- 2026-08-01：补充 RTL 组件测试（标题栏展开箭头镜像、安装进度条方向），修复标题栏 Logo 区在长语言下的 Row 溢出与搜索建议浮层 hover 选中不刷新两个真实缺陷；新增方向感知布局扫描门禁；AGENTS.md 增加 RTL 硬性约定。
- 2026-08-03：明确选择性镜像策略；修复轮播导航、推荐背景与 Linux 窗口控制区；将方向门禁升级为 AST；为阿拉伯语动态占位符增加 BiDi isolate；下载次数改为本地数字格式与多语言复数。
