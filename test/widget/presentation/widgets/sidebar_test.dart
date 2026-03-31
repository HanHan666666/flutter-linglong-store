import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/core/config/local_sidebar_menu_catalog.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/widgets/sidebar.dart';

void main() {
  group('Sidebar', () {
    testWidgets(
      'renders bottom actions horizontally when sidebar is expanded',
      (tester) async {
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
              locale: Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: Sidebar(currentPath: '/my-apps')),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final officeLabel = resolveSidebarMenuLabel(
          menuCode: 'office',
          locale: const Locale('zh'),
          fallbackName: '办公',
        );
        final systemLabel = resolveSidebarMenuLabel(
          menuCode: 'system',
          locale: const Locale('zh'),
          fallbackName: '系统',
        );

        expect(find.text('推 荐'), findsOneWidget);
        expect(find.text('全 部'), findsOneWidget);
        expect(find.text('排 行'), findsOneWidget);
        expect(find.text('更 新'), findsNothing);

        expect(find.text(officeLabel), findsOneWidget);
        expect(find.text(systemLabel), findsOneWidget);
        final officeY = tester.getTopLeft(find.text(officeLabel)).dy;
        final systemY = tester.getTopLeft(find.text(systemLabel)).dy;
        final myAppsY = tester.getTopLeft(find.byTooltip('我的应用')).dy;
        final downloadsY = tester.getTopLeft(find.byTooltip('下载管理')).dy;
        final settingY = tester.getTopLeft(find.byTooltip('设置')).dy;
        final myAppsX = tester.getTopLeft(find.byTooltip('我的应用')).dx;
        final downloadsX = tester.getTopLeft(find.byTooltip('下载管理')).dx;
        final settingX = tester.getTopLeft(find.byTooltip('设置')).dx;

        expect(officeY, lessThan(systemY));
        expect(systemY, lessThan(myAppsY));
        expect((myAppsY - downloadsY).abs(), lessThan(2));
        expect((downloadsY - settingY).abs(), lessThan(2));
        expect(myAppsX, lessThan(downloadsX));
        expect(downloadsX, lessThan(settingX));
      },
    );

    testWidgets(
      'uses widened desktop width and single-line english labels',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sidebarConfigProvider.overrideWith((ref) async => const []),
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

        expect(Sidebar.defaultWidth, 176);

        final recommendText = tester.widget<Text>(find.text('Recommend'));
        expect(recommendText.maxLines, 1);
        expect(recommendText.softWrap, isFalse);
        expect(recommendText.overflow, TextOverflow.ellipsis);
      },
    );
  });
}
