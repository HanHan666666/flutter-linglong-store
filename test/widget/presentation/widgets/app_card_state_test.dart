import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
