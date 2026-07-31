/// Linux 当前进程安装身份探测实现。
///
/// 探测顺序以“当前实际运行来源”为准：AppImage 环境证据优先，其次查询当前
/// 可执行文件在 dpkg/RPM 数据库中的归属。系统里仅仅残留同名包不会改变结果。
library;

import 'dart:convert';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/app_self_update.dart';
import '../../domain/repositories/app_self_update_gateways.dart';

/// Linux 安装身份探测器。
class LinuxAppInstallationProbe implements AppInstallationProbe {
  /// 创建可注入系统边界的探测器。
  LinuxAppInstallationProbe({
    required ShellCommandExecutor shellExecutor,
    Map<String, String>? environment,
    String? resolvedExecutable,
    Future<bool> Function(String path)? fileExists,
  }) : _shellExecutor = shellExecutor,
       _environment = environment ?? Platform.environment,
       _resolvedExecutable = resolvedExecutable ?? Platform.resolvedExecutable,
       _fileExists = fileExists ?? ((path) async => File(path).exists());

  /// 正式 DEB/RPM 包名。
  static const String packageName = 'linglong-store';

  final ShellCommandExecutor _shellExecutor;
  final Map<String, String> _environment;
  final String _resolvedExecutable;
  final Future<bool> Function(String path) _fileExists;

  @override
  Future<AppInstallation> detect() async {
    final appImagePath = _environment['APPIMAGE']?.trim();
    if (appImagePath != null &&
        appImagePath.isNotEmpty &&
        await _fileExists(appImagePath)) {
      AppLogger.info('[AppInstallationProbe] 当前进程来自 AppImage: $appImagePath');
      return AppInstallation(
        kind: AppInstallationKind.appImage,
        appImagePath: appImagePath,
      );
    }

    if (_resolvedExecutable.trim().isEmpty) {
      return const AppInstallation(kind: AppInstallationKind.manual);
    }
    if (await _isOwnedByDpkg(_resolvedExecutable)) {
      return const AppInstallation(
        kind: AppInstallationKind.packageManagerDpkg,
      );
    }
    if (await _isOwnedByRpm(_resolvedExecutable)) {
      return const AppInstallation(kind: AppInstallationKind.packageManagerRpm);
    }
    return const AppInstallation(kind: AppInstallationKind.manual);
  }

  Future<bool> _isOwnedByDpkg(String executable) async {
    final result = await _query(['dpkg-query', '-S', executable]);
    if (result == null || !result.success) {
      return false;
    }
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.trimLeft().startsWith('$packageName:')) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _isOwnedByRpm(String executable) async {
    final result = await _query([
      'rpm',
      '-qf',
      '--qf',
      '%{NAME}\n',
      executable,
    ]);
    return result != null &&
        result.success &&
        result.stdout.trim() == packageName;
  }

  Future<ShellCommandResult?> _query(List<String> command) async {
    try {
      return await _shellExecutor.run(
        command,
        timeout: const Duration(seconds: 10),
      );
    } catch (error, stackTrace) {
      // 某一包管理器不存在只代表当前身份不属于它，继续尝试下一种身份。
      AppLogger.warning(
        '[AppInstallationProbe] 查询当前可执行文件归属失败: ${command.first}',
        error,
        stackTrace,
      );
      return null;
    }
  }
}
