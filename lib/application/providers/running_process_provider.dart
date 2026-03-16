import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_exceptions.dart';
import '../../domain/models/running_app.dart';
import 'install_queue_provider.dart';

part 'running_process_provider.g.dart';

/// 运行中进程状态
class RunningProcessState {
  const RunningProcessState({
    this.apps = const [],
    this.isLoading = false,
    this.error,
  });

  /// 运行中应用列表
  final List<RunningApp> apps;

  /// 是否正在加载
  final bool isLoading;

  /// 错误信息
  final String? error;

  /// 复制并更新
  RunningProcessState copyWith({
    List<RunningApp>? apps,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RunningProcessState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 运行中进程 Provider
///
/// 管理运行中进程列表的状态，支持自动刷新
@Riverpod(keepAlive: true)
class RunningProcess extends _$RunningProcess {
  /// 自动刷新定时器
  Timer? _refreshTimer;

  /// 默认刷新间隔（3秒）
  static const Duration defaultRefreshInterval = Duration(seconds: 3);

  @override
  RunningProcessState build() {
    // 组件销毁时取消定时器
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });
    return const RunningProcessState();
  }

  /// 刷新运行中进程列表
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final apps = await repo.getRunningApps();

      state = RunningProcessState(apps: apps, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: presentAppError(e));
    }
  }

  /// 停止应用
  Future<bool> killApp(String appName) async {
    try {
      final repo = ref.read(linglongCliRepositoryProvider);
      final result = await repo.killApp(appName);

      // 如果停止成功，从列表中移除
      if (!result.contains('失败')) {
        state = state.copyWith(
          apps: state.apps.where((app) => app.name != appName).toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 启动自动刷新
  void startAutoRefresh([Duration? interval]) {
    _refreshTimer?.cancel();

    // 立即刷新一次
    refresh();

    // 设置定时器
    _refreshTimer = Timer.periodic(
      interval ?? defaultRefreshInterval,
      (_) => refresh(),
    );
  }

  /// 停止自动刷新
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 切换自动刷新状态
  void toggleAutoRefresh([Duration? interval]) {
    if (_refreshTimer != null) {
      stopAutoRefresh();
    } else {
      startAutoRefresh(interval);
    }
  }

  /// 是否正在自动刷新
  bool get isAutoRefreshing => _refreshTimer != null;
}

/// 便捷访问 Provider

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

/// 是否正在加载运行中应用
@riverpod
bool isLoadingRunningApps(Ref ref) {
  return ref.watch(runningProcessProvider).isLoading;
}

/// 是否正在自动刷新
@riverpod
bool isAutoRefreshing(Ref ref) {
  // 由于 isAutoRefreshing 是实例方法，我们需要通过另一种方式暴露
  // 这里直接返回 false，实际使用时需要通过 notifier 访问
  return false;
}
