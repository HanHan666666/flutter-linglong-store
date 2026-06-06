import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_icon.dart';

const Duration _kInstallFlyoutDuration = Duration(milliseconds: 920);
const Duration _kDownloadPulseDuration = Duration(milliseconds: 520);

/// Shell 级安装反馈动画层。
///
/// 负责把安装入口的图标飞向下载中心按钮，不参与任何业务入队逻辑。
class InstallToDownloadFlyoutLayer extends StatefulWidget {
  const InstallToDownloadFlyoutLayer({required this.child, super.key});

  final Widget child;

  static InstallToDownloadFlyoutController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InstallToDownloadFlyoutScope>()
        ?.controller;
  }

  @override
  State<InstallToDownloadFlyoutLayer> createState() =>
      _InstallToDownloadFlyoutLayerState();
}

class _InstallToDownloadFlyoutLayerState
    extends State<InstallToDownloadFlyoutLayer> {
  late final InstallToDownloadFlyoutController _controller =
      InstallToDownloadFlyoutController._(this);

  final List<_InstallFlightEntry> _activeFlights = <_InstallFlightEntry>[];
  final List<_DownloadPulseEntry> _activePulses = <_DownloadPulseEntry>[];
  GlobalKey? _downloadTargetKey;
  int _sequence = 0;

  /// 遵循系统减少/禁用动画偏好，避免用户关闭系统动画后仍看到强反馈。
  bool get _animationsDisabled {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
  }

  void _registerDownloadTarget(GlobalKey key) {
    _downloadTargetKey = key;
  }

  void _unregisterDownloadTarget(GlobalKey key) {
    if (identical(_downloadTargetKey, key)) {
      _downloadTargetKey = null;
    }
  }

  bool _launch({
    required GlobalKey sourceKey,
    required String appId,
    String? appName,
    String? iconUrl,
  }) {
    final targetRect = _resolveRect(_downloadTargetKey);
    if (targetRect == null || _animationsDisabled) {
      return false;
    }

    final sourceRect = _resolveRect(sourceKey);
    if (sourceRect == null) {
      _enqueuePulse(targetRect);
      return true;
    }

    final entry = _InstallFlightEntry(
      id: 'install-download-flyout-${_sequence++}',
      appId: appId,
      appName: appName,
      iconUrl: iconUrl,
      sourceRect: sourceRect,
      targetRect: targetRect,
    );
    setState(() => _activeFlights.add(entry));
    return true;
  }

  void _pulseDownloadCenter() {
    final targetRect = _resolveRect(_downloadTargetKey);
    if (targetRect == null || _animationsDisabled) {
      return;
    }
    _enqueuePulse(targetRect);
  }

  void _enqueuePulse(Rect targetRect) {
    final pulse = _DownloadPulseEntry(
      id: 'download-center-pulse-${_sequence++}',
      targetRect: targetRect,
    );
    setState(() => _activePulses.add(pulse));
  }

  void _removeFlight(_InstallFlightEntry entry) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeFlights.removeWhere((item) => item.id == entry.id);
      _activePulses.add(
        _DownloadPulseEntry(
          id: 'download-center-pulse-${_sequence++}',
          targetRect: entry.targetRect,
        ),
      );
    });
  }

  void _removePulse(_DownloadPulseEntry entry) {
    if (!mounted) {
      return;
    }

    setState(() {
      _activePulses.removeWhere((item) => item.id == entry.id);
    });
  }

  Rect? _resolveRect(GlobalKey? key) {
    final targetContext = key?.currentContext;
    final targetRenderObject = targetContext?.findRenderObject();
    final hostRenderObject = context.findRenderObject();

    if (targetRenderObject is! RenderBox ||
        hostRenderObject is! RenderBox ||
        !targetRenderObject.attached ||
        !targetRenderObject.hasSize ||
        !hostRenderObject.hasSize) {
      return null;
    }

    final rawRect =
        targetRenderObject.localToGlobal(
          Offset.zero,
          ancestor: hostRenderObject,
        ) &
        targetRenderObject.size;
    final hostRect = Offset.zero & hostRenderObject.size;
    final visibleRect = rawRect.intersect(hostRect);
    if (visibleRect.isEmpty ||
        visibleRect.width < 1 ||
        visibleRect.height < 1) {
      return null;
    }
    return visibleRect;
  }

  @override
  Widget build(BuildContext context) {
    return _InstallToDownloadFlyoutScope(
      controller: _controller,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                for (final entry in _activeFlights)
                  _InstallFlightWidget(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onCompleted: () => _removeFlight(entry),
                  ),
                for (final entry in _activePulses)
                  _DownloadPulseWidget(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onCompleted: () => _removePulse(entry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InstallToDownloadFlyoutController {
  InstallToDownloadFlyoutController._(this._state);

  final _InstallToDownloadFlyoutLayerState _state;

  bool launch({
    required GlobalKey sourceKey,
    required String appId,
    String? appName,
    String? iconUrl,
  }) {
    return _state._launch(
      sourceKey: sourceKey,
      appId: appId,
      appName: appName,
      iconUrl: iconUrl,
    );
  }

  void pulseDownloadCenter() {
    _state._pulseDownloadCenter();
  }

  void registerDownloadTarget(GlobalKey key) {
    _state._registerDownloadTarget(key);
  }

  void unregisterDownloadTarget(GlobalKey key) {
    _state._unregisterDownloadTarget(key);
  }
}

class _InstallToDownloadFlyoutScope extends InheritedWidget {
  const _InstallToDownloadFlyoutScope({
    required this.controller,
    required super.child,
  });

  final InstallToDownloadFlyoutController controller;

  @override
  bool updateShouldNotify(_InstallToDownloadFlyoutScope oldWidget) {
    return !identical(controller, oldWidget.controller);
  }
}

/// 下载中心目标锚点。
///
/// 侧边栏只需把真实点击区域包进来，动画层会自动解析目标位置。
class DownloadCenterFlyoutTarget extends StatefulWidget {
  const DownloadCenterFlyoutTarget({required this.child, super.key});

  final Widget child;

  @override
  State<DownloadCenterFlyoutTarget> createState() =>
      _DownloadCenterFlyoutTargetState();
}

class _DownloadCenterFlyoutTargetState
    extends State<DownloadCenterFlyoutTarget> {
  final GlobalKey _anchorKey = GlobalKey(debugLabel: 'download-center-anchor');
  InstallToDownloadFlyoutController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = InstallToDownloadFlyoutLayer.maybeOf(context);
    if (identical(nextController, _controller)) {
      return;
    }

    _controller?.unregisterDownloadTarget(_anchorKey);
    _controller = nextController;
    _controller?.registerDownloadTarget(_anchorKey);
  }

  @override
  void dispose() {
    _controller?.unregisterDownloadTarget(_anchorKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _anchorKey, child: widget.child);
  }
}

class _InstallFlightEntry {
  const _InstallFlightEntry({
    required this.id,
    required this.appId,
    required this.sourceRect,
    required this.targetRect,
    this.appName,
    this.iconUrl,
  });

  final String id;
  final String appId;
  final String? appName;
  final String? iconUrl;
  final Rect sourceRect;
  final Rect targetRect;
}

class _DownloadPulseEntry {
  const _DownloadPulseEntry({required this.id, required this.targetRect});

  final String id;
  final Rect targetRect;
}

class _InstallFlightWidget extends StatefulWidget {
  const _InstallFlightWidget({
    required this.entry,
    required this.onCompleted,
    super.key,
  });

  final _InstallFlightEntry entry;
  final VoidCallback onCompleted;

  @override
  State<_InstallFlightWidget> createState() => _InstallFlightWidgetState();
}

class _InstallFlightWidgetState extends State<_InstallFlightWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _kInstallFlyoutDuration)
        ..addStatusListener(_handleAnimationStatus)
        ..forward();

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.18, 0.88, 0.26, 1),
  );

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final shadowColor = colorScheme.shadow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _progress.value;
        final center = _evaluateCurve(progress);
        final iconSize = lerpDouble(
          widget.entry.sourceRect.shortestSide,
          math.max(30, widget.entry.targetRect.shortestSide * 0.68),
          progress,
        )!;
        final opacity = progress < 0.9
            ? 1.0
            : lerpDouble(
                1,
                0,
                (progress - 0.9) / 0.1,
              )!.clamp(0.0, 1.0).toDouble();
        final scale = progress < 0.24
            ? lerpDouble(0.94, 1.12, progress / 0.24)!
            : lerpDouble(1.12, 0.82, (progress - 0.24) / 0.76)!;
        final rotation = lerpDouble(0.04, -0.18, progress)!;
        final haloSize = iconSize + lerpDouble(26, 16, progress)!;
        final glowOpacity = progress < 0.72
            ? lerpDouble(0.28, 0.2, progress / 0.72)!
            : lerpDouble(0.2, 0.08, (progress - 0.72) / 0.28)!;
        final outlineOpacity = progress < 0.82
            ? lerpDouble(0.5, 0.34, progress / 0.82)!
            : lerpDouble(0.34, 0.0, (progress - 0.82) / 0.18)!;
        final shadowOpacity = lerpDouble(0.3, 0.12, progress)!;
        final iconRadius = lerpDouble(
          widget.entry.sourceRect.shortestSide * 0.18,
          11,
          progress,
        )!;

        return Positioned(
          left: center.dx - (haloSize / 2),
          top: center.dy - (haloSize / 2),
          child: Opacity(
            key: const Key('install-download-flyout'),
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: haloSize,
                  height: haloSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 用主题色光晕强调飞行轨迹，避免图标在复杂背景中被吃掉。
                      Container(
                        key: const Key('install-download-flyout-glow'),
                        width: haloSize,
                        height: haloSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: glowOpacity),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(
                                alpha: glowOpacity * 0.72,
                              ),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: shadowColor.withValues(
                                alpha: shadowOpacity,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: iconSize + 8,
                        height: iconSize + 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(iconRadius + 4),
                          border: Border.all(
                            color: primaryColor.withValues(
                              alpha: outlineOpacity,
                            ),
                            width: 1.6,
                          ),
                        ),
                      ),
                      AppIcon(
                        iconUrl: widget.entry.iconUrl,
                        appName: widget.entry.appName,
                        size: iconSize,
                        borderRadius: iconRadius,
                        memCacheWidth: math.max(64, (iconSize * 2).round()),
                        maxDiskCacheWidth: math.max(96, (iconSize * 3).round()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _evaluateCurve(double t) {
    final start = widget.entry.sourceRect.center;
    final end = widget.entry.targetRect.center;
    final horizontalDistance = end.dx - start.dx;
    final verticalDistance = end.dy - start.dy;
    final lift = math.min(
      118,
      math.max(
        54,
        horizontalDistance.abs() * 0.16 + verticalDistance.abs() * 0.2,
      ),
    );
    final control = Offset(
      lerpDouble(start.dx, end.dx, 0.42)! -
          math.min(44, horizontalDistance.abs() * 0.12),
      math.min(start.dy, end.dy) - lift,
    );

    return Offset(
      _quadraticBezier(start.dx, control.dx, end.dx, t),
      _quadraticBezier(start.dy, control.dy, end.dy, t),
    );
  }

  double _quadraticBezier(double start, double control, double end, double t) {
    final inverse = 1 - t;
    return (inverse * inverse * start) +
        (2 * inverse * t * control) +
        (t * t * end);
  }
}

class _DownloadPulseWidget extends StatefulWidget {
  const _DownloadPulseWidget({
    required this.entry,
    required this.onCompleted,
    super.key,
  });

  final _DownloadPulseEntry entry;
  final VoidCallback onCompleted;

  @override
  State<_DownloadPulseWidget> createState() => _DownloadPulseWidgetState();
}

class _DownloadPulseWidgetState extends State<_DownloadPulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _kDownloadPulseDuration)
        ..addStatusListener(_handleAnimationStatus)
        ..forward();

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final shadowColor = colorScheme.shadow;
    final center = widget.entry.targetRect.center;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _progress.value;
        final primarySize = lerpDouble(
          widget.entry.targetRect.width,
          widget.entry.targetRect.width + 38,
          progress,
        )!;
        final secondarySize = lerpDouble(
          widget.entry.targetRect.width * 0.9,
          widget.entry.targetRect.width + 72,
          progress,
        )!;
        final highlightSize = lerpDouble(
          widget.entry.targetRect.width * 0.72,
          widget.entry.targetRect.width * 1.08,
          progress,
        )!;
        final primaryOpacity = lerpDouble(0.42, 0, progress)!;
        final secondaryOpacity = lerpDouble(0.18, 0, progress)!;
        final highlightOpacity = lerpDouble(0.24, 0, progress)!;

        return Stack(
          children: [
            Positioned(
              left: center.dx - (secondarySize / 2),
              top: center.dy - (secondarySize / 2),
              child: Container(
                key: const Key('install-download-target-pulse'),
                width: secondarySize,
                height: secondarySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: secondaryOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: secondaryOpacity),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: center.dx - (primarySize / 2),
              top: center.dy - (primarySize / 2),
              child: Container(
                width: primarySize,
                height: primarySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: primaryOpacity),
                    width: 2.0,
                  ),
                ),
              ),
            ),
            Positioned(
              left: center.dx - (highlightSize / 2),
              top: center.dy - (highlightSize / 2),
              child: Container(
                key: const Key('install-download-target-highlight'),
                width: highlightSize,
                height: highlightSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: highlightOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(
                        alpha: highlightOpacity * 0.8,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
