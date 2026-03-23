import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/presentation/widgets/install_button.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';

void main() {
  group('InstallButton Widget', () {
    group('Install state', () {
      testWidgets('should display "安装" label in Chinese', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.notInstalled),
            ),
          ),
        );

        expect(find.text('安 装'), findsOneWidget);
      });

      testWidgets('should display download icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.notInstalled),
            ),
          ),
        );

        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('should call onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.notInstalled,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Installing state', () {
      testWidgets('should display progress indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.5,
              ),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display progress percentage', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.75,
              ),
            ),
          ),
        );

        expect(find.textContaining('75%'), findsOneWidget);
      });

      testWidgets('should display download speed when provided', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.5,
                downloadSpeed: '2.5 MB/s',
              ),
            ),
          ),
        );

        expect(find.textContaining('2.5 MB/s'), findsOneWidget);
      });

      testWidgets('should not display speed when state is not installing', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.pending,
                downloadSpeed: '2.5 MB/s',
              ),
            ),
          ),
        );

        expect(find.textContaining('2.5 MB/s'), findsNothing);
      });
    });

    group('Pending state', () {
      testWidgets('should display "等待安装" label in Chinese', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.pending),
            ),
          ),
        );

        expect(find.text('等待安装'), findsOneWidget);
      });

      testWidgets('should display "Waiting" label in English', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.pending),
            ),
          ),
        );

        expect(find.text('Waiting'), findsOneWidget);
      });

      testWidgets('should display circular progress indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.pending),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should not show cancel button initially', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.pending,
                onCancel: () {},
              ),
            ),
          ),
        );

        // 初始状态显示"等待安装"，不是"取消安装"
        expect(find.text('等待安装'), findsOneWidget);
        expect(find.text('取消安装'), findsNothing);
      });

      testWidgets('should show "取消安装" on hover', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.pending,
                onCancel: () {},
              ),
            ),
          ),
        );

        // 初始状态
        expect(find.text('等待安装'), findsOneWidget);

        // 模拟悬停
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(InstallButton)));
        await tester.pumpAndSettle();

        // 悬停后显示"取消安装"
        expect(find.text('取消安装'), findsOneWidget);
        expect(find.text('等待安装'), findsNothing);
      });

      testWidgets('should call onCancel when tapped while hovering', (tester) async {
        var cancelled = false;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.pending,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        );

        // 模拟悬停
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(InstallButton)));
        await tester.pumpAndSettle();

        // 点击取消
        await tester.tap(find.byType(InstallButton));
        await tester.pump();

        expect(cancelled, isTrue);
      });

      testWidgets('should show close icon on hover', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.pending,
                onCancel: () {},
              ),
            ),
          ),
        );

        // 模拟悬停
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(InstallButton)));
        await tester.pumpAndSettle();

        // 悬停后显示关闭图标
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should not allow cancel if onCancel is null', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.pending),
            ),
          ),
        );

        // 模拟悬停
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(InstallButton)));
        await tester.pump(const Duration(milliseconds: 200)); // 不用 pumpAndSettle，因为动画会持续

        // 没有 onCancel，悬停后仍然显示"等待安装"
        expect(find.text('等待安装'), findsOneWidget);
        expect(find.text('取消安装'), findsNothing);
      });
    });

    group('Installed state', () {
      testWidgets('should display "打开" label in Chinese', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.installed),
            ),
          ),
        );

        expect(find.text('打 开'), findsOneWidget);
      });

      testWidgets('should display open icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.installed),
            ),
          ),
        );

        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });
    });

    group('Update state', () {
      testWidgets('should display "更新" label in Chinese', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.update),
            ),
          ),
        );

        expect(find.text('更 新'), findsOneWidget);
      });

      testWidgets('should display update icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.update),
            ),
          ),
        );

        expect(find.byIcon(Icons.update), findsOneWidget);
      });
    });

    group('Uninstall state', () {
      testWidgets('should display "卸载" label in Chinese', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.uninstall),
            ),
          ),
        );

        expect(find.text('卸 载'), findsOneWidget);
      });
    });

    group('Disabled state', () {
      testWidgets('should be disabled when disabled is true', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.update,
                disabled: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        // 禁用状态按钮不可点击
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });
    });

    group('Button sizes', () {
      testWidgets('small size should have correct height', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.update,
                size: ButtonSize.small,
              ),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, 28);
      });

      testWidgets('medium size should have correct height', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.update,
                size: ButtonSize.medium,
              ),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, 32);
      });

      testWidgets('large size should have correct height', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.update,
                size: ButtonSize.large,
              ),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
        expect(sizedBox.height, 40);
      });
    });
  });
}