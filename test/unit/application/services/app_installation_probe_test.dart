import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/platform/self_update/linux_app_installation_probe.dart';

/// 按命令返回预设结果的系统边界替身。
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

/// 创建固定命令结果。
ShellCommandResult _result({String stdout = '', int exitCode = 0}) {
  return ShellCommandResult(stdout: stdout, stderr: '', exitCode: exitCode);
}

void main() {
  setUpAll(AppLogger.init);

  group('LinuxAppInstallationProbe', () {
    test('AppImage 证据优先于机器上残留的 DEB 包', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((_) async {
            fail('AppImage 身份明确时不应查询系统包数据库');
          }),
        ),
        environment: const {'APPIMAGE': '/opt/store.AppImage'},
        resolvedExecutable: '/tmp/.mount_store/store',
        fileExists: (path) async => path == '/opt/store.AppImage',
      );

      final installation = await probe.detect();

      expect(installation.kind, AppInstallationKind.appImage);
      expect(installation.appImagePath, '/opt/store.AppImage');
    });

    test('当前可执行文件归属 linglong-store DEB 时识别为 dpkg', () async {
      final commands = <List<String>>[];
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _result(stdout: 'linglong-store: /usr/bin/linglong-store\n');
          }),
        ),
        environment: const {},
        resolvedExecutable: '/usr/bin/linglong-store',
      );

      expect(
        (await probe.detect()).kind,
        AppInstallationKind.packageManagerDpkg,
      );
      // 查询命令固定绝对路径并显式指定包数据库目录（docs/51 复核加固）。
      expect(commands.single, <String>[
        '/usr/bin/dpkg-query',
        '--admindir',
        '/var/lib/dpkg',
        '-S',
        '/usr/bin/linglong-store',
      ]);
    });

    test('dpkg 不归属且 RPM 包名匹配时识别为 rpm', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            if (command.first == '/usr/bin/dpkg-query') {
              return _result(exitCode: 1);
            }
            return _result(stdout: 'linglong-store\n');
          }),
        ),
        environment: const {},
        resolvedExecutable: '/usr/bin/linglong-store',
      );

      expect(
        (await probe.detect()).kind,
        AppInstallationKind.packageManagerRpm,
      );
    });

    test('包数据库只命中其它软件时保持手动安装身份', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            if (command.first == '/usr/bin/dpkg-query') {
              return _result(stdout: 'another-package: /usr/local/bin/store\n');
            }
            return _result(stdout: 'another-package\n');
          }),
        ),
        environment: const {},
        resolvedExecutable: '/usr/local/bin/store',
      );

      expect((await probe.detect()).kind, AppInstallationKind.manual);
    });
  });

  group('isManagedBySystemPackageManager（docs/51 信任判定）', () {
    test('dpkg 命中即返回 true 且不再查询其它包管理器', () async {
      final commands = <List<String>>[];
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _result(
              stdout: 'linglong-store: /opt/linglong-store/linglong_store\n',
            );
          }),
        ),
        resolvedExecutable: '/opt/linglong-store/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isTrue);
      expect(commands, <List<String>>[
        <String>[
          '/usr/bin/dpkg-query',
          '--admindir',
          '/var/lib/dpkg',
          '-S',
          '/opt/linglong-store/linglong_store',
        ],
      ]);
    });

    test('任意包名归属即可信（不校验包名，docs/51 §4.1）', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((_) async {
            return _result(
              stdout:
                  'some-other-package: /opt/linglong-store/linglong_store\n',
            );
          }),
        ),
        resolvedExecutable: '/opt/linglong-store/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isTrue);
    });

    test('dpkg 未命中、rpm 命中时返回 true', () async {
      final commands = <List<String>>[];
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            if (command.first == '/usr/bin/dpkg-query') {
              return _result(exitCode: 1);
            }
            return _result(stdout: 'linglong-store\n');
          }),
        ),
        resolvedExecutable: '/opt/linglong-store/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isTrue);
      expect(commands.map((command) => command.first), <String>[
        '/usr/bin/dpkg-query',
        '/usr/bin/rpm',
      ]);
    });

    test('仅 pacman 命中时返回 true（AUR 形态）', () async {
      final commands = <List<String>>[];
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            if (command.first == '/usr/bin/pacman') {
              return _result(
                stdout:
                    '/opt/linglong-store/linglong_store '
                    'is owned by linglong-store-bin 3.5.0-1\n',
              );
            }
            return _result(exitCode: 1);
          }),
        ),
        resolvedExecutable: '/opt/linglong-store/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isTrue);
      expect(commands.map((command) => command.first), <String>[
        '/usr/bin/dpkg-query',
        '/usr/bin/rpm',
        '/usr/bin/pacman',
      ]);
    });

    test('三库均未命中时返回 false', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((_) async => _result(exitCode: 1)),
        ),
        resolvedExecutable: '/home/user/bundle/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isFalse);
    });

    test('包管理器命令缺失（探测异常）按未命中处理，不得失败开放', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            throw Exception('模拟命令缺失: ${command.first}');
          }),
        ),
        resolvedExecutable: '/home/user/bundle/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isFalse);
    });

    test('探测超时按未命中处理（fail closed）', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner(
            (_) =>
                Future<ShellCommandResult>.error(TimeoutException('timeout')),
          ),
        ),
        resolvedExecutable: '/home/user/bundle/linglong_store',
      );

      expect(await probe.isManagedBySystemPackageManager(), isFalse);
    });

    test('可执行路径为空时不查询任何包管理器', () async {
      final commands = <List<String>>[];
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _result();
          }),
        ),
        resolvedExecutable: '   ',
      );

      expect(await probe.isManagedBySystemPackageManager(), isFalse);
      expect(commands, isEmpty);
    });
  });
}
