/// Linux 自更新安装适配器。
///
/// DEB、RPM 与 AppImage 的系统差异被隔离在三个适配器中；Application 只按
/// 当前安装身份选择适配器，不感知 pkexec、chmod 或原子文件替换细节。
library;

import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/app_self_update.dart';
import '../../domain/repositories/app_self_update_gateways.dart';

/// DEB 安装适配器。
class DpkgAppUpdateInstaller implements AppUpdateInstaller {
  /// 创建 DEB 安装适配器。
  const DpkgAppUpdateInstaller(this._executor);

  final ShellCommandExecutor _executor;

  @override
  AppInstallationKind get installationKind =>
      AppInstallationKind.packageManagerDpkg;

  @override
  Future<void> install({
    required AppInstallation installation,
    required String packagePath,
  }) {
    return _runPrivilegedInstall(_executor, [
      'pkexec',
      'dpkg',
      '-i',
      packagePath,
    ]);
  }
}

/// RPM 安装适配器。
class RpmAppUpdateInstaller implements AppUpdateInstaller {
  /// 创建 RPM 安装适配器。
  const RpmAppUpdateInstaller(this._executor);

  final ShellCommandExecutor _executor;

  @override
  AppInstallationKind get installationKind =>
      AppInstallationKind.packageManagerRpm;

  @override
  Future<void> install({
    required AppInstallation installation,
    required String packagePath,
  }) {
    return _runPrivilegedInstall(_executor, [
      'pkexec',
      'rpm',
      '-Uvh',
      packagePath,
    ]);
  }
}

/// AppImage 原地替换适配器。
class AppImageAppUpdateInstaller implements AppUpdateInstaller {
  /// 创建 AppImage 安装适配器。
  const AppImageAppUpdateInstaller(this._executor);

  final ShellCommandExecutor _executor;

  @override
  AppInstallationKind get installationKind => AppInstallationKind.appImage;

  @override
  Future<void> install({
    required AppInstallation installation,
    required String packagePath,
  }) async {
    final oldPath = installation.appImagePath;
    if (oldPath == null ||
        oldPath.trim().isEmpty ||
        !await File(oldPath).exists()) {
      throw StateError('当前 AppImage 文件已经不存在');
    }

    final stagedPath = '$oldPath.new';
    await _deleteIfExists(stagedPath);
    try {
      await File(packagePath).copy(stagedPath);
      final chmodResult = await _executor.run([
        'chmod',
        '755',
        stagedPath,
      ], timeout: const Duration(seconds: 10));
      if (!chmodResult.success) {
        throw FileSystemException('无法设置 AppImage 执行权限', stagedPath);
      }
      await File(stagedPath).rename(oldPath);
      AppLogger.info('[AppSelfUpdate] AppImage 已安全替换: $oldPath');
      return;
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        '[AppSelfUpdate] 当前用户无法替换 AppImage，回退 pkexec',
        error,
        stackTrace,
      );
      await _deleteIfExists(stagedPath);
    }

    await _runPrivilegedInstall(_executor, [
      'pkexec',
      'install',
      '-m',
      '755',
      packagePath,
      oldPath,
    ]);
  }
}

Future<void> _runPrivilegedInstall(
  ShellCommandExecutor executor,
  List<String> command,
) async {
  final result = await executor.run(
    command,
    timeout: const Duration(minutes: 30),
  );
  if (result.success) {
    return;
  }
  AppLogger.warning(
    '[AppSelfUpdate] 安装命令失败: ${command.first} -> ${result.primaryMessage}',
  );
  throw StateError('安装失败: ${result.primaryMessage}');
}

Future<void> _deleteIfExists(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
