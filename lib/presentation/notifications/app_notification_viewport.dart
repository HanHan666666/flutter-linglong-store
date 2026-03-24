import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_notification_provider.dart';
import 'app_notification_card.dart';

class AppNotificationViewport extends ConsumerStatefulWidget {
  const AppNotificationViewport({
    required this.topOffset,
    required this.rightOffset,
    this.priority = 0,
    super.key,
  });

  final double topOffset;
  final double rightOffset;
  final int priority;

  @override
  ConsumerState<AppNotificationViewport> createState() =>
      _AppNotificationViewportState();
}

class _AppNotificationViewportState extends ConsumerState<AppNotificationViewport> {
  late final String _viewportId;
  late AppNotificationController _lifecycleController;
  bool _hostRegistered = false;

  void _registerHostSilently() {
    _lifecycleController.registerViewportHost(
      _viewportId,
      priority: widget.priority,
      isActive: () => mounted,
      notify: false,
    );
    _hostRegistered = true;
  }

  void _scheduleViewportHostNotification() {
    scheduleMicrotask(() {
      _lifecycleController.notifyViewportHostsChanged();
    });
  }

  @override
  void initState() {
    super.initState();
    _viewportId = '${widget.priority}-${identityHashCode(this)}';
    _lifecycleController = ref.read(appNotificationProvider.notifier);
    _registerHostSilently();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _lifecycleController.notifyViewportHostsChanged();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lifecycleController = ref.read(appNotificationProvider.notifier);
  }

  @override
  void activate() {
    super.activate();
    if (_hostRegistered) {
      return;
    }
    _registerHostSilently();
    _scheduleViewportHostNotification();
  }

  @override
  void deactivate() {
    if (_hostRegistered) {
      _lifecycleController.unregisterViewportHost(
        _viewportId,
        notify: false,
      );
      _hostRegistered = false;
      _scheduleViewportHostNotification();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_hostRegistered) {
      _lifecycleController.unregisterViewportHost(_viewportId, notify: false);
      _hostRegistered = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appNotificationProvider);
    final shouldRender = ref
        .read(appNotificationProvider.notifier)
        .shouldRenderInViewport(_viewportId);

    if (state.items.isEmpty || !shouldRender) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: widget.topOffset,
      right: widget.rightOffset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < state.items.length; index++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AppNotificationCard(
                key: ValueKey(state.items[index].id),
                item: state.items[index],
                onDismiss: () => ref
                    .read(appNotificationProvider.notifier)
                    .dismiss(state.items[index].id),
                onAction: () => ref
                    .read(appNotificationProvider.notifier)
                    .triggerAction(state.items[index].id),
                onHoverChanged: (isHovering) {
                  final controller = ref.read(appNotificationProvider.notifier);
                  if (isHovering) {
                    controller.pauseDismiss(state.items[index].id);
                    return;
                  }
                  controller.resumeDismiss(state.items[index].id);
                },
              ),
            ),
            if (index != state.items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
