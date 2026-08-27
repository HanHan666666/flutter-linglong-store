# 日韩德法繁中多语言扩展设计

> 文档版本：1.0
> 更新日期：2026-08-27
> 适用范围：Flutter 界面、Linux 窗口标题、XDG Desktop Entry、AppStream 元数据、CJK 字形渲染、语言解析与持久化
> 关联文档：`docs/37-russian-localization-design.md`、`docs/38-arb-driven-linux-metadata.md`、`docs/41-arabic-localization-design.md`

## 背景

在中文（模板）、英文、西班牙语、俄语、阿拉伯语基础上，一次性新增五种发布语言：
**日语（ja）、韩语（ko）、德语（de）、法语（fr）、繁体中文（zh-Hant）**。全部流程
遵循 `docs/38` §9 的 ARB 驱动强制流程，语言集合、Linux 元数据均从 ARB 目录自动推导。

与阿拉伯语（RTL）不同，本次五种语言均为 LTR，无需方向性布局改动；核心难点集中在
**繁体中文的双 zh 变体消歧**、**CJK 字形变体**与**法德语的名词复数**。

## 方案要点

### 1. 语言资源（六个元数据标识）

| 语言 | `@@locale` | `@@linuxDesktopLocale` | `@@appStreamLocale` | 复数类别 |
|------|-----------|------------------------|---------------------|----------|
| 日语 | `ja` | `ja` | `ja` | other（无屈折） |
| 韩语 | `ko` | `ko` | `ko` | other（无屈折） |
| 德语 | `de` | `de` | `de` | one/other |
| 法语 | `fr` | `fr` | `fr` | one/many/other（CLDR：one 含 0/1，many 为百万级） |
| 繁体中文 | `zh_Hant` | `zh_TW` | `zh-Hant` | other（无屈折） |

- 每语言完整翻译模板 `app_zh.arb` 全部 678 条消息 + 6 个 Linux 元数据键 +
  `languageSelfName`。
- 复数策略沿用阿语先例：**各语言在自身 ARB 内声明复数**。德/法在俄语圈定的
  12 个"名词计数语境键"上启用 ICU 复数，其余计数键保持直接插值；日/韩/繁中
  语法上无名词复数屈折，全部直接插值。
- 繁体中文由 `app_zh.arb` 经 OpenCC `cn→twp`（台湾正体+惯用词汇）批量转换后
  人工覆写校订，保证全库用字一致；品牌「玲珑」保留汉字形态，技术标识
  （`ll-cli`、`linyaps`、`systemd`、`bind mount`、`partial commits`、`og://appId`、
  `org.deepin.linglong.PackageManager.service` 等）一律保留原文。
- 台湾惯用词汇对照（OpenCC twp + 人工校订）：设置→設定、网络→網路、软件→軟體、
  卸载→解除安裝、进程→處理程序、队列→佇列、缓存→快取、磁盘→磁碟、文件→檔案、
  信息→資訊、搜索→搜尋、刷新→重新整理、加载→載入、默认→預設、渠道→頻道、
  仓库→儲存庫、组件→元件、变量→變數、优先级→優先順序、屏幕→螢幕、字体→字型、
  粘贴→貼上、终端→終端機、权限→權限（twp 的「許可權」为大陆 MS 译法，已覆写）。
- 后端内容语言契约不变：`resolveApiLang` 维持 zh_CN/en_US 映射，五种新语言的
  后端数据沿用现有回退（与 es/ru/ar 先例一致）。

### 2. 繁体中文双 zh 变体消歧（`app_locale.dart`）

`zh`（简体）与 `zh_Hant`（繁体）并存后，原"按 language code 首个命中"的解析会
把繁体用户错误路由到简体。升级为**打分择优**：

- 输入拆解为 language/script/region 三段（Locale 对象读命名字段，字符串按
  BCP 47 顺序 `language-script-region` 拆分）；
- 命中语言记 1 分，script 完全一致 +4 分，region 完全一致 +2 分，取最高分；
- 输入仅有 `zh_地区` 而无 script 时，按 Unicode CLDR likelySubtags 惯例提示：
  TW/HK/MO → Hant，其余中文地区保持简体；该提示是公共语言事实，不是第二份
  语言白名单；
- 平局时偏好子标签更少的基础资源（`zh_SG`、裸 `zh` 归简体），不依赖生成列表
  顺序；
- 0 分候选不参与占位，未知语言仍返回 `null` 由调用方回退。

### 3. 语言持久化升级为完整标签（`global_provider.dart`）

`setLocale` 由存 `languageCode` 改为存 `toLanguageTag()`（如 `zh-Hant`）。只存
languageCode 会把简繁折叠成同一个 `zh`，重启后无法还原文字变体；纯语言码语言
的 tag 即 languageCode，历史持久化值天然兼容，无需迁移。

### 4. CJK 字形变体字体栈（`app_theme.dart`）

原全局静态 `Noto Sans CJK SC` 打头的回退栈会让日文汉字与繁体字渲染成简体笔形。
新增 `AppCjkGlyphVariant`（hans/hant/ja/ko）：

- `cjkGlyphVariantOf(Locale)` 解析：script 优先（Hant→hant、Hans→hans），中文无
  script 按台/港/澳归 hant，ja/ko 按 language code，其余语言维持简体形态；
- 各变体把目标地区字库（TC/JP/KR）排到首位，其余 CJK 字库继续兜底缺字，
  `Noto Sans Arabic` 与 `Noto Color Emoji` 固定末尾；
- `buildLightTheme/buildDarkTheme` 新增可选 `appLocale` 参数，`app.dart` 闭包
  捕获当前 locale 传入；语言切换随 MaterialApp 重建自动生效，零额外监听。

### 5. 语言菜单高度（`app_language_selector.dart`）

10 种语言 × 48px 条目 + 内边距 = 488px，超过 `AppAnchoredMenu` 默认 320px 上限会
触发内部滚动。语言选择器显式传 `maximumMenuHeight = locales.length × 48 + 8`，
常规窗口下整份列表一次性完整展示；极小屏或超长列表时仍由 SDK 钳制并回退滚动。

### 6. 繁体平台标识决策（记录备选）

- **采用**：应用内统一 `zh-Hant`（script 标签天然覆盖台/港/澳繁体用户）；
  Desktop Entry 单值 `zh_TW`（最普及的繁体桌面环境，精确命中）；AppStream 单值
  `zh-Hant`（BCP 47 规范表达"整个繁体书写区"）。
- **已知权衡**：zh_HK/zh_MO 系统的启动器名称按 freedesktop 回退链落到英文默认值
  （简体的 `zh_CN` 与繁体的 `zh_TW` 都不匹配 `zh_HK`）；应用内界面不受影响，
  应用内 locale 解析仍能正确显示繁体。
- **备选方案（未采用）**：渲染器为每个 ARB 额外输出裸语言别名行
  （`Name[zh]=…`），借 glib 的"精确 → 语言_地区 → 裸语言 → 默认"查找链让
  zh_HK 落到繁体别名。该增强可让全语言受益且零每语言配置，但需同步修改
  发布校验器与 `docs/38` §6.2 的字段集合契约，发布链路改动大于收益，留作
  后续可选项。

## 测试与验证

- `app_locale_test.dart`：
  - 各新语言区域 Locale 归一 + 自称名 + 计数消息代表值；
  - zh/zh-Hant 消歧四组：持久化 `zh-Hant`、台/港/澳归繁体、大陆/新加坡/裸 zh
    归简体、未知纯语言返回 `null`；
  - `selectableAppLocales` 去重断言改用完整语言标签（zh 与 zh-Hant 共享
    languageCode）。
- `format_utils_test.dart`：五种新语言的下载次数代表值（含法语 one/many/other
  三类与本地化千位分隔）。
- `setting_page_test.dart`：语言菜单首尾项与高度上限改为从 `selectableAppLocales`
  推导（`条目数×48+8`），新增语言无需再改语言字面量断言。
- 门禁实测：`verify_localization_resources`（10 locales/678 键）→ `gen-l10n` →
  `verify-generated-sources.sh` → `flutter analyze` 0 issue → `flutter test`
  973 全通过 → Stable/Nightly 渲染 + `desktop-file-validate` 通过 +
  AppStream 三字段语言集合校验（11 项 = 默认 + 10 locale）。
- `appstreamcli` 开发机缺失，沿用阿语先例以渲染脚本内置校验兜底。

## 后续维护注意

1. **新增语言零代码改动**：只需新增 ARB（含 6 元数据键与 `languageSelfName`）→
   校验 → `gen-l10n` → 渲染元数据；语言菜单与设置页断言已泛化，无需跟改。
2. **语言菜单视觉上限**：每新增一种语言菜单最大高度 +48px；超过屏幕可用高度时
   SDK 自动钳制并出现滚动，属预期行为。
3. **繁体用字维护**：修改 `app_zh.arb` 后繁体需同步走 OpenCC twp + 校订流程，
   不要直接在 `app_zh_Hant.arb` 手工补简体字；注意 twp 的已知误转
   （权限→許可權、移动→行動、账号→賬號）需人工覆写。
4. **模板复数变更警告**（延续 `docs/41`）：若模板 `app_zh.arb` 把计数键改为
   `{count, plural, ...}`，德/法/俄/阿的复数类别必须成为模板类别的超集约束下
   重新评估，否则构建失败。
5. **法语 many 类**：百万级计数走 `many` 分支（如 `1 000 000 de téléchargements`），
   数字经 `decimalPattern('fr')` 呈现不换行窄空格分隔，测试需用
   `NumberFormat` 构造期望值而非硬编码字符串。

## 变更记录

- 2026-08-27：新增日/韩/德/法/繁中五种发布语言（各 678 键完整翻译）；locale
  解析升级为打分消歧；语言持久化升级为完整 BCP 47 标签；主题字体按 locale
  选择 CJK 字形变体；语言菜单高度按条目数自适应。
