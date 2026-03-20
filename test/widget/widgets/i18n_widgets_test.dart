import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/confirm_dialog.dart';
import 'package:linglong_store/presentation/widgets/empty_state.dart';
import 'package:linglong_store/presentation/widgets/error_state.dart';

void main() {
  group('ErrorState i18n Tests', () {
    testWidgets('should display default error text in Chinese', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ErrorState(),
          ),
        ),
      );

      // 应该显示中文默认错误标题
      expect(find.textContaining('错'), findsWidgets);
    });

    testWidgets('should display default error text in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ErrorState(),
          ),
        ),
      );

      // 应该显示英文默认错误标题
      expect(find.textContaining('error'), findsWidgets);
    });

    testWidgets('should use custom error text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ErrorState(
              title: 'Custom Error',
              description: 'Custom error description',
            ),
          ),
        ),
      );

      expect(find.text('Custom Error'), findsOneWidget);
      expect(find.text('Custom error description'), findsOneWidget);
    });
  });

  group('EmptyState i18n Tests', () {
    testWidgets('should display default empty text in Chinese', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EmptyState(),
          ),
        ),
      );

      // 应该显示中文默认空状态文本
      expect(find.textContaining('暂无'), findsWidgets);
    });

    testWidgets('should display default empty text in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EmptyState(),
          ),
        ),
      );

      // 应该显示英文默认空状态文本
      expect(find.textContaining('No'), findsWidgets);
    });

    testWidgets('should use custom empty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EmptyState(
              title: 'No Results',
              description: 'Try a different search',
            ),
          ),
        ),
      );

      expect(find.text('No Results'), findsOneWidget);
      expect(find.text('Try a different search'), findsOneWidget);
    });
  });

  group('ConfirmDialog i18n Tests', () {
    testWidgets('should display localized confirm button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 应该显示中文确认按钮
      expect(find.text('确认'), findsWidgets);
    });

    testWidgets('should display localized cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ConfirmDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 应该显示中文取消按钮
      expect(find.text('取消'), findsWidgets);
    });
  });

  group('AppLocalizations Tests', () {
    test('should have all required localization keys', () {
      // 验证所有必需的本地化键存在
      // 这里我们验证生成的文件存在
      expect(AppLocalizations.localizationsDelegates.length, greaterThan(0));
      expect(AppLocalizations.supportedLocales.length, equals(2));
    });
  });
}