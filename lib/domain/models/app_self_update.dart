/// 应用自更新相关领域模型。
///
/// 只包含纯数据模型与纯函数，不依赖 IO / UI：
/// - [ReleaseAsset]：发布资产（安装包 / 校验文件）的下载信息；
/// - [AppInstallationKind] 与 [AppInstallation]：当前应用安装方式的检测结果；
/// - [normalizeSelfUpdateArch] / [resolveAssetForPackage]：按架构与包类型选择安装包。
library;

/// 发布资产。
///
/// 来自 GitHub / Gitee latest release API 的 `assets` 数组。
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    this.size,
  });

  /// 资产文件名，如 `linglong-store_3.5.0_amd64.deb`。
  final String name;

  /// 可直接下载的 URL。
  final String browserDownloadUrl;

  /// 资产大小（字节），API 未提供时为 null。
  final int? size;

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

  @override
  String toString() {
    return 'ReleaseAsset(name: $name, browserDownloadUrl: $browserDownloadUrl, size: $size)';
  }
}

/// 当前应用的安装方式。
enum AppInstallationKind {
  /// 通过 dpkg 系包管理器安装（Debian / Ubuntu / Deepin / UOS 等）。
  packageManagerDpkg,

  /// 通过 rpm 系包管理器安装（Fedora / RHEL / openSUSE 等）。
  packageManagerRpm,

  /// 以 AppImage 方式运行（可通过 `APPIMAGE` 环境变量定位真实文件并原地替换）。
  appImage,

  /// 手动解压 tar.gz 等方式安装，无法自动更新，只能引导下载。
  manual,
}

/// 安装方式检测结果。
class AppInstallation {
  const AppInstallation({
    required this.kind,
    this.appImagePath,
    this.managerLabel,
  });

  final AppInstallationKind kind;

  /// AppImage 方式运行时，磁盘上真实 AppImage 文件的绝对路径。
  ///
  /// 仅 [AppInstallationKind.appImage] 时有值。
  final String? appImagePath;

  /// 检测到的发行版 / 包管理器标签，用于诊断展示。
  final String? managerLabel;
}

/// 把运行环境的架构标识归一化为发布资产使用的架构段。
///
/// 支持的输入：`x86_64` / `amd64` / `aarch64` / `arm64` / `loongarch64` / `loong64`。
/// 无法识别时返回 null，调用方应视为「当前架构不支持自动安装」。
String? normalizeSelfUpdateArch(String? arch) {
  if (arch == null) {
    return null;
  }
  final normalized = arch.trim().toLowerCase();
  switch (normalized) {
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

/// 从发布资产中为指定架构与包类型挑选安装包。
///
/// 匹配规则基于文件名后缀，避免硬编码完整文件名：
/// - dpkg：`linglong-store_<version>_<arch>.deb`；
/// - rpm：`linglong-store-<version>-1.<rpmArch>.rpm`（amd64→x86_64，arm64→aarch64，loong64 无）；
/// - AppImage：`linglong-store-<version>-<arch>.AppImage`（amd64 / arm64，loong64 无）。
///
/// 找不到匹配资产时返回 null。
ReleaseAsset? resolveAssetForPackage({
  required List<ReleaseAsset> assets,
  required String? arch,
  required AppInstallationKind kind,
}) {
  final normalizedArch = normalizeSelfUpdateArch(arch);
  if (normalizedArch == null) {
    return null;
  }

  String? suffix;
  switch (kind) {
    case AppInstallationKind.packageManagerDpkg:
      suffix = '_$normalizedArch.deb';
      break;
    case AppInstallationKind.packageManagerRpm:
      switch (normalizedArch) {
        case 'amd64':
          suffix = '1.x86_64.rpm';
          break;
        case 'arm64':
          suffix = '1.aarch64.rpm';
          break;
        default:
          // loong64 无 RPM 资产。
          return null;
      }
      break;
    case AppInstallationKind.appImage:
      switch (normalizedArch) {
        case 'amd64':
        case 'arm64':
          suffix = '-$normalizedArch.AppImage';
          break;
        default:
          // loong64 无 AppImage 资产。
          return null;
      }
      break;
    case AppInstallationKind.manual:
      return null;
  }

  for (final asset in assets) {
    if (!asset.name.startsWith('linglong-store')) {
      continue;
    }
    if (asset.name.endsWith(suffix)) {
      return asset;
    }
  }
  return null;
}
