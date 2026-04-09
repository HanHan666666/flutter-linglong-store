import 'package:dio/dio.dart';

import '../../../core/utils/version_compare.dart';

/// 版本检查服务
///
/// 封装 Gitee Release API 调用与 semver 比较逻辑，供设置页等入口复用。
/// 返回 [VersionCheckResult] 供调用方决定如何展示 UI，本服务不包含硬编码文案。
class VersionCheckService {
  VersionCheckService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Gitee Latest Release API
  static const _kGiteeLatestApi =
      'https://gitee.com/api/v5/repos/Shirosu/linglong-store/releases/latest';

  /// 检查是否有新版本可用
  ///
  /// [currentVersion] 当前应用版本号。
  /// 返回 [VersionCheckResult]，调用方根据结果类型格式化用户提示。
  Future<VersionCheckResult> checkForUpdate(String currentVersion) async {
    try {
      final response = await _dio.get(
        _kGiteeLatestApi,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final tagName = response.data['tag_name'] as String?;
      if (tagName == null) {
        return const VersionCheckResultVersionInfoMissing();
      }

      final cleanTag = tagName.replaceAll(RegExp(r'^v'), '');
      final cleanCurrent = currentVersion.replaceAll(RegExp(r'^v'), '');

      // 使用 VersionCompare 进行 semver 比较
      if (VersionCompare.greaterThan(cleanTag, cleanCurrent)) {
        final releaseNotes = response.data['body'] as String?;
        return VersionCheckResultUpdateAvailable(
          currentVersion: currentVersion,
          latestVersion: tagName,
          releaseNotes: releaseNotes,
        );
      }

      return VersionCheckResultNoUpdate(currentVersion: currentVersion);
    } on DioException {
      return const VersionCheckResultNetworkError();
    } catch (e) {
      return const VersionCheckResultNetworkError();
    }
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
    this.releaseNotes,
  });
  final String currentVersion;
  final String latestVersion;
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
