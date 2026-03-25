import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/uninstall_blocked_dialog.dart';

/// 辅助：构建带有 l10n 的测试 MaterialApp
Widget _buildTestApp(Widget child) {
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('UninstallBlockedDialog', () {
    testWidgets('shows active task name and both actions', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 展示弹窗（不等待结果）
      showUninstallBlockedDialog(capturedContext, activeTaskName: '测试应用');

      await tester.pumpAndSettle();

      // 标题
      expect(find.text('暂时无法卸载'), findsOneWidget);
      // 消息体包含应用名
      expect(find.textContaining('测试应用'), findsWidgets);
      // 两个按钮
      expect(find.text('我知道了'), findsOneWidget);
      expect(find.text('查看下载管理'), findsOneWidget);
    });

    testWidgets('returns acknowledge when tapping 我知道了', (tester) async {
      late BuildContext capturedContext;
      UninstallBlockedAction? result;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final future = showUninstallBlockedDialog(
        capturedContext,
        activeTaskName: 'Demo',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();

      result = await future;
      expect(result, UninstallBlockedAction.acknowledge);
    });

    testWidgets('returns openDownloadManager when tapping 查看下载管理', (
      tester,
    ) async {
      late BuildContext capturedContext;
      UninstallBlockedAction? result;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final future = showUninstallBlockedDialog(
        capturedContext,
        activeTaskName: 'Demo',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('查看下载管理'));
      await tester.pumpAndSettle();

      result = await future;
      expect(result, UninstallBlockedAction.openDownloadManager);
    });

    testWidgets('falls back to appId when activeTaskName is empty', (
      tester,
    ) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      showUninstallBlockedDialog(
        capturedContext,
        activeTaskName: '',
        fallbackAppId: 'org.example.demo',
      );

      await tester.pumpAndSettle();
      // 消息体包含 fallbackAppId
      expect(find.textContaining('org.example.demo'), findsWidgets);
    });
  });
}
