import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../../core/di/providers.dart';

part 'installed_apps_provider.g.dart';

/// 已安装应用状态
class InstalledAppsState {
  const InstalledAppsState({
    this.apps = const [],
    this.isLoading = false,
    this.error,
  });

  /// 应用列表
  final List<InstalledApp> apps;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 复制并更新
  InstalledAppsState copyWith({
    List<InstalledApp>? apps,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InstalledAppsState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 已安装应用 Provider
///
/// 管理已安装应用列表的状态
@Riverpod(keepAlive: true)
class InstalledApps extends _$InstalledApps {
  @override
  InstalledAppsState build() {
    return const InstalledAppsState();
  }

  /// 刷新已安装应用列表
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      // 根据设置决定是否在列表中包含基础运行服务
      final showBase = ref.read(settingProvider).showBaseService;
      final apps = await repo.getInstalledApps(includeBaseService: showBase);

      // 通过 API 获取应用详情（图标、中文名等），富化已安装应用列表
      final appRepo = ref.read(appRepositoryProvider);
      final enrichedApps = await appRepo.enrichInstalledAppsWithDetails(apps);

      state = InstalledAppsState(apps: enrichedApps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 从列表中移除应用（卸载后调用）。
  ///
  /// 同一应用可能存在多个版本，只移除当前被卸载的版本。
  void removeApp(String appId, String version) {
    state = state.copyWith(
      apps: state.apps
          .where((app) => !(app.appId == appId && app.version == version))
          .toList(),
    );
  }
}

/// 便捷访问 Provider

/// 已安装应用列表
@riverpod
List<InstalledApp> installedAppsList(Ref ref) {
  return ref.watch(installedAppsProvider).apps;
}

/// 已安装应用数量
@riverpod
int installedAppsCount(Ref ref) {
  return ref.watch(installedAppsProvider).apps.length;
}

/// 是否正在加载已安装应用
@riverpod
bool isLoadingInstalledApps(Ref ref) {
  return ref.watch(installedAppsProvider).isLoading;
}

/// 检查应用是否已安装
@riverpod
bool isAppInstalled(Ref ref, String appId) {
  final apps = ref.watch(installedAppsProvider).apps;
  return apps.any((app) => app.appId == appId);
}
