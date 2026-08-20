import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/app_config.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/data/repositories/analytics_repository_impl.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/mock_classes.mocks.dart';

void main() {
  late MockAppApiService mockApiService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!PreferencesService.isInitialized) {
      await PreferencesService.init();
    }
    await AppLogger.init();
  });

  setUp(() async {
    mockApiService = MockAppApiService();
    await PreferencesService.clear();
  });

  group('AnalyticsRepositoryImpl', () {
    test('reportVisit migrates legacy startup diagnostics fields', () async {
      var clientIpResolverCalls = 0;
      when(mockApiService.saveVisitRecord(any)).thenAnswer(
        (_) async => HttpResponse<dynamic>(
          <String, dynamic>{'code': 200},
          Response<dynamic>(
            requestOptions: RequestOptions(path: '/app/saveVisitRecord'),
          ),
        ),
      );

      final repository = AnalyticsRepositoryImpl(
        apiService: mockApiService,
        clientIpResolver: () async {
          clientIpResolverCalls += 1;
          return '1.2.3.4';
        },
      );

      await repository.initializeSession();

      await repository.reportVisit(
        arch: 'x86_64',
        llVersion: '1.9.0',
        llBinVersion: '1.9.1',
        detailMsg: 'ii  linglong-bin 1.9.1',
        osVersion: 'Linux test kernel',
        repoName: 'stable',
        appVersion: '2.0.0',
      );
      await repository.reportVisit(
        arch: 'x86_64',
        llVersion: '1.9.0',
        llBinVersion: '1.9.1',
        detailMsg: 'ii  linglong-bin 1.9.1',
        osVersion: 'Linux test kernel',
        repoName: 'stable',
        appVersion: '2.0.0',
      );

      final captured = verify(
        mockApiService.saveVisitRecord(captureAny),
      ).captured.cast<SaveVisitRecordRequest>();

      expect(captured, hasLength(2));
      expect(captured.first.clientIp, equals('1.2.3.4'));
      expect(captured.first.llBinVersion, equals('1.9.1'));
      expect(captured.first.detailMsg, equals('ii  linglong-bin 1.9.1'));
      expect(captured.first.visitorId, isNotEmpty);
      expect(captured.last.visitorId, equals(captured.first.visitorId));
      expect(clientIpResolverCalls, equals(1));
    });

    test(
      'reportInstall and reportUninstall include cached client ip',
      () async {
        var clientIpResolverCalls = 0;
        when(mockApiService.saveInstalledRecord(any)).thenAnswer(
          (_) async => HttpResponse<dynamic>(
            <String, dynamic>{'code': 200},
            Response<dynamic>(
              requestOptions: RequestOptions(path: '/app/saveInstalledRecord'),
            ),
          ),
        );

        final repository = AnalyticsRepositoryImpl(
          apiService: mockApiService,
          clientIpResolver: () async {
            clientIpResolverCalls += 1;
            return '5.6.7.8';
          },
        );

        await repository.reportInstall(
          'org.example.demo',
          '1.0.0',
          appName: 'Demo App',
        );
        await repository.reportUninstall(
          'org.example.demo',
          '1.0.0',
          appName: 'Demo App',
        );

        final captured = verify(
          mockApiService.saveInstalledRecord(captureAny),
        ).captured.cast<SaveInstalledRecordRequest>();

        expect(captured, hasLength(2));
        expect(captured.first.clientIp, equals('5.6.7.8'));
        expect(captured.first.addedItems, hasLength(1));
        expect(
          captured.first.addedItems.single.appId,
          equals('org.example.demo'),
        );
        expect(captured.first.addedItems.single.name, equals('Demo App'));
        expect(captured.last.clientIp, equals('5.6.7.8'));
        expect(captured.last.removedItems, hasLength(1));
        expect(
          captured.last.removedItems.single.appId,
          equals('org.example.demo'),
        );
        expect(clientIpResolverCalls, equals(1));
      },
    );

    test('reportInstalledAppsDiff 映射差量并补齐仓库与类型字段', () async {
      when(mockApiService.saveInstalledRecord(any)).thenAnswer(
        (_) async => HttpResponse<dynamic>(
          <String, dynamic>{'code': 200},
          Response<dynamic>(
            requestOptions: RequestOptions(path: '/app/saveInstalledRecord'),
          ),
        ),
      );

      final repository = AnalyticsRepositoryImpl(
        apiService: mockApiService,
        clientIpResolver: () async => '9.9.9.9',
      );

      await repository.reportInstalledAppsDiff(
        addedItems: const [
          InstalledApp(
            appId: 'org.example.new',
            name: 'New App',
            version: '2.0.0',
            arch: 'x86_64',
            module: 'runtime',
            channel: 'stable',
            kind: 'app',
          ),
        ],
        removedItems: const [
          InstalledApp(
            appId: 'org.example.old',
            name: 'Old App',
            version: '1.0.0',
            kind: 'app',
          ),
        ],
      );

      final captured = verify(
        mockApiService.saveInstalledRecord(captureAny),
      ).captured.cast<SaveInstalledRecordRequest>().single;

      expect(captured.visitorId, isNotEmpty);
      expect(captured.addedItems, hasLength(1));
      final added = captured.addedItems.single;
      expect(added.appId, equals('org.example.new'));
      expect(added.name, equals('New App'));
      expect(added.version, equals('2.0.0'));
      expect(added.arch, equals('x86_64'));
      expect(added.module, equals('runtime'));
      expect(added.channel, equals('stable'));
      expect(added.kind, equals('app'));
      // repoName 统一填默认仓库，对齐旧版 Electron 的 defaultRepoName 覆盖行为。
      expect(added.repoName, equals(AppConfig.defaultStoreRepoName));

      expect(captured.removedItems, hasLength(1));
      expect(captured.removedItems.single.appId, equals('org.example.old'));
      expect(captured.removedItems.single.version, equals('1.0.0'));
    });

    test('reportInstalledAppsDiff 双向为空时不发起请求', () async {
      final repository = AnalyticsRepositoryImpl(
        apiService: mockApiService,
        clientIpResolver: () async => '9.9.9.9',
      );

      await repository.reportInstalledAppsDiff(
        addedItems: const [],
        removedItems: const [],
      );

      verifyNever(mockApiService.saveInstalledRecord(any));
    });
  });
}
