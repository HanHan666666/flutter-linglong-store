import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/notifications/app_notification.dart';
import 'package:linglong_store/application/providers/app_notification_provider.dart';

void main() {
  group('AppNotificationController', () {
    test('inserts a notification into visible state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);

      notifier.showInfo(message: '通知已显示');

      final state = container.read(appNotificationProvider);
      expect(state.items, hasLength(1));
      expect(state.items.single.message, '通知已显示');
      expect(state.items.single.type, AppNotificationType.info);
    });

    test('trims the oldest notification when more than three are pushed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);

      notifier.showInfo(message: '第一条');
      notifier.showSuccess(message: '第二条');
      notifier.showWarning(message: '第三条');
      notifier.showError(message: '第四条');

      final state = container.read(appNotificationProvider);
      final messages = state.items.map((item) => item.message).toList();

      expect(state.items, hasLength(3));
      expect(messages, isNot(contains('第一条')));
      expect(messages, containsAll(<String>['第二条', '第三条', '第四条']));
    });

    test('dismiss removes the targeted notification only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);

      final firstId = notifier.showInfo(message: '保留');
      final secondId = notifier.showError(message: '移除');

      notifier.dismiss(secondId);

      final state = container.read(appNotificationProvider);
      expect(state.items, hasLength(1));
      expect(state.items.single.id, firstId);
      expect(state.items.single.message, '保留');
    });

    test(
      'triggerAction invokes handler and dismisses the notification',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(appNotificationProvider.notifier);
        var invoked = false;

        final notificationId = notifier.showWarning(
          message: '需要重试',
          actionLabel: '重试',
          onAction: () {
            invoked = true;
          },
        );

        await notifier.triggerAction(notificationId);

        final state = container.read(appNotificationProvider);
        expect(invoked, isTrue);
        expect(state.items, isEmpty);
      },
    );

    test('auto dismiss removes notification after duration', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);

      notifier.showInfo(
        message: '短暂通知',
        duration: const Duration(milliseconds: 40),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final state = container.read(appNotificationProvider);
      expect(state.items, isEmpty);
    });

    test('pause and resume dismiss keeps notification alive while paused', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);
      final notificationId = notifier.showInfo(
        message: '悬停中的通知',
        duration: const Duration(milliseconds: 60),
      );

      notifier.pauseDismiss(notificationId);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(container.read(appNotificationProvider).items, hasLength(1));

      notifier.resumeDismiss(notificationId);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(container.read(appNotificationProvider).items, isEmpty);
    });

    test('resume dismiss continues from the remaining duration instead of resetting', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appNotificationProvider.notifier);
      final notificationId = notifier.showInfo(
        message: '剩余时长通知',
        duration: const Duration(milliseconds: 120),
      );

      await Future<void>.delayed(const Duration(milliseconds: 70));
      notifier.pauseDismiss(notificationId);
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(container.read(appNotificationProvider).items, hasLength(1));

      notifier.resumeDismiss(notificationId);
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(container.read(appNotificationProvider).items, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(appNotificationProvider).items, isEmpty);
    });
  });
}
