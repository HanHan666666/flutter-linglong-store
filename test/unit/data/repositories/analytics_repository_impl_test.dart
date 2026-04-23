import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/data/repositories/analytics_repository_impl.dart';
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
  });
}
