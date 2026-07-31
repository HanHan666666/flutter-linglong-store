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
      expect(commands.single, ['dpkg-query', '-S', '/usr/bin/linglong-store']);
    });

    test('dpkg 不归属且 RPM 包名匹配时识别为 rpm', () async {
      final probe = LinuxAppInstallationProbe(
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            if (command.first == 'dpkg-query') {
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
            if (command.first == 'dpkg-query') {
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
}
