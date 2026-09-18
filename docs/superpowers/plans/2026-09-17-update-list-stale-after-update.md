# 更新完成后应用仍留在更新列表：根因分析与实施方案

> 状态：**待评审**（本文只做分析与方案设计，未改动任何代码；评审通过后再进入实现）
> 关联问题：用户报告"更新玲珑应用后都已安装完成，更新列表里仍出现该应用；手动刷新或重启客户端后才消失"
> 现场：`com.dongpl.linglong-store.v2`（nightly-20260911，等价于仓库 HEAD `f54f960`）

---

## 1. 现象与影响范围

### 1.1 现象

1. 在「更新」页更新某个应用（单个更新或一键更新）。
2. 下载管理中该任务显示"更新完成"，任务状态为成功。
3. 该应用**仍然留在「更新」页的可更新列表**中：卡片第二行显示的是 `更新前的当前版本 → 最新版本`（现场截图为 `4.1.13.9 → 4.1.13.20`，而本次更新目标正是 `4.1.13.20`）。
4. 手动点「检查更新」或重启客户端后，该条目消失。

### 1.2 影响范围

更新列表是单一状态源 `updateAppsProvider`，因此以下位置会同时出现脏数据：

- 「更新」页列表与头部"共 N 个应用可更新"（`lib/presentation/pages/update_app/update_app_page.dart:123`）
- 侧边栏「更新」角标（`lib/application/providers/menu_badge_provider.dart:62`）
- 应用卡片"可更新"状态（`lib/application/providers/application_card_state_provider.dart:103`）
- 详情页更新态（`lib/presentation/pages/app_detail/app_detail_page.dart:99`）

附带风险：脏条目会诱导用户重复点击更新（现场 Journal 中同一应用被重复更新），而"更新页在队列活跃期禁止重复入队"的保护只在队列活跃窗口内有效。

---

## 2. 现场证据（只读排查）

### 2.1 关键时间线（2026-09-17）

| 时间 | 事实 | 证据 |
| --- | --- | --- |
| 17:04:50 | 商店发布微信 `4.1.13.20` | `~/.cache/com.dongpl.linglong-store.v2/cache.hive` 中该版本详情的 `createTime` |
| 17:28:27 | 用户发起单个更新任务（`kind=update`，`batchId=null`） | `~/.local/state/com.dongpl.linglong-store.v2/operations/queue-v2.json` 的 `createdAt=1789637307458` |
| 17:28:49 | 任务成功 | 同文件 `finishedAt=1789637329198` |
| 17:28:50 | Journal 最后一次写入，且 `outbox` 已为空 | 同文件 mtime + `outbox: []` |
| ~17:28:50 | **本次同步读到的已安装版本仍是 `4.1.13.9`** | `cache.hive` 中 `app_details\|zh\|com.tencent.wechat\|4.1.13.9\|…` 键仍在使用；屏幕上的条目正是 `4.1.13.9 → 4.1.13.20` |
| ~17:30:52 | 重建快照后读到 `4.1.13.20`，条目消失 | `cache.hive` mtime 17:30:52 + 新增 `…\|4.1.13.20\|…` 键 |

补充事实（非缺陷）：详情缓存 TTL 为 5 分钟（`lib/core/config/app_config.dart:27`），本次更新是真实有效的（商店确实在今天 17:04:50 发布了 4.1.13.20）；下载管理里出现两条"微信 更新完成"是 Journal 历史记录（9/11 批次一条、今天一条），属正常保留。

### 2.2 由证据得出的事实

1. 任务成功后的副作用**确实被消费**：Journal `outbox` 为空且文件此后未再写入，说明"乐观移除 + 同步"在完成瞬间执行过，不是事件丢失或协调器未启动。
2. 因此条目是**被重新计算回来的**，且重算时使用的已安装快照是更新前的版本。
3. 该状态会一直保持到下一次真正重建快照（手动检查更新 / 重启），这与用户描述的规避方式一致。

---

## 3. 根因分析

### 3.1 判定链路

```
任务成功
 → AppOperationLifecycleCoordinator._consumeTaskSucceeded
    ├─ updateAppsProvider.removeApp(appId)          // 乐观移除，正确
    └─ AppCollectionSyncService.syncAfterSuccessfulOperation()
         ├─ installedAppsProvider.refresh()          // 重建已安装快照（ll-cli list）
         └─ updateAppsProvider.checkUpdates()        // 用快照版本比对远端最新版本
```

`checkUpdates()` 判定"是否可更新"的唯一依据是：**远端返回的最新版本 != 已安装快照中的版本**（`lib/application/providers/update_apps_provider.dart:171-191`）。因此只要快照是旧的，就必然判出"可更新"，即使刚刚更新成功。

### 3.2 三处让"旧快照"能驱动"新结论"的代码缺陷

| # | 位置 | 问题 |
| --- | --- | --- |
| D1 | `lib/data/repositories/linglong_cli_repository_impl.dart:514-517` | CLI 打出终态 `completed` 就 `return`，**跳过** `_confirmInstalledTarget`（519-525）。即：把"CLI 报告完成"当成"`ll-cli list` 已收敛"，没有任何"目标版本已可见"的自证 |
| D2 | `lib/application/providers/installed_apps_provider.dart:66-69` + `lib/application/providers/update_apps_provider.dart:109-121` | 快照刷新失败时**静默保留旧 `apps`**（仅置 error），而 `checkUpdates()` 完全不看这个 error，只判断"列表是否为空" → 用更新前的版本问服务端，服务端自然回答"有更新" |
| D3 | `lib/application/providers/app_collection_sync_provider.dart:17-27` + `lib/application/providers/app_operation_lifecycle_coordinator.dart:215-234` | 顺序（先 installed 再 updates）是对的，但整条链路包在 `_runBestEffort` 里，失败只写日志、用户侧完全无感；同时 `InstalledApps.refresh()` 缺少 `UpdateApps._latestRequestId` 那样的请求序号守卫，并发刷新时旧响应可覆盖新快照（`installed_apps_provider.dart:52-70`） |

### 3.3 对应的三种触发形态（同一根因）

| 形态 | 机制 |
| --- | --- |
| F1 收敛延迟 | `ll-cli upgrade` 报告完成后，`ll-cli list`（或守护进程）尚未暴露新版本，紧随其后的重建快照拿到旧版本 |
| F2 刷新失败 | 那一刻 `ll-cli list` 失败/超时（例如守护进程仍忙于收尾），旧快照被留用 |
| F3 并发覆盖 | 另有一路刷新在更新前发起、在同步之后完成并覆盖新快照 |

> 用户已确认"复现频率与刷新时机均不确定"，因此方案必须同时覆盖 F1/F2/F3，并留下可诊断日志，以便下次复现时定形。

### 3.4 历史上三次修复为什么没根治

`97e8e46`（顺序化 + 请求序号）、`280c35a`（乐观移除）、`036ee44`（多版本取最新 + 刷新闪动）解决的是**应用内部并发与展示**问题，前提都是"installed 快照刷新后就是最新事实"。当快照本身**未收敛或刷新失败**（F1/F2/F3）时，这三层防护全部失效：
- 顺序化只能保证"先刷新再比对"，不能保证"刷新到的是新版本"；
- 乐观移除会被随后的重算直接覆盖回来；
- `UpdateApps` 的请求序号守卫只保护"自己新旧响应"，管不到"已安装快照来源"。

因此本轮必须在**"快照可用/已收敛"这一契约**上补齐，而不是再补一层 UI 或时序补丁。

---

## 4. 方案对比与选型

### 方案 A（推荐）：成功后收敛确认 + 未确认不重算

- A① 加固快照来源：`InstalledApps.refresh()` 返回成败结果 + 请求序号守卫。
- A② 新增 Application 层"收敛确认"服务：按任务 `target.expectedVersion` 做**有界重试**（最多 3 次、间隔约 1s），确认目标版本已在快照中可见。
- A③ 同步入口按确认结果分流：未确认 → **不调用 `checkUpdates()`**，保留乐观移除，等下一次成功刷新/手动检查/启动自然收敛；已确认 → 保持现有 `refresh → checkUpdates` 顺序。
- A④（可选二期）结果兜底：`latestVersion == 该应用最近一次成功更新任务的 expectedVersion` 时不再视为可更新。

- 改动面：Application/Data 共 4 个文件 + 1 个新服务 + 测试；不改任务成功语义、不改 UI 时序、不新增 ll-cli 调用方式（只可能重复 `list`）。
- 取舍：未确认时"其他应用的新更新发现"会推迟到下一次检查（手动刷新/启动/下一次操作），这是可接受的降级，且优于"错误地保留已更新条目"。

### 方案 B：Data 层在 emit success 前复验（不做）

在 `linglong_cli_repository_impl.dart:514` 的 `terminalEmitted` 分支先做有界复验再 emit `success`。

- 优点：成功事件本身即代表已收敛，下游全部受益。
- 缺点：必须回答"CLI 说成功、list 未收敛"时任务算成功还是失败——判失败违背事实，判成功则问题只是缩小；同时把"更新完成"展示推迟最多 2~3s。
- 结论：作为长期方向记录，不作为本轮方案。

### 方案 C：成功后延迟固定时间再重算（不做）

把"猜时间"引入业务，延迟更长时依旧复现，违背"越简单越可控"。

---

## 5. 方案 A 详细设计

### 5.1 判定口径必须同源（前置重构）

`lib/application/services/app_operation_recovery_service.dart:75-101` 已经实现了"目标版本 == 实际安装版本即证明更新成功"的规则（含 arch/channel/module/repoName 的宽松匹配）。

**要求：新增的收敛判定不得复制这套规则**，抽出共享判定器（SRP/DRY）：

```dart
// lib/application/services/app_operation_target_matcher.dart（新增）
/// 应用操作目标快照与已安装实例的匹配规则。
///
/// 恢复判定（启动崩溃恢复）与运行期收敛判定必须同源，避免出现
/// "重启后认为已更新成功、运行期却仍认为可更新"的分叉。
class AppOperationTargetMatcher {
  /// 按冻结身份（arch/channel/module/repoName）匹配本机安装实例；未冻结字段容忍差异。
  bool matches(InstalledApp app, AppOperationTargetSnapshot target);

  /// 更新操作是否已满足目标版本（target.expectedVersion 为空时返回 false，不猜测）。
  bool isUpdateSatisfied(InstalledApp app, AppOperationTargetSnapshot target);
}
```

改造点：`AppOperationRecoveryService` 内部改用该判定器（行为保持不变，需由既有测试 + 新增单测覆盖）。

> 若评审希望把改动面压到最小，可退化为"只在收敛服务内实现判定、不动恢复服务"，但必须在文档中记录两处口径的存在与同步维护责任。

### 5.2 数据/状态加固（A①）

```dart
// lib/application/providers/installed_apps_provider.dart
/// 重建已安装快照；返回是否成功落到新快照。
///
/// 已安装快照是"更新列表"判定的唯一事实来源（checkUpdates 只依赖它），
/// 因此这里必须：1) 用请求序号保证旧响应不覆盖新快照；
/// 2) 明确回报成败，避免上层在刷新失败时用旧数据得出"仍有更新"的结论。
Future<bool> refresh();
```

- 失败时行为保持不变：保留旧 `apps` + 置 `error`，额外返回 `false`。
- 现有调用点（`launch_provider.dart:425`、`setting_provider.dart:168`、`my_apps_page.dart:239/272`、`update_apps_provider.dart:113`、`app_collection_sync_provider.dart:20`）均忽略返回值，Dart 中 `Future<bool>` 可赋给 `Future<void>` 语境；若静态分析在 `onRefresh` 处报错，则在调用点显式忽略返回值。

### 5.3 收敛确认服务（A②，新增）

```dart
// lib/application/services/update_convergence_service.dart（新增 + 同名 provider）
/// 一次成功更新对已安装快照提出的收敛期望。
class AppUpdateExpectation {
  const AppUpdateExpectation({required this.appId, required this.expectedVersion});
  final String appId;
  final String expectedVersion;
}

/// 收敛确认结果。
class UpdateConvergenceResult {
  const UpdateConvergenceResult({
    required this.confirmed,
    required this.attempts,
    required this.unconfirmed,
  });
  /// 是否所有期望都已在快照中可见。
  final bool confirmed;
  /// 实际刷新次数（含首次）。
  final int attempts;
  /// 仍未确认的期望，用于诊断日志。
  final List<AppUpdateExpectation> unconfirmed;
}

/// 更新成功后确认已安装快照是否已收敛到目标版本。
abstract class UpdateConvergenceVerifier {
  /// 有界重试：最多 [maxAttempts] 次、每次间隔 [retryDelay]；
  /// 快照刷新失败与"目标版本不可见"都视为未确认。
  Future<UpdateConvergenceResult> verify(List<AppUpdateExpectation> expectations);
}
```

实现要点：
- 每次尝试复用 `installedAppsProvider.notifier.refresh()`（**统一入口**：确认的就是 `checkUpdates()` 将要读取的同一份快照，不引入第二条 `ll-cli list` 解析路径）；详情富化有 5 分钟缓存，重试基本不产生额外网络请求。
- 默认 `maxAttempts = 3`、`retryDelay = Duration(seconds: 1)`，常数集中在服务内并写明理由（覆盖 F1 的短延迟，同时避免无界轮询）。
- 空期望集合直接返回 `confirmed = true`（不改变安装类操作现状）。
- 诊断日志（**本轮的形态取证手段**）：

```
[更新收敛] appId=com.tencent.wechat expected=4.1.13.20 attempts=2 confirmed=true snapshot=4.1.13.20
[更新收敛] appId=com.tencent.wechat expected=4.1.13.20 attempts=3 confirmed=false reason=listStale snapshot=4.1.13.9
[更新收敛] appId=… expected=… attempts=3 confirmed=false reason=refreshFailed error=…
```

### 5.4 同步入口分流（A③）

```dart
// lib/application/providers/app_collection_sync_provider.dart
/// 应用集合变更后的统一同步入口。
///
/// [updateExpectations] 非空表示"刚刚成功更新了这些应用到指定版本"：
/// 必须先在已安装快照中确认目标版本可见，才允许重算更新列表，
/// 否则会基于旧快照把刚更新的应用重新判为可更新。
Future<void> syncAfterSuccessfulOperation({
  List<AppUpdateExpectation> updateExpectations = const [],
});
```

分支行为：

| 场景 | 行为 |
| --- | --- |
| 期望为空（安装类操作、更新页手动刷新） | 保持现状：尽力刷新快照 → `checkUpdates()` |
| 期望非空且已确认 | `checkUpdates()`（快照已在确认过程刷新到位，不重复刷新） |
| 期望非空但未确认 | **跳过 `checkUpdates()`**，保留乐观移除结果；warning 日志；仍触发差量统计上报 |

两条分支都必须继续调用 `installedAppDiffReportServiceProvider.scheduleImmediateCheck()`——安装/更新统计由差量链路产生，跳过更新列表重算**不得**连带丢掉统计上报。

### 5.5 协调器传递期望（A③）

```dart
// lib/application/providers/app_operation_lifecycle_coordinator.dart
// 单任务成功（110-139）：kind=update 且 target.expectedVersion 非空时构造期望。
// 批次完成（142-196）：从批次 taskIds 中筛选 status==success && kind==update 的任务，
//   收集其 (appId, expectedVersion) 一次性传入，保持"批次只重算一次"的现状设计。
```

- 失败/取消的任务不产生期望，因此不会因为它们而卡住更新列表重算。
- 旧持久化任务可能 `target == null`：不参与收敛判定（与 `install_task.dart:46-50` 的既有约束一致，不猜测）。
- `_runBestEffort` 语义保留（外围副作用失败不改变任务结果），但"未确认"是**正常分支**，不进入 catch。

### 5.6 明确不改的内容（非目标）

1. 任务成功/失败语义与"更新完成"UI 时序（不在 Data 层加复验，见方案 B）。
2. 一键更新批次结构、通知编排与文案。
3. `checkUpdates()` 的远端比对规则、忽略更新与请求序号守卫。
4. 安装类操作（`kind=install`）的同步行为。
5. `ll-cli` 调用方式与命令集合（只可能重复 `list`）。

---

## 6. 任务拆分（TDD，逐步可验证）

> 每步先写失败测试再实现；每完成一个功能点单独 commit（Conventional Commits）。

### Task 1：共享判定器
- 新增 `lib/application/services/app_operation_target_matcher.dart`（中文文档注释）+ `test/unit/application/services/app_operation_target_matcher_test.dart`。
- 改造 `app_operation_recovery_service.dart` 复用判定器。
- 验证：`flutter test test/unit/application/services/`（含既有恢复相关测试）+ `flutter analyze`。

### Task 2：已安装快照加固（A①）
- 改 `lib/application/providers/installed_apps_provider.dart`：`Future<bool> refresh()` + 请求序号守卫。
- 新增 `test/unit/application/providers/installed_apps_provider_test.dart`：旧响应不覆盖新快照；失败保留旧数据且返回 `false`；成功返回 `true`。

### Task 3：收敛确认服务（A②）
- 新增 `lib/application/services/update_convergence_service.dart` + 同名 provider。
- 新增 `test/unit/application/services/update_convergence_service_test.dart`，覆盖 F1（第 2 次才可见）、F2（刷新失败）、全部未确认、空期望四种场景（用 fake provider/repository 注入，禁止真实 `ll-cli`）。

### Task 4：同步入口分流（A③）
- 改 `lib/application/providers/app_collection_sync_provider.dart`。
- 扩展 `test/unit/application/providers/app_collection_sync_provider_test.dart`：
  - 未确认 → 不调用 `checkUpdates`、保留乐观移除、仍触发差量上报；
  - 已确认 → 按 `refresh → checkUpdates` 顺序执行。

### Task 5：协调器期望传递
- 改 `lib/application/providers/app_operation_lifecycle_coordinator.dart`。
- 扩展 `test/unit/application/providers/app_operation_lifecycle_coordinator_test.dart`：单任务成功传期望；批次完成只重算一次且只汇总成功任务；无 `target` 的旧任务不产生期望（F3 的并发覆盖由 Task 2 的守卫覆盖）。

### Task 6：页面级回归
- 扩展 `test/widget/presentation/pages/update_app/update_app_page_test.dart`：任务成功且收敛未确认的窗口内，该条目不出现在列表中。

### Task 7：文档与提交
- 同步更新 `docs/07-runtime-sequence-and-state-diagrams.md` 的"更新页刷新契约"（新增：成功后的更新列表重算必须先确认目标版本收敛）。
- `CHANGELOG.md` 追加一条行为变更记录。
- 提交：`fix: 修复更新成功后应用残留更新列表`（代码+测试）；`docs: 补充更新成功后收敛确认设计`（文档）。

---

## 7. 验证矩阵

| 层级 | 用例 | 期望 |
| --- | --- | --- |
| 单元 | F1 延迟收敛 | 第 2 次刷新可见目标版本 → `confirmed=true`，继续重算，列表不含该应用 |
| 单元 | F2 刷新失败 | 3 次均失败 → `confirmed=false`、`reason=refreshFailed`；同步入口跳过 `checkUpdates` |
| 单元 | F3 并发覆盖 | 旧响应后到 → 被请求序号丢弃，状态保持新快照 |
| 单元 | 批次汇总 | 仅成功任务产生期望；失败任务不影响重算 |
| Widget | 更新页 | 成功未确认窗口内条目已移除且不回流 |
| 真机 | 更新一个应用 | 完成后条目立即消失且不回流；日志出现 `[更新收敛] … confirmed=true` |
| 真机 | 故意断网/停守护进程后更新 | 日志 `confirmed=false`，条目仍保持移除，下一次成功检查后恢复正常 |
| 静态 | `flutter analyze` | 0 error / 0 warning |
| 性能 | 计数 `ll-cli list` | 收敛正常时 +1~2 次（后台，非 UI 关键路径）；最坏 +3 次 |

> 真机验证时请保留 `~/.local/share/<app-id>/logs/linglong-store.log`，其中的 `[更新收敛]` 行可直接判定问题属于 F1 还是 F2，用于决定是否需要 A④。

---

## 8. 风险、边界与回滚

| 风险 | 说明 | 处置 |
| --- | --- | --- |
| 未确认时跳过重算 | 其他应用的新更新最迟在"下一次手动检查/启动/下一次操作"出现 | 可接受；文档记录该降级语义 |
| 额外 `ll-cli list` | 最多 3 次，间隔 1s，后台执行 | 富化走 5 分钟缓存；实测慢再考虑"轻量探测（只 list 不富化）"变体 |
| 判定口径分叉 | 恢复逻辑与运行期判定不一致会导致"重启说成功、运行期说可更新" | Task 1 强制同源 |
| 旧任务无 `target` | 不参与判定 | 与既有恢复约束一致，不猜测 |
| 回滚 | 单一行为修复 | `git revert` 两个 commit 即可，无需配置开关 |

---

## 9. 待评审决策项

1. **是否接受"未收敛时跳过更新列表重算"**？（推荐接受：宁可少一次刷新，也不把刚更新的应用放回列表。）
2. **是否把判定器抽成共享组件并改造 `AppOperationRecoveryService`**（推荐），还是仅在收敛服务内实现判定（改动最小但两处口径并存）？
3. **A④ 兜底过滤是否本轮纳入**？（推荐先不纳入：①②③ 已能闭合症状，④ 会新增"更新列表依赖队列任务事实"的跨 Provider 耦合，等真机日志确认后再定。）

---

## 10. 影响文件清单

| 文件 | 类型 |
| --- | --- |
| `lib/application/services/app_operation_target_matcher.dart` | 新增 |
| `lib/application/services/update_convergence_service.dart` | 新增 |
| `lib/application/services/app_operation_recovery_service.dart` | 改造（复用判定器） |
| `lib/application/providers/installed_apps_provider.dart` | 改造（返回成败 + 请求序号） |
| `lib/application/providers/app_collection_sync_provider.dart` | 改造（按确认结果分流） |
| `lib/application/providers/app_operation_lifecycle_coordinator.dart` | 改造（传递期望） |
| `test/unit/application/services/app_operation_target_matcher_test.dart` | 新增 |
| `test/unit/application/services/update_convergence_service_test.dart` | 新增 |
| `test/unit/application/providers/installed_apps_provider_test.dart` | 新增 |
| `test/unit/application/providers/app_collection_sync_provider_test.dart` | 扩展 |
| `test/unit/application/providers/app_operation_lifecycle_coordinator_test.dart` | 扩展 |
| `test/widget/presentation/pages/update_app/update_app_page_test.dart` | 扩展 |
| `docs/07-runtime-sequence-and-state-diagrams.md`、`CHANGELOG.md` | 文档 |

---

## 11. 排查方法与复现取证（备查）

1. 任务事实：`~/.local/state/com.dongpl.linglong-store.v2/operations/queue-v2.json`（`history` / `batches` / `outbox`，时间戳为毫秒）。
2. 已安装版本痕迹：`~/.cache/com.dongpl.linglong-store.v2/cache.hive` 中 `app_details|<locale>|<appId>|<已安装版本>|…` 键——键里带版本号，可反推"某次同步当时认为的已安装版本"。
3. 应用日志：`~/.local/share/com.dongpl.linglong-store.v2/logs/linglong-store.log`（`[LinglongCli] 开始 update: …`、`检查更新失败`，以及本轮新增的 `[更新收敛]` 行）。
4. 判定口径：`lib/application/services/app_operation_recovery_service.dart:75-101`（`expectedVersion` 与已安装版本相等即证明更新成功）。
