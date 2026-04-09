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

    testWidgets('hidden keepalive pages stay out of the paint tree', (
      tester,
    ) async {
      final myAppsKey = GlobalKey<KeepAlivePageWrapperState>();
      final rankingKey = GlobalKey<KeepAlivePageWrapperState>();

      await tester.pumpWidget(
        _StackedVisibilitySyncHarness(
          currentPath: AppRoutes.myApps,
          myAppsKey: myAppsKey,
          rankingKey: rankingKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('my-apps-content'), findsOneWidget);
      expect(find.text('ranking-content'), findsNothing);

      await tester.pumpWidget(
        _StackedVisibilitySyncHarness(
          currentPath: AppRoutes.ranking,
          myAppsKey: myAppsKey,
          rankingKey: rankingKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('my-apps-content'), findsNothing);
      expect(find.text('ranking-content'), findsOneWidget);
    });

    testWidgets('route switch hides previous page on the first frame', (
      tester,
    ) async {
      final updateKey = GlobalKey<KeepAlivePageWrapperState>();
      final rankingKey = GlobalKey<KeepAlivePageWrapperState>();

      await tester.pumpWidget(
        _CrossRouteVisibilityHarness(
          currentPath: AppRoutes.updateApps,
          updateKey: updateKey,
          rankingKey: rankingKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('update-content'), findsOneWidget);
      expect(find.text('ranking-content'), findsNothing);

      await tester.pumpWidget(
        _CrossRouteVisibilityHarness(
          currentPath: AppRoutes.ranking,
          updateKey: updateKey,
          rankingKey: rankingKey,
        ),
      );

      expect(find.text('update-content'), findsNothing);
      expect(find.text('ranking-content'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(updateKey.currentState!.isVisible, isFalse);
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
      home: ShellRouteVisibilityScope(
        currentPath: currentPath,
        child: Stack(
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
      ),
    );
  }
}

class _StackedVisibilitySyncHarness extends StatelessWidget {
  const _StackedVisibilitySyncHarness({
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
      home: ShellRouteVisibilityScope(
        currentPath: currentPath,
        child: Stack(
          children: [
            Positioned.fill(
              child: KeepAlivePageWrapper(
                key: myAppsKey,
                routePath: AppRoutes.myApps,
                child: const ColoredBox(
                  color: Colors.blue,
                  child: Center(child: Text('my-apps-content')),
                ),
              ),
            ),
            Positioned.fill(
              child: KeepAlivePageWrapper(
                key: rankingKey,
                routePath: AppRoutes.ranking,
                child: const ColoredBox(
                  color: Colors.orange,
                  child: Center(child: Text('ranking-content')),
                ),
              ),
            ),
            KeepAliveVisibilitySync(currentPath: currentPath),
          ],
        ),
      ),
    );
  }
}

class _CrossRouteVisibilityHarness extends StatelessWidget {
  const _CrossRouteVisibilityHarness({
    required this.currentPath,
    required this.updateKey,
    required this.rankingKey,
  });

  final String currentPath;
  final GlobalKey<KeepAlivePageWrapperState> updateKey;
  final GlobalKey<KeepAlivePageWrapperState> rankingKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShellRouteVisibilityScope(
        currentPath: currentPath,
        child: Stack(
          children: [
            Positioned.fill(
              child: KeepAlivePageWrapper(
                key: updateKey,
                routePath: AppRoutes.updateApps,
                child: const ColoredBox(
                  color: Colors.green,
                  child: Center(child: Text('update-content')),
                ),
              ),
            ),
            Positioned.fill(
              child: KeepAlivePageWrapper(
                key: rankingKey,
                routePath: AppRoutes.ranking,
                child: const ColoredBox(
                  color: Colors.orange,
                  child: Center(child: Text('ranking-content')),
                ),
              ),
            ),
            KeepAliveVisibilitySync(currentPath: currentPath),
          ],
        ),
      ),
    );
  }
}
