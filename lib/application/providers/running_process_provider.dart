import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/di/repository_provider.dart';
import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';
import '../../domain/repositories/app_repository.dart';
import 'install_queue_provider.dart';

part 'running_process_provider.g.dart';

/// Rust 版本的失败退避表：1 次失败 3s，2 次失败 6s，3 次及以上 10s。
const _refreshBackoffTable = <Duration>[
  Duration(seconds: 3),
  Duration(seconds: 6),
  Duration(seconds: 10),
];

@visibleForTesting
Future<List<RunningApp>> enrichRunningAppsWithDetails({
  required AppRepository appRepository,
  required List<RunningApp> apps,
}) async {
  if (apps.isEmpty) {
    return const [];
  }

  final installedLikeApps = apps
      .map(
        (app) => InstalledApp(
          appId: app.appId,
          name: app.name,
          version: app.version,
          arch: app.arch,
          channel: app.channel,
          icon: app.icon,
        ),
      )
      .toList();

  final enrichedApps = await appRepository.enrichInstalledAppsWithDetails(
    installedLikeApps,
  );
  final enrichedByAppId = {for (final app in enrichedApps) app.appId: app};

  return apps.map((app) {
    final enriched = enrichedByAppId[app.appId];
    if (enriched == null) {
      return app;
    }

    return app.copyWith(
      name: enriched.name.isNotEmpty ? enriched.name : app.name,
      icon: enriched.icon ?? app.icon,
    );
  }).toList();
}

/// 运行中进程状态
class RunningProcessState {
  const RunningProcessState({
    this.apps = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.error,
    this.lastRefreshedAt,
    this.killLoadingIds = const <String>{},
  });

  /// 运行中应用列表
  final List<RunningApp> apps;

  /// 首次加载中
  final bool isInitialLoading;

  /// 静默刷新中
  final bool isRefreshing;

  /// 最近一次错误
  final String? error;

  /// 最近一次成功刷新时间
  final DateTime? lastRefreshedAt;

  /// 正在执行停止操作的行 id 集合
  final Set<String> killLoadingIds;

  bool get hasData => apps.isNotEmpty;

  /// 复制并更新
  RunningProcessState copyWith({
    List<RunningApp>? apps,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    DateTime? lastRefreshedAt,
    Set<String>? killLoadingIds,
  }) {
    return RunningProcessState(
      apps: apps ?? this.apps,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      killLoadingIds: killLoadingIds ?? this.killLoadingIds,
    );
  }
}

/// 运行中进程 Provider
///
/// 对齐 Rust 版本的行为：
/// - 仅在“玲珑进程”标签激活且页面可见时轮询
/// - 并发保护
/// - 失败退避
/// - 恢复可见时立即补刷新
/// - 行级停止 loading
@Riverpod(keepAlive: true)
class RunningProcess extends _$RunningProcess {
  Timer? _refreshTimer;
  bool _isFetching = false;
  int _failureCount = 0;
  bool _isProcessTabActive = false;
  bool _isPageVisible = true;

  /// 默认刷新间隔（3 秒）
  static const Duration defaultRefreshInterval = Duration(seconds: 3);

  @override
  RunningProcessState build() {
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    return const RunningProcessState();
  }

  bool get _shouldPoll => _isProcessTabActive && _isPageVisible;

  /// 当前是否正在自动刷新
  bool get isAutoRefreshing => _refreshTimer != null;

  /// 当前是否处于进程 Tab。
  void setProcessTabActive(bool isActive) {
    _isProcessTabActive = isActive;
    _syncPolling(immediateRefresh: isActive);
  }

  /// 当前页面可见性变化。
  void setPageVisible(bool isVisible) {
    _isPageVisible = isVisible;
    _syncPolling(immediateRefresh: isVisible);
  }

  /// 手动刷新运行中进程列表。
  Future<void> refresh() async {
    _cancelTimer();
    await _fetchOnce(silent: state.hasData);
    _scheduleNext();
  }

  Future<void> _fetchOnce({required bool silent}) async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;
    final hasData = state.hasData;

    state = state.copyWith(
      isInitialLoading: !silent && !hasData,
      isRefreshing: silent || hasData,
      clearError: true,
    );

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final rawApps = await repo.getRunningApps();
      final appRepository = ref.read(appRepositoryProvider);
      final apps = await enrichRunningAppsWithDetails(
        appRepository: appRepository,
        apps: rawApps,
      );

      _failureCount = 0;
      state = state.copyWith(
        apps: apps,
        isInitialLoading: false,
        isRefreshing: false,
        clearError: true,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (e) {
      _failureCount += 1;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        error: presentAppError(e),
      );
    } finally {
      _isFetching = false;
    }
  }

  void _syncPolling({required bool immediateRefresh}) {
    if (!_shouldPoll) {
      _cancelTimer();
      return;
    }

    _cancelTimer();

    if (immediateRefresh) {
      unawaited(_fetchOnce(silent: state.hasData).whenComplete(_scheduleNext));
      return;
    }

    _scheduleNext();
  }

  void _scheduleNext() {
    _cancelTimer();
    if (!_shouldPoll) {
      return;
    }

    final interval = _failureCount > 0
        ? _refreshBackoffTable[(_failureCount - 1).clamp(
            0,
            _refreshBackoffTable.length - 1,
          )]
        : defaultRefreshInterval;

    _refreshTimer = Timer(interval, () async {
      if (!_shouldPoll) {
        _scheduleNext();
        return;
      }

      await _fetchOnce(silent: true);
      _scheduleNext();
    });
  }

  void _cancelTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 停止指定应用。
  Future<bool> killApp(RunningApp app) async {
    final nextLoadingIds = Set<String>.from(state.killLoadingIds)..add(app.id);
    state = state.copyWith(killLoadingIds: nextLoadingIds);

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final result = await repo.killApp(app.appId);
      final success = !result.contains('失败') && !result.contains('异常');

      if (success) {
        await _fetchOnce(silent: true);
      }

      return success;
    } catch (_) {
      return false;
    } finally {
      final updatedIds = Set<String>.from(state.killLoadingIds)..remove(app.id);
      state = state.copyWith(killLoadingIds: updatedIds);
      _scheduleNext();
    }
  }
}

/// 运行中应用列表
@riverpod
List<RunningApp> runningAppsList(Ref ref) {
  return ref.watch(runningProcessProvider).apps;
}

/// 运行中应用数量
@riverpod
int runningAppsCount(Ref ref) {
  return ref.watch(runningProcessProvider).apps.length;
}
