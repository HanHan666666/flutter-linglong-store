# 阿拉伯语本地化与 RTL 布局适配设计

> 文档版本：1.0  
> 更新日期：2026-08-01  
> 适用范围：Flutter 界面、系统通知、Linux 窗口标题、XDG Desktop Entry、AppStream 元数据、RTL 方向感知布局

## 背景

项目通过 Flutter `gen-l10n` 维护中文（模板）、英文、西班牙语、俄语资源，语言列表完全由 ARB 目录驱动（见 `docs/38-arb-driven-linux-metadata.md`）。本次新增阿拉伯语支持，与俄语（`docs/37`）不同，阿拉伯语是 **RTL（从右到左）** 文字，除翻译外还涉及：

1. MaterialApp 按 locale 自动注入 RTL `Directionality`，但 Presentation 层存在 16 处硬编码 `Alignment.centerLeft/centerRight`、`EdgeInsets.only(left/right)`、`TextAlign.right`，在 RTL 下不会自动镜像。
2. 阿拉伯语 ICU 复数规则为 `zero/one/two/few/many/other` 六类（0→zero、1→one、2→two、3-10→few、11-99→many、其余→other），比俄语四类更复杂。
3. Linux 桌面元数据（启动器名称、摘要、搜索关键词、AppStream 描述）需要提供阿拉伯语版本。
4. 系统字体回退列表仅覆盖 CJK，需要补充阿拉伯语字体以保证字形渲染的确定性。

## 目标

- 提供完整阿拉伯语（标准 MSA，无区域变体，locale 代码 `ar`）翻译，覆盖全部 670 条 ARB 消息与 6 条 Linux 平台元数据。
- 阿拉伯语环境下所有文本方向正确：布局镜像、图标方向、进度条方向符合 RTL 阅读习惯。
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
- RTL 修复：全部 16 处硬编码对齐改为方向感知写法（详见下文清单），1 处展开箭头图标按 `Directionality` 镜像。
- `app_theme.dart` 字体回退列表追加 `Noto Sans Arabic`。

### 方案 B：仅翻译 + 最小 RTL 修复

只修 `TextAlign.right`，其余保留。RTL 下部分图标/留白不对称，但功能可用。被否：用户已确认需要完整的 RTL 体验，且方向感知改动在 LTR 下渲染等价，回归风险低。

## RTL 方向性修复清单

原则：**文本流方向语义**（`start`/`end`）随 `Directionality` 镜像；**窗口物理几何**（如 `app_shell.dart:211` 的右下角 content padding）不随 locale 镜像，保留 `EdgeInsets.only(right:)`。

| 文件 | 位置 | 修改 |
|------|------|------|
| `setting_page.dart` | `TextAlign.right` | → `TextAlign.end`（字体缩放百分比值） |
| `my_apps_page.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart` |
| `recommend_page.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（骨架屏标题） |
| `linglong_env_dialog.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（TextButton 内容） |
| `title_bar.dart` | 6 处 | `Alignment.centerLeft`×3 → `centerStart`；`EdgeInsets.only(left:)`×3 → `EdgeInsetsDirectional.only(start:)`；选中项展开箭头在 RTL 下改用 `arrow_back_ios` |
| `app_detail_version_section.dart` | `Alignment.centerRight` | → `AlignmentDirectional.centerEnd`（版本操作区） |
| `app_detail_hero_header.dart` | `Alignment.centerRight` | → `AlignmentDirectional.centerEnd`（日志复制按钮） |
| `install_button.dart` | `Alignment.centerLeft` | → `AlignmentDirectional.centerStart`（进度前景裁剪层，`widthFactor` 逻辑不变，RTL 下进度从右向左增长） |
| `category_filter_header.dart` | 2 处 | `EdgeInsets.only(left/right:)` → `EdgeInsetsDirectional.only(start/end:)` |
| `screenshot_preview_lightbox.dart` | `EdgeInsets.only(right:)` | → `EdgeInsetsDirectional.only(end:)`（缩略图间距） |
| `environment_management_components.dart` | `EdgeInsets.only(right:)` | → `EdgeInsetsDirectional.only(end:)`（错误图标间距） |

明确保留：`app_shell.dart:211`（窗口右下角 content padding，窗口物理几何，Linux 窗口不随 locale 镜像）。

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

- 单元测试：`test/unit/core/i18n/app_locale_test.dart` 新增 `ar_SA`/`ar-SA` 归一断言、`languageSelfName == 'العربية'`、六类复数输出断言（0/1/2/5/20）。
- RTL 冒烟测试：`test/widget/widgets/rtl_arabic_smoke_test.dart` 断言 ar locale 下 `Directionality` 为 RTL、阿拉伯语文本渲染、`AlignmentDirectional.centerStart` 在 RTL 下真实镜像到右侧。
- 设置页测试：现有遍历 `selectableAppLocales` 的用例自动覆盖 `language-option-ar`，无需改动断言。
- 门禁：`verify_localization_resources.dart`（5 locales/670 键一致）→ `gen-l10n` → `flutter analyze` 0 issue → `flutter test` 全量（LTR 下方向感知改动渲染等价，回归为零）。
- 元数据：渲染 Stable/Nightly 后做语言集合校验与 `desktop-file-validate`；`appstreamcli` 在开发机缺失时以渲染脚本内置校验兜底。

## 变更记录

- 2026-08-01：新增 `app_ar.arb`（670 键完整翻译）；RTL 方向感知修复 16 处；字体回退追加 `Noto Sans Arabic`；补充单元测试与 RTL 冒烟测试。
