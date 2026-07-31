/// 遵循 XDG 的一次性更新下载工作区。
///
/// 每次任务在 `$XDG_CACHE_HOME/<app-id>/self-update/` 下创建隔离目录，下载先写
/// `.part` 再原子改名；无论成功、失败或取消，Controller 调用链最终都会清理。
library;

import 'dart:io';

import 'package:path/path.dart' as path;

import '../../core/platform/file_downloader.dart';
import '../../core/storage/app_xdg_paths.dart';
import '../../domain/models/app_self_update.dart';
import '../../domain/repositories/app_self_update_gateways.dart';

/// XDG 更新工作区工厂。
class XdgAppUpdateWorkspaceFactory implements AppUpdateWorkspaceFactory {
  /// 创建正式工作区工厂。
  XdgAppUpdateWorkspaceFactory({
    required FileDownloader downloader,
    Map<String, String>? environment,
  }) : _downloader = downloader,
       _environment = environment;

  final FileDownloader _downloader;
  final Map<String, String>? _environment;

  @override
  Future<AppUpdateWorkspace> create() async {
    final appCache = AppXdgPaths.resolveAppCacheDirectory(
      environment: _environment,
    );
    if (appCache == null) {
      throw StateError('无法解析 XDG 应用缓存目录');
    }
    final root = Directory(path.join(appCache, 'self-update'));
    await root.create(recursive: true);
    final sessionDirectory = await root.createTemp('session-');
    return _XdgAppUpdateWorkspace(
      directory: sessionDirectory,
      downloader: _downloader,
    );
  }
}

class _XdgAppUpdateWorkspace implements AppUpdateWorkspace {
  _XdgAppUpdateWorkspace({
    required Directory directory,
    required FileDownloader downloader,
  }) : _directory = directory,
       _downloader = downloader;

  final Directory _directory;
  final FileDownloader _downloader;
  bool _disposed = false;

  @override
  Future<String> download({
    required String url,
    required String fileName,
    required void Function(int received, int total) onProgress,
    Future<void>? cancellationSignal,
  }) async {
    _ensureActive();
    final safeName = path.basename(fileName);
    if (safeName != fileName || safeName.isEmpty) {
      throw const FormatException('更新资产文件名无效');
    }
    final destinationPath = path.join(_directory.path, safeName);
    final partialPath = '$destinationPath.part';
    try {
      await _downloader.downloadToFile(
        url: url,
        destinationPath: partialPath,
        onProgress: onProgress,
        cancellationSignal: cancellationSignal,
      );
      await File(partialPath).rename(destinationPath);
      return destinationPath;
    } on FileDownloadCancelledException {
      throw const AppSelfUpdateCancelledException();
    } finally {
      final partialFile = File(partialPath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
    }
  }

  @override
  Future<String> computeSha256(String filePath) {
    _ensureActive();
    return computeFileSha256(File(filePath));
  }

  @override
  Future<String> readText(String filePath) {
    _ensureActive();
    return File(filePath).readAsString();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (await _directory.exists()) {
      await _directory.delete(recursive: true);
    }
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('更新工作区已经释放');
    }
  }
}
