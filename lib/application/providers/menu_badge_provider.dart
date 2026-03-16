import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'install_queue_provider.dart';
import 'update_apps_provider.dart';

part 'menu_badge_provider.g.dart';

/// 菜单红点状态
///
/// 存储各菜单项的红点数量
class MenuBadgeState {
  const MenuBadgeState({
    this.updateCount = 0,
    this.installingCount = 0,
  });

  /// 更新页红点数量（可更新应用数量）
  final int updateCount;

  /// 我的应用红点数量（正在安装的应用数量）
  final int installingCount;

  /// 是否有任何红点
  bool get hasAnyBadge => updateCount > 0 || installingCount > 0;

  /// 总红点数量
  int get totalCount => updateCount + installingCount;

  /// 复制并更新
  MenuBadgeState copyWith({
    int? updateCount,
    int? installingCount,
  }) {
    return MenuBadgeState(
      updateCount: updateCount ?? this.updateCount,
      installingCount: installingCount ?? this.installingCount,
    );
  }

  @override
  String toString() {
    return 'MenuBadgeState(updateCount: $updateCount, installingCount: $installingCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuBadgeState &&
        other.updateCount == updateCount &&
        other.installingCount == installingCount;
  }

  @override
  int get hashCode => Object.hash(updateCount, installingCount);
}

/// 菜单红点 Provider
///
/// 计算各菜单项的红点数量：
/// - 更新页：显示可更新应用数量
/// - 我的应用：显示正在安装的应用数量
@riverpod
MenuBadgeState menuBadge(Ref ref) {
  // 监听安装队列状态
  final installQueue = ref.watch(installQueueProvider);

  // 监听可更新应用状态
  final updateApps = ref.watch(updateAppsProvider);

  // 计算正在安装的数量（当前任务 + 队列中待处理任务）
  final installingCount = installQueue.queue.length +
      (installQueue.currentTask != null ? 1 : 0);

  // 获取可更新应用数量
  final updateCount = updateApps.count;

  return MenuBadgeState(
    updateCount: updateCount,
    installingCount: installingCount,
  );
}

/// 便捷访问 Provider

/// 更新页红点数量
@riverpod
int menuUpdateBadgeCount(Ref ref) {
  return ref.watch(menuBadgeProvider).updateCount;
}

/// 我的应用红点数量
@riverpod
int menuInstallingBadgeCount(Ref ref) {
  return ref.watch(menuBadgeProvider).installingCount;
}

/// 是否有任何菜单红点
@riverpod
bool hasMenuBadge(Ref ref) {
  return ref.watch(menuBadgeProvider).hasAnyBadge;
}

/// 菜单总红点数量
@riverpod
int menuTotalBadgeCount(Ref ref) {
  return ref.watch(menuBadgeProvider).totalCount;
}