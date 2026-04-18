import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/presentation/widgets/responsive_app_grid.dart';

class _FakeGridItem {
  const _FakeGridItem(this.appId);

  final String appId;
}

Widget _buildGridTestApp({
  required List<_FakeGridItem> items,
  List<Widget> trailingSlivers = const [],
}) {
  return ProviderScope(
    overrides: [
      applicationCardStateIndexProvider.overrideWithValue(
        const ApplicationCardStateIndex(
          installedVersionByAppId: {},
          updateAppIds: {},
          activeTasksByAppId: {},
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: ResponsiveAppGrid<_FakeGridItem>(
                items: items,
                itemBuilder: (ref, index, item, cardState) {
                  return Text(
                    'item-${item.appId}',
                    textDirection: TextDirection.ltr,
                  );
                },
              ),
            ),
            ...trailingSlivers,
          ],
        ),
      ),
    ),
  );
}

void main() {
  group('ResponsiveAppGrid.calculateChildAspectRatio', () {
    test(
      'uses the shared 96px app card baseline when no override is provided',
      () {
        const width = 720.0;
        const crossAxisCount = 2;
        const itemWidth =
            (width - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

        final ratio = ResponsiveAppGrid.calculateChildAspectRatio(
          width,
          crossAxisCount,
        );

        expect(ratio, closeTo(itemWidth / 96.0, 0.0001));
      },
    );

    test('returns the explicit ratio override unchanged', () {
      final ratio = ResponsiveAppGrid.calculateChildAspectRatio(
        720,
        2,
        childAspectRatio: 3.2,
      );

      expect(ratio, 3.2);
    });
  });

  group('pagination footer sliver', () {
    testWidgets('responsive grid only renders passed items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildGridTestApp(
          items: const [
            _FakeGridItem('a'),
            _FakeGridItem('b'),
            _FakeGridItem('c'),
          ],
        ),
      );

      expect(find.text('item-a'), findsOneWidget);
      expect(find.text('item-b'), findsOneWidget);
      expect(find.text('item-c'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('没有更多了'), findsNothing);
    });

    testWidgets('shows a full-width centered loading indicator', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildGridTestApp(
          items: const [_FakeGridItem('a')],
          trailingSlivers: const [
            PaginationFooterSliver(
              isLoadingMore: true,
              hasMore: true,
              hasItems: true,
            ),
          ],
        ),
      );

      final spinnerCenter = tester.getCenter(
        find.byType(CircularProgressIndicator),
      );
      expect(spinnerCenter.dx, closeTo(600, 1));
      expect(find.text('没有更多了'), findsNothing);
    });

    testWidgets('shows no-more text when items are exhausted', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(
          items: const [_FakeGridItem('a')],
          trailingSlivers: const [
            PaginationFooterSliver(
              isLoadingMore: false,
              hasMore: false,
              hasItems: true,
            ),
          ],
        ),
      );

      expect(find.text('没有更多了'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders nothing when the list is empty', (tester) async {
      await tester.pumpWidget(
        _buildGridTestApp(
          items: const [],
          trailingSlivers: const [
            PaginationFooterSliver(
              isLoadingMore: false,
              hasMore: false,
              hasItems: false,
            ),
          ],
        ),
      );

      expect(find.text('没有更多了'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
