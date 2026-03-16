# 玲珑应用商店 Flutter 迁移计划

> 文档版本: 1.0 | 创建日期: 2026-03-15 | 状态: 规划中

---

## 一、迁移概述

### 1.1 项目背景

当前玲珑应用商店社区版（v2.1.2）基于 **Tauri 2.0 + React 18 + TypeScript + Ant Design 5** 构建，仅运行于 Linux 平台。项目通过 Rust 后端桥接 `ll-cli` 系统命令实现玲珑应用的生命周期管理。

本次迁移目标是将整个应用从 Tauri + React 技术栈 **完全迁移至 Flutter**，实现：
- **UI 100% 像素级还原**：所有页面布局、组件尺寸、颜色、动画、交互效果完全一致
- **逻辑 100% 功能还原**：所有业务流程、状态管理、数据流、错误处理完全等价
- **系统能力等价**：所有 ll-cli 调用、环境检测、安装/卸载/运行等功能完全覆盖

### 1.2 技术栈对照

| 维度 | 原（Tauri + React） | 新（Flutter） |
|------|---------------------|---------------|
| UI 框架 | React 18.3.1 + Ant Design 5 | Flutter 3.24+ |
| 语言 | TypeScript + Rust | Dart + Rust（FFI/插件） |
| 状态管理 | Zustand | Riverpod 2.x |
| 路由 | react-router-dom 7 | go_router |
| HTTP | Alova 3.3.4 | dio + retrofit |
| 数据校验 | Zod | freezed + json_serializable |
| 本地存储 | @tauri-store/zustand | shared_preferences / hive |
| 国际化 | 自研 i18n (core.ts) | flutter_localizations + intl |
| 窗口管理 | Tauri Window API | window_manager |
| 系统命令 | Rust (std::process::Command) | Dart process / Rust FFI |
| CSS / 样式 | SCSS Modules + CSS Variables | Flutter Widget + Theme |
| 构建打包 | Tauri Build (deb/rpm/appimage) | Flutter Linux Build + 打包脚本 |

### 1.3 迁移原则

1. **功能完整性优先**：每个功能点必须有对应的 Flutter 实现，不允许遗漏
2. **UI 像素级还原**：所有尺寸、颜色、字体、间距严格对齐原始设计
3. **渐进式迁移**：按模块逐步迁移，每步可独立验证
4. **架构升级**：利用迁移机会改善现有架构中的不合理之处
5. **测试先行**：每个模块迁移完成后必须有对应测试覆盖

---

## 二、现有系统全面分析

### 2.1 页面清单（10 个页面）

| 编号 | 页面 | 路由 | 复杂度 | 关键功能 |
|------|------|------|--------|---------|
| P01 | 推荐页 | `/` | ★★★ | 轮播 + 无限滚动 + 缓存 + KeepAlive |
| P02 | 全部应用 | `/allapps` | ★★★★ | 分类筛选 + 折叠动画 + 无限滚动 + 缓存 |
| P03 | 应用详情 | `/app_detail` | ★★★★★ | 版本管理 + 安装/卸载/运行 + 截图 + 进度 |
| P04 | 自定义分类 | `/custom_category/:code` | ★★★ | 推荐区 + 排序/过滤 + 无限滚动 + 缓存 |
| P05 | 我的应用 | `/my_apps` | ★★★★ | Tab 切换 + 已安装列表 + 进程管理(原生菜单) |
| P06 | 排行榜 | `/ranking` | ★★★ | 双 Tab + 无限滚动 + 缓存 |
| P07 | 搜索结果 | `/search_list` | ★★ | 防抖搜索 + 无限滚动(无缓存) |
| P08 | 设置 | `/setting` | ★★★ | 持久化配置 + 反馈表单 + 日志上传 |
| P09 | 应用更新 | `/update_apps` | ★★★ | 批量更新 + 浮动按钮 + 队列状态 |
| P10 | 启动页 | (内嵌 Layout) | ★★★★ | 初始化流水线 + 环境检测 + 进度条 |

### 2.2 核心组件清单（9 个）

| 编号 | 组件 | 复杂度 | 功能 |
|------|------|--------|------|
| C01 | ApplicationCard | ★★★★ | 核心卡片（4种操作态 + 加载动画 + shimmer） |
| C02 | ConnectedApplicationCard | ★★ | Store 数据绑定包装器 |
| C03 | ApplicationCardSkeleton | ★★ | 骨架屏卡片 |
| C04 | ApplicationCarousel | ★★★ | 推荐轮播组件 |
| C05 | DownloadProgress | ★★★★ | 下载管理弹窗（队列/进度/历史） |
| C06 | LinglongEnvDialog | ★★★ | 环境检测弹窗 |
| C07 | KeepAliveOutlet | ★★★★★ | 页面缓存（LRU）+ 可见性注入 |
| C08 | SpeedTool | ★★ | 实时网速显示 |
| C09 | Loading | ★ | 加载占位 |

### 2.3 业务逻辑层（Hooks / Services / Stores）

#### Hooks（14 个）

| Hook | 复杂度 | 职责 |
|------|--------|------|
| useLaunch | ★★★★★ | 启动初始化流水线（架构/列表/更新/恢复/统计） |
| useAppInstall | ★★★★ | 统一安装逻辑（入队/降级确认/强制安装/批量） |
| useAppUninstall | ★★★ | 统一卸载逻辑（运行检测/确认/API/同步） |
| useApplicationCardModel | ★★★ | 卡片 ViewModel（三索引 Map + getCardState） |
| useAutoLoadWhenNotScrollable | ★★★ | 滚动触底 + 未满自动补页 + ResizeObserver |
| useCachedPaginatedList | ★★★★★ | 带缓存分页（seed + localStorage + 后台刷新 + 代次控制） |
| usePaginatedList | ★★★ | 无缓存分页（代次控制 + 并发保护） |
| useCheckUpdates | ★★ | 更新检查包装 |
| useGlobalInstallProgress | ★★★★ | 全局安装事件监听（进度/成功/失败/刷新） |
| useKeepAliveVisibility | ★★ | KeepAlive 可见性读取 |
| useLinglongEnv | ★★★ | 环境检测 + 自动安装 |
| useLinglongProcesses | ★★★★ | 进程轮询（智能退避/并发保护/Tab感知） |
| useMenuBadges | ★ | 侧边栏红点 |
| useUploadStore | ★★★ | 客户端自身版本更新检测 |

#### Stores（6 个）

| Store | 持久化 | 状态字段数 |
|-------|--------|----------|
| useGlobalStore | 否 | 17 |
| useSearchStore | 否 | 1 |
| useConfigStore | 是（Tauri Store） | 3 |
| useInstallQueueStore | 部分（localStorage） | 4 + methods |
| useInstalledAppsStore | 否 | 2 |
| useUpdatesStore | 否 | 3 |

#### Services（3 个）

| Service | 功能 |
|---------|------|
| appListCache | 混合缓存（seed + localStorage + 后台刷新） |
| analyticsService | 匿名统计（访问/安装/卸载记录） |
| installService | 安装辅助（错误检测） |

### 2.4 API 层

#### 远程 HTTP API（20 个端点）

| 端点 | 方法 | 功能 |
|------|------|------|
| `/visit/getDisCategoryList` | GET | 应用分类 |
| `/visit/getSearchAppList` | POST | 搜索/分类浏览 |
| `/visit/getAppDetails` | POST | 批量应用详情 |
| `/app/getAppDetail` | POST | 单应用截图详情 |
| `/visit/getWelcomeCarouselList` | POST | 轮播数据 |
| `/visit/getWelcomeAppList` | POST | 推荐列表 |
| `/app/appCheckUpdate` | POST | 批量更新检查 |
| `/visit/getNewAppList` | POST | 最新排行 |
| `/visit/getInstallAppList` | POST | 下载排行 |
| `/visit/getSearchAppVersionList` | POST | 版本列表 |
| `/visit/save` | POST | 旧安装记录 |
| `/web/suggest` | POST | 意见反馈 |
| `/app/uploadLog` | POST | 日志上传 |
| `/app/findShellString` | GET | 环境安装脚本 |
| `/app/saveVisitRecord` | POST | 访问统计 |
| `/app/saveInstalledRecord` | POST | 安装/卸载统计 |
| `/visit/getCustomMenuCategory` | GET | 自定义菜单 |
| `/visit/getRecommendAppList` | POST | 分类推荐 |
| `/visit/getAppListByCategoryIds` | POST | 按分类查询 |
| 外部: `ip-api.com` | GET | 客户端 IP |

#### Tauri IPC 命令（18 个）

| 命令 | 系统调用 | 超时 |
|------|----------|------|
| `get_running_linglong_apps` | `ll-cli ps` + `ll-cli list --json --type=all` | 30s×2 |
| `kill_linglong_app` | `ll-cli kill -s 9 {name}` ×5 | 30s×N |
| `get_installed_linglong_apps` | `ll-cli list --json [--type=all]` | 30s |
| `uninstall_app` | `ll-cli uninstall {id}/{ver}` | 30s |
| `search_versions` | `ll-cli search {id} --json` | 30s |
| `run_app` | `ll-cli run {id}` | fire-and-forget |
| `create_desktop_shortcut` | `ll-cli content {id}` | 30s |
| `install_app` | `ll-cli install {ref} --json -y [--force]` | 360s |
| `cancel_install` | `pkexec killall -15 ll-cli` | 无 |
| `prune_apps` | `ll-cli prune` | 30s |
| `search_remote_app_cmd` | `ll-cli search {id} --json` | 30s |
| `get_ll_cli_version_cmd` | `ll-cli --json --version` | 30s |
| `check_linglong_env_cmd` | 多个系统命令 | 30s |
| `install_linglong_env_cmd` | `pkexec bash /tmp/script.sh` | 无 |
| `get_network_speed` | 读 `/proc/net/dev` | 无 |
| `quit_app` | 进程退出 | 无 |
| 事件: `install-progress` | 安装进度推送 | — |
| `greet` | 内联 | 无 |

### 2.5 系统级能力

| 能力 | 原实现方式 | Flutter 对应 |
|------|-----------|-------------|
| 单实例 | tauri-plugin-single-instance | 自实现（锁文件/DBus） |
| 窗口管理 | @tauri-apps/api/window | window_manager |
| 拖拽标题栏 | data-tauri-drag-region | window_manager + GtkHeaderBar |
| 系统托盘 | tray.rs | system_tray (flutter_linux) |
| 日志 | tauri-plugin-log (10MB 轮转) | logger / ffi 桥接 |
| 文件系统 | tauri-plugin-fs | dart:io |
| 打开链接 | tauri-plugin-opener | url_launcher |
| 系统架构 | @tauri-apps/plugin-os → arch() | dart:io Platform |
| 状态持久化 | @tauri-store/zustand | shared_preferences / hive |
| NVIDIA workaround | 读 /proc/driver/nvidia | Dart 文件检测 |

---

## 三、Flutter 技术选型

### 3.1 核心依赖

| 类别 | 包名 | 版本 | 用途 | 替代说明 |
|------|------|------|------|---------|
| **状态管理** | `flutter_riverpod` | ^2.6.x | 替代 Zustand | 类型安全 + 自动 dispose + 类 Provider 模式 |
| **路由** | `go_router` | ^14.x | 替代 react-router-dom | 声明式路由 + 路由守卫 + 深链接 |
| **HTTP** | `dio` | ^5.x | 替代 Alova | 拦截器 + 超时 + 重试 |
| **HTTP 代码生成** | `retrofit` | ^4.x | 替代手写 API | 注解式 API 定义 + 类型安全 |
| **序列化** | `freezed` + `json_serializable` | latest | 替代 Zod | 不可变模型 + JSON 序列化 |
| **国际化** | `flutter_localizations` + `intl` | 内置 | 替代自研 i18n | 官方推荐方案 |
| **窗口管理** | `window_manager` | ^0.4.x | 替代 Tauri Window | 自定义标题栏 + 窗口控制 |
| **本地存储** | `shared_preferences` | ^2.x | 替代 @tauri-store | 键值对持久化 |
| **本地存储（结构化）** | `hive` + `hive_flutter` | ^2.x | localStorage 替代 | 列表缓存等结构化数据 |
| **进程调用** | `dart:io` Process | 内置 | 替代 Rust Command | ll-cli 命令执行 |
| **打开链接** | `url_launcher` | ^6.x | 替代 plugin-opener | 外部链接打开 |
| **图片缓存** | `cached_network_image` | ^3.x | 新增 | 应用图标/截图离线缓存 |
| **SVG 支持** | `flutter_svg` | ^2.x | 新增 | SVG 图标渲染 |
| **shimmer** | `shimmer` | ^3.x | 新增 | 骨架屏 shimmer 效果 |
| **剪贴板** | 内置 `Clipboard` | 内置 | 替代 navigator.clipboard | 复制操作 |
| **系统信息** | `device_info_plus` | ^10.x | 替代 plugin-os | 架构等系统信息 |
| **包信息** | `package_info_plus` | ^8.x | 新增 | 获取应用版本号 |
| **唯一 ID** | `uuid` | ^4.x | 替代 crypto.getRandomValues | 匿名 visitorId |
| **文件选择** | `file_picker` | ^8.x | 备用 | 日志文件操作 |
| **日志** | `logger` | ^2.x | 替代 tauri-plugin-log | 日志管理 |

### 3.2 开发工具链

| 工具 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | 3.24+ | 框架 |
| Dart SDK | 3.5+ | 语言 |
| `build_runner` | ^2.x | 代码生成（freezed/retrofit） |
| `freezed_annotation` | latest | Freezed 注解 |
| `json_annotation` | latest | JSON 注解 |
| `retrofit_generator` | latest | Retrofit 代码生成 |
| `flutter_lints` | latest | 静态分析 |
| `flutter_test` | 内置 | 测试框架 |
| `mockito` | ^5.x | Mock 测试 |
| `integration_test` | 内置 | 集成测试 |

### 3.3 Rust FFI 桥接（关键决策）

**方案分析：**

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| A: 纯 Dart Process | 最简单、无 Rust 依赖 | 缺少安装进度流式解析、性能不如 Rust | ★★★ |
| B: flutter_rust_bridge | 成熟方案、自动生成绑定 | 增加构建复杂度、学习成本 | ★★★★ |
| C: Dart FFI + 手写绑定 | 灵活可控 | 工作量大、易出错 | ★★ |
| D: 混合方案（Dart Process + 关键路径 Rust） | 平衡复杂度 | 两种技术栈维护 | ★★★★★ |

**推荐方案 D — 混合方案：**

- **Dart `Process`** 处理大多数 ll-cli 命令（list/search/run/kill/uninstall/prune）
- **Rust FFI（通过 flutter_rust_bridge）** 仅用于：
  - 安装流程（需要流式解析 JSON stdout + 超时监控 + 进度事件）
  - 网络速度监控（读 /proc/net/dev，需要高频轮询）
  - NVIDIA workaround（启动时检测）

这样可以复用现有 Rust 代码中最复杂的部分，同时简化大部分命令的实现。

### 3.4 构建与打包

| 平台 | 打包格式 | 工具 |
|------|----------|------|
| Linux (Debian/Ubuntu/Deepin/UOS) | .deb | `flutter build linux` + `dpkg-deb` |
| Linux (Fedora/openEuler) | .rpm | `flutter build linux` + `rpmbuild` |
| Linux (通用) | .AppImage | `flutter build linux` + `appimage-builder` |
| Linux (玲珑) | .layer | `ll-builder` |

---

## 四、模块对照映射表

### 4.1 页面映射

| 原路由 | 原组件 | Flutter 页面 | Flutter 路由 |
|--------|--------|-------------|-------------|
| `/` | Recommend | `RecommendPage` | `/` |
| `/allapps` | AllApps | `AllAppsPage` | `/allapps` |
| `/app_detail` | AppDetail | `AppDetailPage` | `/app_detail` |
| `/custom_category/:code` | CustomCategory | `CustomCategoryPage` | `/custom_category/:code` |
| `/my_apps` | MyApps | `MyAppsPage` | `/my_apps` |
| `/ranking` | Ranking | `RankingPage` | `/ranking` |
| `/search_list` | SearchList | `SearchListPage` | `/search_list` |
| `/setting` | Setting | `SettingPage` | `/setting` |
| `/update_apps` | UpdateApp | `UpdateAppPage` | `/update_apps` |
| (内嵌) | LaunchPage | `LaunchPage` | 初始路由 |

### 4.2 组件映射

| 原组件 | Flutter Widget | 备注 |
|--------|---------------|------|
| ApplicationCard | `ApplicationCard` | StatelessWidget + Consumer |
| ConnectedApplicationCard | `ConnectedApplicationCard` | ConsumerWidget (Riverpod) |
| ApplicationCardSkeleton | `ApplicationCardSkeleton` | Shimmer 效果 |
| ApplicationCarousel | `ApplicationCarousel` | PageView + Timer 自动轮播 |
| DownloadProgress | `DownloadProgressSheet` | showModalBottomSheet 或 Dialog |
| LinglongEnvDialog | `LinglongEnvDialog` | AlertDialog |
| KeepAliveOutlet | `IndexedStack` + `AutomaticKeepAliveClientMixin` | 页面缓存 |
| SpeedTool | `SpeedToolWidget` | StreamBuilder |
| Titlebar | `CustomTitleBar` | PreferredSizeWidget |
| Sidebar | `NavigationSidebar` | NavigationRail 自定义 |

### 4.3 状态管理映射

| Zustand Store | Riverpod Provider | 类型 |
|---------------|------------------|------|
| useGlobalStore | `globalProvider` | StateNotifierProvider |
| useSearchStore | `searchProvider` | StateProvider<String> |
| useConfigStore | `configProvider` | AsyncNotifierProvider（持久化） |
| useInstallQueueStore | `installQueueProvider` | StateNotifierProvider |
| useInstalledAppsStore | `installedAppsProvider` | AsyncNotifierProvider |
| useUpdatesStore | `updatesProvider` | AsyncNotifierProvider |

### 4.4 Hook → Provider/Controller 映射

| React Hook | Flutter 等价 | 实现方式 |
|------------|-------------|---------|
| useLaunch | `LaunchController` | Riverpod AsyncNotifier |
| useAppInstall | `AppInstallController` | Riverpod Notifier |
| useAppUninstall | `AppUninstallController` | Riverpod Notifier |
| useApplicationCardModel | `applicationCardModelProvider` | Riverpod Provider (computed) |
| useAutoLoadWhenNotScrollable | `ScrollPaginationController` | ScrollController + NotificationListener |
| useCachedPaginatedList | `CachedPaginatedListNotifier` | Riverpod family + Hive 缓存 |
| usePaginatedList | `PaginatedListNotifier` | Riverpod family |
| useCheckUpdates | `updatesProvider` 的方法 | 合入 updatesProvider |
| useGlobalInstallProgress | `installProgressProvider` | Riverpod StreamProvider |
| useKeepAliveVisibility | `RouteAware` + `VisibilityDetector` | Widget mixin |
| useLinglongEnv | `linglongEnvProvider` | Riverpod AsyncNotifier |
| useLinglongProcesses | `linglongProcessesProvider` | Riverpod StreamNotifier + Timer |
| useMenuBadges | `menuBadgesProvider` | Riverpod computed Provider |
| useUploadStore | `appUpdateProvider` | Riverpod AsyncNotifier |

### 4.5 服务层映射

| 原服务 | Flutter 等价 | 实现方式 |
|--------|-------------|---------|
| appListCache (seed+localStorage+刷新) | `AppListCacheService` | Hive 存储 + 构建期 seed JSON 资源 |
| analyticsService | `AnalyticsService` | 单例 + dio |
| installService | 合入 `AppInstallController` | 简化 |
| request.ts (Alova) | `ApiClient` (dio) | 单例 + 拦截器 |
| invoke/ (Tauri IPC) | `LinglongCliService` | Process + Rust FFI |
| invoke/schemas.ts (Zod) | Freezed 模型自动校验 | json_serializable |

---

## 五、关键技术难点与解决方案

### 5.1 KeepAlive 页面缓存

**原实现：** `KeepAliveOutlet` 通过 `display:none` 隐藏页面，LRU 最多 10 页，注入可见性 Context。

**Flutter 方案：**
```
IndexedStack (显示当前页) 
  + AutomaticKeepAliveClientMixin (保持页面状态)
  + RouteObserver/自定义 VisibilityNotifier (可见性通知)
```

- 使用 `IndexedStack` 配合路由索引实现页面保活
- 每个需要保活的页面混入 `AutomaticKeepAliveClientMixin`
- 通过 `VisibilityNotifier` (InheritedWidget) 注入可见状态
- LRU 淘汰通过维护 `List<String>` 访问顺序实现
- 可见性变化时通知子组件暂停/恢复副作用

### 5.2 无限滚动 + 缓存分页

**原实现：** `useCachedPaginatedList` = seed 数据 + localStorage 运行时缓存 + 请求代次控制 + KeepAlive 可见性门控。

**Flutter 方案：**
- Riverpod `family` Provider（以 cacheKey 为参数）
- `ScrollController` + `NotificationListener<ScrollNotification>` 监听触底
- `LayoutBuilder` + `WidgetsBinding.addPostFrameCallback` 替代 ResizeObserver 检测"未撑满自动补页"
- Hive box 存储运行时缓存快照
- 构建期 seed 数据作为 Flutter assets（JSON 文件）
- 请求代次 (generation) 通过 `CancelToken` + 递增计数器实现

### 5.3 安装进度流式解析

**原实现：** Rust 异步 spawn `ll-cli install --json` → stdout 逐行读取 → JSON 解析 → Tauri event 推送前端。

**Flutter 方案（通过 Rust FFI）：**
- 保留现有 Rust 安装模块代码
- 通过 `flutter_rust_bridge` 暴露流式 API
- Dart 端通过 `Stream<InstallProgress>` 接收进度
- 全局 `StreamController` 广播安装事件

**备选方案（纯 Dart）：**
- `Process.start()` 获取 `Process` 实例
- `process.stdout.transform(utf8.decoder).transform(LineSplitter())` 逐行读取
- 自行解析 JSON 行并发射事件
- 超时通过 `Timer` + 最后进度时间戳实现

### 5.4 系统托盘 & 窗口管理

**原实现：** Tauri 无装饰窗口 + 自定义标题栏 + tray.rs 托盘。

**Flutter 方案：**
- `window_manager` 设置无装饰窗口、最小尺寸、拖拽区域
- 自定义 `TitleBar` Widget 实现最小化/最大化/关闭
- `system_tray` 包实现系统托盘
- 关闭时检查安装队列，确认后退出

### 5.5 单实例控制

**原实现：** `tauri-plugin-single-instance`

**Flutter 方案：**
- 方案 A: 使用 `single_instance` 包（基于 TCP socket）
- 方案 B: 自实现文件锁 (`/tmp/linglong-store.lock`) + DBus 信号
- 检测到重复实例时激活已有窗口 (`window_manager.focus()`)

### 5.6 NVIDIA DMABUF Workaround

**原实现：** Rust 启动时检测 `/proc/driver/nvidia/version`，设置环境变量。

**Flutter 方案：**
- 在 `main()` 中检测 NVIDIA GPU
- 设置 `WEBKIT_DISABLE_DMABUF_RENDERER=1`（仅影响 WebView 场景）
- Flutter 本身不使用 WebView，此 workaround **可能不需要**
- 但如果 Flutter GTK embedding 有类似问题，保留检测逻辑

### 5.7 错误码体系

**原实现：** `installErrorCodes.ts` — 40+ 错误码 → i18n key 映射。

**Flutter 方案：**
- 创建 `InstallErrorCode` 枚举
- 每个错误码映射到 `AppLocalizations` 的 key
- `getInstallErrorMessage()` 函数保持相同逻辑

---

## 六、迁移风险评估

### 6.1 高风险项

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| Flutter Linux 桌面成熟度不如 Web | 可能有平台 bug | 早期验证关键功能，建立 issue 跟踪 |
| Ant Design 组件在 Flutter 无直接替代 | UI 还原工作量大 | 建立自定义组件库，逐一对标 |
| KeepAlive 在 Flutter 复杂度高 | 可能有内存泄漏 | 严格测试 + 内存监控 |
| ll-cli 命令输出解析 | Dart 正则/JSON 解析兼容性 | 保留 Rust 解析层用 FFI 桥接 |
| 安装进度流式通信 | Dart Process stdout 可能有不同行为 | 先验证 Pure Dart 方案，不行用 Rust FFI |

### 6.2 中风险项

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| 自定义标题栏在不同 Linux DE 下表现不一 | 拖拽/按钮可能异常 | 测试 GNOME/KDE/DDE/Wayland/X11 |
| 构建打包覆盖多个 Linux 发行版 | 打包脚本复杂 | 复用现有 build/ 目录逻辑 |
| 字体渲染差异 | 中文字体可能不一致 | 明确字体回退链，必要时嵌入字体 |
| Hive 存储大量缓存数据性能 | 列表缓存读写可能慢 | 设置大小限制 + 异步读写 |

### 6.3 低风险项

| 风险 | 影响 | 缓解策略 |
|------|------|---------|
| Dart Process 执行 ll-cli | 基本等价 Rust Command | 充分测试各种 ll-cli 输出格式 |
| go_router 路由功能 | 全覆盖 react-router 功能 | 标准方案，风险极低 |
| dio HTTP 请求 | 完全覆盖 Alova 功能 | 成熟方案 |

---

## 七、质量保障策略

### 7.1 测试计划

| 测试类型 | 覆盖范围 | 工具 |
|----------|---------|------|
| 单元测试 | 所有 Provider/Service/Model | flutter_test + mockito |
| Widget 测试 | 所有自定义组件 | flutter_test |
| 集成测试 | 关键用户流程 | integration_test |
| 平台测试 | 多 Linux 发行版 | 手动 + CI (Docker) |
| 性能测试 | 列表滚动/内存/启动时间 | flutter_driver + DevTools |
| 回归对比 | 逐页截图对比 | 手动 + 像素对比工具 |

### 7.2 验收标准

每个模块迁移完成的验收条件：

1. **功能验收**：所有原有功能点通过功能测试用例
2. **UI 验收**：逐页截图对比，差异率 < 5%（允许平台渲染差异）
3. **性能验收**：
   - 启动时间 ≤ 原版 +20%
   - 列表滚动 60fps
   - 内存使用 ≤ 原版 +30%
4. **测试覆盖**：单元测试覆盖率 ≥ 80%
5. **代码审查**：通过至少一位其他开发者的 Code Review

---

## 八、环境搭建

### 8.1 开发环境

```bash
# 1. 安装 Flutter SDK
sudo snap install flutter --classic
# 或手动安装
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# 2. 安装 Linux 桌面开发依赖
sudo apt-get install -y \
  clang cmake git ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev

# 3. 安装 Rust（如需 FFI）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 4. 安装 flutter_rust_bridge 工具（如需）
cargo install flutter_rust_bridge_codegen

# 5. 验证环境
flutter doctor
flutter config --enable-linux-desktop

# 6. 创建项目
flutter create --platforms=linux linglong_store
```

### 8.2 项目初始化配置

```yaml
# pubspec.yaml 关键配置
name: linglong_store
description: 玲珑应用商店社区版
version: 3.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # ... 详见架构设计文档中的完整依赖列表

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
    - assets/seeds/
    - assets/i18n/
```

---

## 九、交付物清单

迁移完成后应交付：

| 编号 | 交付物 | 说明 |
|------|--------|------|
| D01 | Flutter 源码 | 完整可编译运行的 Flutter 项目 |
| D02 | 构建脚本 | deb/rpm/AppImage 打包脚本 |
| D03 | 单元测试 | 覆盖率 ≥ 80% |
| D04 | 集成测试 | 关键流程自动化 |
| D05 | UI 对比报告 | 逐页截图对比 |
| D06 | 性能对比报告 | 启动时间/内存/帧率 |
| D07 | CHANGELOG | 迁移变更记录 |
| D08 | 部署文档 | 各发行版安装说明 |
| D09 | 开发者文档 | 架构说明 + 开发指南 |

---

## 十、迁移排除项

以下内容**不在**本次迁移范围内：

1. **新增功能**：仅还原现有功能，不新增
2. **后端 API 变更**：远程 API 保持不变
3. **ll-cli 版本更新**：基于当前 ll-cli 行为迁移
4. **macOS/Windows 支持**：仅面向 Linux
5. **自动化 CI/CD**：可后续补充
6. **E2E 自动化测试**：首版以手动验收为主

---

## 附录 A：术语表

| 术语 | 说明 |
|------|------|
| 玲珑 (Linglong) | 深度科技开发的应用容器化格式 |
| ll-cli | 玲珑命令行工具 |
| KeepAlive | 页面保活/缓存机制 |
| Seed 数据 | 构建时预生成的首屏缓存数据 |
| 代次控制 | 请求版本号机制，用于废弃过期响应 |
| 槽位 (Slot) | 全局单一安装任务锁 |

## 附录 B：参考文档

- [Flutter Linux Desktop 官方文档](https://docs.flutter.dev/platform-integration/linux/building)
- [Riverpod 文档](https://riverpod.dev/)
- [go_router 文档](https://pub.dev/packages/go_router)
- [flutter_rust_bridge 文档](https://cjycode.com/flutter_rust_bridge/)
- [window_manager 文档](https://pub.dev/packages/window_manager)
