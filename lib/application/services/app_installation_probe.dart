import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/app_self_update.dart';
import '../../domain/models/linux_distribution.dart';
import 'linux_distribution_resolver.dart';

/// 应用安装方式检测服务。
///
/// 两步确认：
/// 1. 读取 `/etc/os-release` 检测发行版，得到系统包管理器（dpkg / rpm）；
/// 2. 去对应包管理器查询是否已安装本包（`linglong-store`）。
///
/// 包管理器查不到时，若当前以 AppImage 方式运行（`APPIMAGE` 环境变量非空且
/// 文件存在），则返回 AppImage 安装方式，可直接替换磁盘上的 AppImage 文件。
/// 其余情况视为手动安装（tar.gz 解压等），无法自动更新。
class AppInstallationProbe {
  AppInstallationProbe({
    LinuxDistributionResolver? distributionResolver,
    ShellCommandExecutor? shellExecutor,
    Map<String, String>? environment,
    Future<Map<String, String>?> Function()? readOsRelease,
    Future<bool> Function(String path)? fileExists,
  }) : _distributionResolver = distributionResolver ?? const LinuxDistributionResolver(),
       _shellExecutor = shellExecutor ?? ShellCommandExecutor(),
       _environment = environment ?? Platform.environment,
       _readOsRelease = readOsRelease,
       _fileExists = fileExists ?? ((path) async => File(path).exists());

  /// 自更新升级目标包名（与 DEB/RPM 包名一致）。
  static const String packageName = 'linglong-store';

  final LinuxDistributionResolver _distributionResolver;
  final ShellCommandExecutor _shellExecutor;
  final Map<String, String> _environment;
  final Future<Map<String, String>?> Function()? _readOsRelease;
  final Future<bool> Function(String path) _fileExists;

  /// 检测当前应用的安装方式。
  Future<AppInstallation> detect() async {
    final osRelease = await _loadOsRelease();
    final distribution = _distributionResolver.resolve(osRelease);

    switch (distribution.packageManager) {
      case LinuxPackageManager.dpkg:
        final installed = await _isDpkgInstalled();
        if (installed) {
          return const AppInstallation(
            kind: AppInstallationKind.packageManagerDpkg,
            managerLabel: 'dpkg',
          );
        }
      case LinuxPackageManager.rpm:
        final installed = await _isRpmInstalled();
        if (installed) {
          return const AppInstallation(
            kind: AppInstallationKind.packageManagerRpm,
            managerLabel: 'rpm',
          );
        }
      case null:
        break;
    }

    // 包管理器未识别或未查到本包：AppImage 兜底。
    final appImagePath = _environment['APPIMAGE'];
    if (appImagePath != null && appImagePath.trim().isNotEmpty) {
      final exists = await _fileExists(appImagePath);
      if (exists) {
        AppLogger.info('[AppInstallationProbe] 检测到 AppImage 运行方式: $appImagePath');
        return AppInstallation(
          kind: AppInstallationKind.appImage,
          appImagePath: appImagePath,
          managerLabel: 'appimage',
        );
      }
    }

    return const AppInstallation(kind: AppInstallationKind.manual);
  }

  Future<Map<String, String>?> _loadOsRelease() async {
    if (_readOsRelease != null) {
      return _readOsRelease();
    }
    try {
      final file = File('/etc/os-release');
      if (!await file.exists()) {
        return null;
      }
      return parseOsRelease(await file.readAsString());
    } on FileSystemException catch (e) {
      AppLogger.warning('[AppInstallationProbe] 读取 /etc/os-release 失败: $e');
      return null;
    }
  }

  Future<bool> _isDpkgInstalled() async {
    return _queryPackage(['dpkg', '-s', packageName]);
  }

  Future<bool> _isRpmInstalled() async {
    return _queryPackage(['rpm', '-q', packageName]);
  }

  Future<bool> _queryPackage(List<String> command) async {
    try {
      final result = await _shellExecutor.run(
        command,
        timeout: const Duration(seconds: 10),
      );
      return result.success;
    } catch (e) {
      // 命令不存在或执行异常视为未安装；同时捕获 Error 与 Exception，
      // 避免包管理器缺失等异常冒泡打断安装方式检测。
      AppLogger.warning('[AppInstallationProbe] 查询包失败 ${command.first}: $e');
      return false;
    }
  }
}

/// 解析 `/etc/os-release` 内容为键值映射。
///
/// 支持 `KEY=value` 与 `KEY="value"` 两种写法，忽略注释与空行。
Map<String, String> parseOsRelease(String content) {
  final result = <String, String>{};
  for (final rawLine in const LineSplitter().convert(content)) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final separator = line.indexOf('=');
    if (separator <= 0) {
      continue;
    }
    final key = line.substring(0, separator).trim();
    var value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) {
      result[key] = value;
    }
  }
  return result;
}
