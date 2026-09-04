# Linux 应用身份单一配置源设计

## 1. 背景

玲珑应用商店当前已经把 Linux 主应用身份统一为
`com.dongpl.linglong-store.v2`，并使用
`com.dongpl.linglong-store.v2.desktop` 作为 canonical desktop ID。为了兼容
历史安装入口，Stable 和 Nightly 还分别安装隐藏的兼容 desktop 文件。

目前这些身份信息仍散落在多个技术层：

| 技术层 | 当前职责 | 现存问题 |
| --- | --- | --- |
| Dart | XDG 目录、MethodChannel 名称 | 保存了应用 ID 或由它派生的字符串字面量 |
| CMake | GTK `GApplication` ID | 独立维护应用 ID |
| C++ | Linux 系统通知 MethodChannel | 独立维护完整通道名称 |
| 打包渲染脚本 | canonical desktop ID、Stable/Nightly 兼容 desktop ID、WM Class | 脚本内重新声明身份 |
| AUR 发布与校验脚本 | 选择和校验 desktop 文件 | 再次保存相同文件名 |
| 清理与 smoke 脚本 | 构造 XDG 路径、校验打包产物 | 测试代码重复产品身份字面量 |

这会带来两个维护问题：

1. 修改应用身份时必须同时修改多个语言和构建入口，容易漏改。
2. 测试可能只验证自己复制的旧常量，无法发现配置源之间已经漂移。

系统通知功能需要让 GTK Application ID、desktop ID、AppStream launchable
和 MethodChannel 同时保持一致，因此进一步放大了这种分散带来的修改面。

## 2. 设计目标

本次重构需要满足以下目标：

1. 仓库内只有一个可人工编辑的当前应用身份配置源。
2. canonical desktop ID、WM Class、XDG 命名空间和系统通知通道必须从应用
   ID 推导，不允许作为第二份独立配置存在。
3. Stable 与 Nightly 的兼容 desktop ID 必须显式配置，并允许未来增加多个
   兼容别名。
4. Dart、CMake、C++ 和 Shell 消费到的值必须来自同一个配置源。
5. 普通 `flutter run`、`flutter analyze` 和 IDE 分析不能依赖 `jq`、`yq`
   或运行时读取仓库文件。
6. 打包脚本读取配置时不得执行配置文件中的 Shell 代码。
7. 配置和生成物漂移时必须尽早失败，不能继续产出身份不一致的软件包。
8. 本次重构不改变现有 Stable/Nightly 安装行为、XDG 路径、协议入口或包名。

## 3. 非目标

以下内容不纳入当前应用身份配置：

1. Debian、RPM、AUR 和 AppImage 的包名。包名属于发行渠道属性，不等于
   Linux 应用身份。
2. Flutter 可执行文件名和发布压缩包名称。它们属于构建产物布局。
3. `org.linglong-store.LinyapsManager` 等历史数据目录 ID。历史 ID 是迁移
   规则的一部分，必须保留在迁移或清理代码中并注明来源，不能伪装成当前
   应用别名。
4. `og://` 协议的业务语义。协议声明继续由 desktop 模板负责，本次只保证
   兼容 desktop 文件名由统一身份配置提供。
5. 在运行时根据发行版或桌面环境切换身份。应用身份在构建时固定，所有
   Linux 发行版使用同一套 Freedesktop/GLib 语义。

## 4. 候选方案

### 4.1 直接使用 Shell 环境文件

所有脚本通过 `source application-identity.env` 读取配置，再让 Dart 和
CMake 保留自己的常量。

优点是实现简单；缺点是配置文件可以执行任意 Shell 代码，而且 Dart/CMake
仍然存在副本，不能真正解决单一来源问题，因此不采用。

### 4.2 使用 JSON、YAML 或 TOML

结构化格式有成熟语义，但当前构建链最早阶段不能保证存在 `jq`、`yq` 或
特定版本的 Python。CMake 最低版本为 3.13，也不能依赖较新版本才提供的
JSON 解析能力。为了读取少量稳定字段引入新的 bootstrap 依赖不划算，因此
不采用。

### 4.3 严格声明文件加生成适配器

使用受限的 `KEY=VALUE` 声明文件保存不可推导的身份事实。Shell 通过严格
解析器读取；Dart 和 CMake 使用由生成器产生并提交到仓库的类型化适配文件。

该方案具备以下特点：

- 配置文件只允许数据，不能执行命令。
- 不给正常 Flutter 开发流程增加前置依赖。
- 生成物可以在代码审查中看到，并通过 `--check` 验证是否最新。
- C++ 继续使用 CMake 注入的 `APPLICATION_ID`，无需增加第三份生成头文件。

本项目采用此方案。

## 5. 唯一配置源

新增仓库级配置：

```text
config/application_identity.conf
```

配置只包含不可推导的字段：

```ini
APPLICATION_ID=com.dongpl.linglong-store.v2
STABLE_COMPAT_DESKTOP_IDS=linglong-store.desktop
NIGHTLY_COMPAT_DESKTOP_IDS=linglong-store-nightly.desktop
```

兼容 desktop ID 使用英文逗号分隔。当前每个渠道只有一个兼容 ID，但数据
结构允许未来在不修改消费者接口的情况下增加别名。

### 5.1 字段约束

`APPLICATION_ID` 必须：

- 使用反向 DNS 形式。
- 至少包含两个点分段。
- 每个分段只能包含 ASCII 字母、数字、下划线或连字符。
- 不能以点、连字符或下划线开头、结尾。

兼容 desktop ID 必须：

- 以 `.desktop` 结尾。
- 只包含 ASCII 字母、数字、点、下划线或连字符。
- 列表中不能有空项或重复项。
- 不能等于 canonical desktop ID。
- Stable 和 Nightly 列表之间不能重复。

配置解析器还必须拒绝：

- 未知字段。
- 重复字段。
- 缺失字段。
- 引号、变量展开、命令替换和行内注释。
- 包含换行、空白或路径分隔符的值。

## 6. 派生身份

所有可以由 `APPLICATION_ID` 唯一确定的值都不再配置：

| 派生项 | 规则 | 当前结果 |
| --- | --- | --- |
| canonical desktop ID | `${APPLICATION_ID}.desktop` | `com.dongpl.linglong-store.v2.desktop` |
| GTK Application ID | `${APPLICATION_ID}` | `com.dongpl.linglong-store.v2` |
| XDG 应用命名空间 | `${APPLICATION_ID}` | `com.dongpl.linglong-store.v2` |
| WM Class | `${APPLICATION_ID}` | `com.dongpl.linglong-store.v2` |
| AppStream launchable | canonical desktop ID | `com.dongpl.linglong-store.v2.desktop` |
| 系统通知通道 | `${APPLICATION_ID}/system_notification` | `com.dongpl.linglong-store.v2/system_notification` |
| 系统强调色通道 | `${APPLICATION_ID}/system_accent_color` | `com.dongpl.linglong-store.v2/system_accent_color` |

禁止为了调用方便把这些派生结果重新写回身份配置。

## 7. 组件设计

### 7.1 Shell 严格读取器

新增：

```text
build/scripts/lib/application-identity.sh
```

读取器负责：

1. 按行读取声明文件，不使用 `source` 或 `eval`。
2. 校验字段集合、值格式、必填项和跨字段约束。
3. 导出只读语义变量：
   - `APPLICATION_ID`
   - `CANONICAL_DESKTOP_ID`
   - `STABLE_COMPAT_DESKTOP_IDS`
   - `NIGHTLY_COMPAT_DESKTOP_IDS`
   - `WM_CLASS`
   - `SYSTEM_NOTIFICATION_CHANNEL`
   - `SYSTEM_ACCENT_COLOR_CHANNEL`
4. 提供按发行渠道选择兼容 desktop ID 列表的公共函数。
5. 所有错误写入 stderr，并返回非零退出码。

打包、发布、清理和 smoke 脚本只允许通过该读取器取得当前身份。

### 7.2 生成器

新增：

```text
build/scripts/generate-application-identity.sh
```

生成器支持：

```bash
./build/scripts/generate-application-identity.sh
./build/scripts/generate-application-identity.sh --check
```

默认模式原子更新生成文件；`--check` 只比较内容，不修改工作区。生成过程先
写临时文件，内容完整后再替换目标，避免中断时留下半个文件。

生成目标：

```text
lib/core/config/generated/application_identity.g.dart
linux/generated/application_identity.cmake
```

两个生成文件都必须包含：

- 中文文件级说明。
- 明确的“由生成器产生，请勿手工修改”标识。
- 配置源相对路径。

### 7.3 Dart 适配器

Dart 生成文件提供不可实例化的常量类，至少包含：

- `applicationId`
- `canonicalDesktopId`
- `systemNotificationChannel`
- `systemAccentColorChannel`
- Stable/Nightly 兼容 desktop ID 常量列表

`AppXdgPaths`、`LinuxSystemNotificationGateway` 和
`LinuxSystemAccentColorGateway` 通过该类读取身份，不再保存字面量。

生成文件不负责发行渠道判断，避免把打包逻辑带入应用运行时。

### 7.4 CMake 与 C++

`linux/CMakeLists.txt` 引入生成的 CMake 文件，并在创建 runner 前检查
`APPLICATION_ID` 非空。

runner 继续把 `APPLICATION_ID` 作为编译定义传入 C++。系统通知通道改为：

```cpp
APPLICATION_ID "/system_notification"
```

系统强调色 EventChannel 同规则派生（`linux/runner/system_accent_color_channel.cc`）：

```cpp
APPLICATION_ID "/system_accent_color"
```

C/C++ 字符串字面量在编译期完成拼接，因此不会引入运行时分配，也无需再
生成 C++ 头文件。

### 7.5 打包渲染与发行脚本

`render-packaging-templates.sh` 通过公共读取器获得：

- application ID
- canonical desktop ID
- WM Class
- 当前渠道兼容 desktop ID 列表

Deb、RPM、AppImage 打包脚本继续消费渲染目录中的实际文件，不重新推导文件
名。AUR 发布和校验脚本使用公共读取器，避免再次声明 canonical/compat ID。

当一个渠道配置多个兼容 desktop ID 时，渲染器应为每个别名生成一个隐藏
desktop 文件；打包脚本应完整安装这些文件，不能假设永远只有一个别名。

### 7.6 清理脚本

`clear-local-data.sh` 使用公共读取器得到当前 `APPLICATION_ID`，再按 XDG
规范构造当前数据目录。

历史目录列表继续在清理脚本中显式维护，因为它们不是当前身份的派生值。

## 8. 生成物与漂移控制

生成文件虽然提交到 Git，但不属于人工配置源。它们必须满足：

1. 文件头标记生成来源。
2. 代码评审禁止直接修改生成文件。
3. release、nightly 和本地验证入口执行生成器 `--check`。
4. `--check` 失败时输出需要重新生成的文件，并返回非零。
5. 生成器连续执行两次不得产生差异。

这样可以兼顾 Flutter/CMake 的开箱即用与真正的单一人工配置源。

## 9. 遗留 Linux runner 文件

当前 CMake 只编译 `linux/runner/main.cc`、`linux/runner/my_application.cc` 和
`linux/runner/system_notification_channel.cc`。仓库根部仍存在未进入构建的
`linux/my_application.cc` 与 `linux/my_application.h`，其中旧实现还保存了
应用 ID 字面量。

迁移时应再次通过 CMake 和全仓引用检查确认它们没有消费者，然后在独立
重构提交中删除。不能通过同步修改死文件来制造“已统一”的假象。

## 10. 迁移步骤

### 阶段一：建立配置和生成链

1. 新增身份声明文件。
2. 新增严格 Shell 读取器。
3. 新增生成器及 Dart/CMake 生成物。
4. 验证生成器幂等和 `--check` 行为。

此阶段不改变现有消费者，便于单独检查基础设施。

### 阶段二：迁移运行时

1. `AppXdgPaths` 改读生成的 Dart 身份类。
2. Linux 通知 gateway 改读生成的通道常量。
3. CMake 改为引入生成配置。
4. C++ 通知通道从编译定义派生。

迁移后运行时行为必须与迁移前完全一致。

### 阶段三：迁移打包和运维脚本

1. 打包模板渲染器使用公共读取器。
2. AUR 发布、校验脚本使用公共读取器。
3. release/nightly/package smoke 脚本从统一身份构造期望值。
4. 本地数据清理及其 smoke 脚本使用统一应用 ID。
5. 移除脚本中的当前身份重复字面量。

### 阶段四：清理死代码和固化约定

1. 删除确认未使用的 Linux runner 遗留文件。
2. 更新 `AGENTS.md`，要求后续身份修改只能从声明文件进入。
3. 全仓搜索当前身份字面量；文档、生成物、安装示例和迁移说明以外不得存在
   人工维护的重复定义。

## 11. 验证策略

不为了覆盖率增加与业务无关的单元测试，只验证真实风险边界：

1. 运行生成器，并执行 `--check`。
2. 对非法字段、重复字段、非法 desktop ID 做脚本级失败验证。
3. 分别渲染 Stable 和 Nightly 元数据。
4. 验证 canonical desktop 文件始终存在且可见。
5. 验证每个兼容 desktop 文件隐藏、保留 `og://` handler，并指向相同程序。
6. 验证 AppStream launchable 始终指向 canonical desktop ID。
7. 执行 release/nightly/package smoke。
8. 执行本地数据清理 smoke，确认当前 XDG 目录和历史目录语义不变。
9. 执行 `flutter analyze`。
10. 执行 Linux debug 或 release 构建，确认 CMake 生成配置和 C++ 字符串拼接
    可以通过编译。

## 12. 性能与可靠性

- 身份解析和生成只发生在构建、打包或维护脚本阶段，不进入 UI 热路径。
- Dart 侧仍使用编译期常量，不增加文件 IO、异步初始化或 Provider 订阅。
- C++ 通知通道在编译期拼接，不增加运行时分配。
- 打包失败优先于产出身份不一致的软件包。
- 配置读取不使用外部解析器，避免不同发行版构建环境的工具版本差异。

## 13. 回滚策略

各阶段独立提交。如果迁移中的某个消费者出现问题，可以回退对应阶段，而不
需要撤销已经验证的身份配置基础设施。

配置值在本次重构中保持不变，因此回滚不涉及用户数据迁移、desktop 数据库
重建或协议默认处理器变更。

## 14. 验收标准

完成后必须满足：

1. 当前应用 ID 只在身份声明文件中人工定义。
2. canonical desktop ID、WM Class、XDG 命名空间和通知通道没有独立配置。
3. Stable/Nightly 兼容 desktop ID 只在身份声明文件中人工定义。
4. Dart、CMake、C++、打包、AUR 和清理脚本均消费统一身份。
5. 修改声明文件但未更新生成物时，验证流程明确失败。
6. Stable/Nightly 打包产物和现有用户行为没有变化。
7. 已确认无用的旧 Linux runner 文件不再保留身份字面量。
