import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('RecommendProvider', () {
    group('RecommendState', () {
      test('should have correct default values', () {
        // Arrange & Act
        const state = RecommendState();

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
        const state = RecommendState();

        // Act
        final newState = state.copyWith(
          isLoading: true,
          error: 'Test error',
        );

        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.error, equals('Test error'));
        expect(newState.isLoadingMore, isFalse);
      });
    });

    group('RecommendData', () {
      test('should create with required fields', () {
        // Arrange
        final data = RecommendData(
          banners: [BannerInfo(id: '1', title: 'Test', imageUrl: 'url')],
          categories: [CategoryInfo(code: 'all', name: '全部')],
          apps: const PaginatedResponse<RecommendAppInfo>(
            items: [],
            total: 0,
            page: 1,
            pageSize: 20,
            hasMore: false,
          ),
        );

        // Assert
        expect(data.banners.length, equals(1));
        expect(data.categories.length, equals(1));
        expect(data.apps.items, isEmpty);
      });

      test('should support copyWith', () {
        // Arrange
        final data = RecommendData(
          banners: [BannerInfo(id: '1', title: 'Test', imageUrl: 'url')],
          categories: [CategoryInfo(code: 'all', name: '全部')],
          apps: const PaginatedResponse<RecommendAppInfo>(
            items: [],
            total: 0,
            page: 1,
            pageSize: 20,
            hasMore: false,
          ),
        );

        // Act
        final newData = data.copyWith(
          banners: [BannerInfo(id: '2', title: 'New', imageUrl: 'new')],
        );

        // Assert
        expect(newData.banners.length, equals(1));
        expect(newData.banners[0].id, equals('2'));
        expect(newData.categories.length, equals(1));
      });
    });

    group('BannerInfo', () {
      test('should create with required fields', () {
        // Arrange & Act
        final banner = BannerInfo(
          id: 'banner-1',
          title: 'Test Banner',
          imageUrl: 'https://example.com/image.png',
          targetAppId: 'com.example.app',
          description: 'Description',
        );

        // Assert
        expect(banner.id, equals('banner-1'));
        expect(banner.title, equals('Test Banner'));
        expect(banner.imageUrl, equals('https://example.com/image.png'));
        expect(banner.targetAppId, equals('com.example.app'));
        expect(banner.description, equals('Description'));
      });
    });

    group('CategoryInfo', () {
      test('should create with required fields', () {
        // Arrange & Act
        final category = CategoryInfo(
          code: 'cat-1',
          name: 'Category 1',
          icon: 'icon-url',
          appCount: 10,
        );

        // Assert
        expect(category.code, equals('cat-1'));
        expect(category.name, equals('Category 1'));
        expect(category.icon, equals('icon-url'));
        expect(category.appCount, equals(10));
      });
    });

    group('RecommendAppInfo', () {
      test('should create with required fields', () {
        // Arrange & Act
        final app = RecommendAppInfo(
          appId: 'com.example.app',
          name: 'Test App',
          version: '1.0.0',
          description: 'Description',
          icon: 'icon-url',
          developer: 'Developer',
          category: 'Category',
          size: '10 MB',
          downloadCount: 1000,
        );

        // Assert
        expect(app.appId, equals('com.example.app'));
        expect(app.name, equals('Test App'));
        expect(app.version, equals('1.0.0'));
        expect(app.isInstalled, isFalse);
        expect(app.hasUpdate, isFalse);
      });
    });

    group('PaginatedResponse', () {
      test('should create with correct hasMore calculation', () {
        // Arrange & Act
        const response = PaginatedResponse<RecommendAppInfo>(
          items: [],
          total: 100,
          page: 1,
          pageSize: 20,
          hasMore: true,
        );

        // Assert
        expect(response.total, equals(100));
        expect(response.page, equals(1));
        expect(response.pageSize, equals(20));
        expect(response.hasMore, isTrue);
      });
    });
  });
}