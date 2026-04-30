import 'package:dio/dio.dart';

import '../../../core/utils/version_compare.dart';

class _ReleaseSource {
  const _ReleaseSource({
    required this.apiUrl,
    required this.defaultHtmlUrl,
  });

  final String apiUrl;
  final String defaultHtmlUrl;
}

/// 版本检查服务
///
/// 封装 Release API 调用与 semver 比较逻辑，供设置页等入口复用。
///
/// 优先读取预期的 Gitee 镜像；当镜像仓库尚未就绪、被限制访问或暂时不可达时，
/// 自动回退到当前 Flutter 仓库的 GitHub 正式 Release，避免“检查更新”失效。
/// 返回 [VersionCheckResult] 供调用方决定如何展示 UI，本服务不包含硬编码文案。
class VersionCheckService {
  VersionCheckService({
    Dio? dio,
    Future<Map<String, dynamic>> Function(String url)? fetchReleaseJson,
  }) : _dio = dio ?? Dio(),
       _fetchReleaseJson = fetchReleaseJson;

  final Dio _dio;
  final Future<Map<String, dynamic>> Function(String url)? _fetchReleaseJson;

  static const List<_ReleaseSource> _kReleaseSources = [
    // 先尝试项目约定中的 Gitee 镜像地址，镜像恢复后可直接生效。
    _ReleaseSource(
      apiUrl:
          'https://gitee.com/api/v5/repos/hanplus/flutter-linglong-store/releases/latest',
      defaultHtmlUrl: 'https://gitee.com/hanplus/flutter-linglong-store/releases/latest',
    ),
    // Gitee 镜像异常时，回退到当前 Flutter 仓库的 GitHub 正式 Release。
    _ReleaseSource(
      apiUrl:
          'https://api.github.com/repos/HanHan666666/flutter-linglong-store/releases/latest',
      defaultHtmlUrl:
          'https://github.com/HanHan666666/flutter-linglong-store/releases/latest',
    ),
  ];

  Future<Map<String, dynamic>> _loadReleaseJson(String url) async {
    if (_fetchReleaseJson != null) {
      return _fetchReleaseJson(url);
    }

    final response = await _dio.get<dynamic>(
      url,
      options: Options(
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Release response is not a JSON object');
  }

  String _resolveReleasePageUrl(
    Map<String, dynamic> release,
    String fallbackUrl,
  ) {
    final htmlUrl = release['html_url'] as String?;
    if (htmlUrl != null && htmlUrl.trim().isNotEmpty) {
      return htmlUrl;
    }
    return fallbackUrl;
  }

  /// 检查是否有新版本可用
  ///
  /// [currentVersion] 当前应用版本号。
  /// 返回 [VersionCheckResult]，调用方根据结果类型格式化用户提示。
  Future<VersionCheckResult> checkForUpdate(String currentVersion) async {
    final cleanCurrent = currentVersion.replaceAll(RegExp(r'^v'), '');
    var sawVersionInfoMissing = false;
    DioException? lastDioError;

    for (final source in _kReleaseSources) {
      try {
        final release = await _loadReleaseJson(source.apiUrl);
        final tagName = release['tag_name'] as String?;
        if (tagName == null || tagName.trim().isEmpty) {
          sawVersionInfoMissing = true;
          continue;
        }

        final cleanTag = tagName.replaceAll(RegExp(r'^v'), '');

        // 使用 VersionCompare 进行 semver 比较。
        if (VersionCompare.greaterThan(cleanTag, cleanCurrent)) {
          final releaseNotes = release['body'] as String?;
          return VersionCheckResultUpdateAvailable(
            currentVersion: currentVersion,
            latestVersion: tagName,
            releaseNotes: releaseNotes,
            releasePageUrl: _resolveReleasePageUrl(
              release,
              source.defaultHtmlUrl,
            ),
          );
        }

        return VersionCheckResultNoUpdate(currentVersion: currentVersion);
      } on DioException catch (error) {
        lastDioError = error;
        continue;
      } on FormatException {
        sawVersionInfoMissing = true;
        continue;
      } on StateError {
        sawVersionInfoMissing = true;
        continue;
      }
    }

    if (sawVersionInfoMissing) {
      return const VersionCheckResultVersionInfoMissing();
    }
    if (lastDioError != null) {
      return const VersionCheckResultNetworkError();
    }
    return const VersionCheckResultVersionInfoMissing();
  }
}

/// 版本检查结果（sealed class）
///
/// 使用 typed result 代替硬编码文案，让调用方通过 l10n 格式化用户提示。
sealed class VersionCheckResult {
  const VersionCheckResult();
}

/// 已是最新版本
class VersionCheckResultNoUpdate extends VersionCheckResult {
  const VersionCheckResultNoUpdate({required this.currentVersion});
  final String currentVersion;
}

/// 发现新版本
class VersionCheckResultUpdateAvailable extends VersionCheckResult {
  const VersionCheckResultUpdateAvailable({
    required this.currentVersion,
    required this.latestVersion,
    required this.releasePageUrl,
    this.releaseNotes,
  });
  final String currentVersion;
  final String latestVersion;
  final String releasePageUrl;
  final String? releaseNotes;
}

/// 版本信息缺失（tag_name 为空）
class VersionCheckResultVersionInfoMissing extends VersionCheckResult {
  const VersionCheckResultVersionInfoMissing();
}

/// 网络请求失败
class VersionCheckResultNetworkError extends VersionCheckResult {
  const VersionCheckResultNetworkError();
}
