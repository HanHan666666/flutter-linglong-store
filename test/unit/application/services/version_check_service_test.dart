import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';

/// 创建指定 Release API 的网络失败。
DioException _dioError(String url, int statusCode) {
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

/// 创建能够完成下载后校验的最小 Release 资产集合。
List<Map<String, dynamic>> _assetsWithHashes({required String origin}) {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'linglong-store_3.3.2_amd64.deb',
      'browser_download_url': '$origin/store.deb',
      'size': 12345,
    },
    <String, dynamic>{
      'name': appUpdateHashesAssetName,
      'browser_download_url': '$origin/hashes.sha256',
    },
  ];
}

void main() {
  group('VersionCheckService', () {
    test('镜像携带 SHA256 文件时直接使用镜像结果', () async {
      final requestedUrls = <String>[];
      final service = VersionCheckService(
        fetchReleaseJson: (url) async {
          requestedUrls.add(url);
          return <String, dynamic>{
            'tag_name': 'v3.3.2',
            'body': 'mirror notes',
            'html_url':
                'https://gitee.com/hanplus/flutter-linglong-store/releases/tag/v3.3.2',
            'assets': _assetsWithHashes(origin: 'https://gitee.com/download'),
          };
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(requestedUrls, hasLength(1));
      expect(
        result,
        isA<VersionCheckResultUpdateAvailable>()
            .having((value) => value.latestVersion, 'latestVersion', 'v3.3.2')
            .having((value) => value.assets, 'assets', hasLength(2)),
      );
    });

    test('镜像缺少 SHA256 文件时继续选择可校验的 GitHub', () async {
      final requestedUrls = <String>[];
      final service = VersionCheckService(
        fetchReleaseJson: (url) async {
          requestedUrls.add(url);
          if (url.contains('gitee.com')) {
            return <String, dynamic>{
              'tag_name': 'v3.3.2',
              'html_url': 'https://gitee.com/releases/v3.3.2',
              'assets': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'linglong-store_3.3.2_amd64.deb',
                  'browser_download_url': 'https://gitee.com/store.deb',
                },
              ],
            };
          }
          return <String, dynamic>{
            'tag_name': 'v3.3.2',
            'html_url': 'https://github.com/releases/v3.3.2',
            'assets': _assetsWithHashes(origin: 'https://github.com/download'),
          };
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(requestedUrls, hasLength(2));
      expect(
        (result as VersionCheckResultUpdateAvailable).releasePageUrl,
        contains('github.com'),
      );
    });

    test('所有发布源网络失败时返回稳定网络错误', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => throw _dioError(url, 503),
      );

      expect(
        await service.checkForUpdate('3.3.1'),
        isA<VersionCheckResultNetworkError>(),
      );
    });

    test('旧 Release 没有 SHA256 文件时仍报告新版本供用户手动下载', () async {
      final service = VersionCheckService(
        fetchReleaseJson: (url) async => <String, dynamic>{
          'tag_name': 'v3.3.2',
          'html_url': 'https://github.com/releases/v3.3.2',
        },
      );

      final result = await service.checkForUpdate('3.3.1');

      expect(result, isA<VersionCheckResultUpdateAvailable>());
      expect((result as VersionCheckResultUpdateAvailable).assets, isEmpty);
    });
  });
}
