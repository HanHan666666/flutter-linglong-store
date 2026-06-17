import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/search_hint_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('SearchHintApps provider', () {
    late MockAppApiService mockApiService;

    setUp(() {
      mockApiService = MockAppApiService();
    });

    test('初始状态返回空列表', () {
      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          globalAppProvider
              .overrideWith(() => _TestGlobalApp(const GlobalAppState())),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(searchHintAppsProvider), isEmpty);
    });

    test('拉取下载量榜前 20 条并映射身份字段', () async {
      // 后端实际返回 25 条，Provider 内部不截断；页面侧约定的“前 20 条”
      // 由请求 pageSize=20 保证，这里构造 3 条验证字段映射即可。
      when(mockApiService.getInstallAppList(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as PageParams;
        return _buildResponse(
          [
            AppListItemDTO.fromJson({
              'appId': 'com.app1',
              'zhName': '应用一',
              'version': '1.0.0',
              'arch': 'x86_64',
              'repoName': 'main',
              'module': 'runtime',
            }),
            // 缺失 arch 的条目应回退为请求架构。
            AppListItemDTO.fromJson({
              'appId': 'com.app2',
              'zhName': '应用二',
              'version': '2.0.0',
              'repoName': 'main',
              'module': 'binary',
            }),
            AppListItemDTO.fromJson({
              'appId': 'com.app3',
              'zhName': '应用三',
              'version': '3.0.0',
              'arch': 'x86_64',
            }),
          ],
          currentPage: request.pageNo,
          pageSize: request.pageSize,
        );
      });

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          globalAppProvider.overrideWith(
            () => _TestGlobalApp(const GlobalAppState(arch: 'x86_64')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 触发 provider 构建与 microtask 加载。
      container.listen(searchHintAppsProvider, (_, __) {});
      await _flushAsyncWork();

      final result = container.read(searchHintAppsProvider);

      // 校验请求参数：固定取前 20 条，并携带当前架构。
      final captured =
          verify(mockApiService.getInstallAppList(captureAny)).captured.single
              as PageParams;
      expect(captured.pageNo, equals(1));
      expect(captured.pageSize, equals(20));
      expect(captured.arch, equals('x86_64'));

      // 校验映射结果。
      expect(result.length, equals(3));
      expect(result[0].appId, equals('com.app1'));
      expect(result[0].name, equals('应用一'));
      expect(result[0].arch, equals('x86_64'));
      expect(result[0].repoName, equals('main'));
      expect(result[0].module, equals('runtime'));

      // arch 缺失回退为请求架构。
      expect(result[1].appId, equals('com.app2'));
      expect(result[1].arch, equals('x86_64'));
      expect(result[1].repoName, equals('main'));
      expect(result[1].module, equals('binary'));

      // repoName/module 缺失回退为空串，保证身份字段可用。
      expect(result[2].appId, equals('com.app3'));
      expect(result[2].repoName, equals(''));
      expect(result[2].module, equals(''));
    });

    test('接口失败时维持空列表且不抛错', () async {
      when(mockApiService.getInstallAppList(any))
          .thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          globalAppProvider
              .overrideWith(() => _TestGlobalApp(const GlobalAppState())),
        ],
      );
      addTearDown(container.dispose);

      container.listen(searchHintAppsProvider, (_, __) {});
      await _flushAsyncWork();

      // 失败属锦上添花功能，应静默回退到空列表。
      expect(container.read(searchHintAppsProvider), isEmpty);
    });

    test('返回空记录时维持空列表', () async {
      when(mockApiService.getInstallAppList(any)).thenAnswer((invocation) async {
        final request = invocation.positionalArguments.single as PageParams;
        return _buildResponse(
          [],
          currentPage: request.pageNo,
          pageSize: request.pageSize,
        );
      });

      final container = ProviderContainer(
        overrides: [
          appApiServiceProvider.overrideWithValue(mockApiService),
          globalAppProvider
              .overrideWith(() => _TestGlobalApp(const GlobalAppState())),
        ],
      );
      addTearDown(container.dispose);

      container.listen(searchHintAppsProvider, (_, __) {});
      await _flushAsyncWork();

      expect(container.read(searchHintAppsProvider), isEmpty);
    });
  });
}

/// 刷新 microtask 与 Future 队列，确保 provider 内的异步加载完成。
Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

HttpResponse<AppListResponse> _buildResponse(
  List<AppListItemDTO> records, {
  required int currentPage,
  required int pageSize,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: records,
        total: records.length,
        size: pageSize,
        current: currentPage,
        pages: 1,
      ),
    ),
    Response(
      requestOptions: RequestOptions(path: '/visit/getInstallAppList'),
    ),
  );
}

class _TestGlobalApp extends GlobalApp {
  _TestGlobalApp(this._initialState);

  final GlobalAppState _initialState;

  @override
  GlobalAppState build() => _initialState;
}
