import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/pages/all_apps/all_apps_page.dart';

import '../../../mocks/mock_classes.mocks.dart';

/// 构建分类列表响应
HttpResponse<CategoryListResponse> _buildCategoryResponse(
  List<CategoryDTO> categories,
) {
  return HttpResponse(
    CategoryListResponse(code: 200, data: categories),
    Response(requestOptions: RequestOptions(path: '/visit/getDisCategoryList')),
  );
}

/// 构建搜索结果响应，支持按 categoryId 返回不同数据
HttpResponse<AppListResponse> _buildSearchResponse(
  List<AppListItemDTO> items, {
  int pageSize = 30,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: items,
        total: items.length,
        size: pageSize,
        current: 1,
        pages: 1,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}

/// 使用独立路由包装测试 app，避免 GoRouter 找不到路由报错
Widget _buildTestApp(MockAppApiService mockApiService) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: AllAppsPage()),
      ),
      GoRoute(
        path: '/app/:appId',
        builder: (_, __) => const Scaffold(body: Text('Detail')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      appApiServiceProvider.overrideWithValue(mockApiService),
      // 提供空的应用状态索引，避免依赖 ll-cli 实际安装数据
      applicationCardStateIndexProvider.overrideWithValue(
        const ApplicationCardStateIndex(
          installedVersionByAppId: {},
          updateAppIds: {},
          activeTasksByAppId: {},
        ),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
    ),
  );
}

void main() {
  group('AllAppsPage category chip interaction', () {
    testWidgets(
      'tapping a category chip shows that category app list instead of empty state',
      (tester) async {
        final mockApiService = MockAppApiService();

        // 设置分类列表
        when(mockApiService.getDisCategoryList()).thenAnswer(
          (_) async => _buildCategoryResponse(const [
            CategoryDTO(categoryId: '07', categoryName: '效率办公'),
            CategoryDTO(categoryId: '08', categoryName: '系统工具'),
          ]),
        );

        // 相同接口，按 categoryId 返回不同应用
        when(mockApiService.getSearchAppList(any)).thenAnswer((
          invocation,
        ) async {
          final request =
              invocation.positionalArguments.single as SearchAppListRequest;
          if (request.categoryId == '07') {
            return _buildSearchResponse(const [
              AppListItemDTO(
                appId: 'office.app',
                appName: 'Office App',
                appVersion: '1.0.0',
              ),
            ]);
          }
          // 全部应用（categoryId 为 null）
          return _buildSearchResponse(const [
            AppListItemDTO(
              appId: 'all.app',
              appName: 'All App',
              appVersion: '1.0.0',
            ),
          ]);
        });

        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildTestApp(mockApiService));
        // 等待初始加载完成（多次 pump 确保异步框架处理完毕）
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // 初始状态：应该显示"全部"分类的应用
        expect(find.text('All App'), findsOneWidget);

        // 点击"效率办公"分类胶囊
        await tester.tap(find.text('效率办公'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        // 切换分类后：应显示效率办公分类的应用，不再是"暂无应用"
        expect(find.text('Office App'), findsOneWidget);
        expect(find.text('暂无应用'), findsNothing);
      },
    );

    testWidgets('initial load uses getSearchAppList not getWelcomeAppList', (
      tester,
    ) async {
      final mockApiService = MockAppApiService();

      when(mockApiService.getDisCategoryList()).thenAnswer(
        (_) async => _buildCategoryResponse(const [
          CategoryDTO(categoryId: '07', categoryName: '效率办公'),
        ]),
      );
      when(mockApiService.getSearchAppList(any)).thenAnswer(
        (_) async => _buildSearchResponse(const [
          AppListItemDTO(
            appId: 'test.app',
            appName: 'Test App',
            appVersion: '1.0.0',
          ),
        ]),
      );

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(mockApiService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // 验证使用了正确的 API
      verify(mockApiService.getSearchAppList(any)).called(greaterThan(0));
      verifyNever(mockApiService.getWelcomeAppList(any));
      verifyNever(mockApiService.getSidebarApps(any));
    });
  });
}
