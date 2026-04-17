// test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/app_detail_provider.dart';

void main() {
  group('AppDetailState 折叠状态', () {
    test('默认状态为折叠（isVersionListExpanded = false）', () {
      const state = AppDetailState();
      expect(state.isVersionListExpanded, false);
    });

    test('copyWith 可以更新折叠状态', () {
      const initialState = AppDetailState();
      final updatedState = initialState.copyWith(isVersionListExpanded: true);

      expect(initialState.isVersionListExpanded, false);
      expect(updatedState.isVersionListExpanded, true);
    });
  });

  group('AppDetail Provider toggleVersionList 方法', () {
    test('调用 toggleVersionList 切换折叠状态', () {
      final container = ProviderContainer();
      final provider = container.read(appDetailProvider('test-app').notifier);

      // 初始状态
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, false);

      // 第一次切换：展开
      provider.toggleVersionList();
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, true);

      // 第二次切换：折叠
      provider.toggleVersionList();
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, false);

      container.dispose();
    });
  });
}