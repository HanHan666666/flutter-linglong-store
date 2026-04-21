import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/data/repositories/app_repository_impl.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/core/network/api_exceptions.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  late AppRepositoryImpl repository;
  late MockAppApiService mockApiService;
  late String hiveTestPath;

  setUpAll(() async {
    // 初始化日志
    await AppLogger.init();
    final tempDir = await Directory.systemTemp.createTemp(
      'app_repo_cache_test',
    );
    hiveTestPath = tempDir.path;
    Hive.init(hiveTestPath);
    await Hive.openBox('cache');
  });

  setUp(() {
    mockApiService = MockAppApiService();
    repository = AppRepositoryImpl.withService(mockApiService);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('cache')) {
      await Hive.box('cache').clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await Directory(hiveTestPath).delete(recursive: true);
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
                AppListItemDTO.fromJson({
                  'appId': 'com.example.app1',
                  'zhName': 'App 1',
                  'version': '1.0.0',
                  'icon': 'https://example.com/icon1.png',
                  'description': 'Description 1',
                  'arch': 'aarch64',
                }),
                AppListItemDTO.fromJson({
                  'appId': 'com.example.app2',
                  'zhName': 'App 2',
                  'version': '2.0.0',
                  'icon': 'https://example.com/icon2.png',
                  'description': 'Description 2',
                  'arch': 'x86_64',
                }),
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
        expect(result[0].arch, equals('aarch64'));
        expect(result[1].appId, equals('com.example.app2'));
        final captured =
            verify(mockApiService.getWelcomeAppList(captureAny)).captured.single
                as PageParams;
        expect(captured.arch, equals(_expectedCurrentArch()));
      });

      test('should return empty list when data is null', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const AppListResponse(code: 200, data: null),
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
          const AppListResponse(
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
          const AppListResponse(
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
        expect(captured.arch, equals(_expectedCurrentArch()));
        expect(captured.pageNo, equals(2));
        expect(captured.pageSize, equals(50));
      });

      test(
        'passes category to getSearchAppList when requesting filtered all apps',
        () async {
          // Arrange
          final mockResponse = HttpResponse(
            const AppListResponse(
              code: 200,
              data: AppListPagedData(
                records: [],
                total: 0,
                size: 30,
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
          await repository.getAllApps(category: '07', page: 1, pageSize: 30);

          // Assert - categoryId \u5fc5\u987b\u900f\u4f20\u5230\u8bf7\u6c42\u4e2d
          final captured =
              verify(
                    mockApiService.getSearchAppList(captureAny),
                  ).captured.single
                  as SearchAppListRequest;
          expect(captured.arch, equals(_expectedCurrentArch()));
          expect(captured.keyword, equals(''));
          expect(captured.categoryId, equals('07'));
          expect(captured.pageSize, equals(30));
        },
      );

      test('omits categoryId when category is null (full catalog)', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const AppListResponse(
            code: 200,
            data: AppListPagedData(
              records: [],
              total: 0,
              size: 30,
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

        // Act: \u4e0d\u4f20 category \u65f6\uff0c\u5e94\u5c06 categoryId \u7f6e\u4e3a null
        await repository.getAllApps(page: 1, pageSize: 30);

        // Assert
        final captured =
            verify(mockApiService.getSearchAppList(captureAny)).captured.single
                as SearchAppListRequest;
        expect(captured.arch, equals(_expectedCurrentArch()));
        expect(captured.categoryId, isNull);
      });
    });

    group('searchApps', () {
      test('should return matching apps for keyword', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const AppListResponse(
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
          const AppListResponse(
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
        expect(captured.arch, equals(_expectedCurrentArch()));
        expect(captured.keyword, equals('test keyword'));
      });
    });

    group('getAppDetail', () {
      tearDown(() {
        ApiClient.getLocale = null;
      });

      test('should return app detail on success', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const AppDetailResponse(
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
        expect(result.name, equals('Test App'));
        expect(result.screenshots.length, equals(1));
      });

      test('should throw exception when app not found', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const AppDetailResponse(code: 200, data: null),
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
          const AppDetailResponse(
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
        expect(captured.single.lang, equals('zh_CN'));
      });

      test('should map English locale to en_US for detail request', () async {
        // Arrange
        ApiClient.getLocale = () => 'en';
        final mockResponse = HttpResponse(
          const AppDetailResponse(
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
        await repository.getAppDetail('com.example.app');

        // Assert
        final captured =
            verify(mockApiService.getAppDetail(captureAny)).captured.single
                as List<AppDetailSearchBO>;
        expect(captured.single.lang, equals('en_US'));
      });
    });

    group('getVersions', () {
      test('should request versions with explicit repoName and arch', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const VersionListResponse(code: 200, data: []),
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
        await repository.getVersions(
          'com.example.app',
          repoName: 'stable',
          arch: 'aarch64',
        );

        // Assert
        final captured =
            verify(
                  mockApiService.getSearchAppVersionList(captureAny),
                ).captured.single
                as AppVersionListRequest;
        expect(captured.appId, equals('com.example.app'));
        expect(captured.repoName, equals('stable'));
        expect(captured.arch, equals('aarch64'));
      });

      test(
        'should normalize duplicate modules and sort versions descending',
        () async {
          // Arrange
          final mockResponse = HttpResponse(
            const VersionListResponse(
              code: 200,
              data: [
                AppVersionDTO(
                  versionId: 'runtime-2',
                  appId: 'com.example.app',
                  versionNo: '1.9.0',
                  module: 'runtime',
                ),
                AppVersionDTO(
                  versionId: 'binary-2',
                  appId: 'com.example.app',
                  versionNo: '1.9.0',
                  module: 'binary',
                ),
                AppVersionDTO(
                  versionId: 'binary-3',
                  appId: 'com.example.app',
                  versionNo: '2.0.0',
                  module: 'binary',
                ),
                AppVersionDTO(
                  versionId: 'binary-1',
                  appId: 'com.example.app',
                  versionNo: '1.0.0',
                  module: 'binary',
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
          expect(result.length, equals(3));
          expect(result[0].versionNo, equals('2.0.0'));
          expect(result[1].versionNo, equals('1.9.0'));
          expect(result[1].module, equals('binary'));
          expect(result[2].versionNo, equals('1.0.0'));
        },
      );

      test('should return empty list when no versions', () async {
        // Arrange
        final mockResponse = HttpResponse(
          const VersionListResponse(code: 200, data: []),
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

    group('getAppComments', () {
      test('should request comment list by appId', () async {
        final mockResponse = HttpResponse(
          const AppCommentListResponse(
            code: 200,
            data: [
              AppCommentDTO(
                id: 'comment-1',
                appId: 'com.example.app',
                version: '1.0.0',
                remark: '评论内容',
                createTime: '2026-03-23 09:00:00',
              ),
            ],
          ),
          Response(
            requestOptions: RequestOptions(path: '/app/getAppCommentList'),
          ),
        );

        when(
          mockApiService.getAppCommentList(any),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.getAppComments('com.example.app');

        expect(result, hasLength(1));
        expect(result.single.remark, equals('评论内容'));
        final captured =
            verify(mockApiService.getAppCommentList(captureAny)).captured.single
                as AppCommentSearchBO;
        expect(captured.appId, equals('com.example.app'));
      });
    });

    group('saveAppComment', () {
      test('should post trimmed comment payload and return success', () async {
        final mockResponse = HttpResponse(
          const BooleanResponse(code: 200, data: true),
          Response(requestOptions: RequestOptions(path: '/app/saveAppComment')),
        );

        when(
          mockApiService.saveAppComment(any),
        ).thenAnswer((_) async => mockResponse);

        final result = await repository.saveAppComment(
          appId: 'com.example.app',
          remark: '很好用',
          version: '1.0.0',
        );

        expect(result, isTrue);
        final captured =
            verify(mockApiService.saveAppComment(captureAny)).captured.single
                as AppCommentSaveBO;
        expect(captured.appId, equals('com.example.app'));
        expect(captured.remark, equals('很好用'));
        expect(captured.version, equals('1.0.0'));
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
          const AppListArrayResponse(
            code: 200,
            data: [
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
          const AppListResponse(
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
          const AppListResponse(
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
          const AppListResponse(
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
        expect(captured.arch, equals(_expectedCurrentArch()));
        expect(captured.pageSize, equals(50));
      });
    });

    group('mapDetailToInstalledApp', () {
      test('should correctly map AppDetailDTO to InstalledApp', () {
        // Arrange
        const dto = AppDetailDTO(
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
        const dto = AppDetailDTO(
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

    group('enrichInstalledAppsWithDetails', () {
      test(
        'should cache detail enrichment and skip remote request on repeated calls',
        () async {
          final apps = [
            const InstalledApp(
              appId: 'org.deepin.calculator',
              name: 'deepin-calculator',
              version: '6.5.31.1',
              arch: 'x86_64',
              channel: 'main',
              module: 'binary',
            ),
          ];

          final mockResponse = HttpResponse(
            const AppListArrayResponse(
              code: 200,
              data: [
                AppListItemDTO(
                  appId: 'org.deepin.calculator',
                  appName: '计算器',
                  appVersion: '6.5.31.1',
                  appIcon: 'https://example.com/calculator.png',
                  appDesc: '计算器应用',
                ),
              ],
            ),
            Response(
              requestOptions: RequestOptions(path: '/app/getAppDetails'),
            ),
          );

          when(
            mockApiService.getAppDetails(any),
          ).thenAnswer((_) async => mockResponse);

          final firstResult = await repository.enrichInstalledAppsWithDetails(
            apps,
          );
          final secondResult = await repository.enrichInstalledAppsWithDetails(
            apps,
          );

          expect(
            firstResult.single.icon,
            equals('https://example.com/calculator.png'),
          );
          expect(
            secondResult.single.icon,
            equals('https://example.com/calculator.png'),
          );
          expect(secondResult.single.name, equals('计算器'));
          verify(mockApiService.getAppDetails(any)).called(1);
        },
      );

      test('should only request uncached app details', () async {
        final cachedApps = [
          const InstalledApp(
            appId: 'org.deepin.calculator',
            name: 'deepin-calculator',
            version: '6.5.31.1',
            arch: 'x86_64',
            channel: 'main',
            module: 'binary',
          ),
        ];
        final mixedApps = [
          ...cachedApps,
          const InstalledApp(
            appId: 'org.deepin.camera',
            name: 'deepin-camera',
            version: '6.5.36.1',
            arch: 'x86_64',
            channel: 'main',
            module: 'binary',
          ),
        ];

        when(mockApiService.getAppDetails(any)).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single as List<AppDetailsBO>;
          final appIds = request.map((item) => item.appId).toList();

          if (appIds.length == 1 && appIds.single == 'org.deepin.calculator') {
            return HttpResponse(
              const AppListArrayResponse(
                code: 200,
                data: [
                  AppListItemDTO(
                    appId: 'org.deepin.calculator',
                    appName: '计算器',
                    appVersion: '6.5.31.1',
                    appIcon: 'https://example.com/calculator.png',
                  ),
                ],
              ),
              Response(
                requestOptions: RequestOptions(path: '/app/getAppDetails'),
              ),
            );
          }

          return HttpResponse(
            const AppListArrayResponse(
              code: 200,
              data: [
                AppListItemDTO(
                  appId: 'org.deepin.camera',
                  appName: '相机',
                  appVersion: '6.5.36.1',
                  appIcon: 'https://example.com/camera.png',
                ),
              ],
            ),
            Response(
              requestOptions: RequestOptions(path: '/app/getAppDetails'),
            ),
          );
        });

        await repository.enrichInstalledAppsWithDetails(cachedApps);
        final result = await repository.enrichInstalledAppsWithDetails(
          mixedApps,
        );

        expect(result, hasLength(2));
        expect(result.first.name, equals('计算器'));
        expect(result.last.name, equals('相机'));

        final capturedRequests = verify(
          mockApiService.getAppDetails(captureAny),
        ).captured.cast<List<AppDetailsBO>>();
        expect(capturedRequests, hasLength(2));
        expect(capturedRequests.last.map((item) => item.appId), [
          'org.deepin.camera',
        ]);
      });
    });
  });
}

String _expectedCurrentArch() {
  try {
    final archFile = File('/proc/sys/kernel/arch');
    if (archFile.existsSync()) {
      return archFile.readAsStringSync().trim();
    }
  } catch (_) {}

  try {
    final result = Process.runSync('uname', ['-m']);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
  } catch (_) {}

  return 'x86_64';
}
