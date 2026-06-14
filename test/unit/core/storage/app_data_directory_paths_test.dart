import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:linglong_store/core/storage/app_data_directory_paths.dart';

void main() {
  group('AppDataDirectoryPaths', () {
    test('XDG_DATA_HOME 优先于 HOME', () {
      final dataHome = AppDataDirectoryPaths.resolveDataHomeDirectoryPath(
        environment: {
          'XDG_DATA_HOME': '/custom/xdg',
          'HOME': '/home/user',
        },
      );
      expect(dataHome, '/custom/xdg');
    });

    test('XDG_DATA_HOME 为空时回退到 HOME/.local/share', () {
      final dataHome = AppDataDirectoryPaths.resolveDataHomeDirectoryPath(
        environment: {
          'XDG_DATA_HOME': '',
          'HOME': '/home/user',
        },
      );
      expect(dataHome, p.join('/home/user', '.local', 'share'));
    });

    test('HOME 缺失时返回 null', () {
      final dataHome = AppDataDirectoryPaths.resolveDataHomeDirectoryPath(
        environment: <String, String>{},
      );
      expect(dataHome, isNull);
    });

    test('resolveCurrentDataDirectoryPath 拼接当前 applicationId', () {
      final path = AppDataDirectoryPaths.resolveCurrentDataDirectoryPath(
        environment: {'XDG_DATA_HOME': '/data'},
      );
      expect(path, '/data/${AppDataDirectoryPaths.applicationId}');
    });

    test('resolveLegacyDataDirectoryPath 拼接 legacy applicationId', () {
      final path = AppDataDirectoryPaths.resolveLegacyDataDirectoryPath(
        environment: {'XDG_DATA_HOME': '/data'},
      );
      expect(path, '/data/${AppDataDirectoryPaths.legacyApplicationId}');
    });

    test('resolveCurrentLogFilePath 拼接 logs 子目录与文件名', () {
      final path = AppDataDirectoryPaths.resolveCurrentLogFilePath(
        environment: {'XDG_DATA_HOME': '/data'},
      );
      expect(
        path,
        p.join(
          '/data',
          AppDataDirectoryPaths.applicationId,
          AppDataDirectoryPaths.logsDirectoryName,
          AppDataDirectoryPaths.logFileName,
        ),
      );
    });

    test('resolveMigrationStateFilePath 拼接状态文件名', () {
      final path = AppDataDirectoryPaths.resolveMigrationStateFilePath(
        environment: {'XDG_DATA_HOME': '/data'},
      );
      expect(
        path,
        p.join(
          '/data',
          AppDataDirectoryPaths.applicationId,
          AppDataDirectoryPaths.migrationStateFileName,
        ),
      );
    });

    test('resolveMigrationLockFilePath 拼接锁文件名', () {
      final path = AppDataDirectoryPaths.resolveMigrationLockFilePath(
        environment: {'XDG_DATA_HOME': '/data'},
      );
      expect(
        path,
        p.join(
          '/data',
          AppDataDirectoryPaths.applicationId,
          AppDataDirectoryPaths.migrationLockFileName,
        ),
      );
    });

    test('applicationId 与 legacyApplicationId 不相同', () {
      expect(
        AppDataDirectoryPaths.applicationId,
        isNot(equals(AppDataDirectoryPaths.legacyApplicationId)),
      );
    });
  });
}
