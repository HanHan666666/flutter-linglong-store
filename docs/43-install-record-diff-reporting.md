# 安装记录差量上报与用户体验计划设计

## 1. 背景与目标

旧版玲珑应用商店（Electron 版 GershonWang/linglong-store v1.9.0，Tauri 版同源）对
「安装记录」的统计并非在安装成功回调里直接上报，而是通过
**轮询已安装列表做差量对比** 完成。Flutter 版迁移初期只实现了「商店内操作成功后
单条上报」，与旧版行为不等价，具体缺口：

| 行为 | Electron 旧版 | 迁移初期 Flutter |
|------|---------------|------------------|
| 商店外安装/卸载（命令行 ll-cli 等） | 轮询差量可捕获 | 不上报 |
| 每次启动全量基线上报 | 首轮快照为空，全量作为 addedItems | 无 |
| 更新时报旧版本 removedItems | 版本变化天然产生旧移除+新新增 | 只报新版本 addedItems |

本次改造将 Flutter 版对齐到差量模型，并新增「用户体验计划」开关，让用户可以
一键关闭全部匿名统计上报。

## 2. 旧版逻辑溯源（以 Electron 版为准）

- 入口：`src/util/WorkerInstalled.ts`
  - `TIMER_INTERVALS.INSTALLED_ITEMS = 3000`，每 3 秒（1 秒防抖）执行
    `ll-cli --json list --type=all`；
  - `src/store/installedItems.ts` 的 `initInstalledItems` 将结果与内存快照按
    `appId + version` 对比，得出 `addedItems` / `removedItems`；首轮快照为空时
    全量已安装应用均作为 `addedItems`；
  - 差量非空 → IPC `visit` → 主进程 `axios.post(/app/saveInstalledRecord)`，
    请求体 `{visitorId, clientIp, addedItems, removedItems}`；
  - 安装/卸载完成后调用 `reflushInstalledItemsImmediate()` 立即触发一次对比。
- 启动访问记录：`src/pages/index.vue` 环境检测完成后 POST `/app/saveVisitRecord`。
- 服务端（linglong-server `AppServiceImpl`）：
  - `saveInstalledRecord` 为 addedItems 每项写入安装记录并 `installCount + 1`，
    removedItems 写卸载记录并 `uninstallCount + 1`，随后清排行榜缓存；
  - `installCount` 即「下载排行」`/visit/getInstallAppList` 的数据来源。
- 主表匹配口径：按非空字段（appId/name/version/arch/channel/kind/module/repoName）
  精确匹配，Electron 上报项统一带 `repoName = defaultRepoName`。

## 3. Flutter 版差量模型设计

### 3.1 核心服务

`lib/application/services/installed_app_diff_report_service.dart`
（Provider 包装：`lib/application/providers/installed_app_diff_report_provider.dart`）

- **数据来源**：直接调用 `linglongCliRepository.getInstalledApps(includeBaseService: true)`
  获取全量原始列表（含 runtime 组件），**不复用** `installedAppsProvider`——后者受
  `showBaseService` 设置过滤 runtime，且经 `enrichInstalledAppsWithDetails` 富化会改写
  name，都会破坏差量口径。
- **对比键**：`appId + version`，与旧版一致。更新场景天然产生「旧版本移除 +
  新版本新增」。
- **快照语义**：内存快照（不持久化）。首轮为空 → 全量作为 `addedItems` 基线上报，
  与旧版「每次启动全量基线」行为完全一致。
- **触发链路**：
  1. 启动：`launch_provider._complete()` 读取 Provider 常驻并 `start()`，执行首轮
     基线检测（此时统计上下文预热已完成，visitorId/clientIp 就绪）；
  2. 轮询：30 秒自续期单发 Timer（非 periodic，天然防重叠）；
  3. 立即检测：`AppCollectionSyncService.syncAfterSuccessfulOperation` 末尾调用
     `scheduleImmediateCheck()`（500ms 防抖），对齐旧版 `reflushInstalledItemsImmediate`；
     安装/更新（经队列 Outbox 协调器）与卸载（经 AppUninstallService）都收敛到该
     同步服务，因此商店内操作完成后 1~2 秒内完成上报。
- **可见性门控**：`WidgetsBindingObserver.didChangeAppLifecycleState`，非 `resumed`
  （Linux 最小化/隐藏）时取消全部 Timer，本地 ll-cli 调用也不执行；恢复可见时立即
  补检一次再恢复正常轮询。
- **容错**：ll-cli 执行异常时保留旧快照，差量顺延到下一轮；上报失败仅记日志
  （fire-and-forget），快照不回滚，避免下轮重复上报。
- **幂等**：`start()` 重复调用安全；防重入标志避免并发检测。

### 3.2 轮询间隔：3 秒 → 30 秒的取舍

旧版 3 秒轮询对「绝对高性能」的 Flutter 版过重（每分钟 20 次本地命令执行）。
收敛为：

- 商店内操作：立即检测路径，秒级上报，不受轮询间隔影响；
- 商店外变更：最长延迟一个轮询周期（30s）或窗口恢复可见时被发现——**只延迟发现，
  不丢事件**（差量对比最终一定会捕获全部变更）。

### 3.3 上报接口

- `AnalyticsRepository.reportInstalledAppsDiff({addedItems, removedItems})`：
  domain 层接口，接收 `List<InstalledApp>`；
- `InstalledRecordItemDTO` 字段：appId/name/version/arch/module/channel +
  **repoName/kind**（本次新增，对齐 Electron 上报内容，提升服务端主表匹配精度；
  repoName 统一填 `AppConfig.defaultStoreRepoName`，与旧版 defaultRepoName 覆盖行为
  一致）；
- POST `/app/saveInstalledRecord`，双向差量为空时不发请求。

### 3.4 旧事件驱动上报的收敛（避免重复计数）

差量模型上线后，以下旧上报点已移除，差量检测是安装/卸载统计的唯一链路：

- `app_operation_lifecycle_coordinator.dart` 中任务成功后的 `reportInstall`；
- `app_uninstall_service.dart` 中卸载成功后的 `reportUninstall`
  （`UninstallReporter` typedef 一并删除）。

时序变化：商店内操作的上报从「任务成功回调即时」变为「操作同步链路完成后约
1~2 秒」，fire-and-forget 语义不变。

## 4. 用户体验计划开关

### 4.1 偏好与 UI

- `UserPreferences.joinUserExperienceProgram`（默认 `true`，保持旧版始终上报的统计
  口径），`GlobalApp.setUserExperienceProgram` 写入；
- 设置页「商店选项」区新增 SwitchListTile：标题「用户体验计划」，副标题「发送匿名
  使用统计，帮助我们改进商店」；
- 标题尾部感叹号按钮（`A11yIconButton` + `Icons.info_outline_rounded`，48×48 触点、
  `a11yUserExperienceProgramInfo` 语义）打开
  `lib/presentation/widgets/user_experience_program_dialog.dart` 说明弹窗。

### 4.2 门控范围（关闭后全部停止）

| 门控点 | 行为 |
|--------|------|
| `launch_provider._prepareStartupAnalyticsContext` | 不调 `initializeSession`：不生成访问标识、不请求公网 IP（商店版本解析与统计无关，照常执行） |
| `launch_provider._reportStartupVisit` | 不发送 `/app/saveVisitRecord` |
| `installedAppDiffReportServiceProvider` | `ref.listen` 偏好变化：关闭时 `setReportingEnabled(false)` 取消全部 Timer（本地轮询命令也不执行）；重新开启时立即补检并恢复轮询 |

- 门控全部实时读取当前偏好，切换即时生效；
- 关闭期间内存快照**照常维护逻辑上不存在**（检测已停止）：重新开启后的第一轮
  检测快照为空 → 自然产生一次全量基线上报，与「每次启动全量基线」语义一致。

### 4.3 说明弹窗文案（中文）

> **用户体验计划**
> 加入用户体验计划，你正在帮助玲珑商店变得更好。我们只收集少量匿名信息，用于改进应用推荐与下载体验：
> - 匿名设备标识（一串随机字符，无法识别你）
> - 系统架构、系统版本与内核信息、主机名、玲珑环境版本
> - 应用的安装、更新与卸载记录
> - 网络地址（仅用于地区统计）
>
> 这些信息不包含个人隐私，也不会用于识别你的身份。你可以随时关闭开关，关闭后不会再上报任何数据。

文案原则：只描述「收集了什么」，不解释技术实现；语气正向、强调可控可退出。

**关于主机名的如实披露**：`osVersion` 上报内容包含 `uname -a` 完整输出（见
`linglong_environment_service._buildReportedOsVersion`，`kernel:` 段），`uname -a`
第二个字段即主机名。两个版本行为一致，上报逻辑不做改动，弹窗与本文档如实说明。

### 4.4 国际化

新增 key（zh/en/es/ru/ar 五语言同步）：`userExperienceProgram`、
`userExperienceProgramDesc`、`userExperienceProgramDialogIntro`、
`userExperienceProgramDialogItemIdentity`、`userExperienceProgramDialogItemSystem`、
`userExperienceProgramDialogItemApps`、`userExperienceProgramDialogItemNetwork`、
`userExperienceProgramDialogFooter`、`a11yUserExperienceProgramInfo`（a11y 前缀约定）。
流程遵循 `docs/38-arb-driven-linux-metadata.md`（arb → `flutter gen-l10n` → 生成物入库）。

## 5. 测试

- `test/unit/application/services/installed_app_diff_report_service_test.dart`：
  首轮全量基线、无变化不重复上报、外部安装/卸载差量、更新（旧 removed + 新 added）、
  ll-cli 异常恢复、窗口隐藏暂停/恢复补检、start 幂等、体验计划关闭/重开行为；
- `test/unit/data/repositories/analytics_repository_impl_test.dart`：批量差量映射、
  repoName/kind 补齐、双向为空不发请求；
- `test/unit/application/providers/launch_provider_test.dart`：启动完成挂载差量服务、
  体验计划关闭时不预热不访问上报；
- `test/unit/application/providers/app_collection_sync_provider_test.dart`：同步完成后
  必须触发差量检测；
- `test/widget/presentation/pages/setting_page_test.dart`：开关切换写入偏好、说明弹窗
  打开/关闭与无障碍语义。

## 6. 变更记录

- 2026-08-20：初始实现。对齐 Electron 差量模型（外部安装捕获、启动全量基线、更新
  双向差量），移除旧事件驱动上报，新增用户体验计划开关与采集说明弹窗。
