import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/app_notification.dart';

final appNotificationProvider =
    NotifierProvider<AppNotificationController, AppNotificationState>(
      AppNotificationController.new,
    );

class AppNotificationController extends Notifier<AppNotificationState> {
  static const int _maxVisibleItems = 3;
  int _nextId = 0;
  int _nextViewportOrder = 0;
  final Map<String, Timer> _dismissTimers = <String, Timer>{};
  final Map<String, Duration> _remainingDurations = <String, Duration>{};
  final Map<String, DateTime> _dismissStartedAt = <String, DateTime>{};
  final Map<String, AppNotificationActionHandler> _actionHandlers =
      <String, AppNotificationActionHandler>{};
  final Map<String, ({int priority, int order, bool Function() isActive})>
  _viewportHosts = <String, ({int priority, int order, bool Function() isActive})>{};

  @override
  AppNotificationState build() {
    ref.onDispose(_disposeResources);
    return const AppNotificationState();
  }

  String showInfo({
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    String? actionId,
    AppNotificationActionHandler? onAction,
  }) {
    return _show(
      type: AppNotificationType.info,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      actionId: actionId,
      onAction: onAction,
    );
  }

  String showSuccess({
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    String? actionId,
    AppNotificationActionHandler? onAction,
  }) {
    return _show(
      type: AppNotificationType.success,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      actionId: actionId,
      onAction: onAction,
    );
  }

  String showWarning({
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    String? actionId,
    AppNotificationActionHandler? onAction,
  }) {
    return _show(
      type: AppNotificationType.warning,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      actionId: actionId,
      onAction: onAction,
    );
  }

  String showError({
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    String? actionId,
    AppNotificationActionHandler? onAction,
  }) {
    return _show(
      type: AppNotificationType.error,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      actionId: actionId,
      onAction: onAction,
    );
  }

  void dismiss(String notificationId) {
    _clearNotificationResources(notificationId);
    state = state.copyWith(
      items: state.items
          .where((item) => item.id != notificationId)
          .toList(growable: false),
    );
  }

  Future<void> triggerAction(String notificationId) async {
    final handler = _actionHandlers.remove(notificationId);
    _cancelTimer(notificationId);
    dismiss(notificationId);
    if (handler != null) {
      await handler();
    }
  }

  void pauseDismiss(String notificationId) {
    final startedAt = _dismissStartedAt[notificationId];
    final remaining = _remainingDurations[notificationId];
    if (startedAt != null && remaining != null) {
      final elapsed = DateTime.now().difference(startedAt);
      final nextRemaining = remaining - elapsed;
      _remainingDurations[notificationId] = nextRemaining.isNegative
          ? Duration.zero
          : nextRemaining;
    }
    _dismissStartedAt.remove(notificationId);
    _cancelTimer(notificationId);
  }

  void resumeDismiss(String notificationId) {
    final duration = _remainingDurations[notificationId];
    final itemExists = state.items.any((item) => item.id == notificationId);
    if (!itemExists || duration == null || _dismissTimers.containsKey(notificationId)) {
      return;
    }
    if (duration == Duration.zero) {
      dismiss(notificationId);
      return;
    }
    _startDismissTimer(notificationId, duration);
  }

  void registerViewportHost(
    String viewportId, {
    required int priority,
    required bool Function() isActive,
    bool notify = true,
  }) {
    _viewportHosts[viewportId] = (
      priority: priority,
      order: ++_nextViewportOrder,
      isActive: isActive,
    );
    if (notify) {
      notifyViewportHostsChanged();
    }
  }

  void unregisterViewportHost(String viewportId, {bool notify = true}) {
    if (_viewportHosts.remove(viewportId) != null) {
      if (notify) {
        notifyViewportHostsChanged();
      }
    }
  }

  void notifyViewportHostsChanged() {
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(viewportEpoch: state.viewportEpoch + 1);
  }

  bool shouldRenderInViewport(String viewportId) {
    final currentHost = _viewportHosts[viewportId];
    if (currentHost == null || !currentHost.isActive()) {
      return false;
    }

    ({int priority, int order, bool Function() isActive})? winner;
    for (final host in _viewportHosts.values) {
      if (!host.isActive()) {
        continue;
      }
      if (winner == null ||
          host.priority > winner.priority ||
          (host.priority == winner.priority && host.order > winner.order)) {
        winner = host;
      }
    }

    return winner != null &&
        winner.priority == currentHost.priority &&
        winner.order == currentHost.order;
  }

  String _show({
    required AppNotificationType type,
    required String message,
    required Duration duration,
    String? actionLabel,
    String? actionId,
    AppNotificationActionHandler? onAction,
  }) {
    final notificationId = 'app-notification-${++_nextId}';
    final hasAction = actionLabel != null && onAction != null;
    final nextItems = <AppNotificationItem>[
      AppNotificationItem(
        id: notificationId,
        message: message,
        type: type,
        duration: duration,
        actionLabel: hasAction ? actionLabel : null,
        actionId: hasAction ? (actionId ?? notificationId) : null,
      ),
      ...state.items,
    ];

    while (nextItems.length > _maxVisibleItems) {
      final removed = nextItems.removeLast();
      _clearNotificationResources(removed.id);
    }

    if (hasAction) {
      _actionHandlers[notificationId] = onAction;
    }

    _remainingDurations[notificationId] = duration;
    _startDismissTimer(notificationId, duration);

    state = state.copyWith(items: nextItems);
    return notificationId;
  }

  void _startDismissTimer(String notificationId, Duration duration) {
    _cancelTimer(notificationId);
    _dismissStartedAt[notificationId] = DateTime.now();
    _remainingDurations[notificationId] = duration;
    _dismissTimers[notificationId] = Timer(duration, () {
      dismiss(notificationId);
    });
  }

  void _cancelTimer(String notificationId) {
    _dismissTimers.remove(notificationId)?.cancel();
  }

  void _clearNotificationResources(String notificationId) {
    _cancelTimer(notificationId);
    _remainingDurations.remove(notificationId);
    _dismissStartedAt.remove(notificationId);
    _actionHandlers.remove(notificationId);
  }

  void _disposeResources() {
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    _dismissTimers.clear();
    _remainingDurations.clear();
    _dismissStartedAt.clear();
    _actionHandlers.clear();
    _viewportHosts.clear();
  }
}
