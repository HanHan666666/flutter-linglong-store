import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/storage/app_data_directory_migration.dart';
import 'package:path/path.dart' as path;

void main() {
  group('AppDataDirectoryMigration', () {
    test('prefers XDG_DATA_HOME when resolving the current data directory', () {
      final resolvedDirectory =
          AppDataDirectoryMigration.resolveCurrentDataDirectoryPath(
            environment: <String, String>{
              'HOME': '/home/tester',
              'XDG_DATA_HOME': '/tmp/custom-data-home',
            },
          );

      expect(
        resolvedDirectory,
        '/tmp/custom-data-home/com.dongpl.linglong-store.v2',
      );
    });

    test('falls back to HOME local share when XDG_DATA_HOME is missing', () {
      final resolvedLogFilePath =
          AppDataDirectoryMigration.resolveCurrentLogFilePath(
            environment: <String, String>{'HOME': '/home/tester'},
          );

      expect(
        resolvedLogFilePath,
        '/home/tester/.local/share/com.dongpl.linglong-store.v2/logs/linglong-store.log',
      );
    });

    late Directory sandboxDirectory;
    late String legacyDataDirectoryPath;
    late String currentDataDirectoryPath;
    late List<String> warnings;

    setUp(() async {
      sandboxDirectory = await Directory.systemTemp.createTemp(
        'app-data-directory-migration-test-',
      );
      legacyDataDirectoryPath = path.join(sandboxDirectory.path, 'legacy');
      currentDataDirectoryPath = path.join(sandboxDirectory.path, 'current');
      warnings = <String>[];
    });

    tearDown(() async {
      if (await sandboxDirectory.exists()) {
        await sandboxDirectory.delete(recursive: true);
      }
    });

    AppDataDirectoryMigration createMigration({
      Future<void> Function(Directory legacyDirectory)? deleteLegacyDirectory,
    }) {
      return AppDataDirectoryMigration(
        legacyDataDirectoryPath: legacyDataDirectoryPath,
        currentDataDirectoryPath: currentDataDirectoryPath,
        onWarning: warnings.add,
        deleteLegacyDirectory: deleteLegacyDirectory,
      );
    }

    test(
      'does nothing when the legacy data directory does not exist',
      () async {
        final migration = createMigration();

        await migration.migrate();

        expect(Directory(currentDataDirectoryPath).existsSync(), isFalse);
        expect(warnings, isEmpty);
      },
    );

    test(
      'migrates files into a newly created current directory and removes the legacy directory',
      () async {
        await Directory(legacyDataDirectoryPath).create(recursive: true);
        await File(
          path.join(legacyDataDirectoryPath, 'settings.json'),
        ).writeAsString('legacy');

        final migration = createMigration();

        await migration.migrate();

        expect(Directory(currentDataDirectoryPath).existsSync(), isTrue);
        expect(
          File(
            path.join(currentDataDirectoryPath, 'settings.json'),
          ).readAsStringSync(),
          'legacy',
        );
        expect(Directory(legacyDataDirectoryPath).existsSync(), isFalse);
      },
    );

    test('keeps the current file when a filename collision happens', () async {
      await Directory(legacyDataDirectoryPath).create(recursive: true);
      await File(
        path.join(legacyDataDirectoryPath, 'settings.json'),
      ).writeAsString('legacy');
      await Directory(currentDataDirectoryPath).create(recursive: true);
      await File(
        path.join(currentDataDirectoryPath, 'settings.json'),
      ).writeAsString('current');

      final migration = createMigration();

      await migration.migrate();

      expect(
        File(
          path.join(currentDataDirectoryPath, 'settings.json'),
        ).readAsStringSync(),
        'current',
      );
      expect(Directory(legacyDataDirectoryPath).existsSync(), isFalse);
    });

    test('recursively migrates nested directories', () async {
      await Directory(
        path.join(legacyDataDirectoryPath, 'level-1', 'level-2'),
      ).create(recursive: true);
      await File(
        path.join(legacyDataDirectoryPath, 'level-1', 'level-2', 'nested.txt'),
      ).writeAsString('nested-value');

      final migration = createMigration();

      await migration.migrate();

      expect(
        File(
          path.join(
            currentDataDirectoryPath,
            'level-1',
            'level-2',
            'nested.txt',
          ),
        ).readAsStringSync(),
        'nested-value',
      );
      expect(Directory(legacyDataDirectoryPath).existsSync(), isFalse);
    });

    test('does not throw when deleting the legacy directory fails', () async {
      await Directory(legacyDataDirectoryPath).create(recursive: true);
      await File(
        path.join(legacyDataDirectoryPath, 'settings.json'),
      ).writeAsString('legacy');

      final migration = createMigration(
        deleteLegacyDirectory: (legacyDirectory) async {
          throw const FileSystemException(
            'simulated deletion failure',
            '/tmp/legacy',
          );
        },
      );

      await migration.migrate();

      expect(
        File(
          path.join(currentDataDirectoryPath, 'settings.json'),
        ).readAsStringSync(),
        'legacy',
      );
      expect(Directory(legacyDataDirectoryPath).existsSync(), isTrue);
      expect(
        warnings,
        contains(
          allOf(
            contains('Failed to delete legacy data directory'),
            contains(legacyDataDirectoryPath),
          ),
        ),
      );
    });
  });
}
