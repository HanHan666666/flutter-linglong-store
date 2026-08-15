import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/ranking_provider.dart';
import 'package:linglong_store/domain/models/ranking_models.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('RankingProvider', () {
    group('RankingType', () {
      test('should have correct enum values', () {
        // Assert
        expect(RankingType.values.length, equals(2));
        expect(RankingType.download.code, equals('download'));
        expect(RankingType.rising.code, equals('rising'));
      });
    });

    group('RankingState', () {
      test('should have correct default values', () {
        // Arrange & Act
        const state = RankingState();

        // Assert
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.data, isNull);
        expect(state.selectedType, equals(RankingType.rising)); // 默认进入最新上架榜
      });

      test('should support copyWith', () {
        // Arrange
        const state = RankingState();

        // Act
        final newState = state.copyWith(
          isLoading: true,
          error: 'Test error',
          selectedType: RankingType.rising,
        );

        // Assert
        expect(newState.isLoading, isTrue);
        expect(newState.error, equals('Test error'));
        expect(newState.selectedType, equals(RankingType.rising));
      });

      test('should preserve data when copyWith does not override it', () {
        // Arrange
        final apps = [
          const RankingAppInfo(
            appId: 'com.app1',
            name: 'App 1',
            version: '1.0.0',
            rank: 1,
          ),
        ];
        final data = RankingData(type: RankingType.download, apps: apps);
        final state = RankingState(
          data: data,
          selectedType: RankingType.download,
        );

        // Act - 只修改 selectedType，保留 data
        final newState = state.copyWith(selectedType: RankingType.rising);

        // Assert - data 应该被保留
        expect(newState.data, equals(data));
        expect(newState.selectedType, equals(RankingType.rising));
      });
    });

    group('RankingData', () {
      test('should create with required fields', () {
        // Arrange
        const data = RankingData(
          type: RankingType.download,
          apps: [
            RankingAppInfo(
              appId: 'com.example.app',
              name: 'Test App',
              version: '1.0.0',
              rank: 1,
            ),
          ],
        );

        // Assert
        expect(data.type, equals(RankingType.download));
        expect(data.apps.length, equals(1));
        expect(data.apps[0].rank, equals(1));
      });

      test('should support copyWith', () {
        // Arrange
        const data = RankingData(type: RankingType.download, apps: []);

        // Act
        final newData = data.copyWith(type: RankingType.rising);

        // Assert
        expect(newData.type, equals(RankingType.rising));
        expect(newData.apps, isEmpty);
      });
    });

    group('RankingAppInfo', () {
      test('should create with required fields', () {
        // Arrange & Act
        const app = RankingAppInfo(
          appId: 'com.example.app',
          name: 'Test App',
          version: '1.0.0',
          description: 'Description',
          icon: 'icon-url',
          developer: 'Developer',
          category: 'Category',
          size: '10 MB',
          downloadCount: 1000,
          rank: 5,
        );

        // Assert
        expect(app.appId, equals('com.example.app'));
        expect(app.name, equals('Test App'));
        expect(app.version, equals('1.0.0'));
        expect(app.rank, equals(5));
        expect(app.downloadCount, equals(1000));
        expect(app.isInstalled, isFalse);
        expect(app.hasUpdate, isFalse);
      });

      test('should track ranking position', () {
        // Arrange & Act
        final apps = List.generate(
          10,
          (i) => RankingAppInfo(
            appId: 'com.example.app$i',
            name: 'App $i',
            version: '1.0.0',
            rank: i + 1,
          ),
        );

        // Assert
        for (int i = 0; i < 10; i++) {
          expect(apps[i].rank, equals(i + 1));
        }
      });
    });

    group('RankingState with data', () {
      test('should hold complete ranking data', () {
        // Arrange
        final apps = [
          const RankingAppInfo(
            appId: 'com.app1',
            name: 'App 1',
            version: '1.0.0',
            rank: 1,
            downloadCount: 10000,
          ),
          const RankingAppInfo(
            appId: 'com.app2',
            name: 'App 2',
            version: '1.0.0',
            rank: 2,
            downloadCount: 8000,
          ),
        ];
        final data = RankingData(type: RankingType.download, apps: apps);
        final state = RankingState(data: data);

        // Assert
        expect(state.data, isNotNull);
        expect(state.data!.apps.length, equals(2));
        expect(state.data!.type, equals(RankingType.download));
      });
    });

    group('API behavior', () {
      late MockAppApiService mockApiService;

      setUp(() {
        mockApiService = MockAppApiService();
      });

      test('passes current arch to rising and download ranking requests', () async {
        when(mockApiService.getNewAppList(any)).thenAnswer((invocation) async {
          final request = invocation.positionalArguments.single as PageParams;
          return _buildRankingResponse(
            [
              AppListItemDTO.fromJson({
                'appId': 'new.app',
                'zhName': 'New App',
                'version': '1.0.0',
                'arch': 'aarch64',
              }),
            ],
            path: '/visit/getNewAppList',
            currentPage: request.pageNo,
            pageSize: request.pageSize,
          );
        });
        when(mockApiService.getInstallAppList(any)).thenAnswer((invocation) async {
          final request = invocation.positionalArguments.single as PageParams;
          return _buildRankingResponse(
            [
              AppListItemDTO.fromJson({
                'appId': 'download.app',
                'zhName': 'Download App',
                'version': '2.0.0',
                'arch': 'aarch64',
              }),
            ],
            path: '/visit/getInstallAppList',
            currentPage: request.pageNo,
            pageSize: request.pageSize,
          );
        });

        final container = ProviderContainer(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
            globalAppProvider.overrideWith(
              () => _TestGlobalApp(const GlobalAppState(arch: 'aarch64')),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.listen<RankingState>(rankingProvider, (_, _) {});
        await _flushAsyncWork();

        final risingCaptured = verify(mockApiService.getNewAppList(captureAny))
            .captured
            .single as PageParams;
        expect(risingCaptured.arch, equals('aarch64'));

        await container
            .read(rankingProvider.notifier)
            .selectType(RankingType.download);
        await _flushAsyncWork();

        final downloadCaptured =
            verify(mockApiService.getInstallAppList(captureAny))
                .captured
                .single as PageParams;
        final state = container.read(rankingProvider);

        expect(downloadCaptured.arch, equals('aarch64'));
        expect(
          state.data?.apps.single.toInstalledApp().arch,
          equals('aarch64'),
        );
      });
    });

    group('pagination', () {
      late MockAppApiService mockApiService;

      setUp(() {
        mockApiService = MockAppApiService();
      });

      AppListItemDTO dtoOf(String appId, String name) =>
          AppListItemDTO.fromJson({
            'appId': appId,
            'zhName': name,
            'version': '1.0.0',
          });

      test('首页 30 条，触底加载合并且名次跨页连续，无更多后停止请求', () async {
        final page1 =
            List.generate(30, (i) => dtoOf('app.$i', 'App $i'));
        final page2 =
            List.generate(10, (i) => dtoOf('more.$i', 'More $i'));
        // mockito 的 verify 会消费调用记录，这里在应答内自行记录请求参数
        final sentRequests = <PageParams>[];

        when(mockApiService.getNewAppList(any)).thenAnswer((invocation) async {
          final request = invocation.positionalArguments.single as PageParams;
          sentRequests.add(request);
          return _buildRankingResponse(
            request.pageNo == 2 ? page2 : page1,
            path: '/visit/getNewAppList',
            currentPage: request.pageNo,
            pageSize: request.pageSize,
            pages: 2,
          );
        });

        final container = ProviderContainer(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );
        addTearDown(container.dispose);
        container.listen<RankingState>(rankingProvider, (_, _) {});
        await _flushAsyncWork();

        // 首页请求应使用 30 条分页
        expect(sentRequests.single.pageSize, 30);
        expect(sentRequests.single.pageNo, 1);

        var state = container.read(rankingProvider);
        expect(state.data!.apps.length, 30);
        expect(state.hasMore, isTrue);
        expect(state.data!.apps.first.rank, 1);
        expect(state.data!.apps.last.rank, 30);

        await container.read(rankingProvider.notifier).loadMore();
        await _flushAsyncWork();

        state = container.read(rankingProvider);
        expect(state.data!.apps.length, 40);
        // 第二页从已加载条数继续编号
        expect(state.data!.apps[30].rank, 31);
        // 第 2 页为最后一页（current=2, pages=2）
        expect(state.hasMore, isFalse);

        // hasMore=false 后 loadMore 不再发起新请求
        await container.read(rankingProvider.notifier).loadMore();
        expect(sentRequests.length, 2);
      });

      test('无更多数据时 loadMore 直接短路，不再发请求', () async {
        final sentRequests = <PageParams>[];
        when(mockApiService.getNewAppList(any)).thenAnswer((invocation) async {
          final request = invocation.positionalArguments.single as PageParams;
          sentRequests.add(request);
          return _buildRankingResponse(
            const [],
            path: '/visit/getNewAppList',
            currentPage: request.pageNo,
            pageSize: request.pageSize,
            pages: 1,
          );
        });

        final container = ProviderContainer(
          overrides: [
            appApiServiceProvider.overrideWithValue(mockApiService),
          ],
        );
        addTearDown(container.dispose);
        container.listen<RankingState>(rankingProvider, (_, _) {});
        await _flushAsyncWork();

        // 空榜单：无数据且 hasMore=false
        expect(container.read(rankingProvider).hasMore, isFalse);
        expect(sentRequests.length, 1);

        // loadMore 应直接短路，不产生第二个请求
        await container.read(rankingProvider.notifier).loadMore();
        expect(sentRequests.length, 1);
      });
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

HttpResponse<AppListResponse> _buildRankingResponse(
  List<AppListItemDTO> records, {
  required String path,
  required int currentPage,
  required int pageSize,
  int pages = 1,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: records.length,
        size: pageSize,
        current: currentPage,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: path)),
  );
}

class _TestGlobalApp extends GlobalApp {
  _TestGlobalApp(this._initialState);

  final GlobalAppState _initialState;

  @override
  GlobalAppState build() => _initialState;
}
