# ARB 驱动的 Linux 本地化元数据设计

> 状态：已确认，作为后续新增语言和维护 Linux 平台元数据的强制约定  
> 适用范围：Flutter 界面、XDG Desktop Entry、AppStream、Stable/Nightly 打包  
> 关联文档：`docs/37-russian-localization-design.md`

## 1. 背景

项目已经使用 Flutter `gen-l10n` 管理界面语言，但 Linux 平台元数据仍由打包模板
和 Shell 变量手工维护。俄语接入后出现了以下不一致：

- Desktop Entry 的 `Name` 有中文和俄语，缺少西班牙语；英文仅隐含在无 locale
  标记的默认字段中。
- `GenericName`、`Comment`、`Keywords` 各自拥有不同的语言集合。
- AppStream 的 `name`、`summary`、`description` 只有默认值和俄语。
- Stable/Nightly smoke test 按具体语言硬编码断言，新增语言必须继续修改测试脚本。
- `render-packaging-templates.sh` 使用 `display_name_ru`、`summary_text_ru` 等
  语言专用变量；继续增加语言会让 Shell 按语言线性增长。

这类结构无法表达“当前到底发布了哪些语言”，也无法自动发现某个字段漏掉某种
语言。解决目标不是补几行西班牙语，而是让发布语言集合、资源内容和平台元数据
从同一个来源推导。

## 2. 目标

1. `lib/core/i18n/l10n/app_*.arb` 是发布语言集合和本地化文本的唯一人工来源。
2. 新增发布语言时不修改 Dart 业务代码、Linux 模板、Shell 语言变量或按语言编写
   的 smoke test。
3. 同一个本地化字段要么覆盖全部发布语言，要么对所有语言都不存在，禁止部分
   语言存在、部分语言缺失。
4. Desktop Entry 遵循 XDG locale 后缀与默认值规则，AppStream 使用合法的
   `xml:lang` BCP 47 标签。
5. Stable 与 Nightly 只通过渠道选择对应文案，不复制语言注册逻辑。
6. 生成过程必须正确转义 Desktop Entry 和 XML，且在构建阶段拒绝空翻译、漏键、
   错占位符、残留模板标记和语言集合漂移。
7. 用户可见界面文案必须来自 ARB；日志、命令输出、后端原始诊断等不可翻译事实
   保持原样，不混入 UI 本地化资源。

## 3. 非目标

- 不在客户端伪造后端尚未提供的应用名称、分类、标签或详情翻译。
- 不翻译 `ll-cli`、Shell、systemd、后端返回的原始诊断和完整日志。
- 不为 DEB/RPM 控制字段创造非标准的内嵌多语言格式；这些字段保持英文发布元数据，
  发行版若需要翻译应使用其自身的包索引翻译机制。
- 不引入按发行版或桌面环境分支，生成结果必须可用于 DDE、GNOME、KDE 等遵循
  Freedesktop 规范的环境。

## 4. 规范依据

### 4.1 Desktop Entry

Freedesktop Desktop Entry 规范要求：

- 可本地化键使用 `Key[LOCALE]=value`。
- 只要存在带 locale 后缀的键，就必须同时存在不带后缀的默认键。
- locale 使用 POSIX 形式：`lang[_COUNTRY][@MODIFIER]`，编码部分不写入键名。
- 当前 locale 无匹配项时使用不带后缀的默认值。
- `Name`、`GenericName`、`Comment` 和 `Keywords` 都属于可本地化字段。

规范入口：

- <https://specifications.freedesktop.org/desktop-entry/latest/localized-keys.html>
- <https://specifications.freedesktop.org/desktop-entry/latest/recognized-keys.html>

### 4.2 AppStream

AppStream 的 `name`、`summary` 和描述内容使用 `xml:lang` 提供本地化值。Flutter、
POSIX 和 BCP 47 对 script、country、modifier 的表示并不完全等价，因此不能用简单
的下划线/连字符替换猜测平台 locale。每个 ARB 显式声明两个不可翻译的平台标识：

| `@@locale` | `@@linuxDesktopLocale` | `@@appStreamLocale` |
|---|---|---|
| `ru` | `ru` | `ru` |
| `pt_BR` | `pt_BR` | `pt-BR` |
| `zh` | `zh_CN` | `zh-CN` |

最终文件必须通过 `appstreamcli validate --no-net`；Desktop Entry 必须通过
`desktop-file-validate`。

## 5. 唯一来源与资源模型

### 5.1 发布语言集合

生成器只发现以下形式的 ARB：

```text
lib/core/i18n/l10n/app_<locale>.arb
```

每个文件必须声明与文件名一致的 `@@locale`，并声明合法且唯一的
`@@linuxDesktopLocale`、`@@appStreamLocale`。存在于该目录的合法 ARB 就代表一个
正式发布语言；试译或未完成语言不得放入该目录。

设置页、系统 locale 解析、Flutter `supportedLocales` 和 Linux 元数据都从这个集合
推导，禁止再维护第二份语言白名单。

### 5.2 Linux 元数据键

Stable 应用名称直接复用已有 `appTitle`。每个 ARB 还必须提供：

| ARB 键 | 用途 |
|---|---|
| `linuxDesktopNameNightly` | Nightly Desktop Entry 与 AppStream 名称 |
| `linuxDesktopGenericName` | Desktop Entry `GenericName` |
| `linuxDesktopComment` | Stable Desktop Entry `Comment` 与 AppStream `summary` |
| `linuxDesktopCommentNightly` | Nightly `Comment` 与 AppStream `summary` |
| `linuxDesktopKeywords` | Desktop Entry `Keywords`，必须以分号分隔并以分号结尾 |
| `linuxAppStreamDescription` | AppStream 单段完整描述 |

这些键属于发布元数据，不允许在 Shell、XML、Desktop 模板或测试中保存具体语言
文本。

### 5.3 默认值

无 locale 标记的 Desktop Entry 与 AppStream 值统一从声明
`"@@linuxMetadataFallback": true` 的 ARB 读取，当前由 `app_en.arb` 承担。这是未知
locale 的跨发行版回退值。英文同时属于完整发布语言集合，生成器显式渲染英文 locale
项；无标记默认值不能被误认为另一套独立文案。

所有正式 ARB 中必须恰好有一个回退标记。如果未来要更换平台默认语言，只移动这一
标记，禁止在生成器、模板或渠道脚本中写死 locale。

## 6. 严格完整性规则

### 6.1 ARB

所有正式 ARB 必须满足：

- 消息键集合与模板 ARB 完全一致。
- `@@locale` 与文件名一致。
- 两个平台 locale 标识合法且在各自格式内唯一。
- `@@linuxMetadataFallback` 必须恰好在一个 ARB 中为 `true`。
- 同一消息的占位符集合一致。
- Linux 元数据键存在、非空且没有首尾空白。
- Desktop Entry 单行值不得包含原始换行。
- `linuxDesktopKeywords` 必须是合法的非空分号列表。
- ICU plural/select 必须能被 `flutter gen-l10n` 解析。

任何一项失败都阻止生成和发布。

### 6.2 Desktop Entry

规范定义如下：

- Canonical desktop 文件启用 `Name`、`GenericName`、`Comment`、`Keywords`，四个字段
  都必须覆盖完整发布语言集合。
- Compatibility desktop 文件只启用 `Name` 和 `Comment`，两者覆盖完整发布语言集合；
  `GenericName` 和 `Keywords` 对所有语言都不存在。
- 任意本地化字段必须同时存在无 locale 标记的英文回退值。
- 每个字段的 locale 集合必须等于 ARB 发布语言集合，禁止额外语言或漏语言。
- Stable/Nightly 的 locale 集合必须完全相同，只允许文本内容随渠道变化。

### 6.3 AppStream

- `name`、`summary`、`description` 必须分别覆盖完整发布语言集合。
- 三个字段的 locale 集合必须完全一致。
- 必须同时存在无 `xml:lang` 的英文回退值。
- locale 标签使用 BCP 47 连字符形式。
- XML 文本由生成器统一转义，ARB 中禁止预先写 `&amp;` 等 XML 实体。

### 6.4 用户界面

- `MaterialApp` 下的 Presentation 代码必须使用非空 `AppLocalizations`，禁止
  `l10n?.key ?? '中文兜底'`。
- 新增用户可见文案必须先添加到模板 ARB，再补齐所有正式 ARB。
- Application/Domain 不保存自然语言运行状态；跨层状态使用枚举、代码和结构化参数，
  由 Presentation 映射到 ARB。
- 纯日志、内部异常、CLI 原始输出、Shell 原始输出和后端原始诊断不作为 UI 文案；
  如需面向用户展示摘要，必须另建结构化状态和 ARB 文案，原文只作为可复制诊断。

## 7. 生成架构

```text
app_zh.arb ─┐
app_en.arb ─┤
app_es.arb ─┼─> LocalizationResourceCatalog
app_ru.arb ─┘          │
                       ├─> ARB 键/占位符/平台字段校验
                       ├─> flutter gen-l10n
                       └─> LinuxMetadataRenderer
                                 │
                                 ├─> canonical .desktop
                                 ├─> compatibility .desktop 列表
                                 └─> AppStream XML
```

实现分为两个职责：

1. `LocalizationResourceCatalog` 负责发现、解析和校验 ARB，提供稳定的 locale 与消息
   查询接口。
2. `LinuxMetadataRenderer` 负责把模板中的字段级标记替换为完整多语言块，并验证输出
   不存在残留标记或语言集合漂移。

`render-packaging-templates.sh` 继续负责架构、版本、路径、应用身份和包格式参数；它只
传入 `stable/nightly` 渠道，不再认识任何具体语言。

## 8. 模板约定

模板只允许字段级标记，不允许具体语言行：

```ini
[Desktop Entry]
@LOCALIZED_DESKTOP_NAME@
@LOCALIZED_DESKTOP_GENERIC_NAME@
@LOCALIZED_DESKTOP_COMMENT@
@LOCALIZED_DESKTOP_KEYWORDS@
```

```xml
<component type="desktop-application">
@LOCALIZED_APPSTREAM_NAME@
@LOCALIZED_APPSTREAM_SUMMARY@
  <description>
@LOCALIZED_APPSTREAM_DESCRIPTION@
  </description>
</component>
```

禁止在模板中重新出现：

- `Name[ru]=...`
- `<summary xml:lang="es">...</summary>`
- `@DISPLAY_NAME_RU@`
- 任何 `_RU/_ES/_FR/_DE` 语言专用占位符。

## 9. 新增语言的强制流程

以后每次新增语言必须按以下步骤执行，不得直接修改 Desktop Entry、AppStream 或打包
Shell：

1. 从模板 ARB 创建 `app_<locale>.arb`。
2. 设置与文件名一致的 `@@locale`，并填写正确的 `@@linuxDesktopLocale` 和
   `@@appStreamLocale`；不要通过字符替换猜测 script/country 映射。
3. 翻译全部消息，包括本族语名称和六个 Linux 元数据键；普通新增语言不得设置
   `@@linuxMetadataFallback`。
4. 运行本地化资源校验。
5. 运行 `flutter gen-l10n` 并提交生成源码。
6. 分别渲染 Stable 与 Nightly 元数据。
7. 对渲染结果运行通用语言集合校验、`desktop-file-validate` 和
   `appstreamcli validate --no-net`。
8. 至少在该语言 locale 下人工检查设置页、窗口标题、启动器名称、应用搜索关键词、
   系统通知和 AppStream 展示。

新增语言时禁止修改：

- `lib/core/i18n/app_locale.dart` 的语言列表。
- `MaterialApp.supportedLocales`。
- `render-packaging-templates.sh` 中的语言变量。
- Desktop/AppStream 模板中的具体 locale 行。
- Stable/Nightly smoke test 中的具体语言断言。

如果新增语言需要修改上述位置，说明自动发现或生成边界已经退化，必须先修复生成
架构，不能继续复制分支。

## 10. 验证与发布门禁

每次涉及 ARB、模板或生成器的变更至少执行：

```bash
dart run build/scripts/verify_localization_resources.dart
flutter gen-l10n
bash build/scripts/verify-generated-sources.sh

bash build/scripts/render-packaging-templates.sh \
  --inner --version 0.0.0 --arch amd64 --channel stable \
  --output-dir /tmp/linglong-store-metadata-stable

bash build/scripts/render-packaging-templates.sh \
  --inner --version 0.0.0-nightly.20260731+local --arch amd64 \
  --channel nightly --output-dir /tmp/linglong-store-metadata-nightly
```

随后对两个输出目录执行 Desktop Entry、AppStream 和语言集合验证。发布构建必须使用
同一 ARB Git 基线，禁止从未提交或不同版本的翻译资源生成包。

## 11. 迁移范围

本次迁移包括：

1. 为四个现有 ARB 补齐六个 Linux 元数据键。
2. 抽取共享 ARB 目录读取与严格校验能力。
3. 新增通用 Linux 元数据渲染器。
4. 把三个模板迁移为字段级生成标记。
5. 删除 Shell 中的俄语专用变量和替换逻辑。
6. 把 Stable/Nightly 测试从俄语字面量改为通用结构验证。
7. 删除构建 bundle 内无渠道、未渲染的 AppStream 模板副本，防止占位符进入产物。
8. 清理仍可能向用户显示中文兜底的 Presentation 路径，并把缺失的用户文案补入
   全部 ARB。

迁移完成后，新增第五种语言的人工配置面只剩一个 ARB 文件；Flutter 生成源码属于
确定性生成物，Linux 模板和打包脚本不再随语言数量增长。
