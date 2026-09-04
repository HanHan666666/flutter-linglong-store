/// 特权 helper 的统一定位入口：bundle 内路径解析、FUSE 检测与暂存（docs/47 §5.2）。
///
/// 所有运行形态（DEB/RPM/AUR/Copr、解压 bundle、开发构建、AppImage）都必须
/// 经由本类取得 pkexec 要执行的 helper 路径；启动方式的唯一分支依据是
/// bundle 所在文件系统是否为 FUSE，不读取 `APPIMAGE`/`APPDIR`、不查询包管理器、
/// 不区分 Debug/Release（§5.2）。
///
/// FUSE 形态的暂存创建与回收完全由本类（GUI 侧）负责，helper 不感知暂存概念
/// （§5.2.1 第 5 步）；每次准备启动前先清扫上次遗留目录，兜住 GUI 在认证期间
/// 被 SIGKILL 的场景。
library;

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../../logging/app_logger.dart';
import '../../storage/app_xdg_paths.dart';
import 'privileged_helper_exception.dart';

/// bundle 内 helper 的固定相对位置（相对 `Platform.resolvedExecutable`）。
const String _helperRelativePath = 'libexec/linglong_store_helper';

/// 暂存根目录名，位于应用运行时目录（`$XDG_RUNTIME_DIR/<app-id>/`）下。
const String _stagingRootName = 'helper-staging';

/// 一次启动前解析出的 helper 执行路径与配套清理职责。
class PreparedHelperPath {
  PreparedHelperPath._({
    required this.path,
    required this.staged,
    this.stagingFile,
    this.stagingDir,
  });

  /// 交给 pkexec 执行的绝对路径：非 FUSE 形态为 bundle 内路径，FUSE 形态为
  /// 一次性暂存副本路径（§10.3：两者业务语义完全一致）。
  final String path;

  /// 是否走了 FUSE 暂存分支。
  final bool staged;

  /// 暂存文件与其父目录；直启形态为 null。
  final String? stagingFile;
  final String? stagingDir;

  bool _released = false;

  /// 幂等清理暂存副本。
  ///
  /// 调用时机（§5.2.1 第 5 步）：收到 `ready` 后立即调用（pkexec 认证期间
  /// 路径必须存在，删除不能早于 ready；unlink 已运行进程的 exe 无害）；
  /// pkexec 启动失败、授权取消（126）、helper 退出等失败路径同样调用。
  /// 直启形态是空操作。清理失败只记录日志，不影响业务流程。
  Future<void> release() async {
    if (!staged || _released) {
      return;
    }
    _released = true;
    final file = stagingFile;
    final dir = stagingDir;
    try {
      if (file != null) {
        final f = File(file);
        if (await f.exists()) {
          await f.delete();
        }
      }
      if (dir != null) {
        final d = Directory(dir);
        if (await d.exists()) {
          // 只删除本次创建的随机子目录；目录非空（不应发生）时保留，
          // 交由下次启动的清扫兜底。
          final children = await d.list().length;
          if (children == 0) {
            await d.delete();
          }
        }
      }
    } catch (error, stackTrace) {
      AppLogger.warning('特权 helper 暂存清理失败（残留由下次启动清扫）', error,
          stackTrace);
    }
  }
}

/// 所有运行形态唯一的 helper 定位与暂存入口。
class PrivilegedHelperBinary {
  /// 创建 preparer。
  ///
  /// [mountinfoReader] 与 [appRuntimeDirResolver] 为测试注入点：默认读取
  /// `/proc/self/mountinfo` 与 `$XDG_RUNTIME_DIR/<app-id>/`；生产代码不需要
  /// 显式传参。
  PrivilegedHelperBinary({
    String Function()? mountinfoReader,
    String? Function()? appRuntimeDirResolver,
    String? bundleHelperPathOverride,
  }) : _mountinfoReader = mountinfoReader ?? _readMountinfo,
       _appRuntimeDirResolver =
           appRuntimeDirResolver ?? AppXdgPaths.resolveAppRuntimeDirectory,
       _bundleHelperPathOverride = bundleHelperPathOverride;

  final String Function() _mountinfoReader;
  final String? Function() _appRuntimeDirResolver;
  final String? _bundleHelperPathOverride;

  /// 解析本次启动要执行的 helper 路径。
  ///
  /// 抛出：
  /// - [PrivilegedHelperUnavailableException]：bundle 内 helper 缺失、FUSE 形态
  ///   下暂存根不可用或复制失败。统一按 §10.3“授权组件不可用”处理。
  Future<PreparedHelperPath> prepare() async {
    final bundlePath = _bundleHelperPathOverride ?? _defaultBundleHelperPath();

    if (!File(bundlePath).existsSync()) {
      throw PrivilegedHelperUnavailableException(
        'privileged helper binary not found: $bundlePath',
      );
    }

    // 无论本次是否走暂存分支，都先清扫上次遗留；兜住 GUI 在认证期间被
    // SIGKILL 的场景（§5.2.1 第 5 步）。目录不存在时空操作。
    await sweepStagingRoot();

    final isFuse = _isBundleOnFuse(bundlePath);
    if (!isFuse) {
      return PreparedHelperPath._(path: bundlePath, staged: false);
    }

    final stagedPath = await _createStagingCopy(bundlePath);
    AppLogger.info('特权 helper 位于 FUSE 文件系统，已创建暂存副本: '
        '${stagedPath.stagingFile}');
    return stagedPath;
  }

  /// 清扫暂存根中上次遗留的目录。
  ///
  /// 范围只限本应用暂存根（`$XDG_RUNTIME_DIR/<app-id>/helper-staging/`），不扫描
  /// `$XDG_RUNTIME_DIR` 全局；残留上界因此有限（该目录也随会话销毁）。
  /// 遗留目录中可能仍有上次 GUI 被杀后存活的 helper：unlink 其 exe 无害，
  /// 随机目录名也保证不会与本次新副本冲突。
  Future<void> sweepStagingRoot() async {
    final root = _stagingRoot();
    if (root == null) {
      return;
    }
    final dir = Directory(root);
    if (!dir.existsSync()) {
      return;
    }
    try {
      await for (final entity in dir.list()) {
        try {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        } catch (error) {
          AppLogger.warning('清扫暂存条目失败，跳过: ${entity.path}', error);
        }
      }
    } catch (error) {
      AppLogger.warning('清扫暂存根失败: $root', error);
    }
  }

  /// bundle 内 helper 的默认绝对路径：以 `Platform.resolvedExecutable` 所在
  /// bundle 为唯一基准，不接受环境变量或调用方指定其他路径（§5.2.1 第 1 步）。
  String _defaultBundleHelperPath() {
    return p.join(
      p.dirname(Platform.resolvedExecutable),
      _helperRelativePath,
    );
  }

  String? _stagingRoot() {
    final appRuntimeDir = _appRuntimeDirResolver();
    if (appRuntimeDir == null || appRuntimeDir.isEmpty) {
      return null;
    }
    return p.join(appRuntimeDir, _stagingRootName);
  }

  bool _isBundleOnFuse(String bundlePath) {
    String mountinfo;
    try {
      mountinfo = _mountinfoReader();
    } catch (error) {
      // 读不到 mountinfo 时保守视为 FUSE（§5.2.1 第 2 步）。
      AppLogger.warning('读取 /proc/self/mountinfo 失败，保守按 FUSE 暂存', error);
      return true;
    }
    return isPathOnFuseFileSystem(bundlePath, mountinfo);
  }

  /// 创建一次性暂存副本：随机 0700 子目录 + 0500 独占文件（§5.2.1 第 4 步）。
  Future<PreparedHelperPath> _createStagingCopy(String bundlePath) async {
    final root = _stagingRoot();
    if (root == null) {
      throw const PrivilegedHelperUnavailableException(
        'XDG_RUNTIME_DIR 不可用，无法为 FUSE 形态创建 helper 暂存',
      );
    }
    final rootDir = Directory(root);
    if (!rootDir.existsSync()) {
      // 暂存根随应用运行时目录创建；权限依赖 0700 父目录（systemd 保证）。
      await rootDir.create(recursive: true);
    }

    final random = Random.secure();
    Directory? stagingDir;
    for (var attempt = 0; attempt < 3; attempt++) {
      final candidate = Directory(
        p.join(root, _randomName(random)),
      );
      if (!candidate.existsSync()) {
        await candidate.create();
        stagingDir = candidate;
        break;
      }
    }
    if (stagingDir == null) {
      throw const PrivilegedHelperUnavailableException(
        '无法创建不重复的 helper 暂存目录',
      );
    }
    final dirPath = stagingDir.path;

    try {
      // 子目录与文件权限用 chmod 显式确定：Dart 创建受 umask 影响，而暂存
      // 目录必须固定 0700、副本固定 0500。chmod 以当前用户身份执行；同 UID
      // 环境被篡改的风险按 §5.2.2 已接受处理。
      await _chmod('700', dirPath);

      final target = p.join(dirPath, 'linglong_store_helper');
      final source = File(bundlePath);
      final sourceLength = await source.length();
      await source.copy(target);
      final copiedLength = await File(target).length();
      if (copiedLength != sourceLength) {
        throw const PrivilegedHelperUnavailableException(
          'helper 暂存副本长度不一致',
        );
      }
      await _chmod('500', target);

      return PreparedHelperPath._(
        path: target,
        staged: true,
        stagingFile: target,
        stagingDir: dirPath,
      );
    } catch (error) {
      // 创建失败路径的幂等清理（§11 第 14 条）。
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // 清理失败交给下次启动清扫兜底。
      }
      if (error is PrivilegedHelperException) {
        rethrow;
      }
      throw PrivilegedHelperUnavailableException('helper 暂存创建失败: $error');
    }
  }

  Future<void> _chmod(String mode, String target) async {
    final result = await Process.run('chmod', [mode, target]);
    if (result.exitCode != 0) {
      throw PrivilegedHelperUnavailableException(
        'chmod $mode $target 失败: ${result.stderr}',
      );
    }
  }

  static String _randomName(Random random) {
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _readMountinfo() {
    return File('/proc/self/mountinfo').readAsStringSync();
  }
}

// ---------------------------------------------------------------------------
// mountinfo 解析（纯函数，便于单测覆盖 §13.2 的全部边界）
// ---------------------------------------------------------------------------

/// 判断 [absolutePath] 是否位于 FUSE 文件系统。
///
/// 解析 [mountinfoContent]（`/proc/self/mountinfo` 格式）：取包含该路径的
/// 最长挂载点（前缀按路径分量边界匹配），fstype 为 `fuse`、`fuseblk` 或以
/// `fuse.` 开头即视为 FUSE。
///
/// 文件内容为空、无匹配挂载点或解析异常时一律保守返回 true：误判直启会让
/// 用户走完授权才在执行处失败，而多暂存一次只是冗余复制（§5.2.1 第 2 步）。
bool isPathOnFuseFileSystem(String absolutePath, String mountinfoContent) {
  try {
    final mountpoint = _longestCoveringMountPoint(absolutePath, mountinfoContent);
    if (mountpoint == null) {
      return true;
    }
    return isFuseFileSystemType(mountpoint.fstype);
  } catch (_) {
    return true;
  }
}

/// fstype 是否属于 FUSE 家族。
bool isFuseFileSystemType(String fstype) {
  return fstype == 'fuse' || fstype == 'fuseblk' || fstype.startsWith('fuse.');
}

class _MountEntry {
  const _MountEntry({required this.mountPoint, required this.fstype});

  final String mountPoint;
  final String fstype;
}

/// 取包含 [absolutePath] 的最长挂载点。
///
/// 匹配按路径分量边界：目标等于挂载点，或以“挂载点 + `/`”开头，避免
/// `/tmp/appimage` 被挂载点 `/tmp/app` 错误覆盖。
_MountEntry? _longestCoveringMountPoint(
  String absolutePath,
  String mountinfoContent,
) {
  _MountEntry? best;
  for (final line in mountinfoContent.split('\n')) {
    if (line.trim().isEmpty) {
      continue;
    }
    final entry = _parseMountinfoLine(line);
    if (entry == null) {
      continue;
    }
    final mountPoint = entry.mountPoint;
    // 根挂载点 "/" 需要单独处理：字符串拼接 "/" + "/" 无法匹配任何绝对路径。
    final covers = mountPoint == '/'
        ? absolutePath.startsWith('/')
        : absolutePath == mountPoint || absolutePath.startsWith('$mountPoint/');
    if (covers &&
        (best == null || mountPoint.length > best.mountPoint.length)) {
      best = entry;
    }
  }
  return best;
}

/// 解析单行 mountinfo。
///
/// 格式：`id parent major:minor root mountpoint options... - fstype source ...`；
/// mountpoint 是第 5 个字段，fstype 位于 `-` 分隔符后的第一个字段。
/// mountpoint 中的空格等字符以八进制转义（`\040` 空格、`\011` 制表、
/// `\012` 换行、`\134` 反斜杠），必须反转义后再匹配。
_MountEntry? _parseMountinfoLine(String line) {
  final parts = line.split(' ');
  if (parts.length < 7) {
    return null;
  }
  final separatorIndex = parts.indexOf('-');
  if (separatorIndex < 0 || separatorIndex + 1 >= parts.length) {
    return null;
  }
  return _MountEntry(
    mountPoint: _unescapeMountinfoField(parts[4]),
    fstype: _unescapeMountinfoField(parts[separatorIndex + 1]),
  );
}

/// 反转义 mountinfo 字段中的八进制转义序列。
String _unescapeMountinfoField(String field) {
  if (!field.contains(_backslash)) {
    return field;
  }
  final buffer = StringBuffer();
  for (var i = 0; i < field.length; i++) {
    final char = field[i];
    if (char == _backslash && i + 4 <= field.length) {
      final octal = field.substring(i + 1, i + 4);
      final code = int.tryParse(octal, radix: 8);
      if (code != null && code >= 0 && code <= 255) {
        buffer.writeCharCode(code);
        i += 3;
        continue;
      }
    }
    buffer.write(char);
  }
  return buffer.toString();
}

/// Dart 原始字符串不能以反斜杠结尾，这里用具名字符常量表达。
const String _backslash = '\\';
