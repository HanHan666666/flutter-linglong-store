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
              'assets': [
                {
                  'name': 'linglong-store_3.3.2_amd64.deb',
                  'browser_download_url': 'https://gitee.com/x/pkg.deb',
                },
              ],
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
            )
            .having(
              (value) => value.assets,
              'assets',
              hasLength(1),
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

    test('falls back to the next source when the mirror omits assets', () async {
      final requestedUrls = <String>[];
      final service = VersionCheckService(
        fetchReleaseJson: (url) async {
          requestedUrls.add(url);
          if (url.contains('gitee.com/api/v5/repos/hanplus/flutter-linglong-store')) {
            // Gitee 返回了更新但未携带资产，应继续尝试 GitHub 获取完整资产。
            return {
              'tag_name': 'v3.3.2',
              'html_url': 'https://gitee.com/hanplus/flutter-linglong-store/releases/tag/v3.3.2',
            };
          }
          if (url.contains('api.github.com/repos/HanHan666666/flutter-linglong-store')) {
            return {
              'tag_name': 'v3.3.2',
              'html_url': 'https://github.com/HanHan666666/flutter-linglong-store/releases/tag/v3.3.2',
              'assets': [
                {
                  'name': 'linglong-store_3.3.2_amd64.deb',
                  'browser_download_url': 'https://github.com/x/pkg.deb',
                },
              ],
            };
          }
          fail('unexpected release URL: $url');
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(requestedUrls, hasLength(2));
      final available = result as VersionCheckResultUpdateAvailable;
      expect(available.assets, hasLength(1));
      expect(
        available.releasePageUrl,
        contains('github.com'),
      );
    });

    test('returns network error when all release sources fail', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => throw buildDioError(url, 503),
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(result, isA<VersionCheckResultNetworkError>());
    });

    test('parses release assets into the update result', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => <String, dynamic>{
          'tag_name': 'v3.3.2',
          'body': 'notes',
          'html_url': 'https://github.com/x/releases/tag/v3.3.2',
          'assets': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'linglong-store_3.3.2_amd64.deb',
              'browser_download_url': 'https://cdn.example.com/pkg.deb',
              'size': 12345,
            },
            <String, dynamic>{
              'name': 'hashes.sha256',
              'browser_download_url': 'https://cdn.example.com/hashes.sha256',
            },
          ],
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(result, isA<VersionCheckResultUpdateAvailable>());
      final available = result as VersionCheckResultUpdateAvailable;
      expect(available.assets, hasLength(2));
      expect(available.assets.first.name, 'linglong-store_3.3.2_amd64.deb');
      expect(
        available.assets.first.browserDownloadUrl,
        'https://cdn.example.com/pkg.deb',
      );
      expect(available.assets.first.size, 12345);
      expect(available.assets[1].name, 'hashes.sha256');
    });

    test('tolerates a release without an assets list', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => <String, dynamic>{
          'tag_name': 'v3.3.2',
          'html_url': 'https://github.com/x/releases/tag/v3.3.2',
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      final available = result as VersionCheckResultUpdateAvailable;
      expect(available.assets, isEmpty);
    });
  });
}
