import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/di/providers.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/data/repositories/app_repository_impl.dart';
import 'package:linglong_store/presentation/pages/app_detail/app_detail_page.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../mocks/mock_classes.mocks.dart';

void main() {
  late MockAppApiService mockApiService;
  late ProviderContainer container;

  setUpAll(() async {
    await AppLogger.init();
  });

  setUp(() {
    mockApiService = MockAppApiService();
    container = ProviderContainer(
      overrides: [
        appRepositoryProvider.overrideWith(
          (ref) => AppRepositoryImpl.withService(mockApiService),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AppDetail comments', () {
    test('loadDetail 成功后会同步加载评论列表', () async {
      when(mockApiService.getAppDetail(any)).thenAnswer(
        (_) async => HttpResponse(
          const AppDetailResponse(
            code: 200,
            data: {
              'org.deepin.album': [
                {
                  'appId': 'org.deepin.album',
                  'zhName': '相册',
                  'version': '6.0.49.1',
                },
              ],
            },
          ),
          Response(requestOptions: RequestOptions(path: '/app/getAppDetail')),
        ),
      );
      when(mockApiService.getSearchAppVersionList(any)).thenAnswer(
        (_) async => HttpResponse(
          const VersionListResponse(code: 200, data: []),
          Response(
            requestOptions: RequestOptions(path: '/visit/getSearchAppVersionList'),
          ),
        ),
      );
      when(mockApiService.getAppCommentList(any)).thenAnswer(
        (_) async => HttpResponse(
          const AppCommentListResponse(
            code: 200,
            data: [
              AppCommentDTO(
                id: 'comment-1',
                appId: 'org.deepin.album',
                version: '6.0.49.1',
                remark: '评论内容',
                createTime: '2026-03-23 09:00:00',
              ),
            ],
          ),
          Response(
            requestOptions: RequestOptions(path: '/app/getAppCommentList'),
          ),
        ),
      );

      await container
          .read(appDetailProvider('org.deepin.album').notifier)
          .loadDetail(null);

      final state = container.read(appDetailProvider('org.deepin.album'));
      expect(state.comments, hasLength(1));
      expect(state.comments.single.remark, equals('评论内容'));
    });

    test('submitComment 成功后会重新拉取最新评论', () async {
      when(mockApiService.saveAppComment(any)).thenAnswer(
        (_) async => HttpResponse(
          const BooleanResponse(code: 200, data: true),
          Response(
            requestOptions: RequestOptions(path: '/app/saveAppComment'),
          ),
        ),
      );
      when(mockApiService.getAppCommentList(any)).thenAnswer(
        (_) async => HttpResponse(
          const AppCommentListResponse(
            code: 200,
            data: [
              AppCommentDTO(
                id: 'comment-2',
                appId: 'org.deepin.album',
                version: '6.0.49.1',
                remark: '提交后的最新评论',
                createTime: '2026-03-23 10:00:00',
              ),
            ],
          ),
          Response(
            requestOptions: RequestOptions(path: '/app/getAppCommentList'),
          ),
        ),
      );

      await container
          .read(appDetailProvider('org.deepin.album').notifier)
          .submitComment('提交后的最新评论', version: '6.0.49.1');

      final state = container.read(appDetailProvider('org.deepin.album'));
      expect(state.isSubmittingComment, isFalse);
      expect(state.comments.single.remark, equals('提交后的最新评论'));
      verify(mockApiService.saveAppComment(any)).called(1);
      verify(mockApiService.getAppCommentList(any)).called(1);
    });
  });
}
