import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/sidebar_width_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'sidebar.dart';

/// 可拖拽调整宽度的侧边栏容器（issue #27）
///
/// 业务定位：在 [AppShell] 的主布局中同时承载「侧边栏本体」与「拖拽手柄」，
/// 让用户可以加宽或收窄左侧导航栏，宽度经 [sidebarWidthProvider] 持久化。
///
/// 性能设计（本项目要求绝对高 UI 响应速度）：
/// - 拖拽帧只更新外层 [SizedBox] 的紧约束宽度，`sidebar`/`child` 两个
///   widget 实例在拖拽期间保持不变，Flutter 会短路子树重建、仅按新宽度
///   重新排版（Widget build 零开销，只有必要的 Layout）；
/// - 紧约束会覆盖 `Sidebar` 内部的默认宽度（176px），因此 [Sidebar]
///   自身无需感知可调宽度这一特性；
/// - 拖拽帧内不发生任何持久化 IO，落盘只在拖拽结束时执行一次。
///
/// 方向感知（RTL）：阿拉伯语下 `Row` 整体镜像、侧边栏渲染在物理右侧，
/// 拖拽增宽方向与键盘左右键语义随之翻转，杜绝硬编码物理方向。
class ResizableSidebar extends ConsumerStatefulWidget {
  const ResizableSidebar({
    required this.sidebar,
    required this.child,
    super.key,
  });

  /// 侧边栏本体（由调用方组装并注入；本组件只负责宽度约束）
  final Widget sidebar;

  /// 侧边栏右侧的内容区。
  ///
  /// 拖拽帧内该实例保持不变，仅按新宽度重新排版。
  final Widget child;

  @override
  ConsumerState<ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends ConsumerState<ResizableSidebar> {
  /// 读取当前宽度状态（Provider 在拖拽帧内由本组件驱动更新）。
  double get _currentWidth => ref.read(sidebarWidthProvider);

  /// 拖拽更新：把手柄上的水平位移换算成宽度增量。
  ///
  /// LTR 下侧边栏在物理左侧，向右拖为加宽；RTL 下整体镜像后取反。
  void _onDragUpdate(DragUpdateDetails details) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final delta = isRtl ? -details.delta.dx : details.delta.dx;
    ref.read(sidebarWidthProvider.notifier).previewWidth(_currentWidth + delta);
  }

  /// 拖拽结束：提交持久化（帧内零 IO，落盘只发生在这里）。
  void _onDragEnd(DragEndDetails details) {
    ref.read(sidebarWidthProvider.notifier).commitWidth();
  }

  /// 双击手柄：恢复默认宽度并清除持久化。
  void _onDoubleTap() {
    ref.read(sidebarWidthProvider.notifier).resetWidth();
  }

  /// 键盘/无障碍动作的单步调整（增量已按 RTL 翻转语义）。
  void _adjustWidth(double directionAwareDelta) {
    ref
        .read(sidebarWidthProvider.notifier)
        .previewWidth(_currentWidth + directionAwareDelta);
    // 键盘与无障碍动作是离散的一次性调整，等效一次完整交互，直接落盘。
    ref.read(sidebarWidthProvider.notifier).commitWidth();
  }

  @override
  Widget build(BuildContext context) {
    final width = ref.watch(sidebarWidthProvider);
    // ≤768px 窗口沿用既有的自动折叠行为：固定 56px 图标栏，不支持拖拽，
    // 与手动宽度互不干扰（恢复宽窗口后继续使用用户上次拖拽的宽度）。
    final isCollapsed =
        MediaQuery.sizeOf(context).width <= Sidebar.autoCollapseBreakpoint;

    return Row(
      children: [
        // 拖拽帧内 sidebar 实例不变：仅紧约束宽度变化，子树只重排版不重建。
        if (isCollapsed)
          widget.sidebar
        else
          SizedBox(width: width, child: widget.sidebar),
        // 折叠态隐藏拖拽手柄（56px 图标栏是固定响应式形态）。
        if (!isCollapsed)
          _SidebarResizeHandle(
            onDragUpdate: _onDragUpdate,
            onDragEnd: _onDragEnd,
            onDoubleTap: _onDoubleTap,
            onStepResize: _adjustWidth,
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// 侧边栏拖拽手柄
///
/// 位于侧边栏与内容区之间的窄条交互面：
/// - 悬停/拖拽时显示强调色指示线并切换 `resizeLeftRight` 光标；
/// - 支持指针拖拽、双击重置、左右方向键微调；
/// - 通过 `Semantics` 的 increase/decrease 动作暴露给屏幕阅读器，
///   使无障碍用户同样可以调整侧边栏宽度。
///
/// 组件本身不感知 RTL：位移/按键的方向语义由 [ResizableSidebar] 统一
/// 翻转后经回调传入，保证方向逻辑只有一处实现。
class _SidebarResizeHandle extends StatefulWidget {
  const _SidebarResizeHandle({
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDoubleTap,
    required this.onStepResize,
  });

  /// 拖拽更新回调（原始 [DragUpdateDetails]，RTL 换算由本组件统一完成）
  final GestureDragUpdateCallback onDragUpdate;

  /// 拖拽结束回调（触发持久化）
  final GestureDragEndCallback onDragEnd;

  /// 双击回调（恢复默认宽度）
  final VoidCallback onDoubleTap;

  /// 键盘/无障碍单步调整回调（入参为已按 RTL 翻转的宽度增量）
  final ValueChanged<double> onStepResize;

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  /// 焦点节点：让手柄进入 Tab 遍历，支持键盘调整宽度
  final FocusNode _focusNode = FocusNode(debugLabel: 'SidebarResizeHandle');

  /// 是否处于悬停或拖拽中（控制指示线显隐）
  bool _isActive = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 处理左右方向键：朝内容区方向为加宽，反向为收窄（RTL 下语义翻转）。
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onStepResize(
        isRtl
            ? -SidebarWidthPolicy.keyboardStep
            : SidebarWidthPolicy.keyboardStep,
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onStepResize(
        isRtl
            ? SidebarWidthPolicy.keyboardStep
            : -SidebarWidthPolicy.keyboardStep,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lineColor = _isActive
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.45)
        : Colors.transparent;

    return Semantics(
      label: l10n.a11ySidebarResizeHandle,
      hint: l10n.a11ySidebarResizeHint,
      // 屏幕阅读器的 increase/decrease 动作与键盘方向键等效（增宽为正方向）。
      onIncrease: () => widget.onStepResize(SidebarWidthPolicy.keyboardStep),
      onDecrease: () => widget.onStepResize(-SidebarWidthPolicy.keyboardStep),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          onEnter: (_) => setState(() => _isActive = true),
          onExit: (_) => setState(() => _isActive = false),
          child: GestureDetector(
            // DragStartBehavior.down：拖拽生效的首帧即包含触摸 slop 位移，
            // 宽度变化与指针位移严格 1:1，符合原生 resize 手柄手感
            // （默认 start 会吞掉起手 ~18px，产生明显的跟手迟滞）。
            dragStartBehavior: DragStartBehavior.down,
            behavior: HitTestBehavior.opaque,
            // 点按/起拖即接管焦点，让紧随其后的方向键微调立即可用
            // （纯 Focus 节点不会随点按自动聚焦）。
            onTap: () => _focusNode.requestFocus(),
            onHorizontalDragStart: (_) {
              _focusNode.requestFocus();
              setState(() => _isActive = true);
            },
            onHorizontalDragUpdate: widget.onDragUpdate,
            onHorizontalDragEnd: (details) {
              setState(() => _isActive = false);
              widget.onDragEnd(details);
            },
            onHorizontalDragCancel: () => setState(() => _isActive = false),
            onDoubleTap: widget.onDoubleTap,
            child: SizedBox(
              width: AppSpacing.sm,
              height: double.infinity,
              // 指示线居中铺满全高；全局零动画模式（AppAnimation.fast 为
              // 零时长），显隐直接随 hover/拖拽状态瞬切，无需动画容器。
              child: Center(
                child: SizedBox(
                  width: 2,
                  height: double.infinity,
                  child: ColoredBox(color: lineColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
