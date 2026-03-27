import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
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

  testWidgets('展开态不再渲染下方第二块独立分类面板', (tester) async {
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
      findsNothing,
    );
  });

  testWidgets('展开态直接在顶部同一分类容器内展示全部分类', (tester) async {
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
      find.byKey(const ValueKey('category-filter-container')),
      findsOneWidget,
    );
    expect(find.text('分类 11'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
  });
}
