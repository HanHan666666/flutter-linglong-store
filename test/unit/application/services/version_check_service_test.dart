import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/version_check_service.dart';

DioException buildDioError(String url, int statusCode) {
  final requestOptions = RequestOptions(path: url);
  return DioException(
    requestOptions: requestOptions,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: statusCode,
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('VersionCheckService', () {
    test('prefers the Gitee mirror when the mirror latest release is available', () async {
      final requestedUrls = <String>[];
      final service = VersionCheckService(
        fetchReleaseJson: (url) async {
          requestedUrls.add(url);
          if (url.contains('gitee.com/api/v5/repos/hanplus/flutter-linglong-store')) {
            return {
              'tag_name': 'v3.3.2',
              'body': 'mirror notes',
              'html_url':
                  'https://gitee.com/hanplus/flutter-linglong-store/releases/tag/v3.3.2',
            };
          }
          fail('should not request the fallback source when the mirror is available');
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(requestedUrls, hasLength(1));
      expect(
        result,
        isA<VersionCheckResultUpdateAvailable>()
            .having((value) => value.latestVersion, 'latestVersion', 'v3.3.2')
            .having(
              (value) => value.releasePageUrl,
              'releasePageUrl',
              'https://gitee.com/hanplus/flutter-linglong-store/releases/tag/v3.3.2',
            )
            .having(
              (value) => value.releaseNotes,
              'releaseNotes',
              'mirror notes',
            ),
      );
    });

    test('falls back to GitHub when the Gitee mirror is unavailable', () async {
      final requestedUrls = <String>[];
      final service = VersionCheckService(
        fetchReleaseJson: (url) async {
          requestedUrls.add(url);
          if (url.contains('gitee.com/api/v5/repos/hanplus/flutter-linglong-store')) {
            throw buildDioError(url, 404);
          }
          if (url.contains('api.github.com/repos/HanHan666666/flutter-linglong-store')) {
            return {
              'tag_name': 'v3.3.2',
              'body': 'github notes',
              'html_url':
                  'https://github.com/HanHan666666/flutter-linglong-store/releases/tag/v3.3.2',
            };
          }
          fail('unexpected release URL: $url');
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(requestedUrls, hasLength(2));
      expect(requestedUrls.first, contains('gitee.com/api/v5/repos/hanplus/flutter-linglong-store'));
      expect(
        requestedUrls.last,
        contains('api.github.com/repos/HanHan666666/flutter-linglong-store'),
      );
      expect(
        result,
        isA<VersionCheckResultUpdateAvailable>()
            .having((value) => value.latestVersion, 'latestVersion', 'v3.3.2')
            .having(
              (value) => value.releasePageUrl,
              'releasePageUrl',
              'https://github.com/HanHan666666/flutter-linglong-store/releases/tag/v3.3.2',
            ),
      );
    });

    test('returns network error when all release sources fail', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => throw buildDioError(url, 503),
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(result, isA<VersionCheckResultNetworkError>());
    });
  });
}
