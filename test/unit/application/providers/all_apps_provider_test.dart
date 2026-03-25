import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/all_apps_provider.dart';
import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../mocks/mock_classes.mocks.dart';

/// 构建分类列表响应的辅助函数
HttpResponse<CategoryListResponse> _buildCategoryResponse([
  List<CategoryDTO> categories = const [
    CategoryDTO(categoryId: '07', categoryName: '效率办公'),
    CategoryDTO(categoryId: '08', categoryName: '系统工具'),
  ],
]) {
  return HttpResponse(
    CategoryListResponse(code: 200, data: categories),
    Response(requestOptions: RequestOptions(path: '/visit/getDisCategoryList')),
  );
}

/// 构建搜索结果响应的辅助函数
HttpResponse<AppListResponse> _buildSearchResponse(
  List<AppListItemDTO> items, {
  int currentPage = 1,
  int pageSize = 30,
  int total = 0,
  int pages = 1,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: items,
        total: total.isFinite ? total : items.length,
        size: pageSize,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}

/// 等待所有微任务和异步工作完成
Future<void> _flushAsyncWork() async {
  await Future.microtask(() {});
  await Future.delayed(Duration.zero);
  await Future.microtask(() {});
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('AllAppsProvider', () {
    group('AllAppsState', () {
      test('should have correct default values', () {
        const state = AllAppsState();

        expect(state.isLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNull);
        expect(state.data, isNull);
        expect(state.selectedCategoryIndex, equals(0));
        expect(state.currentPage, equals(1));
      });

      test('should support copyWith', () {
        const state = AllAppsState();

        final newState = state.copyWith(
          isLoading: true,
          error: 'Test error',
          selectedCategoryIndex: 2,
        );

        expect(newState.isLoading, isTrue);
        expect(newState.error, equals('Test error'));
        expect(newState.selectedCategoryIndex, equals(2));
      });
    });

    group('AllAppsData', () {
      test('should create with required fields', () {
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

        expect(data.categories.length, equals(1));
        expect(data.apps.items, isEmpty);
      });

      test('should support copyWith', () {
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

        final newData = data.copyWith(
          categories: [
            const CategoryInfo(code: 'all', name: '全部'),
            const CategoryInfo(code: 'cat-1', name: 'Category 1'),
          ],
        );

        expect(newData.categories.length, equals(2));
        expect(newData.apps.items, isEmpty);
      });
    });

    // ------------------------------------------------------------------ //
    // 行为级测试：验证 provider 使用了正确的 API 路径
    // ------------------------------------------------------------------ //
    group('API call behavior', () {
      late MockAppApiService mockApiService;
      late ProviderContainer container;

      setUp(() {
        mockApiService = MockAppApiService();
        when(
          mockApiService.getDisCategoryList(),
        ).thenAnswer((_) async => _buildCategoryResponse());
        when(mockApiService.getSearchAppList(any)).thenAnswer(
          (_) async => _buildSearchResponse(const [
            AppListItemDTO(
              appId: 'all.app',
              appName: 'All App',
              appVersion: '1.0.0',
            ),
          ]),
        );
        container = ProviderContainer(
          overrides: [appApiServiceProvider.overrideWithValue(mockApiService)],
        );
      });

      tearDown(() => container.dispose());

      test(
        'loads all apps via getSearchAppList instead of welcome/sidebar endpoints',
        () async {
          // 订阅以触发初始加载
          container.listen(allAppsProvider, (_, __) {});
          await _flushAsyncWork();

          // 必须调用 getSearchAppList
          verify(mockApiService.getSearchAppList(any)).called(greaterThan(0));
          // 不应调用 getWelcomeAppList 或 getSidebarApps
          verifyNever(mockApiService.getWelcomeAppList(any));
          verifyNever(mockApiService.getSidebarApps(any));
        },
      );

      test(
        'selectCategory sends real categoryId and uses rust page size 30',
        () async {
          container.listen(allAppsProvider, (_, __) {});
          await _flushAsyncWork();

          // 重置计数，只跟踪切换分类后的调用
          clearInteractions(mockApiService);
          when(
            mockApiService.getDisCategoryList(),
          ).thenAnswer((_) async => _buildCategoryResponse());
          when(mockApiService.getSearchAppList(any)).thenAnswer(
            (_) async => _buildSearchResponse(const [
              AppListItemDTO(
                appId: 'office.app',
                appName: 'Office App',
                appVersion: '1.0.0',
              ),
            ]),
          );

          // 切换到第 1 个分类（index=1，对应 categoryId='07'）
          container.read(allAppsProvider.notifier).selectCategory(1);
          await _flushAsyncWork();

          final captured = verify(
            mockApiService.getSearchAppList(captureAny),
          ).captured.cast<SearchAppListRequest>();
          // 最后一次请求必须携带真实 categoryId
          expect(captured.last.categoryId, equals('07'));
          expect(captured.last.pageSize, equals(30));
        },
      );

      test(
        'loadMore preserves current categoryId and uses pageSize 30',
        () async {
          // 先加载第一页（有更多页）
          when(mockApiService.getSearchAppList(any)).thenAnswer(
            (_) async => _buildSearchResponse(
              const [
                AppListItemDTO(
                  appId: 'office.app',
                  appName: 'Office App',
                  appVersion: '1.0.0',
                ),
              ],
              total: 60,
              pages: 2,
            ),
          );

          container.listen(allAppsProvider, (_, __) {});
          await _flushAsyncWork();

          // 切换分类
          clearInteractions(mockApiService);
          when(
            mockApiService.getDisCategoryList(),
          ).thenAnswer((_) async => _buildCategoryResponse());
          when(mockApiService.getSearchAppList(any)).thenAnswer(
            (_) async => _buildSearchResponse(
              const [
                AppListItemDTO(
                  appId: 'office.app',
                  appName: 'Office App',
                  appVersion: '1.0.0',
                ),
              ],
              total: 60,
              pages: 2,
            ),
          );

          container.read(allAppsProvider.notifier).selectCategory(1);
          await _flushAsyncWork();
          clearInteractions(mockApiService);

          // 加载更多
          when(mockApiService.getSearchAppList(any)).thenAnswer(
            (_) async => _buildSearchResponse(const [
              AppListItemDTO(
                appId: 'office2.app',
                appName: 'Office App 2',
                appVersion: '1.0.0',
              ),
            ], currentPage: 2),
          );

          container.read(allAppsProvider.notifier).loadMore();
          await _flushAsyncWork();

          final captured = verify(
            mockApiService.getSearchAppList(captureAny),
          ).captured.cast<SearchAppListRequest>();
          // loadMore 必须保留当前 categoryId 并继续使用 pageSize=30
          expect(captured.last.categoryId, equals('07'));
          expect(captured.last.pageSize, equals(30));
          expect(captured.last.pageNo, equals(2));
        },
      );
    });
  });
}
