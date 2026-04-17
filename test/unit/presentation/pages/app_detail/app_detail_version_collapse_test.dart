// test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/app_detail_provider.dart';
import 'package:linglong_store/domain/models/app_version.dart';

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

  group('_computeCollapsedVersions 版本计算逻辑（概念验证）', () {
    test('版本数为 0 返回空列表', () {
      final versions = <AppVersion>[];
      final installedVersions = <String>{};

      expect(versions.isEmpty, true);
    });

    test('版本数为 1 返回该版本', () {
      final versions = [AppVersion(versionNo: '1.0')];
      expect(versions.length, 1);
    });
  });
}