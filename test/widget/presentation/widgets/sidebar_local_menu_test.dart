import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/widgets/sidebar.dart';

void main() {
  group('Sidebar local dynamic menu config', () {
    testWidgets('renders localized english labels for known local menu codes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
                SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
                SidebarMenuDTO(menuCode: 'dev', menuName: '开发'),
                SidebarMenuDTO(menuCode: 'entertainment', menuName: '娱乐'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Sidebar(currentPath: '/')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Office'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Development'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
    });

    testWidgets('falls back to backend name and generic icon for unknown codes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'experimental', menuName: 'Experimental'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Sidebar(currentPath: '/')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Experimental'), findsOneWidget);
      expect(find.byIcon(Icons.widgets_outlined), findsOneWidget);
    });

    testWidgets('adds tooltip for dynamic menu items', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sidebarConfigProvider.overrideWith(
              (ref) async => const [
                SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
                SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
              ],
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: Sidebar(currentPath: '/')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip('Office'), findsOneWidget);
      expect(find.byTooltip('System'), findsOneWidget);
    });
  });
}
