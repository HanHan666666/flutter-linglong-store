import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_installation_probe.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';

/// 可控的 shell runner 替身，按命令返回预设结果。
class _FakeShellRunner implements ShellCommandRunner {
  _FakeShellRunner(this.onRun);

  final Future<ShellCommandResult> Function(List<String> command) onRun;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    return onRun(command);
  }
}

ShellCommandResult _ok() => const ShellCommandResult(
  stdout: '',
  stderr: '',
  exitCode: 0,
);

ShellCommandResult _notFound() => const ShellCommandResult(
  stdout: '',
  stderr: 'dpkg: no packages found matching linglong-store',
  exitCode: 1,
);

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('parseOsRelease', () {
    test('parses plain and quoted values, ignores comments and blanks', () {
      final parsed = parseOsRelease('''
# comment
ID=ubuntu
NAME="Ubuntu"
PRETTY_NAME='Ubuntu 24.04'
VERSION_ID=24.04

EMPTY=""
''');
      expect(parsed['ID'], 'ubuntu');
      expect(parsed['NAME'], 'Ubuntu');
      expect(parsed['PRETTY_NAME'], 'Ubuntu 24.04');
      expect(parsed['VERSION_ID'], '24.04');
      expect(parsed['EMPTY'], '');
      expect(parsed.containsKey('comment'), isFalse);
    });

    test('returns empty map for empty content', () {
      expect(parseOsRelease(''), isEmpty);
    });
  });

  group('AppInstallationProbe', () {
    test('detects dpkg install when distro is debian-based and dpkg owns package', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'ubuntu',
          'ID_LIKE': 'debian',
        },
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            expect(command.first, 'dpkg');
            return _ok();
          }),
        ),
        environment: const <String, String>{
          'APPIMAGE': '/home/u/linglong-store.AppImage',
        },
        fileExists: (path) async => true,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.packageManagerDpkg);
      expect(result.managerLabel, 'dpkg');
      expect(result.appImagePath, isNull);
    });

    test('detects rpm install when distro is rpm-based and rpm owns package', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'fedora',
          'ID_LIKE': 'fedora',
        },
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            expect(command.first, 'rpm');
            return _ok();
          }),
        ),
        environment: const <String, String>{
          'APPIMAGE': '/home/u/linglong-store.AppImage',
        },
        fileExists: (path) async => true,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.packageManagerRpm);
      expect(result.managerLabel, 'rpm');
    });

    test('falls back to AppImage when package manager has no record', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'ubuntu',
          'ID_LIKE': 'debian',
        },
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _notFound()),
        ),
        environment: const <String, String>{
          'APPIMAGE': '/home/u/linglong-store.AppImage',
        },
        fileExists: (path) async => path == '/home/u/linglong-store.AppImage',
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.appImage);
      expect(result.appImagePath, '/home/u/linglong-store.AppImage');
    });

    test('falls back to AppImage when distro has no package manager', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'arch',
        },
        shellExecutor: ShellCommandExecutor(runner: _FakeShellRunner((_) async => _ok())),
        environment: const <String, String>{
          'APPIMAGE': '/opt/linglong-store.AppImage',
        },
        fileExists: (path) async => true,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.appImage);
    });

    test('returns manual when AppImage path does not exist', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'arch',
        },
        shellExecutor: ShellCommandExecutor(runner: _FakeShellRunner((_) async => _ok())),
        environment: const <String, String>{
          'APPIMAGE': '/gone/linglong-store.AppImage',
        },
        fileExists: (path) async => false,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.manual);
    });

    test('returns manual when no distro, no package manager and no AppImage', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => null,
        shellExecutor: ShellCommandExecutor(runner: _FakeShellRunner((_) async => _ok())),
        environment: const <String, String>{},
        fileExists: (path) async => false,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.manual);
    });

    test('treats missing package manager command as not installed', () async {
      final probe = AppInstallationProbe(
        readOsRelease: () async => const <String, String>{
          'ID': 'ubuntu',
          'ID_LIKE': 'debian',
        },
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            throw StateError('command not found');
          }),
        ),
        environment: const <String, String>{},
        fileExists: (path) async => false,
      );

      final result = await probe.detect();

      expect(result.kind, AppInstallationKind.manual);
    });
  });
}
