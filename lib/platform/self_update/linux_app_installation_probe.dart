/// Linux 当前进程安装身份探测实现。
///
/// 探测顺序以“当前实际运行来源”为准：AppImage 环境证据优先，其次查询当前
/// 可执行文件在 dpkg/RPM/pacman 数据库中的归属。系统里仅仅残留同名包不会
/// 改变结果。
///
/// 安全约束（docs/51）：包管理器归属判定是特权 helper 的唯一信任条件，所有
/// 查询命令固定绝对路径并显式指定包数据库目录，防止同 UID 进程通过 PATH
/// 垫片（如 `~/.local/bin/dpkg-query`）或 `DPKG_ADMINDIR` / rpm 宏等环境
/// 重定向把探测指向伪造数据库；命令或目录不存在时按未命中处理，失败方向
/// 是“回退普通用户直连”（安全方向）。
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

  // 探测命令与包数据库位置：全部使用绝对路径/显式参数，不接受 PATH 与环境
  // 变量重定向（docs/51 复核加固）。非对应发行版上命令不存在即按未命中处理。
  static const String _dpkgQueryBinary = '/usr/bin/dpkg-query';
  static const String _dpkgAdminDir = '/var/lib/dpkg';
  static const String _rpmBinary = '/usr/bin/rpm';
  static const String _rpmDbPath = '/var/lib/rpm';
  static const String _pacmanBinary = '/usr/bin/pacman';
  static const String _pacmanDbPath = '/var/lib/pacman';

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
    final stopwatch = Stopwatch()..start();
    String? matched;
    if (await _isManagedByAnyDpkgPackage(executable)) {
      matched = 'dpkg';
    } else if (await _isManagedByAnyRpmPackage(executable)) {
      matched = 'rpm';
    } else if (await _isManagedByAnyPacmanPackage(executable)) {
      matched = 'pacman';
    }
    stopwatch.stop();
    // 记录命中来源与耗时：首个安装任务会同步等待本判定，便于真机诊断
    // 首次任务延迟来源（docs/51 §4.5）。
    AppLogger.info(
      '[AppInstallationProbe] bundle 包管理器归属判定: '
      'manager=${matched ?? 'none'}, 耗时=${stopwatch.elapsedMilliseconds}ms',
    );
    return matched != null;
  }

  /// dpkg 数据库中是否存在拥有该路径的软件包（不限定包名）。
  ///
  /// 不校验包名：威胁模型是同 UID 进程，任何由 root 级包管理器落盘的文件都
  /// 不具备被其替换的条件；包名白名单会随 AUR 命名（-bin/nightly）与未来
  /// 改名漂移。输出形态包括 `pkg[:arch]: /path` 与 `diversion by ... from: /path`；
  /// 统一按最后一个 `: ` 分隔符取路径精确比对——两类记录都表示 dpkg 管理该
  /// 路径，均按可信处理；查询固定 `LC_ALL=C`，输出不随系统语言变化。
  Future<bool> _isManagedByAnyDpkgPackage(String executable) async {
    final result = await _query([
      _dpkgQueryBinary,
      '--admindir',
      _dpkgAdminDir,
      '-S',
      executable,
    ]);
    if (result == null || !result.success) {
      return false;
    }
    for (final line in const LineSplitter().convert(result.stdout)) {
      final separator = line.lastIndexOf(': ');
      if (separator >= 0 &&
          line.substring(separator + 2).trim() == executable) {
        return true;
      }
    }
    return false;
  }

  /// rpm 数据库中是否存在拥有该路径的软件包（退出码 0 即命中）。
  Future<bool> _isManagedByAnyRpmPackage(String executable) async {
    final result = await _query([
      _rpmBinary,
      '--dbpath',
      _rpmDbPath,
      '-qf',
      executable,
    ]);
    return result != null && result.success;
  }

  /// pacman 数据库中是否存在拥有该路径的软件包（退出码 0 即命中）。
  Future<bool> _isManagedByAnyPacmanPackage(String executable) async {
    final result = await _query([
      _pacmanBinary,
      '--dbpath',
      _pacmanDbPath,
      '-Qo',
      executable,
    ]);
    return result != null && result.success;
  }

  Future<bool> _isOwnedByDpkg(String executable) async {
    final result = await _query([
      _dpkgQueryBinary,
      '--admindir',
      _dpkgAdminDir,
      '-S',
      executable,
    ]);
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
      _rpmBinary,
      '--dbpath',
      _rpmDbPath,
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
        // 固定 C locale：dpkg 的归属输出（含 diversion 行）与错误消息不随系统
        // 语言漂移，保证归属解析在不同 LANG 下行为一致（docs/51 §4.1）。
        environment: const {'LC_ALL': 'C'},
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
