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

  /// docs/51：判断当前运行 bundle 是否由系统包管理器（dpkg/rpm/pacman）安装。
  ///
  /// 依次尝试当前系统可能存在的包管理器；对不存在的命令 [_query] 返回 null，
  /// 按未命中处理并继续（生产机器上通常只会命中一种）。任一命中即返回 true，
  /// 全部未命中或探测异常返回 false——调用方在 false 时必须回退普通用户直连
  /// 路径（无论失败原因是什么，都不得当作来源可信）。
  @override
  Future<bool> isManagedBySystemPackageManager() async {
    final executable = _resolvedExecutable.trim();
    if (executable.isEmpty) {
      return false;
    }
    if (await _isManagedByAnyDpkgPackage(executable)) {
      AppLogger.info('[AppInstallationProbe] bundle 由 dpkg 管理: $executable');
      return true;
    }
    if (await _isManagedByAnyRpmPackage(executable)) {
      AppLogger.info('[AppInstallationProbe] bundle 由 rpm 管理: $executable');
      return true;
    }
    if (await _isManagedByAnyPacmanPackage(executable)) {
      AppLogger.info('[AppInstallationProbe] bundle 由 pacman 管理: $executable');
      return true;
    }
    AppLogger.info('[AppInstallationProbe] bundle 无包管理器归属: $executable');
    return false;
  }

  /// dpkg 数据库中是否存在拥有该路径的软件包（不限定包名）。
  ///
  /// 不校验包名：威胁模型是同 UID 进程，任何由 root 级包管理器落盘的文件都
  /// 不具备被其替换的条件；包名白名单会随 AUR 命名（-bin/nightly）与未来
  /// 改名漂移。输出行为 `pkg[:arch]: /path`，按路径后缀匹配即可。
  Future<bool> _isManagedByAnyDpkgPackage(String executable) async {
    final result = await _query(['dpkg-query', '-S', executable]);
    if (result == null || !result.success) {
      return false;
    }
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.trim().endsWith(executable)) {
        return true;
      }
    }
    return false;
  }

  /// rpm 数据库中是否存在拥有该路径的软件包（退出码 0 即命中）。
  Future<bool> _isManagedByAnyRpmPackage(String executable) async {
    final result = await _query(['rpm', '-qf', executable]);
    return result != null && result.success;
  }

  /// pacman 数据库中是否存在拥有该路径的软件包（退出码 0 即命中）。
  Future<bool> _isManagedByAnyPacmanPackage(String executable) async {
    final result = await _query(['pacman', '-Qo', executable]);
    return result != null && result.success;
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
