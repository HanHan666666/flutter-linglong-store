import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/app_card.dart';
import 'package:linglong_store/presentation/widgets/install_button.dart';

import '../../../test_utils.dart';

void main() {
  group('AppCard state handling', () {
    testWidgets('disables primary button when state is pending', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const AppCard(
            appId: 'org.example.app',
            name: 'Example',
            description: 'Example description',
            buttonState: InstallButtonState.pending,
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));

      expect(find.text('等待安装'), findsOneWidget);
      expect(button.onPressed, isNull);
    });

    testWidgets('shows loading state and disables button when installing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const AppCard(
            appId: 'org.example.app',
            name: 'Example',
            description: 'Example description',
            buttonState: InstallButtonState.installing,
            progress: 0.4,
            isInstalling: true,
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(button.onPressed, isNull);
    });

    testWidgets('passes the icon source key to the primary action callback', (
      tester,
    ) async {
      GlobalKey? capturedSourceKey;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppCard(
              appId: 'org.example.app',
              name: 'Example',
              description: 'Example description',
              buttonState: InstallButtonState.notInstalled,
              onPrimaryPressed: (sourceKey) {
                capturedSourceKey = sourceKey;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(capturedSourceKey, isNotNull);
      expect(capturedSourceKey!.currentContext, isNotNull);
    });

    testWidgets(
      'passes the icon source key from the outlined primary button branch',
      (tester) async {
        GlobalKey? capturedSourceKey;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppCard(
                appId: 'org.example.app',
                name: 'Example',
                description: 'Example description',
                buttonState: InstallButtonState.installed,
                onPrimaryPressed: (sourceKey) {
                  capturedSourceKey = sourceKey;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        expect(capturedSourceKey, isNotNull);
        expect(capturedSourceKey!.currentContext, isNotNull);
      },
    );
  });
}
