# UOS 开发者模式提示设计

## 背景

在 UOS 上，玲珑环境安装和应用安装会额外受到系统开发者模式与权限配置影响。用户如果没有提前打开开发者模式，常见现象是：

- 启动阶段环境安装无法成功；
- 后续应用安装失败，但失败文案无法明确指向 UOS 前置条件。

本次需求要求在 **真正影响用户决策的两个节点** 给出明确提示，避免用户反复重试仍不知道前置条件。

同时，本次实现已从单一 `isUos` 判断重构为 **Linux 发行版画像 + 特殊提示场景** 的统一模型，后续再为其他发行版补充特殊提示或特殊适配时，无需继续复制 `isDeepin`、`isUbuntu` 这类散落判断。

## 用户确认的交互范围

### 1. 环境安装弹窗

只要检测到当前系统为 UOS，并且启动流程进入 `LinglongEnvDialog` 的环境安装提示态，就展示 UOS 专属提示：

- 需要打开系统开发者模式；
- 当前账号需要可获取 `root` 权限；
- 办公设备建议先咨询 IT。

### 2. 应用安装失败

当用户在 UOS 上安装玲珑应用失败时，失败文案要补充开发者模式提醒。

这里 **只覆盖 install 失败，不覆盖 update 失败**，这是当前产品范围内确认过的行为边界。

## 实现落点

## 1. 系统识别

文件：`lib/application/services/linux_distribution_resolver.dart`

- 统一读取 `/etc/os-release` 的结构化字段；
- 通过 `LinuxDistributionResolver` 解析为 `LinuxDistribution` 画像；
- 当前已内建 UOS 规则，未来其他发行版只需要在同一解析器中新增 matcher 和画像。

环境检测服务 `lib/application/services/linglong_environment_service.dart` 只负责调用解析器并透传结果，不再自己维护 `isUos` 这类布尔分支。

## 2. 结构化结果

文件：`lib/domain/models/linglong_env_check_result.dart`

- 新增 `distribution` 字段；
- 所有环境检测结果都携带统一的发行版画像，而不是继续扩散 `isUos` 之类一次性字段。

## 3. 启动弹窗提示

文件：`lib/presentation/widgets/linglong_env_dialog.dart`

- 弹窗不再直接判断 `isUos`；
- 统一根据 `distribution + guidance scenario` 解析提示内容；
- 文案走 l10n，禁止在多个页面重复维护一套发行版说明。

对应文案键：

- `uosEnvInstallHint`

## 4. 安装失败提示收口

文件：`lib/application/providers/install_queue_provider.dart`

- 失败提示统一收口在 `InstallQueue.markFailed()`；
- 读取 `linglongEnvProvider.result?.distribution` 获取当前发行版画像；
- 根据 `task kind -> guidance scenario` 统一决定是否追加提示；
- 当前 UOS 仅覆盖 `appInstallFailure`，`appUpdateFailure` 仍为空规则，因此 update 失败不会误追加。

这样做的原因是：

- `DownloadManagerDialog`、`AppDetailPage` 等多个展示面都依赖队列失败状态；
- 如果在页面层各自拼文案，后续容易出现漏改、重复提示或文案漂移。

对应文案键：

- `uosAppInstallFailureHint`

## 5. 国际化与去重

文件：`lib/core/i18n/install_messages.dart`

- 增加 `guidanceForDistribution()` 与 `appendDistributionGuidance()` 统一入口；
- 当前内部仍映射到 UOS 文案键，但调用方已不再感知具体发行版名称。

## 测试覆盖

### 单元测试

- `test/unit/application/services/linux_distribution_resolver_test.dart`
  - 验证发行版 matcher 能从 `ID / NAME / PRETTY_NAME / ID_LIKE` 解析结构化画像；
  - 验证普通发行版不会被误判为特殊适配发行版。

- `test/unit/application/services/linglong_environment_service_test.dart`
  - 验证 UOS 识别会正确解析为带能力标签的发行版画像。

- `test/unit/application/providers/install_queue_distribution_guidance_test.dart`
  - 验证带特殊画像的发行版在 install 失败时会追加提示；
  - 验证未支持的失败场景不会误追加；
  - 验证普通发行版不会被误伤。

### Widget 测试

- `test/widget/presentation/widgets/linglong_env_dialog_test.dart`
  - 验证环境安装弹窗在有适配规则的发行版场景会展示提示；
  - 验证普通发行版不会误显示特殊提示。

## 当前约定

1. 发行版识别必须继续走 `LinuxDistributionResolver`，不要在页面里直接读 `/etc/os-release`。
2. 环境安装提示只在 `LinglongEnvDialog` 展示，不要在启动页其他位置复制一份提示。
3. 安装失败提示统一在 `InstallQueue.markFailed()` 收口，不要在 `DownloadManagerDialog`、`AppDetailPage` 等页面组件里二次拼接。
4. 新增发行版特殊提示时，优先补：`LinuxDistribution` 画像 → resolver matcher → `InstallMessages` 场景映射，禁止重新引入散落的 `isXxx` 条件。

## 给下一位 AI / 维护者的最短理解路径

如果你刚接手这块逻辑，建议按下面顺序阅读，基本可以在几分钟内看懂设计：

1. `lib/domain/models/linux_distribution.dart`
  - 看“发行版画像、能力标签、guidance scenario”这三个概念是怎么拆开的；
2. `lib/application/services/linux_distribution_resolver.dart`
  - 看 `/etc/os-release` 是如何被收敛成统一画像的；
3. `lib/domain/models/linglong_env_check_result.dart`
  - 看环境检测结果如何把发行版画像透传到后续链路；
4. `lib/core/i18n/install_messages.dart`
  - 看“distribution + scenario -> 最终文案”的唯一映射点；
5. `lib/presentation/widgets/linglong_env_dialog.dart`
  - 看启动环境弹窗如何消费 `envInstallDialog` 场景；
6. `lib/application/providers/install_queue_provider.dart`
  - 看安装失败文案如何在队列层统一追加发行版 guidance。

如果你要新增另一个发行版的特殊提示，请不要从页面开始改，而是先沿着上面的顺序补齐，再跑现有测试。

## 验证结果

本次改动已完成：

- 定向 `flutter analyze`：`No issues found!`
- 相关单测与 Widget 测试：`All tests passed!`