import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/presentation/widgets/category_filter_header.dart';
import 'package:linglong_store/presentation/widgets/category_filter_section.dart';

import '../../../test_utils.dart';

void main() {
  List<CategoryInfo> buildCategories(int count) {
    return List<CategoryInfo>.generate(
      count,
      (index) => CategoryInfo(
        code: 'category-$index',
        name: '分类 $index',
        appCount: index + 1,
      ),
    );
  }

  testWidgets('展开态保持固定头部高度且不再依赖内部滚动容器', (tester) async {
    final delegate = CategoryFilterHeaderDelegate(
      categories: buildCategories(24),
      selectedIndex: 0,
      onSelected: (_) {},
      isExpanded: true,
      onToggleExpand: () {},
    );

    expect(delegate.minExtent, equals(64));
    expect(delegate.maxExtent, equals(64));

    await tester.pumpWidget(
      createTestApp(
        CustomScrollView(
          slivers: [SliverPersistentHeader(pinned: true, delegate: delegate)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('公共分类区在展开时追加完整分类面板', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        CustomScrollView(
          slivers: [
            CategoryFilterSection(
              categories: buildCategories(12),
              selectedIndex: 0,
              onSelected: (_) {},
              showCount: true,
              isExpanded: true,
              onToggleExpand: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-filter-expanded-panel')),
      findsOneWidget,
    );
    expect(find.text('分类 11'), findsOneWidget);
  });
}
