import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/keepalive_visibility_sync.dart';
import 'package:linglong_store/core/config/page_visibility.dart';
import 'package:linglong_store/core/config/routes.dart';

void main() {
  group('KeepAlivePageRegistry', () {
    setUp(() {
      PageVisibilityManager.instance.clearAll();
      KeepAlivePageRegistry.clear();
    });

    testWidgets('syncVisibleRoute hides previous keepalive page and shows current route',
        (tester) async {
      final myAppsKey = GlobalKey<KeepAlivePageWrapperState>();
      final rankingKey = GlobalKey<KeepAlivePageWrapperState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(
                child: KeepAlivePageWrapper(
                  key: myAppsKey,
                  routePath: AppRoutes.myApps,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: KeepAlivePageWrapper(
                  key: rankingKey,
                  routePath: AppRoutes.ranking,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      );

      await tester.pump();

      KeepAlivePageRegistry.syncVisibleRoute(AppRoutes.myApps);
      await tester.pumpAndSettle();

      expect(myAppsKey.currentState!.isVisible, isTrue);
      expect(rankingKey.currentState!.isVisible, isFalse);
      expect(
        PageVisibilityManager.instance.getVisibilityStatus(AppRoutes.myApps),
        equals(PageVisibilityStatus.mountedVisible),
      );
      expect(
        PageVisibilityManager.instance.getVisibilityStatus(AppRoutes.ranking),
        equals(PageVisibilityStatus.mountedHidden),
      );

      KeepAlivePageRegistry.syncVisibleRoute(AppRoutes.ranking);
      await tester.pumpAndSettle();

      expect(myAppsKey.currentState!.isVisible, isFalse);
      expect(rankingKey.currentState!.isVisible, isTrue);
      expect(
        PageVisibilityManager.instance.getVisibilityStatus(AppRoutes.myApps),
        equals(PageVisibilityStatus.mountedHidden),
      );
      expect(
        PageVisibilityManager.instance.getVisibilityStatus(AppRoutes.ranking),
        equals(PageVisibilityStatus.mountedVisible),
      );
    });

    testWidgets('KeepAliveVisibilitySync follows current route changes',
        (tester) async {
      final myAppsKey = GlobalKey<KeepAlivePageWrapperState>();
      final rankingKey = GlobalKey<KeepAlivePageWrapperState>();

      await tester.pumpWidget(
        _VisibilitySyncHarness(
          currentPath: AppRoutes.myApps,
          myAppsKey: myAppsKey,
          rankingKey: rankingKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(myAppsKey.currentState!.isVisible, isTrue);
      expect(rankingKey.currentState!.isVisible, isFalse);

      await tester.pumpWidget(
        _VisibilitySyncHarness(
          currentPath: AppRoutes.ranking,
          myAppsKey: myAppsKey,
          rankingKey: rankingKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(myAppsKey.currentState!.isVisible, isFalse);
      expect(rankingKey.currentState!.isVisible, isTrue);
    });
  });
}

class _VisibilitySyncHarness extends StatelessWidget {
  const _VisibilitySyncHarness({
    required this.currentPath,
    required this.myAppsKey,
    required this.rankingKey,
  });

  final String currentPath;
  final GlobalKey<KeepAlivePageWrapperState> myAppsKey;
  final GlobalKey<KeepAlivePageWrapperState> rankingKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: KeepAlivePageWrapper(
                  key: myAppsKey,
                  routePath: AppRoutes.myApps,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: KeepAlivePageWrapper(
                  key: rankingKey,
                  routePath: AppRoutes.ranking,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
          KeepAliveVisibilitySync(currentPath: currentPath),
        ],
      ),
    );
  }
}
