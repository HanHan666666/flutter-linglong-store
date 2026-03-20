import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/all_apps_provider.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AllAppsProvider', () {
    group('AllAppsState', () {
      test('should have correct default values', () {
        // Arrange & Act
        const state = AllAppsState();

        // Assert
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNull);
        expect(state.data, isNull);
        expect(state.selectedCategoryIndex, equals(0));
        expect(state.currentPage, equals(1));
      });

      test('should support copyWith', () {
        // Arrange
        const state = AllAppsState();

        // Act
        final newState = state.copyWith(
          isLoading: true,
          error: 'Test error',
          selectedCategoryIndex: 2,
        );

        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.error, equals('Test error'));
        expect(newState.selectedCategoryIndex, equals(2));
      });
    });

    group('AllAppsData', () {
      test('should create with required fields', () {
        // Arrange
        const data = AllAppsData(
          categories: [CategoryInfo(code: 'all', name: '全部')],
          apps: PaginatedResponse<RecommendAppInfo>(
            items: [],
            total: 0,
            page: 1,
            pageSize: 20,
            hasMore: false,
          ),
        );

        // Assert
        expect(data.categories.length, equals(1));
        expect(data.apps.items, isEmpty);
      });

      test('should support copyWith', () {
        // Arrange
        const data = AllAppsData(
          categories: [CategoryInfo(code: 'all', name: '全部')],
          apps: PaginatedResponse<RecommendAppInfo>(
            items: [],
            total: 0,
            page: 1,
            pageSize: 20,
            hasMore: false,
          ),
        );

        // Act
        final newData = data.copyWith(
          categories: [
            const CategoryInfo(code: 'all', name: '全部'),
            const CategoryInfo(code: 'cat-1', name: 'Category 1'),
          ],
        );

        // Assert
        expect(newData.categories.length, equals(2));
        expect(newData.apps.items, isEmpty);
      });
    });
  });
}