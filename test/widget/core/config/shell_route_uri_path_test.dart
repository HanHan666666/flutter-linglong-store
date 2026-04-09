import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/shell_primary_route.dart';

void main() {
  testWidgets(
    'shell visibility uses uri.path so pushed detail routes stay visible',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.ranking,
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                _ShellOverlayHarness(currentPath: state.uri.path, child: child),
            routes: [
              GoRoute(
                path: AppRoutes.ranking,
                builder: (context, state) =>
                    const Center(child: Text('ranking-page')),
              ),
              GoRoute(
                path: AppRoutes.appDetail,
                builder: (context, state) =>
                    Center(child: Text('detail-${state.pathParameters['id']}')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('primary-stack'), findsOneWidget);

      router.push('/app/org.example.demo');
      await tester.pumpAndSettle();

      expect(find.text('detail-org.example.demo'), findsOneWidget);
    },
  );

  testWidgets(
    'secondary routes still render with real primary placeholder routes present',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutes.myApps,
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                _ShellOverlayHarness(currentPath: state.uri.path, child: child),
            routes: [
              GoRoute(
                path: AppRoutes.recommend,
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRoutes.myApps,
                builder: (context, state) => const SizedBox.shrink(),
              ),
              GoRoute(
                path: AppRoutes.setting,
                builder: (context, state) =>
                    const Center(child: Text('setting-page-content')),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('primary-stack'), findsOneWidget);

      router.go(AppRoutes.setting);
      await tester.pumpAndSettle();

      expect(find.text('setting-page-content'), findsOneWidget);
    },
  );
}

class _ShellOverlayHarness extends StatelessWidget {
  const _ShellOverlayHarness({required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showOverlay = !ShellPrimaryRoute.isPrimaryPath(currentPath);
    return Scaffold(
      body: Stack(
        children: [
          Offstage(
            offstage: showOverlay,
            child: const Center(child: Text('primary-stack')),
          ),
          if (showOverlay) Positioned.fill(child: child),
        ],
      ),
    );
  }
}
