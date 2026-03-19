# Flutter 架构设计文档

> 文档版本: 1.0 | 创建日期: 2026-03-15

---

## 一、架构总览

### 1.1 分层架构

```
┌─────────────────────────────────────────────────────┐
│                   Presentation Layer                 │
│   Pages / Widgets / Controllers (Riverpod)          │
├─────────────────────────────────────────────────────┤
│                  Application Layer                   │
│   Use Cases / Services / State Notifiers            │
├─────────────────────────────────────────────────────┤
│                    Domain Layer                      │
│   Models (Freezed) / Repository Interfaces          │
├─────────────────────────────────────────────────────┤
│                    Data Layer                        │
│   API Client (dio) / CLI Executor / Local Storage   │
├─────────────────────────────────────────────────────┤
│                   Platform Layer                     │
│   Dart:io Process / Rust FFI / Window Manager       │
└─────────────────────────────────────────────────────┘
```

### 1.2 依赖方向

```
Presentation → Application → Domain ← Data ← Platform
```

- **Presentation** 依赖 **Application**（通过 Riverpod Provider）
- **Application** 依赖 **Domain**（Repository 接口）
- **Data** 实现 **Domain** 的 Repository 接口
- **Platform** 被 **Data** 层调用
- **Domain** 层不依赖任何其他层（纯业务模型）

---

## 二、目录结构

```
lib/
├── main.dart                              # 应用入口
├── app.dart                               # MaterialApp 配置
│
├── core/                                  # 核心基础设施
│   ├── config/                            # 应用配置
│   │   ├── app_config.dart                # 环境变量、API 地址
│   │   ├── theme.dart                     # 主题定义
│   │   └── routes.dart                    # 路由配置 (go_router)
│   │
│   ├── di/                                # 依赖注入（Riverpod 定义汇总）
│   │   └── providers.dart                 # 全局 ProviderContainer
│   │
│   ├── network/                           # 网络层
│   │   ├── api_client.dart                # dio 实例 + 拦截器
│   │   ├── api_interceptors.dart          # 请求/响应拦截器
│   │   └── api_exceptions.dart            # 网络异常定义
│   │
│   ├── storage/                           # 本地存储
│   │   ├── preferences_service.dart       # SharedPreferences 封装
│   │   ├── cache_service.dart             # Hive 缓存封装
│   │   └── seed_data_service.dart         # 构建期 seed 数据读取
│   │
│   ├── platform/                          # 平台能力
│   │   ├── cli_executor.dart              # ll-cli 命令执行器（统一超时/locale）
│   │   ├── process_manager.dart           # 进程管理工具
│   │   ├── window_service.dart            # 窗口管理封装
│   │   ├── single_instance.dart           # 单实例控制
│   │   └── nvidia_workaround.dart         # NVIDIA DMABUF 检测
│   │
│   ├── i18n/                              # 国际化
│   │   ├── l10n/                          # ARB 文件
│   │   │   ├── app_zh.arb                 # 中文资源
│   │   │   └── app_en.arb                 # 英文资源
│   │   ├── app_localizations.dart         # 生成的本地化类
│   │   └── locale_provider.dart           # 语言切换 Provider
│   │
│   ├── constants/                         # 全局常量
│   │   ├── app_constants.dart             # 应用常量
│   │   ├── operate_type.dart              # 操作类型枚举
│   │   └── install_error_codes.dart       # 安装错误码
│   │
│   ├── utils/                             # 工具函数
│   │   ├── version_compare.dart           # 版本号比较
│   │   ├── format_utils.dart              # 格式化（文件大小等）
│   │   ├── debounce_throttle.dart         # 防抖/节流
│   │   └── app_display.dart              # 应用名称/描述展示规则
│   │
│   └── logging/                           # 日志
│       └── app_logger.dart                # 日志配置 + 文件轮转
│
├── domain/                                # 领域层（纯模型 + 接口）
│   ├── models/                            # 数据模型 (Freezed)
│   │   ├── app_main_dto.dart              # 应用基础信息
│   │   ├── app_main_dto.freezed.dart      # (生成)
│   │   ├── app_main_dto.g.dart            # (生成)
│   │   ├── installed_app.dart             # 已安装应用
│   │   ├── enriched_installed_app.dart    # 丰富后的已安装应用
│   │   ├── install_progress.dart          # 安装进度事件
│   │   ├── install_task.dart              # 安装任务
│   │   ├── running_app.dart               # 运行中应用
│   │   ├── search_result_item.dart        # 搜索结果
│   │   ├── app_detail_dto.dart            # 应用详情
│   │   ├── app_screenshot.dart            # 应用截图
│   │   ├── app_category.dart              # 应用分类
│   │   ├── custom_menu_category.dart      # 自定义菜单分类
│   │   ├── page_data.dart                 # 分页数据
│   │   ├── base_response.dart             # API 响应包装
│   │   ├── network_speed.dart             # 网络速度
│   │   ├── linglong_env_check.dart        # 环境检测结果
│   │   ├── update_info.dart               # 更新信息
│   │   └── linglong_repo.dart             # 仓库信息
│   │
│   └── repositories/                      # Repository 接口
│       ├── app_repository.dart            # 应用相关 API
│       ├── linglong_cli_repository.dart   # ll-cli 操作
│       └── analytics_repository.dart      # 统计上报
│
├── data/                                  # 数据层（接口实现）
│   ├── repositories/                      # Repository 实现
│   │   ├── app_repository_impl.dart       # HTTP API 实现
│   │   ├── linglong_cli_repository_impl.dart  # ll-cli 实现
│   │   └── analytics_repository_impl.dart # 统计实现
│   │
│   ├── datasources/                       # 数据源
│   │   ├── remote/                        # 远程数据源
│   │   │   ├── app_api_service.dart       # Retrofit 接口定义
│   │   │   └── app_api_service.g.dart     # (生成)
│   │   │
│   │   └── local/                         # 本地数据源
│   │       ├── installed_apps_local.dart   # 已安装应用本地缓存
│   │       └── app_list_cache_local.dart   # 列表缓存本地存储
│   │
│   └── mappers/                           # 数据映射
│       ├── app_mapper.dart                # API DTO → Domain Model
│       └── cli_output_parser.dart         # CLI 输出 → Domain Model
│
├── application/                           # 应用层（业务编排）
│   ├── providers/                         # Riverpod Providers
│   │   ├── global_provider.dart           # 全局状态
│   │   ├── search_provider.dart           # 搜索状态
│   │   ├── config_provider.dart           # 持久化配置
│   │   ├── install_queue_provider.dart    # 安装队列
│   │   ├── installed_apps_provider.dart   # 已安装应用
│   │   ├── updates_provider.dart          # 更新检查
│   │   ├── install_progress_provider.dart # 安装进度流
│   │   └── linglong_env_provider.dart     # 环境检测
│   │
│   ├── controllers/                       # 业务控制器
│   │   ├── launch_controller.dart         # 启动初始化
│   │   ├── app_install_controller.dart    # 安装逻辑
│   │   ├── app_uninstall_controller.dart  # 卸载逻辑
│   │   ├── process_controller.dart        # 进程管理
│   │   └── app_update_controller.dart     # 客户端更新
│   │
│   └── services/                          # 应用服务
│       ├── app_list_cache_service.dart    # 列表混合缓存
│       ├── analytics_service.dart         # 匿名统计
│       └── app_change_sync_service.dart   # 安装/卸载后同步刷新
│
├── presentation/                          # 展示层
│   ├── app_shell.dart                     # AppShell（Titlebar + Sidebar + Content）
│   │
│   ├── widgets/                           # 通用 Widget
│   │   ├── application_card.dart          # 应用卡片
│   │   ├── connected_application_card.dart # Store 绑定卡片
│   │   ├── application_card_skeleton.dart # 骨架屏卡片
│   │   ├── application_carousel.dart      # 轮播组件
│   │   ├── download_progress_dialog.dart  # 下载管理弹窗
│   │   ├── linglong_env_dialog.dart       # 环境检测弹窗
│   │   ├── speed_tool_widget.dart         # 网速显示
│   │   ├── paginated_grid_view.dart       # 通用分页网格（含自动补页）
│   │   └── empty_state.dart              # 空状态占位
│   │
│   ├── layout/                            # 布局组件
│   │   ├── title_bar.dart                 # 自定义标题栏
│   │   ├── sidebar.dart                   # 侧边栏导航
│   │   ├── launch_page.dart              # 启动页
│   │   └── keep_alive_scaffold.dart       # 页面保活脚手架
│   │
│   └── pages/                             # 页面
│       ├── recommend/                     # 推荐页
│       │   └── recommend_page.dart
│       ├── all_apps/                      # 全部应用
│       │   └── all_apps_page.dart
│       ├── app_detail/                    # 应用详情
│       │   ├── app_detail_page.dart
│       │   └── widgets/                   # 详情页子组件
│       │       ├── app_header.dart
│       │       ├── app_description.dart
│       │       ├── app_screenshots.dart
│       │       └── version_table.dart
│       ├── custom_category/               # 自定义分类
│       │   └── custom_category_page.dart
│       ├── my_apps/                       # 我的应用
│       │   ├── my_apps_page.dart
│       │   ├── widgets/
│       │   │   ├── installed_apps_tab.dart
│       │   │   └── process_tab.dart
│       │   │       ├── process_toolbar.dart
│       │   │       └── process_table.dart
│       ├── ranking/                       # 排行榜
│       │   └── ranking_page.dart
│       ├── search_list/                   # 搜索结果
│       │   └── search_list_page.dart
│       ├── setting/                       # 设置
│       │   ├── setting_page.dart
│       │   └── widgets/
│       │       ├── base_setting_tab.dart
│       │       └── about_tab.dart
│       └── update_app/                    # 应用更新
│           └── update_app_page.dart
│
├── rust/                                  # Rust FFI 模块（可选）
│   ├── src/
│   │   ├── api.rs                         # flutter_rust_bridge 暴露的 API
│   │   ├── install/                       # 复用的安装模块
│   │   └── network.rs                     # 复用的网速模块
│   └── Cargo.toml
│
assets/
├── icons/                                 # 图标资源
│   ├── logo.svg                           # 应用 Logo
│   ├── linyaps.svg                        # 默认应用图标
│   ├── carousel_bg.svg                    # 轮播背景
│   ├── my_apps.svg                        # 我的应用图标
│   ├── download.svg                       # 下载图标
│   ├── setting.svg                        # 设置图标
│   ├── feedback.svg                       # 反馈图标
│   └── upgrade.svg                        # 升级图标
│
├── seeds/                                 # 构建期 seed 缓存
│   ├── recommend_main.json
│   ├── all_apps_main.json
│   └── ranking_new.json
│
└── fonts/                                 # 字体（可选，确保中文渲染一致）
    └── (如需嵌入字体)

test/
├── unit/                                  # 单元测试
│   ├── domain/                            # 模型测试
│   ├── data/                              # Repository 测试
│   ├── application/                       # Provider/Controller 测试
│   └── core/                              # 工具函数测试
│
├── widget/                                # Widget 测试
│   ├── widgets/                           # 通用组件测试
│   └── pages/                             # 页面测试
│
├── golden/                                # Golden 截图基线与对比
│   ├── widgets/
│   └── pages/
│
├── mcp/                                   # MCP 驱动 UI 场景
│   ├── smoke/
│   ├── regression/
│   └── performance/
│
└── integration/                           # 集成测试
    └── app_test.dart

tool/
├── benchmarks/                            # 基准测试脚本
└── perf_reports/                          # 性能报告输出

linux/                                     # Linux 平台配置
├── CMakeLists.txt
├── my_application.h
├── my_application.cc
└── ...
```

---

## 三、核心模块详细设计

> 启动链路已在 2026-03-18 收敛为“单一 `LaunchPage / LaunchSequence` + 首帧同步状态恢复”。
> 详细约束与业务细节见：[`11-startup-flow-and-first-frame-restore.md`](./11-startup-flow-and-first-frame-restore.md)。

### 3.1 应用入口 (main.dart)

```dart
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化日志
  await AppLogger.init();

  // 2. 单实例检测
  final isFirstInstance = await SingleInstance.ensure();
  if (!isFirstInstance) {
    exit(0);
  }

  // 3. 初始化窗口管理器
  await WindowService.init();

  // 4. 初始化本地存储
  await PreferencesService.init();
  final sharedPreferences = await SharedPreferences.getInstance();

  // 5. 初始化网络客户端
  ApiClient.init(
    localeGetter: () =>
        sharedPreferences.getString('linglong-store-language') ?? 'zh',
  );

  // 6. 初始化缓存
  await Hive.initFlutter();

  // 7. 显示窗口
  await WindowService.show();

  // 8. 启动
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LinglongStoreApp(),
    ),
  );
}
```

当前实现约束：

- `main()` 只负责系统级引导，不再承载业务启动流程
- `SharedPreferences` 必须在 `runApp()` 前准备好，并通过 `ProviderScope` 注入
- `MaterialApp` 首帧依赖的语言、主题、基础设置，必须由 Provider 在 `build()` 阶段同步恢复
- 路由外不得再增加第二个“正在初始化”占位页

### 3.2 路由配置 (routes.dart)

```dart
import 'package:go_router/go_router.dart';

// 路由路径常量
abstract class AppRoutes {
  static const launch = '/launch';
  static const recommend = '/';
  static const allApps = '/allapps';
  static const appDetail = '/app_detail';
  static const customCategory = '/custom_category/:code';
  static const myApps = '/my_apps';
  static const ranking = '/ranking';
  static const searchList = '/search_list';
  static const setting = '/setting';
  static const updateApps = '/update_apps';
}

// KeepAlive 白名单
const keepAliveRoutes = {
  AppRoutes.recommend,
  AppRoutes.allApps,
  AppRoutes.searchList,
  AppRoutes.ranking,
};

// 路由配置
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.launch,
    routes: [
      GoRoute(
        path: AppRoutes.launch,
        builder: (_, __) => const LaunchPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const RecommendPage()),
          GoRoute(path: '/allapps', builder: (_, __) => const AllAppsPage()),
          GoRoute(path: '/app_detail', builder: (_, state) => AppDetailPage(
            appInfo: state.extra as EnrichedInstalledApp,
          )),
          GoRoute(path: '/custom_category/:code', builder: (_, state) => 
            CustomCategoryPage(code: state.pathParameters['code']!)),
          GoRoute(path: '/my_apps', builder: (_, __) => const MyAppsPage()),
          GoRoute(path: '/ranking', builder: (_, __) => const RankingPage()),
          GoRoute(path: '/search_list', builder: (_, __) => const SearchListPage()),
          GoRoute(path: '/setting', builder: (_, __) => const SettingPage()),
          GoRoute(path: '/update_apps', builder: (_, __) => const UpdateAppPage()),
        ],
      ),
    ],
    redirect: (context, state) {
      final launchState = ref.read(launchSequenceProvider);
      final currentPath = state.matchedLocation;

      if (!launchState.isCompleted && currentPath != AppRoutes.launch) {
        return AppRoutes.launch;
      }

      if (launchState.isCompleted && currentPath == AppRoutes.launch) {
        return AppRoutes.recommend;
      }

      return null;
    },
  );
});
```

当前实现约束：

- 初始路由必须进入 `LaunchPage`
- 首页是否可进入，由 `launchSequenceProvider` 的完成态控制
- 启动失败、重试、跳过、环境弹窗，都收口在正式启动页内处理

### 3.3 首帧状态恢复

以下 Provider 需要在 `build()` 同步恢复本地状态：

- `globalAppProvider`
  - 当前语言
  - 当前主题模式
  - 用户偏好
- `settingProvider`
  - 当前语言
  - 当前主题模式
  - 当前仓库名
- `installQueueProvider`
  - 当前任务
  - 队列快照

这样做的目的：

- 避免 `MaterialApp` 首帧主题、语言闪烁
- 避免依赖异步 `init()` 再写状态触发二次重建
- 把本地快照恢复与正式启动业务流程分层

### 3.4 正式启动流程

`LaunchSequence` 负责正式业务启动步骤：

1. 环境检测
2. 已安装应用初始化
3. 更新检查
4. 安装队列恢复与纠偏
5. 完成后跳转首页

其中：

- 首帧主题/语言恢复不属于 `LaunchSequence`
- 设置页缓存大小统计不属于启动关键路径
- 非关键路径工作必须延后到相应页面再异步执行

### 3.5 主题系统 (theme.dart)

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // 主色
  static const Color primaryColor = Color(0xFF016FFD);
  
  // 卡片颜色（硬编码值，非主题变量）
  static const Color cardBackground = Color(0xFFF6F6F6);
  static const Color cardBorder = Color(0xFFF6F6F6);
  
  // "打开"按钮样式
  static const Color openButtonBackground = Color(0xFFFFFFFF);
  static const Color openButtonBorder = Color(0xFFD8D8D8);
  static const Color openButtonText = Color(0xFF2C2C2C);
  
  // "精品"标签颜色
  static const Color topLabelColor = Color(0xFFCDA354);
  
  // Modal 阴影
  static const Color modalShadow = Color.fromRGBO(15, 23, 42, 0.16);
  static const Color modalBorder = Color.fromRGBO(15, 23, 42, 0.08);
  
  // 蓝色竖条 indicator（设置页）
  static const Color indicatorColor = Color(0xFF016FFD);
  
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
    ),
    fontFamily: 'Inter, Avenir, Helvetica, Arial',
    textTheme: const TextTheme(
      // 对齐原项目字体层次
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),  // 2rem
      headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w500), // 1.625rem
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w500), // 1.5rem
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),   // 1.25rem
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),  // 1rem
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),    // 0.875rem
      bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),   // 0.75rem
      bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),    // 0.625rem
    ),
    // 卡片主题
    cardTheme: CardTheme(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 0.5rem
        side: const BorderSide(color: cardBorder),
      ),
    ),
    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const StadiumBorder(),
        minimumSize: const Size(68, 28), // 4.25rem × 小尺寸
      ),
    ),
    // 弹窗主题
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,  // 手动设置阴影
    ),
  );
}
```

### 3.4 Network 层 (api_client.dart)

```dart
import 'package:dio/dio.dart';

class ApiClient {
  static late final Dio instance;
  
  static void init({required String baseUrl}) {
    instance = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 请求拦截器
    instance.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 注入 Accept-Language
        final locale = LocaleProvider.currentLocale;
        options.headers['Accept-Language'] = locale.toLanguageTag();
        handler.next(options);
      },
      onResponse: (response, handler) {
        // 统一响应校验
        final data = response.data;
        if (data is Map && data['code'] != null && data['code'] != 200) {
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: data['message'] ?? '请求失败',
          ));
          return;
        }
        handler.next(response);
      },
    ));
    
    // GET 缓存拦截 (5分钟)
    instance.interceptors.add(CacheInterceptor(duration: Duration(minutes: 5)));
  }
}
```

### 3.5 CLI 执行器 (cli_executor.dart)

```dart
import 'dart:io';
import 'dart:convert';

/// ll-cli 命令统一执行器
/// 对标原 Rust executor.rs
class CliExecutor {
  static const _defaultTimeout = Duration(seconds: 30);
  
  /// 强制英文 locale 环境变量（确保输出可解析）
  static const _englishLocaleEnv = {
    'LC_ALL': 'C.UTF-8',
    'LANG': 'C.UTF-8',
    'LANGUAGE': 'C.UTF-8',
    'LC_MESSAGES': 'C.UTF-8',
  };
  
  /// 执行 ll-cli 命令（不检查退出码）
  static Future<CliOutput> execute(
    List<String> args, {
    String label = '',
    Duration timeout = _defaultTimeout,
  }) async {
    final process = await Process.start('ll-cli', args, environment: _englishLocaleEnv);
    
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    
    final exitCode = await process.exitCode.timeout(timeout, onTimeout: () {
      process.kill(ProcessSignal.sigkill);
      throw CliTimeoutException('执行超时 (${timeout.inSeconds}s)', label);
    });
    
    return CliOutput(
      stdout: await stdoutFuture,
      stderr: await stderrFuture, 
      success: exitCode == 0,
      statusCode: exitCode,
    );
  }
  
  /// 执行 ll-cli 命令（退出码非零返回 Error）
  static Future<String> executeOrErr(
    List<String> args, {
    String label = '',
    Duration timeout = _defaultTimeout,
  }) async {
    final output = await execute(args, label: label, timeout: timeout);
    if (!output.success) {
      throw CliExecutionException(output.stderr, output.statusCode, label);
    }
    return output.stdout;
  }
}

class CliOutput {
  final String stdout;
  final String stderr;
  final bool success;
  final int statusCode;
  
  const CliOutput({
    required this.stdout,
    required this.stderr,
    required this.success,
    required this.statusCode,
  });
}
```

### 3.6 状态管理设计 (Riverpod)

#### 全局状态 Provider

```dart
// application/providers/global_provider.dart

@freezed
class GlobalState with _$GlobalState {
  const factory GlobalState({
    @Default(false) bool isInited,
    String? arch,
    String? repoName,
    String? appVersion,
    @Default(false) bool checking,
    @Default(false) bool installing,
    @Default(false) bool checked,
    @Default(false) bool envReady,
    String? reason,
    String? osVersion,
    String? glibcVersion,
    String? kernelInfo,
    String? llVersion,
    String? llBinVersion,
    String? detailMsg,
    @Default([]) List<LinglongRepo> repos,
    @Default(false) bool isContainer,
    String? visitorId,
    String? clientIp,
    @Default([]) List<CustomMenuCategory> customMenuCategory,
  }) = _GlobalState;
}

class GlobalNotifier extends StateNotifier<GlobalState> {
  GlobalNotifier() : super(const GlobalState());
  
  void onInited() => state = state.copyWith(isInited: true);
  void setArch(String arch) => state = state.copyWith(arch: arch);
  void setRepoName(String name) => state = state.copyWith(repoName: name);
  // ... 其他方法保持不可变更新模式
}

final globalProvider = StateNotifierProvider<GlobalNotifier, GlobalState>(
  (ref) => GlobalNotifier(),
);
```

#### 安装队列 Provider

```dart
// application/providers/install_queue_provider.dart

@freezed
class InstallQueueState with _$InstallQueueState {
  const factory InstallQueueState({
    @Default([]) List<InstallTask> queue,
    InstallTask? currentTask,
    @Default([]) List<InstallTask> history,
    @Default(false) bool isProcessing,
  }) = _InstallQueueState;
}

class InstallQueueNotifier extends StateNotifier<InstallQueueState> {
  final Ref _ref;
  
  InstallQueueNotifier(this._ref) : super(const InstallQueueState());
  
  /// 入队安装任务（严格串行）
  void enqueueInstall(InstallTask task) {
    state = state.copyWith(
      queue: [...state.queue, task],
    );
    _processQueue();
  }
  
  /// 批量入队
  void enqueueBatch(List<InstallTask> tasks) {
    state = state.copyWith(
      queue: [...state.queue, ...tasks],
    );
    _processQueue();
  }
  
  /// 处理队列（从头取出一个执行）
  Future<void> _processQueue() async {
    if (state.isProcessing || state.queue.isEmpty) return;
    // ... 实现安装流程
  }
  
  /// 更新进度
  void updateProgress(String appId, double percentage, String message) {
    if (state.currentTask?.appId == appId) {
      state = state.copyWith(
        currentTask: state.currentTask!.copyWith(
          progress: percentage,
          message: message,
        ),
      );
    }
  }
  
  /// 标记成功
  void markSuccess(String appId) { /* ... */ }
  
  /// 标记失败  
  void markFailed(String appId, String error, {int? code}) { /* ... */ }
  
  /// 检查崩溃恢复
  Future<void> checkRecovery() async { /* ... */ }
}

final installQueueProvider = 
    StateNotifierProvider<InstallQueueNotifier, InstallQueueState>(
  (ref) => InstallQueueNotifier(ref),
);
```

### 3.7 页面保活方案 (keep_alive_scaffold.dart)

```dart
/// 页面保活脚手架
/// 对标原 KeepAliveOutlet 的 display:none 切换方案
class KeepAliveScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const KeepAliveScaffold({required this.child, super.key});
  
  @override
  ConsumerState<KeepAliveScaffold> createState() => _KeepAliveScaffoldState();
}

class _KeepAliveScaffoldState extends ConsumerState<KeepAliveScaffold> {
  // 保活页面列表，按访问顺序排列（LRU）
  final List<_CachedPage> _cachedPages = [];
  static const _maxCachedPages = 10;
  
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: _cachedPages.map((p) => 
        _VisibilityWrapper(
          isVisible: p == _currentPage,
          child: p.widget,
        ),
      ).toList(),
    );
  }
}

/// 可见性通知 InheritedWidget
/// 对标原 KeepAliveVisibilityContext
class KeepAliveVisibility extends InheritedWidget {
  final bool isVisible;
  final String pathname;
  
  const KeepAliveVisibility({
    required this.isVisible,
    required this.pathname,
    required super.child,
    super.key,
  });
  
  static KeepAliveVisibility? of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<KeepAliveVisibility>();
  
  @override
  bool updateShouldNotify(KeepAliveVisibility old) => 
    isVisible != old.isVisible || pathname != old.pathname;
}
```

### 3.8 分页列表方案

```dart
/// 通用分页网格视图
/// 对标原 usePaginatedList + useAutoLoadWhenNotScrollable
class PaginatedGridView<T> extends StatefulWidget {
  final List<T> items;
  final bool loading;
  final bool initialLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Widget Function(T item) itemBuilder;
  final int skeletonCount;
  final double minCardWidth;
  final double gap;
  
  const PaginatedGridView({
    required this.items,
    required this.loading,
    required this.initialLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
    this.skeletonCount = 10,
    this.minCardWidth = 288, // 18rem
    this.gap = 16,
    super.key,
  });
  
  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final ScrollController _controller = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    // 首次加载后检查是否需要自动补页
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
  }
  
  void _onScroll() {
    if (_controller.position.pixels >= 
        _controller.position.maxScrollExtent - 200) {
      if (!widget.loading && widget.hasMore) {
        widget.onLoadMore();
      }
    }
  }
  
  void _checkAutoLoad() {
    // 对标 useAutoLoadWhenNotScrollable
    // 如果内容未撑满，自动加载下一页
    if (_controller.hasClients &&
        _controller.position.maxScrollExtent <= _controller.position.viewportDimension &&
        widget.hasMore && !widget.loading) {
      widget.onLoadMore();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.initialLoading) {
      return _buildSkeletonGrid();
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // 滚动通知处理
        return false;
      },
      child: GridView.builder(
        controller: _controller,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: widget.minCardWidth + widget.gap,
          mainAxisExtent: 120, // 7.5rem = 120px
          crossAxisSpacing: widget.gap,
          mainAxisSpacing: widget.gap,
        ),
        itemCount: widget.items.length + (widget.loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.items.length) {
            return const Center(child: Text('加载中...'));
          }
          return widget.itemBuilder(widget.items[index]);
        },
      ),
    );
  }
}
```

---

## 四、关键设计决策

### 4.1 数据模型设计（Freezed）

**原则**：所有数据模型使用 Freezed 生成不可变类 + JSON 序列化。

```dart
// domain/models/installed_app.dart
@freezed
class InstalledApp with _$InstalledApp {
  const factory InstalledApp({
    @JsonKey(name: 'app_id') required String appId,
    required String name,
    required String version,
    String? arch,
    String? channel,
    String? description,
    String? icon,
    String? kind,
    String? module,
    String? runtime,
    String? size,
    @JsonKey(name: 'repo_name') String? repoName,
  }) = _InstalledApp;
  
  factory InstalledApp.fromJson(Map<String, dynamic> json) =>
      _$InstalledAppFromJson(json);
}
```

### 4.2 Repository 接口设计

```dart
// domain/repositories/linglong_cli_repository.dart

abstract class LinglongCliRepository {
  /// 获取已安装应用列表
  Future<List<InstalledApp>> getInstalledApps({bool includeBaseService = false});
  
  /// 获取运行中进程
  Future<List<RunningApp>> getRunningApps();
  
  /// 安装应用（返回进度流）
  Stream<InstallProgress> installApp(String appId, {String? version, bool force = false});
  
  /// 取消安装
  Future<void> cancelInstall(String appId);
  
  /// 卸载应用
  Future<String> uninstallApp(String appId, String version);
  
  /// 运行应用
  Future<void> runApp(String appId);
  
  /// 停止应用
  Future<String> killApp(String appName);
  
  /// 创建桌面快捷方式
  Future<String> createDesktopShortcut(String appId);
  
  /// 搜索版本
  Future<List<InstalledApp>> searchVersions(String appId);
  
  /// 清理废弃服务
  Future<String> pruneApps();
  
  /// 获取网络速度
  Future<NetworkSpeed> getNetworkSpeed();
  
  /// 获取 ll-cli 版本
  Future<String> getLlCliVersion();
  
  /// 检测玲珑环境
  Future<LinglongEnvCheckResult> checkLinglongEnv();
  
  /// 安装玲珑环境
  Future<InstallLinglongResult> installLinglongEnv(String script);
}
```

### 4.3 错误处理策略

```dart
// core/network/api_exceptions.dart

/// 统一错误分级（对标原 errorHandler 策略）
sealed class AppException implements Exception {
  String get message;
  String get userMessage; // 用户可见信息
}

/// 网络错误（用户可修复）
class NetworkException extends AppException { /* ... */ }

/// 业务错误（服务端返回）
class BusinessException extends AppException {
  final int code;
  /* ... */
}

/// CLI 执行超时
class CliTimeoutException extends AppException { /* ... */ }

/// CLI 执行失败
class CliExecutionException extends AppException {
  final int exitCode;
  /* ... */
}

/// 安装错误（含错误码）
class InstallException extends AppException {
  final int errorCode;
  /* ... */
}
```

### 4.4 国际化设计

```yaml
# core/i18n/l10n/app_zh.arb
{
  "@@locale": "zh",
  "appTitle": "玲珑应用商店社区版",
  "recommend": "推 荐",
  "category": "分 类",
  "update": "更 新",
  "office": "办 公",
  "system": "系 统",
  "develop": "开 发",
  "entertainment": "娱 乐",
  "searchPlaceholder": "在这里搜索你想搜索的应用",
  "linglongRecommend": "玲珑推荐",
  "loading": "加载中...",
  "noMoreData": "没有更多数据了",
  "install": "安 装",
  "uninstall": "卸 载",
  "open": "打 开",
  "update_action": "更 新",
  "run": "启 动",
  "cancel": "取消",
  "confirm": "确认",
  "viewDetail": "查看详情",
  "screenShots": "屏幕截图",
  "versionSelect": "版本选择",
  "versionNumber": "版本号",
  "appType": "应用类型",
  "channel": "通道",
  "mode": "模式",
  "repoSource": "仓库来源",
  "fileSize": "文件大小",
  "downloadCount": "下载量",
  "operation": "操作",
  "myApps": "我的应用",
  "linglongProcess": "玲珑进程",
  "baseSetting": "基本设置",
  "about": "关于",
  "envMissing": "检测到当前系统缺少玲珑环境",
  "envMissingDetail": "检测到系统中不存在或版本过低的玲珑组件，需先安装后才能使用商店。",
  "autoInstall": "自动安装",
  "manualInstall": "手动安装",
  "recheck": "重新检测",
  "exitStore": "退出商店"
  // ... 完整 key 列表见 i18n 资源文件
}
```

### 4.5 测试架构设计

项目测试体系采用 **Flutter 官方测试栈 + 官方/推荐 MCP UI 控制能力** 的组合模式：

```
L1 单元测试        -> flutter_test
L2 Widget 测试     -> flutter_test + pumpWidget
L3 Golden 测试     -> matchesGoldenFile
L4 集成测试        -> integration_test
L5 MCP UI 驱动     -> 外部 MCP 控制 Flutter UI / widget tree / semantics
L6 性能基准        -> profile mode + DevTools + MCP 场景驱动
```

#### 测试目录职责

| 目录 | 职责 |
|------|------|
| `test/unit/` | Provider、Service、Parser、Utils 单元测试 |
| `test/widget/` | 组件渲染与交互测试 |
| `test/golden/` | 页面与组件截图基线 |
| `test/integration/` | integration_test 官方集成测试 |
| `test/mcp/` | 通过 MCP 驱动真实 UI 的黑盒回归测试 |
| `tool/benchmarks/` | 性能基准脚本 |

#### MCP 使用原则

MCP 用于补足 `flutter_test` 难以覆盖的桌面端真实交互：

- 点击、输入、滚动、等待异步稳定
- 读取 widget tree / semantics tree
- 截图并执行视觉回归
- 驱动搜索、安装、卸载、KeepAlive 切换等复杂链路

MCP 不是替代单元测试，而是发布前的 **UI 回归与验收驾驶层**。

### 4.6 性能与内存架构约束

迁移后架构必须默认面向高性能、低内存：

#### 渲染约束

- 列表类页面只允许 `builder` 型组件，禁止一次性构建全量子树
- 卡片组件不能直接订阅多个全局 Provider，必须由页面级聚合状态后下发轻量 props
- `build` 中禁止执行 JSON 解析、排序、大 Map 构建、磁盘 IO、网络判断

#### KeepAlive 约束

- 默认保活页数量建议 **6**，硬上限 **10**
- 隐藏页面必须暂停：定时器、自动补页、滚动监听、网络轮询、尺寸观察
- Shell 当前路由必须显式驱动 KeepAlive 页面 `visible/hidden`，不能只依赖 `activate/deactivate` 猜生命周期
- `KeepAlivePageWrapper` 的本地可见状态与 `PageVisibilityManager` 必须保持一致，禁止出现“Widget 仍可见但全局状态已 hidden”的分裂状态
- 页面恢复可见时仅允许一次轻量刷新，禁止重建首屏骨架

#### 缓存约束

- `ImageCache.maximumSizeBytes` 需要限制在 **48MB~64MB**
- 列表缓存必须有 TTL、页数裁剪和 locale 维度
- 截图大图只能按需解码，禁止在列表页预加载全量详情图

#### 目标预算（硬指标）

| 指标 | 目标 |
|------|------|
| 冷启动到首帧 | ≤ 900ms |
| 冷启动到首页可交互 | ≤ 1.8s |
| 列表页滚动平均帧率 | ≥ 60 FPS |
| 99% 帧耗时 | ≤ 16.6ms |
| 首页空闲 RSS | ≤ 180MB |
| 列表页稳定 RSS | ≤ 220MB |
| 详情页稳定 RSS | ≤ 260MB |

---

## 五、编码规范

### 5.1 Dart 编码规范

1. **命名约定**
   - 文件名：`snake_case.dart`
   - 类名：`PascalCase`
   - 变量/函数：`camelCase`
   - 常量：`camelCase`（Dart 惯例，非 SCREAMING_SNAKE）
   - 私有成员：`_`前缀

2. **文件组织**
   - 每个文件只包含一个公开类（辅助类/扩展可在同一文件但保持 private）
   - 文件长度上限 400 行，超过则拆分
   - import 排序：dart → package → 相对路径，每组之间空行

3. **不可变优先**
   - 所有模型使用 Freezed（自带 copyWith, ==, hashCode）
   - 状态更新必须通过 `copyWith` 创建新实例
   - Widget 参数尽量用 `final`
   - 禁止在 State 中直接修改集合（用 `[...list, newItem]`）

4. **空安全**
   - 严格使用 null safety
   - 避免滥用 `!`，优先使用 `?.` 和 `??`
   - API 响应字段标注可空性

5. **异步编程**
   - 优先使用 `async/await`
   - 长时间操作使用 `compute()` 或 `Isolate` 避免阻塞 UI
   - Stream 操作使用 `StreamController.broadcast()`

### 5.2 Flutter Widget 规范

1. **组件分类**
   - `StatelessWidget`：纯展示组件
   - `ConsumerWidget`：需要读取 Riverpod 的组件
   - `ConsumerStatefulWidget`：需要生命周期 + Riverpod 的组件
   - `HookConsumerWidget`：如使用 flutter_hooks

2. **组件大小**
   - build 方法不超过 80 行
   - 复杂 Widget 拆分为子方法 `_buildXxx()`
   - 业务逻辑放入 Provider/Controller，Widget 只负责渲染

3. **性能优化**
   - const 构造函数尽量标注
   - 大列表使用 `ListView.builder` / `GridView.builder`
   - 图片使用 `cached_network_image` 缓存
   - 避免在 build 中创建对象

### 5.3 项目规范

1. **Git 提交**: Conventional Commits (`feat:`, `fix:`, `refactor:` 等)
2. **分支策略**: `main` (稳定) + `develop` (开发) + `feature/*` (功能分支)
3. **代码审查**: 每个 PR 至少一人 Review
4. **静态分析**: flutter analyze 零 warning
5. **格式化**: `dart format` 统一格式，CI 检查

---

## 六、构建与部署

### 6.1 构建命令

```bash
# 开发运行
flutter run -d linux

# 生产构建
flutter build linux --release

# 代码生成（Freezed/Retrofit）
dart run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 单元测试
flutter test

# Golden / Widget / Unit 测试
flutter test test/

# 集成测试
flutter test integration_test/

# Profile 模式性能验证（建议）
flutter run -d linux --profile
```

### 6.2 打包脚本

```bash
# deb 打包
./build/package-deb.sh

# rpm 打包
./build/package-rpm.sh

# AppImage 打包
./build/package-appimage.sh
```

### 6.3 CI 流水线

```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: flutter analyze
      - run: flutter test --coverage
      
  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
      - run: flutter build linux --release
```

---

## 附录：完整 pubspec.yaml

```yaml
name: linglong_store
description: 玲珑应用商店社区版 - Flutter 版
publish_to: none
version: 3.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
    
  # 状态管理
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  
  # 路由
  go_router: ^14.6.2
  
  # 网络
  dio: ^5.7.0
  retrofit: ^4.4.1
  
  # 序列化
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  
  # 窗口管理
  window_manager: ^0.4.3
  
  # 本地存储
  shared_preferences: ^2.3.4
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # UI
  cached_network_image: ^3.4.1
  flutter_svg: ^2.0.16
  shimmer: ^3.0.0
  
  # 工具
  url_launcher: ^6.3.1
  device_info_plus: ^10.1.2
  package_info_plus: ^8.1.3
  uuid: ^4.5.1
  logger: ^2.5.0
  intl: ^0.19.0
  path_provider: ^2.1.5
  path: ^1.9.1
  
  # 系统托盘
  system_tray: ^2.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  retrofit_generator: ^9.1.7
  riverpod_generator: ^2.6.3
  mockito: ^5.4.4
  build_verify: ^3.1.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/icons/
    - assets/seeds/
    
  generate: true  # 启用 flutter_localizations 代码生成
```
