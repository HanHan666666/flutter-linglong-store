// 全局 Provider 定义汇总
//
// 此文件导出所有应用级别的 Provider，便于在需要时统一导入。
// 使用方式：import 'package:linglong_store/core/di/providers.dart';

// ==================== 领域模型导出 ====================

// 安装队列状态（领域模型，由 provider 层引用）
export '../../domain/models/install_queue_state.dart' show InstallQueueState;

// ==================== 基础设施 Provider ====================

// SharedPreferences - 需要在 main.dart 中初始化
export '../../application/providers/install_queue_provider.dart'
    show sharedPreferencesProvider;

// ==================== Repository Provider ====================

export '../../application/providers/install_queue_provider.dart'
    show linglongCliRepositoryProvider;

export 'repository_provider.dart'
    show appRepositoryProvider, analyticsRepositoryProvider;

// ==================== 状态管理 Provider ====================

// 安装队列
export '../../application/providers/install_queue_provider.dart'
    show
        installQueueProvider,
        installQueueStateProvider,
        currentInstallTaskProvider,
        pendingInstallQueueProvider,
        installHistoryProvider,
        hasActiveInstallTasksProvider,
        InstallQueue,
        EnqueueTaskParams;

// 全局状态
export '../../application/providers/global_provider.dart'
    show
        globalAppProvider,
        currentLocaleProvider,
        currentThemeModeProvider,
        userPreferencesProvider,
        isDarkModeProvider,
        isEnvReadyProvider,
        isAppInitializedProvider,
        GlobalApp,
        GlobalAppState,
        UserPreferences;

// 可更新应用
export '../../application/providers/update_apps_provider.dart'
    show
        updateAppsProvider,
        updatableAppsListProvider,
        updatableAppsCountProvider,
        hasUpdatableAppsProvider,
        UpdateApps,
        UpdateAppsState,
        UpdatableApp;

// ==================== 设置 Provider ====================

// 设置页面
export '../../application/providers/setting_provider.dart'
    show
        settingProvider,
        SettingState,
        Setting,
        formatBytes,
        supportedLocales,
        languageNames;
