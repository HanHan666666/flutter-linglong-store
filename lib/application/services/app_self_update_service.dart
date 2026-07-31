import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/platform/file_downloader.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/app_self_update.dart';
import 'app_installation_probe.dart';
import 'version_check_service.dart';

/// 自更新阶段。
enum AppSelfUpdatePhase {
  /// 检测安装方式。
  detectingInstallation,

  /// 选择安装包。
  resolvingAsset,

  /// 下载安装包。
  downloading,

  /// 校验安装包（sha256）。
  verifying,

  /// 执行安装。
  installing,

  /// 重启应用。
  restarting,

  /// 完成。
  done,

  /// 失败。
  failed,
}

/// 自更新进度事件。
class AppSelfUpdateProgress {
  const AppSelfUpdateProgress(
    this.phase, {
    this.progress = 0,
    this.error,
  });

  final AppSelfUpdatePhase phase;

  /// 0..1 的整体进度。
  final double progress;

  /// 失败阶段携带的异常。
  final Object? error;
}

/// 无法自动更新的原因。
enum AppSelfUpdateUnsupportedReason {
  /// 手动安装（tar.gz 解压等），无法自动更新。
  manualInstall,

  /// 当前架构没有对应的安装包。
  unsupportedArch,

  /// release 缺少 `hashes.sha256` 校验文件或目标文件没有 hash 行。
  missingChecksumFile,

  /// 安装包 sha256 与官方校验值不一致，中止安装。
  checksumMismatch,
}

/// 无法自动更新异常。
class AppSelfUpdateUnsupportedException implements Exception {
  const AppSelfUpdateUnsupportedException(this.reason);

  final AppSelfUpdateUnsupportedReason reason;

  @override
  String toString() => 'AppSelfUpdateUnsupportedException($reason)';
}

/// 应用自更新编排服务。
///
/// 统一编排「检测安装方式 → 选择安装包 → 下载 → sha256 校验 → 安装 → 重启」。
/// 全部依赖注入，便于单元测试：
/// - deb / rpm 通过 `pkexec` 执行系统包管理器安装；
/// - AppImage 通过原地替换磁盘文件完成更新；
/// - 手动安装 / 架构无包 / 缺校验文件时抛 [AppSelfUpdateUnsupportedException]。
class AppSelfUpdateService {
  AppSelfUpdateService({
    required AppInstallationProbe probe,
    required FileDownloader downloader,
    required ShellCommandExecutor shellExecutor,
    required String Function() currentArch,
    required Future<void> Function(String executable) restartApp,
    required Future<void> Function() closeApp,
    String? tempDirectory,
  }) : _probe = probe,
       _downloader = downloader,
       _shellExecutor = shellExecutor,
       _currentArch = currentArch,
       _restartApp = restartApp,
       _closeApp = closeApp,
       _tempDirectory = tempDirectory;

  static const String checksumAssetName = 'hashes.sha256';

  /// deb / rpm 安装后，应用二进制所在的固定路径。
  static const String packagedExecutablePath =
      '/opt/linglong-store/linglong_store';

  final AppInstallationProbe _probe;
  final FileDownloader _downloader;
  final ShellCommandExecutor _shellExecutor;
  final String Function() _currentArch;
  final Future<void> Function(String executable) _restartApp;
  final Future<void> Function() _closeApp;
  final String? _tempDirectory;

  /// 执行自更新。
  ///
  /// 各阶段通过 [onProgress] 回调进度；返回是否成功。
  /// 无法自动更新时抛 [AppSelfUpdateUnsupportedException]。
  Future<bool> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required void Function(AppSelfUpdateProgress progress) onProgress,
  }) async {
    try {
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.detectingInstallation,
          progress: 0.05,
        ),
      );
      final installation = await _probe.detect();

      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.resolvingAsset,
          progress: 0.1,
        ),
      );
      final arch = _currentArch();
      final asset = resolveAssetForPackage(
        assets: update.assets,
        arch: arch,
        kind: installation.kind,
      );
      if (asset == null) {
        if (installation.kind == AppInstallationKind.manual) {
          throw const AppSelfUpdateUnsupportedException(
            AppSelfUpdateUnsupportedReason.manualInstall,
          );
        }
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.unsupportedArch,
        );
      }

      // 下载安装包。
      final downloadDir = _tempDirectory ?? Directory.systemTemp.path;
      final downloadPath = '$downloadDir/${asset.name}';
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.downloading,
          progress: 0.15,
        ),
      );
      final downloadedFile = await _downloader.downloadToFile(
        url: asset.browserDownloadUrl,
        destinationPath: downloadPath,
        onProgress: (received, total) {
          final fraction = total > 0 ? received / total : null;
          onProgress(
            AppSelfUpdateProgress(
              AppSelfUpdatePhase.downloading,
              progress: fraction == null ? 0.5 : 0.15 + 0.65 * fraction,
            ),
          );
        },
      );

      // sha256 校验。
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.verifying,
          progress: 0.82,
        ),
      );
      final checksumAsset = _findAsset(
        update.assets,
        checksumAssetName,
      );
      if (checksumAsset == null) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.missingChecksumFile,
        );
      }
      final expectedHash = await _loadExpectedHash(
        checksumAsset,
        asset.name,
      );
      if (expectedHash == null) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.missingChecksumFile,
        );
      }
      final actualHash = await computeSha256(downloadedFile);
      if (!_hashEquals(actualHash, expectedHash)) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.checksumMismatch,
        );
      }

      // 安装。
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.installing,
          progress: 0.9,
        ),
      );
      final installed = await _install(
        installation,
        downloadedFile,
      );
      if (!installed) {
        throw StateError('安装失败');
      }

      // 清理下载的安装包与校验文件，避免在系统临时目录累积。
      await _cleanupDownloadedFiles(downloadedFile, checksumAsset);

      // 重启。
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.restarting,
          progress: 0.97,
        ),
      );
      await _restart(installation);

      onProgress(
        const AppSelfUpdateProgress(AppSelfUpdatePhase.done, progress: 1),
      );
      return true;
    } catch (e) {
      AppLogger.error('[AppSelfUpdate] 自更新失败', e);
      onProgress(
        AppSelfUpdateProgress(
          AppSelfUpdatePhase.failed,
          progress: 0,
          error: e,
        ),
      );
      rethrow;
    }
  }

  ReleaseAsset? _findAsset(List<ReleaseAsset> assets, String name) {
    for (final asset in assets) {
      if (asset.name == name) {
        return asset;
      }
    }
    return null;
  }

  /// 下载 `hashes.sha256` 并返回 [targetName] 对应的 sha256。
  Future<String?> _loadExpectedHash(
    ReleaseAsset checksumAsset,
    String targetName,
  ) async {
    final downloadDir = _tempDirectory ?? Directory.systemTemp.path;
    final path = '$downloadDir/$checksumAssetName';
    final file = await _downloader.downloadToFile(
      url: checksumAsset.browserDownloadUrl,
      destinationPath: path,
    );
    final content = await file.readAsString();
    return parseHashesFile(content)[targetName];
  }

  Future<bool> _install(
    AppInstallation installation,
    File downloadedFile,
  ) async {
    switch (installation.kind) {
      case AppInstallationKind.packageManagerDpkg:
        return _runPrivilegedInstall(
          ['pkexec', 'dpkg', '-i', downloadedFile.path],
        );
      case AppInstallationKind.packageManagerRpm:
        return _runPrivilegedInstall(
          ['pkexec', 'rpm', '-Uvh', downloadedFile.path],
        );
      case AppInstallationKind.appImage:
        final oldPath = installation.appImagePath;
        if (oldPath == null || oldPath.trim().isEmpty) {
          return false;
        }
        return _replaceAppImage(downloadedFile, oldPath);
      case AppInstallationKind.manual:
        return false;
    }
  }

  Future<bool> _runPrivilegedInstall(List<String> command) async {
    final result = await _shellExecutor.run(
      command,
      timeout: const Duration(minutes: 30),
    );
    if (!result.success) {
      AppLogger.warning(
        '[AppSelfUpdate] 安装命令失败: ${command.join(' ')} -> ${result.primaryMessage}',
      );
    }
    return result.success;
  }

  /// 清理下载的安装包与 `hashes.sha256` 临时文件。
  ///
  /// AppImage 场景安装包已在替换时删除，这里删除不存在的文件会被忽略。
  Future<void> _cleanupDownloadedFiles(
    File packageFile,
    ReleaseAsset checksumAsset,
  ) async {
    final downloadDir = _tempDirectory ?? Directory.systemTemp.path;
    final targets = <String>{
      packageFile.path,
      '$downloadDir/$checksumAssetName',
    };
    for (final path in targets) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException catch (e) {
        AppLogger.warning('[AppSelfUpdate] 清理临时文件失败 $path: $e');
      }
    }
  }

  /// AppImage 原地替换：先尝试同目录 copy + rename（用户目录可写时免 root），
  /// 失败回退 `pkexec install`。
  Future<bool> _replaceAppImage(File newFile, String oldPath) async {
    try {
      final newTmpPath = '$oldPath.new';
      await newFile.copy(newTmpPath);
      await File(newTmpPath).rename(oldPath);
      try {
        await newFile.delete();
      } on FileSystemException {
        // 清理失败不影响结果。
      }
      AppLogger.info('[AppSelfUpdate] AppImage 已原地替换: $oldPath');
      return true;
    } on FileSystemException catch (e) {
      AppLogger.warning(
        '[AppSelfUpdate] 直接替换 AppImage 失败，回退 pkexec: $e',
      );
    }
    final result = await _shellExecutor.run(
      ['pkexec', 'install', '-m', '755', newFile.path, oldPath],
      timeout: const Duration(minutes: 5),
    );
    return result.success;
  }

  Future<void> _restart(AppInstallation installation) async {
    final executable = switch (installation.kind) {
      AppInstallationKind.appImage => installation.appImagePath,
      _ => packagedExecutablePath,
    };
    if (executable == null || executable.trim().isEmpty) {
      return;
    }
    await _restartApp(executable);
    await _closeApp();
  }
}

/// 解析 `hashes.sha256` 内容（sha256sum 文本格式 `<hash>  <filename>`）。
///
/// 只接受 64 位十六进制摘要行，其余内容忽略，避免把说明文字误当校验条目。
/// 返回 filename → hash 映射。
Map<String, String> parseHashesFile(String content) {
  final result = <String, String>{};
  for (final line in const LineSplitter().convert(content)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    // sha256sum 文本模式：`<hash>  <filename>` 或 `<hash> *<filename>`。
    final separator = trimmed.indexOf(' ');
    if (separator <= 0) {
      continue;
    }
    var filename = trimmed.substring(separator + 1).trim();
    if (filename.startsWith('*')) {
      filename = filename.substring(1);
    }
    final hash = trimmed.substring(0, separator).trim();
    if (!_isHexDigest64(hash)) {
      continue;
    }
    result[filename] = hash;
  }
  return result;
}

/// 判断字符串是否为 64 位十六进制摘要。
bool _isHexDigest64(String value) {
  if (value.length != 64) {
    return false;
  }
  for (final code in value.codeUnits) {
    final isDigit = code >= 0x30 && code <= 0x39;
    final isLowerHex = code >= 0x61 && code <= 0x66;
    final isUpperHex = code >= 0x41 && code <= 0x46;
    if (!isDigit && !isLowerHex && !isUpperHex) {
      return false;
    }
  }
  return true;
}

/// 大小写不敏感比较两个十六进制 sha256。
bool _hashEquals(String actual, String expected) {
  return actual.toLowerCase() == expected.toLowerCase();
}
