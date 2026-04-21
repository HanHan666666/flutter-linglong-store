import 'dart:io';

import 'package:path/path.dart' as path;

typedef InstallLogClock = DateTime Function();

/// 自动安装日志文件管理服务。
class LinglongInstallLogService {
  LinglongInstallLogService({
    String? logDirectoryPath,
    String? fileName,
    InstallLogClock? clock,
  }) : _logDirectoryPath = logDirectoryPath,
       _fileName = fileName,
       _clock = clock ?? DateTime.now;

  final String? _logDirectoryPath;
  final String? _fileName;
  final InstallLogClock _clock;

  String get logDirectoryPath {
    if (_logDirectoryPath != null && _logDirectoryPath.isNotEmpty) {
      return _logDirectoryPath;
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return path.join(
        home,
        '.local',
        'share',
        'com.dongpl.linglong-store.v2',
        'logs',
      );
    }

    return path.join(Directory.systemTemp.path, 'linglong-store', 'logs');
  }

  Future<File> createInstallLogFile() async {
    final directory = Directory(logDirectoryPath);
    await directory.create(recursive: true);

    final file = File(path.join(directory.path, _fileName ?? _buildFileName()));
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    return file;
  }

  String directoryPathOf(String filePath) {
    return path.dirname(filePath);
  }

  String _buildFileName() {
    final now = _clock();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'linglong-env-install-$timestamp.log';
  }
}
