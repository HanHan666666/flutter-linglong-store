import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:linglong_store/data/repositories/app_repository_impl.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/core/network/api_exceptions.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  late AppRepositoryImpl repository;
  late MockAppApiService mockApiService;

  setUpAll(() async {
    // 初始化日志
    await AppLogger.init();
  });

  setUp(() {
    mockApiService = MockAppApiService();
    repository = AppRepositoryImpl.withService(mockApiService);
  });

  group('AppRepositoryImpl', () {
    group('getRecommendApps', () {
      test('should return list of InstalledApp on success', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [
                AppListItemDTO(
                  appId: 'com.example.app1',
                  appName: 'App 1',
                  appVersion: '1.0.0',
                  appIcon: 'https://example.com/icon1.png',
                  appDesc: 'Description 1',
                ),
                AppListItemDTO(
                  appId: 'com.example.app2',
                  appName: 'App 2',
                  appVersion: '2.0.0',
                  appIcon: 'https://example.com/icon2.png',
                  appDesc: 'Description 2',
                ),
              ],
              total: 2,
              size: 20,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getWelcomeAppList'),
          ),
        );

        when(
          mockApiService.getWelcomeAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRecommendApps();

        // Assert
        expect(result.length, equals(2));
        expect(result[0].appId, equals('com.example.app1'));
        expect(result[0].name, equals('App 1'));
        expect(result[1].appId, equals('com.example.app2'));
        verify(mockApiService.getWelcomeAppList(any)).called(1);
      });

      test('should return empty list when data is null', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(code: 200, data: null),
          Response(
            requestOptions: RequestOptions(path: '/visit/getWelcomeAppList'),
          ),
        );

        when(
          mockApiService.getWelcomeAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRecommendApps();

        // Assert
        expect(result, isEmpty);
      });

      test('should rethrow exception on failure', () async {
        // Arrange
        when(mockApiService.getWelcomeAppList(any)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/visit/getWelcomeAppList'),
            error: const NetworkException('Network error'),
          ),
        );

        // Act & Assert
        expect(
          () => repository.getRecommendApps(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getAllApps', () {
      test('should return list of InstalledApp on success', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [
                AppListItemDTO(
                  appId: 'com.example.app1',
                  appName: 'App 1',
                  appVersion: '1.0.0',
                ),
              ],
              total: 1,
              size: 20,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
          ),
        );

        when(
          mockApiService.getSearchAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getAllApps();

        // Assert
        expect(result.length, equals(1));
        expect(result[0].appId, equals('com.example.app1'));
        verify(mockApiService.getSearchAppList(any)).called(1);
      });

      test('should pass correct pagination parameters', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [],
              total: 0,
              size: 20,
              current: 2,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
          ),
        );

        when(
          mockApiService.getSearchAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getAllApps(page: 2, pageSize: 50);

        // Assert
        final captured =
            verify(mockApiService.getSearchAppList(captureAny)).captured.single
                as SearchAppListRequest;
        expect(captured.pageNo, equals(2));
        expect(captured.pageSize, equals(50));
      });
    });

    group('searchApps', () {
      test('should return matching apps for keyword', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [
                AppListItemDTO(
                  appId: 'com.example.search',
                  appName: 'Search App',
                  appVersion: '1.0.0',
                ),
              ],
              total: 1,
              size: 20,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
          ),
        );

        when(
          mockApiService.getSearchAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.searchApps('search');

        // Assert
        expect(result.length, equals(1));
        expect(result[0].name, equals('Search App'));
      });

      test('should pass keyword in request', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [],
              total: 0,
              size: 20,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getSearchAppList'),
          ),
        );

        when(
          mockApiService.getSearchAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await repository.searchApps('test keyword');

        // Assert
        final captured =
            verify(mockApiService.getSearchAppList(captureAny)).captured.single
                as SearchAppListRequest;
        expect(captured.keyword, equals('test keyword'));
      });
    });

    group('getAppDetail', () {
      test('should return app detail on success', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppDetailResponse(
            code: 200,
            data: {
              'com.example.app': [
                {
                  'appId': 'com.example.app',
                  'zhName': 'Test App',
                  'version': '1.0.0',
                  'icon': 'https://example.com/icon.png',
                  'description': 'Test description',
                  'appScreenshotList': [
                    {'screenshotKey': 'https://example.com/screenshot.png'},
                  ],
                },
              ],
            },
          ),
          Response(requestOptions: RequestOptions(path: '/app/getAppDetail')),
        );

        when(
          mockApiService.getAppDetail(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getAppDetail('com.example.app');

        // Assert
        expect(result.appId, equals('com.example.app'));
        expect(result.appName, equals('Test App'));
        expect(result.screenshotList?.length, equals(1));
      });

      test('should throw exception when app not found', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppDetailResponse(code: 200, data: null),
          Response(requestOptions: RequestOptions(path: '/app/getAppDetail')),
        );

        when(
          mockApiService.getAppDetail(any),
        ).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.getAppDetail('nonexistent'),
          throwsA(isA<Exception>()),
        );
      });

      test('should use custom arch when provided', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppDetailResponse(
            code: 200,
            data: {
              'com.example.app': [
                {
                  'appId': 'com.example.app',
                  'zhName': 'Test App',
                  'version': '1.0.0',
                },
              ],
            },
          ),
          Response(requestOptions: RequestOptions(path: '/app/getAppDetail')),
        );

        when(
          mockApiService.getAppDetail(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getAppDetail('com.example.app', arch: 'aarch64');

        // Assert
        final captured =
            verify(mockApiService.getAppDetail(captureAny)).captured.single
                as List<AppDetailSearchBO>;
        expect(captured.single.arch, equals('aarch64'));
      });
    });

    group('getVersions', () {
      test('should return list of versions', () async {
        // Arrange
        final mockResponse = HttpResponse(
          VersionListResponse(
            code: 200,
            data: [
              AppVersionDTO(
                versionId: 'v1',
                versionNo: '1.0.0',
                description: 'Initial release',
              ),
              AppVersionDTO(
                versionId: 'v2',
                versionNo: '2.0.0',
                description: 'Major update',
              ),
            ],
          ),
          Response(
            requestOptions: RequestOptions(
              path: '/visit/getSearchAppVersionList',
            ),
          ),
        );

        when(
          mockApiService.getSearchAppVersionList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getVersions('com.example.app');

        // Assert
        expect(result.length, equals(2));
        expect(result[0].versionNo, equals('1.0.0'));
        expect(result[1].versionNo, equals('2.0.0'));
      });

      test('should return empty list when no versions', () async {
        // Arrange
        final mockResponse = HttpResponse(
          VersionListResponse(code: 200, data: const []),
          Response(
            requestOptions: RequestOptions(
              path: '/visit/getSearchAppVersionList',
            ),
          ),
        );

        when(
          mockApiService.getSearchAppVersionList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getVersions('com.example.app');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('enrichInstalledAppsWithDetails', () {
      test('should merge icon and description from array response', () async {
        final apps = [
          repository.mapDetailToInstalledApp(
            const AppDetailDTO(
              appId: 'com.example.app',
              appName: 'Example',
              appVersion: '1.0.0',
            ),
          ),
        ];

        final mockResponse = HttpResponse(
          AppListArrayResponse(
            code: 200,
            data: const [
              AppListItemDTO(
                appId: 'com.example.app',
                appName: '示例应用',
                appIcon: 'https://example.com/icon.png',
                appDesc: '示例描述',
              ),
            ],
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getAppDetails'),
          ),
        );

        when(
          mockApiService.getAppDetails(any),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.enrichInstalledAppsWithDetails(apps);

        expect(result.single.name, equals('示例应用'));
        expect(result.single.icon, equals('https://example.com/icon.png'));
        expect(result.single.description, equals('示例描述'));
      });
    });

    group('getRanking', () {
      test('should return new apps for type=new', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [
                AppListItemDTO(
                  appId: 'com.new.app',
                  appName: 'New App',
                  appVersion: '1.0.0',
                ),
              ],
              total: 1,
              size: 100,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getNewAppList'),
          ),
        );

        when(
          mockApiService.getNewAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRanking(type: 'new');

        // Assert
        expect(result.length, equals(1));
        verify(mockApiService.getNewAppList(any)).called(1);
        verifyNever(mockApiService.getInstallAppList(any));
      });

      test('should return install apps for type=download', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [
                AppListItemDTO(
                  appId: 'com.popular.app',
                  appName: 'Popular App',
                  appVersion: '1.0.0',
                ),
              ],
              total: 1,
              size: 100,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getInstallAppList'),
          ),
        );

        when(
          mockApiService.getInstallAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getRanking(type: 'download');

        // Assert
        expect(result.length, equals(1));
        verify(mockApiService.getInstallAppList(any)).called(1);
        verifyNever(mockApiService.getNewAppList(any));
      });

      test('should use limit parameter correctly', () async {
        // Arrange
        final mockResponse = HttpResponse(
          AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [],
              total: 0,
              size: 50,
              current: 1,
              pages: 1,
            ),
          ),
          Response(
            requestOptions: RequestOptions(path: '/visit/getNewAppList'),
          ),
        );

        when(
          mockApiService.getNewAppList(any),
        ).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getRanking(limit: 50);

        // Assert
        final captured =
            verify(mockApiService.getNewAppList(captureAny)).captured.single
                as PageParams;
        expect(captured.pageSize, equals(50));
      });
    });

    group('mapDetailToInstalledApp', () {
      test('should correctly map AppDetailDTO to InstalledApp', () {
        // Arrange
        final dto = AppDetailDTO(
          appId: 'com.example.app',
          appName: 'Test App',
          appVersion: '1.0.0',
          appIcon: 'https://example.com/icon.png',
          appDesc: 'Description',
          arch: 'x86_64',
          channel: 'stable',
          appKind: 'app',
          appModule: 'main',
          appRuntime: 'runtime',
          packageSize: '10 MB',
          repoName: 'community',
        );

        // Act
        final result = repository.mapDetailToInstalledApp(dto);

        // Assert
        expect(result.appId, equals('com.example.app'));
        expect(result.name, equals('Test App'));
        expect(result.version, equals('1.0.0'));
        expect(result.icon, equals('https://example.com/icon.png'));
        expect(result.description, equals('Description'));
        expect(result.arch, equals('x86_64'));
        expect(result.channel, equals('stable'));
        expect(result.kind, equals('app'));
        expect(result.module, equals('main'));
        expect(result.runtime, equals('runtime'));
        expect(result.size, equals('10 MB'));
        expect(result.repoName, equals('community'));
      });

      test('should handle null optional fields', () {
        // Arrange
        final dto = AppDetailDTO(
          appId: 'com.example.app',
          appName: 'Test App',
          appVersion: '1.0.0',
        );

        // Act
        final result = repository.mapDetailToInstalledApp(dto);

        // Assert
        expect(result.icon, isNull);
        expect(result.description, isNull);
        expect(result.arch, equals('x86_64')); // Uses default
        expect(result.channel, equals('stable')); // Uses default
      });
    });
  });
}
