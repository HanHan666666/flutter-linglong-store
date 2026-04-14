import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/di/repository_provider.dart';
import '../../domain/models/app_detail.dart';
import '../../domain/models/installed_app.dart';
import 'installed_apps_provider.dart';

part 'update_apps_provider.g.dart';

/// 可更新应用信息
class UpdatableApp {
  const UpdatableApp({
    required this.installedApp,
    required this.latestVersion,
    this.latestVersionDescription,
    this.latestVersionSize,
  });

  /// 已安装的应用信息
  final InstalledApp installedApp;

  /// 最新版本号
  final String latestVersion;

  /// 最新版本更新说明
  final String? latestVersionDescription;

  /// 最新版本大小
  final String? latestVersionSize;

  /// 应用ID
  String get appId => installedApp.appId;

  /// 应用名称
  String get name => installedApp.name;

  /// 当前版本
  String get currentVersion => installedApp.version;

  /// 应用图标
  String? get icon => installedApp.icon;
}

/// 可更新应用状态
class UpdateAppsState {
  const UpdateAppsState({
    this.apps = const [],
    this.isLoading = false,
    this.error,
  });

  /// 可更新应用列表
  final List<UpdatableApp> apps;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 可更新应用数量
  int get count => apps.length;

  /// 是否为空
  bool get isEmpty => apps.isEmpty;

  /// 复制并更新
  UpdateAppsState copyWith({
    List<UpdatableApp>? apps,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UpdateAppsState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 可更新应用 Provider
///
/// 管理可更新应用列表的状态
@Riverpod(keepAlive: true)
class UpdateApps extends _$UpdateApps {
  int _latestRequestId = 0;

  @override
  UpdateAppsState build() {
    return const UpdateAppsState();
  }

  /// 检查更新
  ///
  /// 比较已安装应用与远程最新版本，返回可更新列表
  Future<void> checkUpdates() async {
    final requestId = ++_latestRequestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 获取已安装应用列表
      var installedApps = ref.read(installedAppsProvider).apps;

      if (installedApps.isEmpty) {
        // 如果没有已安装应用，先刷新
        await ref.read(installedAppsProvider.notifier).refresh();
        installedApps = ref.read(installedAppsProvider).apps;
      }

      // 从远程 API 获取最新版本信息
      final updatableApps = await _checkUpdatesFromRemote(installedApps);

      // 只允许最新一次检查落状态，避免旧请求覆盖新结果。
      if (requestId != _latestRequestId) {
        return;
      }

      state = UpdateAppsState(apps: updatableApps, isLoading: false);
    } catch (e, s) {
      AppLogger.error('检查更新失败', e, s);
      if (requestId != _latestRequestId) {
        return;
      }
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 从远程检查更新
  Future<List<UpdatableApp>> _checkUpdatesFromRemote(
    List<InstalledApp> installedApps,
  ) async {
    if (installedApps.isEmpty) return [];

    // 通过 Repository 检查更新，返回领域模型 AppDetail
    final appRepo = ref.read(appRepositoryProvider);
    final updateDetails = await appRepo.checkAppUpdates(installedApps);

    final updatableApps = <UpdatableApp>[];

    for (final appDetail in updateDetails) {
      // 找到对应的已安装应用
      final installedApp = installedApps.firstWhere(
        (app) => app.appId == appDetail.appId,
        orElse: () => installedApps.first,
      );

      // 如果版本不同，说明有更新（使用领域模型的 version 字段）
      if (appDetail.version != installedApp.version) {
        updatableApps.add(
          UpdatableApp(
            installedApp: installedApp,
            latestVersion: appDetail.version,
            latestVersionDescription:
                appDetail.releaseNote ?? appDetail.detailDescription,
            latestVersionSize: appDetail.packageSize,
          ),
        );
      }
    }

    return updatableApps;
  }

  /// 刷新更新列表
  Future<void> refresh() async {
    await checkUpdates();
  }

  /// 乐观移除指定应用（更新/安装成功后立即调用，不等异步刷新）。
  ///
  /// 用于在任务完成时立即从 UI 列表中移除已更新的应用，
  /// 避免用户看到过时的"待更新"条目。后续 [checkUpdates()] 会
  /// 基于最新版本重新计算，作为最终一致性兜底。
  void removeApp(String appId) {
    if (state.apps.any((app) => app.appId == appId)) {
      state = state.copyWith(
        apps: state.apps.where((app) => app.appId != appId).toList(),
      );
    }
  }
}

/// 便捷访问 Provider

/// 可更新应用列表
@riverpod
List<UpdatableApp> updatableAppsList(Ref ref) {
  return ref.watch(updateAppsProvider).apps;
}

/// 可更新应用数量
@riverpod
int updatableAppsCount(Ref ref) {
  return ref.watch(updateAppsProvider).count;
}

/// 是否有可更新应用
@riverpod
bool hasUpdatableApps(Ref ref) {
  return ref.watch(updateAppsProvider).count > 0;
}
