/// 应用自更新领域模型与纯解析规则。
///
/// 本文件只描述 Release 资产、当前运行身份和 SHA256 文件格式，不包含网络、
/// 文件或提权操作。客户端按宽松文件名后缀选择包，再用 Release 的哈希文件校验。
library;

import 'dart:convert';

/// Release API 返回的发布资产。
class ReleaseAsset {
  /// 创建发布资产。
  const ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    this.size,
  });

  /// 资产文件名。
  final String name;

  /// 可直接下载的 URL。
  final String browserDownloadUrl;

  /// Release API 报告的资产大小；未提供时为空。
  final int? size;

  /// 从 GitHub 或 Gitee Release API 结构读取资产。
  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: (json['name'] as String?) ?? '',
      browserDownloadUrl:
          (json['browser_download_url'] as String?) ??
          (json['url'] as String?) ??
          '',
      size: (json['size'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReleaseAsset &&
        other.name == name &&
        other.browserDownloadUrl == browserDownloadUrl &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(name, browserDownloadUrl, size);
}

/// 当前进程的安装方式。
enum AppInstallationKind {
  /// 当前可执行文件属于 dpkg 安装包。
  packageManagerDpkg,

  /// 当前可执行文件属于 RPM 安装包。
  packageManagerRpm,

  /// 当前进程由 AppImage 启动。
  appImage,

  /// 其它手动安装方式，不执行自动更新。
  manual,
}

/// 当前进程安装身份的探测结果。
class AppInstallation {
  /// 创建安装身份。
  const AppInstallation({required this.kind, this.appImagePath});

  /// 当前进程的安装方式。
  final AppInstallationKind kind;

  /// AppImage 真实文件路径，仅 AppImage 身份有效。
  final String? appImagePath;
}

/// Release 中 SHA256 清单的固定资产名。
const String appUpdateHashesAssetName = 'hashes.sha256';

/// 按当前安装身份和架构选择唯一的 Release 安装包。
///
/// 文件名只依赖发布脚本已有的架构后缀，不绑定版本号；stable 与 nightly 的
/// 中间分隔符可以不同。匹配到多个候选时拒绝继续，避免资产异常时随意安装。
ReleaseAsset? resolveAppUpdatePackageAsset({
  required List<ReleaseAsset> assets,
  required AppInstallationKind installationKind,
  required String? arch,
}) {
  final normalizedArch = normalizeSelfUpdateArch(arch);
  if (normalizedArch == null ||
      installationKind == AppInstallationKind.manual) {
    return null;
  }
  final suffix = switch (installationKind) {
    AppInstallationKind.packageManagerDpkg => '$normalizedArch.deb',
    AppInstallationKind.packageManagerRpm => switch (normalizedArch) {
      'amd64' => 'x86_64.rpm',
      'arm64' => 'aarch64.rpm',
      _ => null,
    },
    AppInstallationKind.appImage => '-$normalizedArch.AppImage',
    AppInstallationKind.manual => null,
  };
  if (suffix == null) {
    return null;
  }

  ReleaseAsset? match;
  for (final asset in assets) {
    if (asset.browserDownloadUrl.isEmpty || !asset.name.endsWith(suffix)) {
      continue;
    }
    if (match != null) {
      throw StateError('同一架构和安装方式存在多个更新资产');
    }
    match = asset;
  }
  return match;
}

/// 查找 Release 中唯一的 `hashes.sha256` 资产。
ReleaseAsset? resolveAppUpdateHashesAsset(List<ReleaseAsset> assets) {
  ReleaseAsset? match;
  for (final asset in assets) {
    if (asset.name != appUpdateHashesAssetName ||
        asset.browserDownloadUrl.isEmpty) {
      continue;
    }
    if (match != null) {
      throw StateError('Release 中存在多个 hashes.sha256');
    }
    match = asset;
  }
  return match;
}

/// 从标准 `sha256sum` 输出中读取指定资产的摘要。
///
/// 文件名必须完整匹配，不能使用 contains 或仅匹配 basename 的一部分，避免一份
/// 清单同时包含相似文件名时取错摘要。重复条目同样视为发布资产异常。
String? parseAppUpdateSha256(String content, String assetName) {
  final linePattern = RegExp(r'^([0-9a-fA-F]{64})[ \t]+\*?(.+)$');
  String? match;
  for (final line in const LineSplitter().convert(content)) {
    final parsed = linePattern.firstMatch(line);
    if (parsed == null || parsed.group(2) != assetName) {
      continue;
    }
    if (match != null) {
      throw StateError('hashes.sha256 中存在重复资产摘要');
    }
    match = parsed.group(1)!.toLowerCase();
  }
  return match;
}

/// 无法执行自动更新的稳定原因。
enum AppSelfUpdateUnsupportedReason {
  /// 当前运行方式不是 DEB、RPM 或 AppImage。
  manualInstall,

  /// Release 没有当前架构和安装方式的资产。
  unsupportedArch,

  /// Release 缺少哈希文件或目标安装包的摘要。
  missingChecksumFile,

  /// 下载包的 SHA256 与 Release 清单不一致。
  checksumMismatch,
}

/// 无法安全执行自动更新。
class AppSelfUpdateUnsupportedException implements Exception {
  /// 创建稳定业务异常。
  const AppSelfUpdateUnsupportedException(this.reason);

  /// 不支持原因。
  final AppSelfUpdateUnsupportedReason reason;

  @override
  String toString() => 'AppSelfUpdateUnsupportedException($reason)';
}

/// 用户在进入安装阶段前取消更新。
class AppSelfUpdateCancelledException implements Exception {
  /// 创建取消异常。
  const AppSelfUpdateCancelledException();
}

/// 把系统架构归一化为发布资产使用的架构。
String? normalizeSelfUpdateArch(String? arch) {
  if (arch == null) {
    return null;
  }
  switch (arch.trim().toLowerCase()) {
    case 'x86_64':
    case 'amd64':
      return 'amd64';
    case 'aarch64':
    case 'arm64':
      return 'arm64';
    case 'loongarch64':
    case 'loong64':
      return 'loong64';
    default:
      return null;
  }
}
