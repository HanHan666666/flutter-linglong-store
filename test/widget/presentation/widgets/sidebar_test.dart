import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/widgets/sidebar.dart';

void main() {
  group('Sidebar', () {
    testWidgets('renders dynamic menus above bottom vertical actions', (
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
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Sidebar(currentPath: '/my-apps')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('推荐'), findsOneWidget);
      expect(find.text('全 部'), findsOneWidget);
      expect(find.text('排 行'), findsOneWidget);
      expect(find.text('更 新'), findsNothing);

      expect(find.text('办公'), findsOneWidget);
      expect(find.text('系统'), findsOneWidget);
      expect(find.text('我的应用'), findsOneWidget);
      expect(find.text('下载管理'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      final officeY = tester.getTopLeft(find.text('办公')).dy;
      final systemY = tester.getTopLeft(find.text('系统')).dy;
      final myAppsY = tester.getTopLeft(find.text('我的应用')).dy;
      final downloadsY = tester.getTopLeft(find.text('下载管理')).dy;
      final settingY = tester.getTopLeft(find.text('设置')).dy;

      expect(officeY, lessThan(systemY));
      expect(systemY, lessThan(myAppsY));
      expect(myAppsY, lessThan(downloadsY));
      expect(downloadsY, lessThan(settingY));
    });
  });
}
