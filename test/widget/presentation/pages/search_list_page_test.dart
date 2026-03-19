import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/presentation/pages/search_list/search_list_page.dart';

void main() {
  testWidgets(
    'search list page uses top header search as the only input entry',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SearchListPage(),
          ),
        ),
      );

      expect(find.byType(TextField), findsNothing);
      expect(find.text('在顶部搜索框输入关键词'), findsOneWidget);
      expect(find.text('按 Enter 开始搜索应用'), findsOneWidget);
    },
  );
}
