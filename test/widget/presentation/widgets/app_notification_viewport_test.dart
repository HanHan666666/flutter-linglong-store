import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_notification_provider.dart';
import 'package:linglong_store/presentation/notifications/app_notification_viewport.dart';

void main() {
  group('AppNotificationViewport', () {
    testWidgets('renders notifications in the top-right stack', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: Placeholder()),
                  AppNotificationViewport(topOffset: 64, rightOffset: 16),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppNotificationViewport));
      final container = ProviderScope.containerOf(context, listen: false);

      container
          .read(appNotificationProvider.notifier)
          .showSuccess(message: '安装成功');

      await tester.pump();

      expect(find.text('安装成功'), findsOneWidget);

      final messageRect = tester.getRect(find.text('安装成功'));
      expect(messageRect.top, greaterThanOrEqualTo(64));
    });

    testWidgets('shows action and dismiss controls only when handler exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  AppNotificationViewport(topOffset: 64, rightOffset: 16),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppNotificationViewport));
      final container = ProviderScope.containerOf(context, listen: false);
      final localizations = MaterialLocalizations.of(context);

      container
          .read(appNotificationProvider.notifier)
          .showWarning(message: '需要处理', actionLabel: '重试', onAction: () {});

      await tester.pump();

      expect(find.text('重试'), findsOneWidget);
      expect(find.byTooltip(localizations.closeButtonTooltip), findsOneWidget);

      container
          .read(appNotificationProvider.notifier)
          .showWarning(message: '无动作按钮', actionLabel: '忽略');

      await tester.pump();

      expect(find.text('忽略'), findsNothing);
    });

    testWidgets('hover pauses dismiss until pointer leaves the notification', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  AppNotificationViewport(topOffset: 64, rightOffset: 16),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppNotificationViewport));
      final container = ProviderScope.containerOf(context, listen: false);

      container.read(appNotificationProvider.notifier).showInfo(
        message: '悬停暂停',
        duration: const Duration(milliseconds: 120),
      );

      await tester.pump();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.text('悬停暂停')));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('悬停暂停'), findsOneWidget);

      await gesture.moveTo(const Offset(1, 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 121));

      expect(find.text('悬停暂停'), findsNothing);
    });

    testWidgets('renders notification only in the highest priority viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  AppNotificationViewport(topOffset: 64, rightOffset: 16),
                  AppNotificationViewport(
                    topOffset: 12,
                    rightOffset: 12,
                    priority: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppNotificationViewport).first);
      final container = ProviderScope.containerOf(context, listen: false);

      container
          .read(appNotificationProvider.notifier)
          .showSuccess(message: '只显示一次');

      await tester.pump();

      expect(find.text('只显示一次'), findsOneWidget);
      final messageRect = tester.getRect(find.text('只显示一次'));
      expect(messageRect.top, lessThan(40));
    });

    testWidgets('does not throw when viewport and provider scope are disposed together', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  AppNotificationViewport(topOffset: 64, rightOffset: 16),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppNotificationViewport), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('notification migrates back when higher priority viewport is removed', (
      tester,
    ) async {
      var showDialogViewport = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Stack(
                    children: [
                      const AppNotificationViewport(
                        topOffset: 64,
                        rightOffset: 16,
                      ),
                      if (showDialogViewport)
                        const AppNotificationViewport(
                          topOffset: 12,
                          rightOffset: 12,
                          priority: 1,
                        ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: TextButton(
                          onPressed: () => setState(() {
                            showDialogViewport = false;
                          }),
                          child: const Text('remove'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(AppNotificationViewport).first);
      final container = ProviderScope.containerOf(context, listen: false);

      container
          .read(appNotificationProvider.notifier)
          .showSuccess(message: '宿主迁移');

      await tester.pump();
      expect(find.text('宿主迁移'), findsOneWidget);
      expect(tester.getRect(find.text('宿主迁移')).top, lessThan(40));

      tester.widget<TextButton>(find.byType(TextButton)).onPressed!.call();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('宿主迁移'), findsOneWidget);
      expect(tester.getRect(find.text('宿主迁移')).top, greaterThanOrEqualTo(64));
    });
  });
}
