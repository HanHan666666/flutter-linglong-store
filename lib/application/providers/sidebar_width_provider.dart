import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import 'application_dependency_providers.dart' show sharedPreferencesProvider;

part 'sidebar_width_provider.g.dart';

/// 侧边栏宽度策略常量
///
/// 集中约束「可拖拽宽度」的合法区间与持久化键，供 Application 层
/// （宽度状态）与 Presentation 层（侧边栏渲染、拖拽手柄）共同引用，
/// 避免边界值在两层各自硬编码后逐渐失配。
///
/// 边界取值依据：
/// - 下限 120px：底部三个 32px 图标按钮横排（3×32 + 8×2 内边距 = 112px）
///   的最小可容纳宽度，再窄会挤压底部动作区；
/// - 上限 400px：窗口最小宽度 1280px（[WindowService.minWidth]）下
///   内容区仍保留 ≥880px，保证列表/详情等主工作区可用；
/// - 默认 176px：沿用既有展开态宽度，为英文菜单单行预留。
abstract class SidebarWidthPolicy {
  /// 展开态默认宽度（px）
  static const double defaultWidth = 176.0;

  /// 可拖拽宽度的下限（px）
  static const double minWidth = 120.0;

  /// 可拖拽宽度的上限（px）
  static const double maxWidth = 400.0;

  /// 键盘方向键 / 无障碍 increase/decrease 动作的单步调整量（px）
  static const double keyboardStep = 16.0;

  /// 展开态宽度的持久化键（shared_preferences）。
  ///
  /// 仅在拖拽结束/重置时写入，拖拽帧不产生任何 IO。
  static const String prefsKey = 'sidebar_expanded_width';

  /// 将任意候选宽度钳制到合法区间
  static double clamp(double width) {
    if (width < minWidth) return minWidth;
    if (width > maxWidth) return maxWidth;
    return width;
  }
}

/// 侧边栏展开宽度状态
///
/// 业务定位：侧边栏可拖拽调宽（issue #27）的唯一宽度事实来源。
/// 采用「帧内预览、结束时落盘」的两阶段契约：
/// - [previewWidth]：拖拽帧高频调用，只更新内存状态，保证帧内零 IO；
/// - [commitWidth]：拖拽结束调用一次，把当前宽度持久化；
/// - [resetWidth]：恢复默认宽度并清除持久化键。
///
/// 持久化读取发生在 [build]（同步）：SharedPreferences 在 main 阶段
/// 已完成初始化并注入 [sharedPreferencesProvider]，不存在异步竞态；
/// 读取失败时回退默认宽度，绝不阻塞首帧。
@Riverpod(keepAlive: true)
class SidebarWidth extends _$SidebarWidth {
  @override
  double build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final stored = prefs.getDouble(SidebarWidthPolicy.prefsKey);
      if (stored == null) return SidebarWidthPolicy.defaultWidth;
      return SidebarWidthPolicy.clamp(stored);
    } catch (e, s) {
      // 持久化不可用属于可容忍降级：本次会话使用默认宽度即可。
      AppLogger.warning('恢复侧边栏宽度失败，使用默认宽度', e, s);
      return SidebarWidthPolicy.defaultWidth;
    }
  }

  /// 拖拽帧预览：仅更新内存宽度（钳制到合法区间），不做持久化。
  void previewWidth(double width) {
    final next = SidebarWidthPolicy.clamp(width);
    if (next == state) return;
    state = next;
  }

  /// 拖拽结束：将当前宽度持久化。
  ///
  /// 写入失败只记日志，内存状态保持有效（下次会话回退默认宽度）。
  void commitWidth() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      unawaited(prefs.setDouble(SidebarWidthPolicy.prefsKey, state));
    } catch (e, s) {
      AppLogger.warning('持久化侧边栏宽度失败', e, s);
    }
  }

  /// 重置：恢复默认宽度并清除持久化键（双击手柄触发）。
  void resetWidth() {
    state = SidebarWidthPolicy.defaultWidth;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      unawaited(prefs.remove(SidebarWidthPolicy.prefsKey));
    } catch (e, s) {
      AppLogger.warning('清除侧边栏宽度持久化失败', e, s);
    }
  }
}
