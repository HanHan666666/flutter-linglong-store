import 'dart:async';

enum AppNotificationType { info, success, warning, error }

typedef AppNotificationActionHandler = FutureOr<void> Function();

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.actionId,
    this.dismissible = true,
  });

  final String id;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final String? actionId;
  final bool dismissible;
}

class AppNotificationState {
  const AppNotificationState({
    this.items = const <AppNotificationItem>[],
    this.viewportEpoch = 0,
  });

  final List<AppNotificationItem> items;
  final int viewportEpoch;

  AppNotificationState copyWith({
    List<AppNotificationItem>? items,
    int? viewportEpoch,
  }) {
    return AppNotificationState(
      items: items ?? this.items,
      viewportEpoch: viewportEpoch ?? this.viewportEpoch,
    );
  }
}
