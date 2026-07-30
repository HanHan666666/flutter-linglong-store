# Flutter 应用架构

> 当前版本：2.0<br>
> 校准日期：2026-07-30<br>
> 适用范围：玲珑应用商店 Linux 桌面客户端

## 1. 文档定位

本文描述当前代码已经采用的分层、依赖装配、启动流程、核心状态机和开发边界。
它是新增功能和结构调整时的总入口，不再保留迁移初期的假想目录、依赖版本副本或
已失效的 CI 示例。

专项业务细节由 `docs/` 下对应设计文档维护。本文只说明模块如何协作，以及修改一类
能力时应该落在哪一层。

## 2. 架构目标

项目只面向 Linux 桌面，核心约束如下：

1. Presentation 保持高响应，不在 Widget `build` 中执行 IO、解析或大规模聚合。
2. Application 编排用例和状态机，优先依赖 Domain 端口，不创建具体基础设施。
3. Domain 保存稳定业务事实和接口，不依赖 Flutter UI、Data 或 Platform。
4. Data 负责 HTTP、`ll-cli`、持久化格式和外部数据到 Domain 的转换。
5. Platform 封装 Linux 桌面与系统能力，不把发行版判断散落到业务层。
6. 所有生产依赖在根部一次装配，测试按触达范围覆盖端口。
7. 可恢复事实先持久化，再执行通知、统计、自动运行等外部副作用。
8. 生成源码完整提交并由 CI 重放校验，干净检出可以直接分析和构建。

## 3. 当前分层

```text
main.dart / app.dart
        │
        ▼
bootstrap/  ────────────────┐
        │                   │ 创建具体实现
        ▼                   ▼
presentation/ ───────► application/ ───────► domain/
        │                   │                  ▲
        │                   │                  │ 实现端口
        │                   ▼                  │
        └────► core/      core/              data/
                    平台与通用设施              │
                                                ▼
                                             core/platform/

platform/notifications/ ─────────────────────► domain/
```

### 3.1 稳定依赖规则

- `domain/` 不得导入 `application/`、`data/`、`platform/` 或 `presentation/`。
- Repository、Journal 和系统通知的接口放在 `domain/repositories/`。
- 具体 Repository 只在 `data/repositories/` 实现。
- Linux 系统通知等独立平台适配放在 `platform/`，并实现 Domain 端口。
- `application/providers/application_dependency_providers.dart` 只声明外部端口，
  不创建 Data 或 Platform 实现。
- `bootstrap/production_dependency_overrides.dart` 是生产实现的唯一组合根。
- Presentation 优先只读取 Application Provider，并通过轻量 props 驱动子组件。

### 3.2 Core 的实际定位

`core/` 是当前项目的共享基础设施集合，不是一个独立业务层：

- `core/config`：路由、主题、应用配置、生成的应用身份；
- `core/network`：Dio 初始化、拦截器和网络异常；
- `core/storage`：XDG 路径、偏好、缓存和本地身份；
- `core/platform`：命令执行、窗口、单实例、渲染器和本地路径打开；
- `core/i18n`：ARB 生成物和结构化状态到当前语言文案的格式化；
- `core/accessibility`：语义、焦点、键盘和字体缩放基础组件；
- `core/logging`、`core/security`、`core/migrations`：跨业务基础能力。

路由配置会引用 Presentation 页面，部分 Application 服务仍直接复用
`core/platform` 执行器。这是当前已知的受控依赖，不应被描述成 Domain/Data
标准依赖。新增可替换系统能力时，应优先定义端口并由组合根注入；不要继续扩大
Application 对具体平台类的直接依赖。

### 3.3 当前迁移例外

以下依赖仍是后续治理候选，但不阻塞当前结构：

- 列表类 Provider 仍直接使用 `data/models/api_dto.dart` 和部分 mapper；
- 环境管理、引导修复和渲染设置仍直接使用 `core/platform` 能力；
- 少量 Presentation 组件直接打开本地路径、同步窗口状态或读取 API DTO；
- `core/config/routes.dart` 同时承担路由组合职责并引用 Presentation。

修改这些区域时，应就近把 DTO 转换、平台端口或路由组合边界收敛，禁止新增第二套
类似依赖。不要为了追求目录纯度一次性重写稳定业务。

## 4. 目录职责

```text
lib/
├── main.dart
├── app.dart
├── bootstrap/
│   └── production_dependency_overrides.dart
├── application/
│   ├── mappers/
│   ├── providers/
│   └── services/
├── domain/
│   ├── models/
│   └── repositories/
├── data/
│   ├── datasources/remote/
│   ├── mappers/
│   ├── models/
│   ├── persistence/
│   └── repositories/
├── platform/
│   └── notifications/
├── core/
│   ├── accessibility/
│   ├── config/
│   ├── i18n/
│   ├── logging/
│   ├── migrations/
│   ├── network/
│   ├── platform/
│   ├── protocol/
│   ├── security/
│   ├── storage/
│   └── utils/
└── presentation/
    ├── helpers/
    ├── mixins/
    ├── pages/
    └── widgets/
```

### 4.1 Bootstrap

`main.dart` 只处理进程级启动顺序，`bootstrap/` 负责把生产基础设施绑定到
Application 端口。禁止在业务 Provider 中通过默认值偷偷创建 Repository。

生产组合根当前注入：

- `SharedPreferences`；
- 商店 API、匿名统计、错误解决方案 Repository；
- `LinglongCliRepository` 和仓库管理端口；
- XDG App Operation Journal；
- 旧队列迁移 Repository；
- Linux 系统通知 Gateway。

测试不需要复制完整组合根，只覆盖测试实际触达的端口。未注入端口会抛出包含
Provider 名称的确定性错误。

### 4.2 Domain

Domain 保存跨 UI 和基础设施稳定的业务语言：

- 应用、版本、评论、运行实例；
- 安装进度、任务、队列和状态机；
- 更新批次、目标快照、Outbox effect；
- 结构化操作失败和 `ll-cli` 失败；
- 环境检查、仓库配置和修复结果；
- 系统通知请求；
- Repository 和 Gateway 接口。

Domain 模型可使用 Freezed 和 JSON 注解，但源文件不得依赖生成器的具体实现逻辑。
展示文案、`BuildContext`、Dio、进程对象和文件路径不属于 Domain。

### 4.3 Data

Data 负责外部格式：

- Retrofit/Dio 接口和 API DTO；
- `ll-cli --json` 调用与结构化输出解析；
- DTO/CLI 结果到 Domain 模型的映射；
- XDG Journal 原子读写；
- 旧 SharedPreferences 队列迁移；
- latest-wins 持久化写入队列。

Data 不决定 UI 文案。空结果、命令失败和解析失败必须使用 Domain 可区分的返回类型，
不能继续用空列表或任意字符串混合表达。

### 4.4 Application

Application 负责用例、状态发布和跨端口编排：

- 启动序列；
- 应用列表、详情、搜索、推荐、排行和更新状态；
- 安装、更新、取消、恢复和一键更新；
- 卸载统一流程；
- 忽略更新；
- 生命周期 Outbox 副作用；
- 环境分析与修复；
- 安装错误解决方案和引导修复；
- `og://` 协议安装控制器。

Riverpod Provider 是应用状态和 UI 的连接方式，不等于可以把全部逻辑堆在
Notifier 中。纯转换进入 service/reducer，单任务资源生命周期进入 executor，
对外依赖通过端口读取。

### 4.5 Presentation

Presentation 只负责：

- 读取和选择 Application 状态；
- 把当前状态转换为界面 props；
- 管理焦点、动画、控制器等局部 UI 生命周期；
- 收集用户意图并调用 Application 入口；
- 使用当前 locale 渲染结构化状态。

复杂页面采用四类协作者：

1. 页面或弹窗容器：单次聚合 Provider 和局部生命周期；
2. Actions/Flow：异步交互编排，不长期保存 `BuildContext`；
3. Logic/ViewData：无副作用派生和轻量展示数据；
4. Section/Widget：只接收状态与回调的纯展示组件。

当前已按此模式拆分：

- `presentation/pages/app_detail/`；
- `presentation/widgets/download_manager/`；
- `presentation/widgets/linglong_environment_management/`。

## 5. 启动与根生命周期

`main(List<String> arguments)` 的固定顺序：

1. 初始化 Flutter binding 和图片缓存上限；
2. 初始化日志；
3. 解析冷启动 `og://` 参数；
4. 完成单实例仲裁；
5. 初始化窗口；
6. 在任何数据服务之前执行 XDG 数据迁移；
7. 初始化 SharedPreferences；
8. 初始化生产 API Client；
9. 初始化缓存；
10. 显示窗口并注册退出信号；
11. 创建带生产依赖覆盖的根 `ProviderScope`；
12. 运行 `LinglongStoreApp`。

`LinglongStoreApp` 负责主题、语言、字体缩放、无障碍根节点、路由和运行期
`og://` 桥接。平台协议只把 URL 交给 `OgInstallController`，安装仍必须进入统一
操作队列。

### 5.1 业务启动序列

`LaunchSequence` 依次执行：

```text
环境检测
  → 后台预热本地搜索索引
  → 已安装应用初始化
  → 更新检查
  → 操作队列恢复
  → 启动常驻生命周期协调器
  → 完成并进入主界面
```

搜索索引预热和部分统计准备可以并发，但不得改变进入主界面的前置事实。
环境不可用时停留在可诊断状态，不允许假装启动成功。

## 6. 应用操作架构

安装、更新和一键更新共用 `installQueueProvider` 所管理的同一状态：

```text
用户意图
  → AppOperationQueueController
  → InstallQueue
      ├── AppOperationQueueReducer
      ├── AppOperationBatchReducer
      ├── AppOperationTaskExecutor
      ├── AppOperationRecoveryService
      ├── AppOperationStateStore
      └── AppOperationPersistenceBarrier
  → XDG Journal
  → AppOperationLifecycleCoordinator
      ├── 列表同步
      ├── 匿名统计
      ├── 安装后自动运行
      └── 一键更新系统通知
```

### 6.1 状态与持久化

队列、当前任务、历史、批次和 Outbox 统一写入：

```text
$XDG_STATE_HOME/com.dongpl.linglong-store.v2/operations/queue-v2.json
```

不存在 `XDG_STATE_HOME` 时由 `AppXdgPaths` 按 XDG 规则解析回退路径。业务层禁止
拼接 `$HOME`、发行版专有路径或另建一份队列状态。

Journal 使用 latest-wins 合并写：

- 最多一个正在写入的快照；
- 最多一个可被更新状态替换的等待快照；
- 普通进度先更新内存，不阻塞 UI；
- 任务启动、任务终态和 Outbox 消费使用持久化屏障；
- 屏障完成表示该状态或更新状态已经原子落盘。

### 6.2 单任务执行

`AppOperationTaskExecutor` 一次只拥有一个任务，负责：

- 选择 `installApp` 或 `updateApp`；
- 消费结构化 CLI 进度；
- 维护超时状态机；
- 把进度、超时、流异常和无终态结束转换为携带 taskId 的事件；
- 精确取消当前任务；
- 释放计时器和流生命周期。

Executor 不读取或修改全局队列。`InstallQueue` 根据 taskId 接受事件，防止旧任务
回调覆盖新任务。

### 6.3 批次和通知

一键更新在入队时创建包含完整目标快照的 `AppOperationBatch`。完成状态只由该批次
自己的 taskId 全部进入终态推导，禁止用“全局队列为空”判断。

批次完成先形成持久化 Outbox effect，再由常驻
`AppOperationLifecycleCoordinator` 消费。系统通知链路为：

```text
UpdateBatchNotificationPolicy
  → SystemNotificationGateway
  → Linux MethodChannel
  → GNotification
  → Freedesktop 通知服务
```

该实现不判断 Deepin、Debian、Ubuntu 或 Fedora，不调用 `notify-send`，依赖 Linux
桌面通用通知协议。通知失败或用户关闭通知不改变更新任务结果。

详细协议见：

- `docs/25-update-batch-system-notification.md`
- `docs/27-architecture-remediation-roadmap.md`
- `docs/29-app-operation-queue-decomposition-design.md`

## 7. 结构化错误与本地化

错误边界遵循：

```text
Data：解析外部失败
  → Domain：稳定类别、阶段、退出码、诊断事实
  → Application：状态迁移、重试和恢复决策
  → Presentation/core/i18n：按当前 locale 生成文案
```

持久化状态不保存新的本地化展示策略。旧 Journal 的历史文案只用于兼容读取，
新状态优先保存 `AppOperationFailure`。

`InstallTask.commandOutput` 是下载中心和详情页“复制日志”的唯一来源；
`diagnosticMessage` 是错误帮助查询的来源。UI 不得回退拼接另一份日志或错误文本。

详细设计见 `docs/31-structured-cli-error-and-i18n-boundary-design.md`。

## 8. 玲珑环境管理

上层唯一入口是 `LinglongEnvironmentManagementService`。内部按变化原因拆分为：

- `LinglongEnvironmentProbe`：只读命令和输出解析；
- `LinglongEnvironmentHealthAnalyzer`：健康问题分类；
- `LinglongOstreeRepairService`：本地数据修复；
- `LinglongDataPermissionRepairService`：目录权限修复；
- `LinglongStorageMigrationService`：systemd bind mount 保存位置迁移；
- `LinglongManagementCommandWorkspace`：XDG 日志和临时脚本生命周期。

Provider 和 Presentation 不得复制 Shell 命令、脚本正文或兼容判断。界面只通过
`LinglongEnvironmentManagementActions` 编排确认、调用和反馈，各 Tab 保持纯展示。

详细设计见：

- `docs/21-linglong-environment-management.md`
- `docs/32-linglong-environment-management-service-decomposition.md`
- `docs/33-linglong-environment-management-dialog-decomposition.md`

## 9. Presentation 性能边界

### 9.1 Provider 订阅

- 页面级容器聚合全局 Provider，再向卡片和 Section 下发轻量 props；
- 使用 `select` 缩小重建字段；
- 高频状态只有真正展示时才订阅；
- 子组件不得为方便而重复订阅安装队列、网速或全局偏好；
- 异步回调返回后先检查 `context.mounted`。

应用详情页只在已安装时订阅更新列表、存在任务时订阅安装文案、安装中且 CLI
未提供速度时订阅系统网速。

### 9.2 列表和缓存

- 大列表使用 builder；
- API DTO 解析和排序不在 `build` 中执行；
- 页面缓存 key 必须包含 locale；
- KeepAlive 页面使用 LRU，上限 10；
- 隐藏页面暂停滚动监听、自动补页和轮询；
- 页面恢复只做轻量刷新；
- 应用图片使用统一缓存，不自行创建无上限缓存。

### 9.3 无障碍

新交互优先使用 `core/accessibility/` 中的 A11y 组件。装饰性图标排除语义，
列表区域、加载状态和错误操作提供国际化语义标签；页面和弹窗隔离焦点。

完整约定见仓库根 `AGENTS.md`。

## 10. 网络与环境配置

默认商店 API 为生产环境：

```text
https://storeapi.linyaps.org.cn
```

开发、测试和部署如需覆盖，使用 `AppConfig` 已定义的编译期环境配置，不在
Repository 或页面内写第二个地址。后端契约需要参考相邻仓库：

```text
/home/han/code/linglong-store/linglong-server
```

网络错误在 `core/network` 统一标准化；Repository 负责外部响应到 Domain 的映射，
页面不得直接创建 Dio。

详细配置见 `docs/30-api-environment-configuration.md`。

## 11. 生成源码

仓库提交所有参与编译的稳定生成源码：

- `**/*.g.dart`；
- `**/*.freezed.dart`；
- `**/*.mocks.dart`；
- `lib/core/i18n/l10n/app_localizations*.dart`；
- Dart/CMake 应用身份生成物。

禁止手工编辑生成文件。统一校验：

```bash
build/scripts/verify-generated-sources.sh
```

脚本重放 `build_runner`、Flutter l10n 和应用身份校验，并在生成文件相对当前提交
发生修改、删除或未跟踪新增时失败。

完整策略见 `docs/36-generated-source-policy.md`。应用身份的唯一人工配置源和 XDG
约束见 `docs/26-application-identity-single-source.md`。

## 12. 测试与质量门禁

测试目录按风险类型组织：

```text
test/unit/          纯规则、Service、Parser、Repository 和工具
test/widget/        页面、组件、语义和 Provider 交互
test/golden/        视觉基线
integration_test/   真实应用流程
test/mocks/         Mockito 输入与生成物
```

测试用于保护真实风险，不为覆盖数字制造无业务价值用例。结构重构优先复用已有
行为测试；新增持久化、恢复、并发、解析或安全边界时补针对性测试。

PR CI 顺序：

1. `flutter pub get`；
2. `build/scripts/verify-generated-sources.sh`；
3. `flutter analyze`；
4. `flutter test`；
5. release/nightly CLI smoke test。

本地常用命令：

```bash
flutter analyze
flutter test
flutter build linux --release
bash build/scripts/application-identity-smoke-test.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

完整测试和性能指标见 `docs/06-testing-and-performance-spec.md`。

## 13. 修改入口决策

新增或调整能力时按以下顺序定位：

1. 先确认 Domain 是否已有模型或端口；
2. 外部 HTTP、CLI、文件或平台格式落在 Data/Platform；
3. 跨端口流程、重试、恢复和状态迁移落在 Application；
4. Presentation 只收集意图和渲染；
5. 具体实现只在组合根装配；
6. 更新对应 `docs/` 设计和 `AGENTS.md` 长期约定；
7. 运行与风险相称的生成、分析、测试和构建验证。

以下做法禁止：

- 页面或 Widget 新增 `ll-cli`/Shell 调用；
- Application Provider 创建 RepositoryImpl；
- 用全局队列为空推导某个批次完成；
- 外部副作用领先于 Journal durable barrier；
- Data 生成用户界面文案；
- 多处维护 application ID、desktop ID 或 API 默认地址；
- 修改注解或 ARB 后遗漏生成物；
- 为拆文件而增加没有变化轴的抽象层。

## 14. 相关架构文档

- `docs/07-runtime-sequence-and-state-diagrams.md`
- `docs/25-update-batch-system-notification.md`
- `docs/26-application-identity-single-source.md`
- `docs/27-architecture-remediation-roadmap.md`
- `docs/28-dependency-composition-root-design.md`
- `docs/29-app-operation-queue-decomposition-design.md`
- `docs/30-api-environment-configuration.md`
- `docs/31-structured-cli-error-and-i18n-boundary-design.md`
- `docs/32-linglong-environment-management-service-decomposition.md`
- `docs/33-linglong-environment-management-dialog-decomposition.md`
- `docs/34-download-manager-dialog-decomposition.md`
- `docs/35-app-detail-page-decomposition.md`
- `docs/36-generated-source-policy.md`
