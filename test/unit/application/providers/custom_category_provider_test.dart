import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/custom_category_provider.dart';
import 'package:linglong_store/application/providers/sidebar_config_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/data/models/api_dto.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('CustomCategoryProvider', () {
    late MockAppApiService mockApiService;
    late String Function()? previousLocaleGetter;

    setUp(() {
      mockApiService = MockAppApiService();
      previousLocaleGetter = ApiClient.getLocale;
      ApiClient.getLocale = () => 'en';
    });

    tearDown(() {
      ApiClient.getLocale = previousLocaleGetter;
    });

    test('isolates category state by code and uses api total as app count', () async {
      when(mockApiService.getSidebarApps(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as SidebarAppsRequest;

        if (request.menuCode == 'office') {
          return _buildSidebarAppsResponse(
            const [
              AppListItemDTO(
                appId: 'office.app',
                appName: 'Office App',
                appVersion: '1.0.0',
              ),
            ],
            currentPage: 1,
            pageSize: request.pageSize,
            total: 101,
            pages: 4,
          );
        }

        return _buildSidebarAppsResponse(
          const [
            AppListItemDTO(
              appId: 'system.app',
              appName: 'System App',
              appVersion: '2.0.0',
            ),
          ],
          currentPage: 1,
          pageSize: request.pageSize,
          total: 202,
          pages: 7,
        );
      });

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          sidebarConfigProvider.overrideWith(
            (ref) async => const [
              SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
              SidebarMenuDTO(menuCode: 'system', menuName: '系统'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen<CustomCategoryState>(
        customCategoryProvider('office'),
        (_, __) {},
      );
      container.listen<CustomCategoryState>(
        customCategoryProvider('system'),
        (_, __) {},
      );

      await _flushAsyncWork();

      final officeState = container.read(customCategoryProvider('office'));
      final systemState = container.read(customCategoryProvider('system'));

      expect(officeState.data?.categoryInfo.name, equals('Office'));
      expect(officeState.data?.categoryInfo.appCount, equals(101));
      expect(officeState.data?.apps.items.single.appId, equals('office.app'));

      expect(systemState.data?.categoryInfo.name, equals('System'));
      expect(systemState.data?.categoryInfo.appCount, equals(202));
      expect(systemState.data?.apps.items.single.appId, equals('system.app'));
    });

    test('uses rust parity page size 30 for initial load and load more', () async {
      when(mockApiService.getSidebarApps(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as SidebarAppsRequest;

        if (request.pageNo == 1) {
          return _buildSidebarAppsResponse(
            const [
              AppListItemDTO(
                appId: 'office.app.one',
                appName: 'Office App One',
                appVersion: '1.0.0',
              ),
            ],
            currentPage: 1,
            pageSize: request.pageSize,
            total: 2,
            pages: 2,
          );
        }

        return _buildSidebarAppsResponse(
          const [
            AppListItemDTO(
              appId: 'office.app.two',
              appName: 'Office App Two',
              appVersion: '2.0.0',
            ),
          ],
          currentPage: 2,
          pageSize: request.pageSize,
          total: 2,
          pages: 2,
        );
      });

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          sidebarConfigProvider.overrideWith(
            (ref) async => const [
              SidebarMenuDTO(menuCode: 'office', menuName: '办公'),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      container.listen<CustomCategoryState>(
        customCategoryProvider('office'),
        (_, __) {},
      );
      await _flushAsyncWork();

      await container.read(customCategoryProvider('office').notifier).loadMore();

      final state = container.read(customCategoryProvider('office'));
      expect(state.data?.apps.items, hasLength(2));

      final captured =
          verify(mockApiService.getSidebarApps(captureAny)).captured
              .cast<SidebarAppsRequest>();
      expect(captured[0].pageSize, equals(30));
      expect(captured[1].pageNo, equals(2));
      expect(captured[1].pageSize, equals(30));
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

HttpResponse<AppListResponse> _buildSidebarAppsResponse(
  List<AppListItemDTO> records, {
  required int currentPage,
  required int pageSize,
  required int total,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: total,
        size: pageSize,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/app/sidebar/apps')),
  );
}
