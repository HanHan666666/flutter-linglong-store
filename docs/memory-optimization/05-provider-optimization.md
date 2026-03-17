# 05 - 状态管理与 Provider 优化

> **优先级：P1~P2** | **预估节省：20~40 MB** | **风险：中**

---

## 5.1 keepAlive Provider 审计

### 当前 keepAlive: true 的 Provider

| Provider | 文件 | 数据规模 | 是否合理 |
|----------|------|----------|----------|
| `globalAppProvider` | `global_provider.dart` | 轻量（locale/theme） | ✅ 合理 |
| `settingProvider` | `setting_provider.dart` | 轻量 | ✅ 合理 |
| `linglongEnvProvider` | `linglong_env_provider.dart` | 轻量 | ✅ 合理 |
| `launchSequenceProvider` | `launch_provider.dart` | 轻量 | ✅ 合理 |
| `installQueueProvider` | `install_queue_provider.dart` | 中等（队列 ≤50 条） | ✅ 合理 |
| `installQueueManagerProvider` | `install_queue_provider.dart` | 中等 | ✅ 合理 |
| `runningProcessProvider` | `running_process_provider.dart` | 中等 + Timer | ⚠️ 可优化 |
| **`installedAppsProvider`** | `installed_apps_provider.dart` | **高** — 全量应用列表 | ⚠️ 可优化 |

### 结论

- 6 个轻量/中等 Provider keepAlive 合理，无需改动
- 2 个 Provider 可优化：`installedAppsProvider` 和 `runningProcessProvider`

---

## 5.2 优化 installedAppsProvider

### 问题

```dart
@Riverpod(keepAlive: true)  // 永驻内存
class InstalledApps extends _$InstalledApps {
  Future<void> refresh() async {
    // 1. 从 ll-cli 获取已安装应用列表
    final apps = await repo.getInstalledApps();
    // 2. 从 API 富化每个应用（图标URL、中文名、描述等）
    final enrichedApps = await appRepo.enrichInstalledAppsWithDetails(apps);
    // 3. 全量存入 state
    state = InstalledAppsState(apps: enrichedApps, isLoading: false);
  }
}
```

- `enrichInstalledAppsWithDetails` 富化后每个应用包含完整的 API 返回数据
- 若用户安装了 200 个应用，每个 ~5KB = **~1 MB 数据层** + 对应 Widget 渲染缓存
- keepAlive 使其永驻内存

### 优化方案

**方案 A：精简富化数据（推荐）**

只保留 UI 展示所需的最小字段，不存储完整 API 返回：

```dart
/// 已安装应用的精简展示模型
class InstalledAppSlim {
  final String appId;
  final String name;
  final String version;
  final String? iconUrl;     // 仅存 URL，不缓存图片数据
  final String? arch;
  final String? channel;
  // 移除：完整描述、截图列表、开发者信息等
}
```

在 `enrichInstalledAppsWithDetails` 中只提取必要字段：

```dart
final enrichedApps = await appRepo.enrichInstalledAppsWithDetails(apps);
// 转为精简模型，丢弃不必要的详情数据
final slimApps = enrichedApps.map((app) => app.toSlim()).toList();
state = InstalledAppsState(apps: slimApps);
```

**方案 B：延迟富化（按需加载）**

不在 `refresh()` 时一次性富化全部应用，而是在「我的应用」页面渲染卡片时按需获取：

```dart
// 初始只存 ll-cli 的基础数据
final apps = await repo.getInstalledApps();
state = InstalledAppsState(apps: apps); // 不调用 enrichInstalledAppsWithDetails

// 在 AppCard build 时按需获取图标
// 通过单独的 family provider 按 appId 获取详情
@riverpod
Future<AppDetail?> appDetail(Ref ref, String appId) async {
  final repo = ref.read(appRepositoryProvider);
  return repo.getAppDetail(appId);
}
```

### 推荐

优先实施 **方案 A**（精简数据），改动面小、风险低。方案 B 可作为后续优化。

### 预估节省

- **5~15 MB**（取决于安装应用数量）

---

## 5.3 优化 runningProcessProvider 的定时刷新

### 问题

```dart
@Riverpod(keepAlive: true)
class RunningProcess extends _$RunningProcess {
  Timer? _refreshTimer;

  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3), // 每 3 秒刷新
      (_) => refresh(),
    );
  }
}
```

- keepAlive + 每 3 秒 `Timer.periodic` 刷新进程列表
- 即使用户不在「进程管理」页也在轮询

### 优化方案

确保定时器只在进程管理页可见时运行：

```dart
/// 在进程管理页面中控制定时器
@override
void initState() {
  super.initState();
  // 进入页面时启动自动刷新
  ref.read(runningProcessProvider.notifier).startAutoRefresh();
}

@override
void dispose() {
  // 离开页面时停止自动刷新
  ref.read(runningProcessProvider.notifier).stopAutoRefresh();
  super.dispose();
}
```

若已有此逻辑则验证其正确性。关键是 **确保离开页面后 Timer 确实被取消**。

### 预估节省

- 减少后台无意义轮询带来的数据更新 = **2~5 MB**

---

## 5.4 优化排行榜 pageSize

### 问题

```dart
// ranking_provider.dart — 4 个 Tab 各一次加载 100 条
const PageParams(pageNo: 1, pageSize: 100)
```

- 4 个排行榜 Tab × 100 条 = 400 条数据对象
- 400 条 × 每条含 AppIcon 等 UI 组件
- KeepAlive 页面不释放

### 优化方案

改为分页加载，首屏 30 条 + 滚动加载更多：

```dart
// ❌ 修改前
const PageParams(pageNo: 1, pageSize: 100)

// ✅ 修改后
PageParams(pageNo: _currentPage, pageSize: 30)
```

同时为排行榜添加 loadMore 逻辑（参考全部应用页的实现）。

### 改动文件

| 文件 | 改动 |
|------|------|
| `lib/application/providers/ranking_provider.dart` | pageSize 100→30，添加 loadMore 方法 |
| `lib/presentation/pages/ranking/ranking_page.dart` | 添加滚动监听触发 loadMore |

### 预估节省

- 初始加载数据从 400 条→120 条 = 约减少 70% 初始数据
- 配合 KeepAlive 优化 = **10~20 MB**

---

## 5.5 本章改动汇总

| 编号 | 改动 | 文件数 | 风险 | 节省内存 | 阶段 |
|------|------|--------|------|----------|------|
| 5.2 | installedAppsProvider 精简数据 | 2~3 | 低 | 5~15 MB | Phase 2 |
| 5.3 | runningProcess 定时器管控 | 1~2 | 低 | 2~5 MB | Phase 2 |
| 5.4 | 排行榜分页 30 条 | 2 | 中 | 10~20 MB | Phase 2 |
| **合计** | | **5~7 文件** | | **17~40 MB** | |
