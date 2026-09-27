import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import 'application_dependency_providers.dart';
import 'setting_provider.dart';

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
  /// 已安装快照的请求序号。
  ///
  /// 已安装快照是"更新列表"判定的唯一事实来源（更新检查只读取这里的版本），
  /// 因此并发刷新时只允许最后一次请求落状态，避免先发起的旧快照覆盖新快照。
  int _latestRequestId = 0;

  @override
  InstalledAppsState build() {
    return const InstalledAppsState();
  }

  /// 重建已安装应用列表快照，并回报本次请求是否成功落下新快照。
  ///
  /// 返回值供上层判断"这份快照是否可信"：更新成功后的收敛确认与更新列表
  /// 重算必须建立在刷新成功的快照之上，禁止在刷新失败时继续用旧版本比对。
  /// 失败（含被更新的请求取代）时保留调用前的 `apps`，只更新 loading/error，
  /// 调用方仍能读到"最后一次成功快照"，但不会被误导为最新事实。
  Future<bool> refresh() async {
    final requestId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      // 根据设置决定是否在列表中包含基础运行服务
      final showBase = ref.read(settingProvider).showBaseService;
      final apps = await repo.getInstalledApps(includeBaseService: showBase);

      // 通过 API 获取应用详情（图标、中文名等），富化已安装应用列表
      final appRepo = ref.read(appRepositoryProvider);
      final enrichedApps = await appRepo.enrichInstalledAppsWithDetails(apps);

      if (requestId != _latestRequestId) {
        return false;
      }

      state = InstalledAppsState(apps: enrichedApps, isLoading: false);
      return true;
    } catch (e) {
      if (requestId != _latestRequestId) {
        return false;
      }

      state = state.copyWith(isLoading: false, error: presentAppError(e));
      return false;
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
