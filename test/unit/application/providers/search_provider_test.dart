import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/search_provider.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('SearchProvider', () {
    group('SearchState', () {
      test('should have correct default values', () {
        // Arrange & Act
        const state = SearchState(query: '', results: []);

        // Assert
        expect(state.query, isEmpty);
        expect(state.results, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNull);
        expect(state.currentPage, equals(1));
        expect(state.hasMore, isTrue);
        expect(state.total, equals(0));
      });

      test('should support copyWith', () {
        // Arrange
        const state = SearchState(query: '', results: []);

        // Act
        final newState = state.copyWith(
          query: 'test query',
          isLoading: true,
          total: 10,
        );

        // Assert
        expect(newState.query, equals('test query'));
        expect(newState.isLoading, isTrue);
        expect(newState.total, equals(10));
        expect(newState.results, isEmpty);
      });

      test('should handle search results', () {
        // Arrange
        final results = [
          RecommendAppInfo(
            appId: 'com.example.app1',
            name: 'App 1',
            version: '1.0.0',
          ),
          RecommendAppInfo(
            appId: 'com.example.app2',
            name: 'App 2',
            version: '2.0.0',
          ),
        ];

        // Act
        final state = SearchState(
          query: 'test',
          results: results,
          total: 2,
          hasMore: false,
        );

        // Assert
        expect(state.query, equals('test'));
        expect(state.results.length, equals(2));
        expect(state.total, equals(2));
        expect(state.hasMore, isFalse);
      });

      test('should track pagination state', () {
        // Arrange
        const state = SearchState(
          query: 'test',
          results: [],
          currentPage: 2,
          hasMore: true,
          total: 50,
        );

        // Assert
        expect(state.currentPage, equals(2));
        expect(state.hasMore, isTrue);
        expect(state.total, equals(50));
      });

      test('should track loading states independently', () {
        // Arrange
        const stateLoading = SearchState(
          query: 'test',
          results: [],
          isLoading: true,
        );
        const stateLoadingMore = SearchState(
          query: 'test',
          results: [],
          isLoadingMore: true,
        );

        // Assert
        expect(stateLoading.isLoading, isTrue);
        expect(stateLoading.isLoadingMore, isFalse);
        expect(stateLoadingMore.isLoading, isFalse);
        expect(stateLoadingMore.isLoadingMore, isTrue);
      });

      test('should handle error state', () {
        // Arrange & Act
        const state = SearchState(
          query: 'test',
          results: [],
          error: 'Network error',
        );

        // Assert
        expect(state.error, equals('Network error'));
        expect(state.isLoading, isFalse);
      });
    });
  });
}