import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/linglong_environment_management_service.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/linglong_environment_management.dart';

void main() {
  group('LinglongEnvironmentManagementService', () {
    test(
      'analyzeEnvironment reports ostree integrity warning while repository remains usable',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          ..._healthyEnvironmentCommands(),
          'll-cli --json ps': const ShellCommandResult(
            stdout: '[]',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 /var/lib/linglong': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 1000000000 940000000 60000000 94% /var\n',
            stderr: '',
            exitCode: 0,
          ),
          'findmnt --json /var/lib/linglong': const ShellCommandResult(
            stdout:
                '{"filesystems":[{"target":"/var/lib/linglong","source":"/dev/nvme0n1p5","fstype":"ext4","options":"rw"}]}',
            stderr: '',
            exitCode: 0,
          ),
          'ostree fsck --repo=/var/lib/linglong/repo --quiet':
              const ShellCommandResult(
                stdout: '',
                stderr: 'error: Corrupted file object found',
                exitCode: 1,
              ),
        });
        final service = _buildManagementService(runner);

        final analysis = await service.analyzeEnvironment();

        expect(analysis.envResult.isOk, isTrue);
        expect(analysis.storage.usagePercent, 94);
        expect(analysis.ostree.isOk, isTrue);
        expect(analysis.ostree.hasIntegrityWarning, isTrue);
        expect(
          analysis.issues.map((issue) => issue.code),
          containsAll([
            LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
            LinglongEnvironmentIssueCode.storageNearlyFull,
          ]),
        );
        final ostreeIssue = analysis.issues.firstWhere(
          (issue) =>
              issue.code ==
              LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
        );
        expect(ostreeIssue.severity, LinglongEnvironmentIssueSeverity.warning);
        expect(ostreeIssue.title, 'OSTree 对象完整性风险');
        expect(
          ostreeIssue.repairAction,
          LinglongEnvironmentRepairAction.ostreeFsckDelete,
        );
        expect(ostreeIssue.rawDetail, contains('Corrupted file object'));
      },
    );

    test(
      'analyzeEnvironment reports ostree repository unavailable when refs cannot be read',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          ..._healthyEnvironmentCommands(),
          'll-cli --json ps': const ShellCommandResult(
            stdout: '[]',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 /var/lib/linglong': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 1000000000 400000000 600000000 40% /var\n',
            stderr: '',
            exitCode: 0,
          ),
          'findmnt --json /var/lib/linglong': const ShellCommandResult(
            stdout:
                '{"filesystems":[{"target":"/var/lib/linglong","source":"/dev/nvme0n1p5","fstype":"ext4","options":"rw"}]}',
            stderr: '',
            exitCode: 0,
          ),
          'ostree refs --repo=/var/lib/linglong/repo': const ShellCommandResult(
            stdout: '',
            stderr: 'error: opening repo: No such file or directory',
            exitCode: 1,
          ),
        });
        final service = _buildManagementService(runner);

        final analysis = await service.analyzeEnvironment();

        expect(analysis.ostree.isAvailable, isTrue);
        expect(analysis.ostree.isOk, isFalse);
        expect(analysis.ostree.hasIntegrityWarning, isFalse);
        final ostreeIssue = analysis.issues.firstWhere(
          (issue) =>
              issue.code ==
              LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
        );
        expect(ostreeIssue.severity, LinglongEnvironmentIssueSeverity.error);
        expect(ostreeIssue.title, 'OSTree 仓库不可用');
        expect(ostreeIssue.rawDetail, contains('opening repo'));
        expect(
          runner.commands.map((command) => command.join(' ')),
          isNot(contains('ostree fsck --repo=/var/lib/linglong/repo --quiet')),
        );
      },
    );

    test(
      'analyzeEnvironment reports ostree tool unavailable when deep check cannot run',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          ..._healthyEnvironmentCommands(),
          'll-cli --json ps': const ShellCommandResult(
            stdout: '[]',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 /var/lib/linglong': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 1000000000 400000000 600000000 40% /var\n',
            stderr: '',
            exitCode: 0,
          ),
          'findmnt --json /var/lib/linglong': const ShellCommandResult(
            stdout:
                '{"filesystems":[{"target":"/var/lib/linglong","source":"/dev/nvme0n1p5","fstype":"ext4","options":"rw"}]}',
            stderr: '',
            exitCode: 0,
          ),
        });
        final service = _buildManagementService(runner);

        final analysis = await service.analyzeEnvironment();

        expect(analysis.ostree.isAvailable, isFalse);
        expect(analysis.ostree.isOk, isFalse);
        expect(analysis.ostree.hasIntegrityWarning, isFalse);
        final ostreeIssue = analysis.issues.firstWhere(
          (issue) =>
              issue.code == LinglongEnvironmentIssueCode.ostreeToolUnavailable,
        );
        expect(ostreeIssue.severity, LinglongEnvironmentIssueSeverity.warning);
        expect(ostreeIssue.rawDetail, contains('ostree fsck 命令执行失败'));
      },
    );

    test(
      'analyzeEnvironment reports running apps as storage move blocker',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          ..._healthyEnvironmentCommands(),
          'll-cli --json ps': const ShellCommandResult(
            stdout:
                '[{"app":"cn.wps.wps-office","containerId":"abc","pid":1234}]',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 /var/lib/linglong': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 1000000000 400000000 600000000 40% /var\n',
            stderr: '',
            exitCode: 0,
          ),
          'findmnt --json /var/lib/linglong': const ShellCommandResult(
            stdout: '{"filesystems":[]}',
            stderr: '',
            exitCode: 0,
          ),
          'ostree fsck --repo=/var/lib/linglong/repo --quiet':
              const ShellCommandResult(stdout: '', stderr: '', exitCode: 0),
        });
        final service = _buildManagementService(runner);

        final analysis = await service.analyzeEnvironment();

        expect(analysis.runningAppCount, 1);
        expect(analysis.canMoveStorage, isFalse);
        expect(
          analysis.issues.map((issue) => issue.code),
          contains(LinglongEnvironmentIssueCode.runningAppsBlockStorageMove),
        );
      },
    );

    test('analyzeEnvironment reports linglong data permission mismatch', () async {
      final runner = _FakeShellCommandRunner.fromCommands({
        ..._healthyEnvironmentCommands(),
        'll-cli --json ps': const ShellCommandResult(
          stdout: '[]',
          stderr: '',
          exitCode: 0,
        ),
        'df -PB1 /var/lib/linglong': const ShellCommandResult(
          stdout:
              'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 1000000000 400000000 600000000 40% /var\n',
          stderr: '',
          exitCode: 0,
        ),
        'findmnt --json /var/lib/linglong': const ShellCommandResult(
          stdout:
              '{"filesystems":[{"target":"/var/lib/linglong","source":"/dev/nvme0n1p5","fstype":"ext4","options":"rw"}]}',
          stderr: '',
          exitCode: 0,
        ),
        'stat -c %U:%G:%a:%n /var/lib/linglong /var/lib/linglong/.version /var/lib/linglong/config.yaml /var/lib/linglong/states.json /var/lib/linglong/repo /var/lib/linglong/layers /var/lib/linglong/entries /var/lib/linglong/merged':
            const ShellCommandResult(
              stdout:
                  'deepin-linglong:deepin-linglong:755:/var/lib/linglong\n'
                  'root:root:664:/var/lib/linglong/.version\n'
                  'deepin-linglong:deepin-linglong:644:/var/lib/linglong/config.yaml\n'
                  'root:root:664:/var/lib/linglong/states.json\n'
                  'root:root:775:/var/lib/linglong/repo\n'
                  'root:root:775:/var/lib/linglong/layers\n'
                  'root:root:775:/var/lib/linglong/entries\n'
                  'root:root:775:/var/lib/linglong/merged\n',
              stderr: '',
              exitCode: 0,
            ),
        'ostree fsck --repo=/var/lib/linglong/repo --quiet':
            const ShellCommandResult(stdout: '', stderr: '', exitCode: 0),
      });
      final service = _buildManagementService(runner);

      final analysis = await service.analyzeEnvironment();

      expect(analysis.dataPermission.isOk, isFalse);
      expect(
        analysis.dataPermission.detail,
        contains('/var/lib/linglong/.version'),
      );
      final issue = analysis.issues.firstWhere(
        (issue) =>
            issue.code ==
            LinglongEnvironmentIssueCode.linglongDataPermissionAbnormal,
      );
      expect(issue.severity, LinglongEnvironmentIssueSeverity.error);
      expect(issue.title, '玲珑数据目录权限异常');
      expect(
        issue.repairAction,
        LinglongEnvironmentRepairAction.fixDataPermissions,
      );
    });

    test('repairOstreeRepository runs privileged fsck with log file', () async {
      final runner = _FakeShellCommandRunner.fromCommands({
        'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
            const ShellCommandResult(
              stdout: 'Deleted corrupted object\n',
              stderr: '',
              exitCode: 0,
            ),
      });
      final service = _buildManagementService(runner);

      final result = await service.repairOstreeRepository(
        logFilePath: '/tmp/linglong-ostree-repair.log',
      );

      expect(result.success, isTrue);
      expect(result.action, LinglongEnvironmentRepairAction.ostreeFsckDelete);
      expect(runner.commands.single, [
        'pkexec',
        'ostree',
        'fsck',
        '--repo=/var/lib/linglong/repo',
        '--all',
        '--delete',
      ]);
      expect(
        runner.logOptions.single?.filePath,
        '/tmp/linglong-ostree-repair.log',
      );
    });

    test(
      'repairOstreeRepository treats normal partial commits as successful non-corruption state',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
              const ShellCommandResult(
                stdout:
                    'fsck objects (1024/1024) 100%\n'
                    '1 partial commits not verified\n'
                    'object fsck of 12 commits completed successfully - no errors found.\n',
                stderr: '',
                exitCode: 0,
              ),
        });
        final service = _buildManagementService(runner);

        final result = await service.repairOstreeRepository(
          logFilePath: '/tmp/linglong-ostree-repair.log',
        );

        expect(result.success, isTrue);
        expect(result.message, contains('修复已执行'));
        expect(result.message, isNot(contains('重新拉取')));
        expect(runner.commands, [
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--all',
            '--delete',
          ],
        ]);
      },
    );

    test(
      'repairOstreeRepository repulls fsck-detected partial commits and fails when verification still reports corruption',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands(
          {
            'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
                const ShellCommandResult(
                  stdout:
                      'fsck objects (41652/41652) 100%\n'
                      '32 partial commits not verified\n',
                  stderr:
                      'error: 32 partial commits from fsck-detected corruption\n',
                  exitCode: 1,
                ),
          },
          dynamicResult: (command) {
            if (command.length == 3 &&
                command[0] == 'pkexec' &&
                command[1] == 'bash' &&
                command[2].endsWith('.sh')) {
              return const ShellCommandResult(
                stdout:
                    '发现 32 个 fsck 标记的 partial commits，开始重新拉取。\n'
                    'RE-PULL stable:main/org.deepin.calculator/6.5.34.1/loong64/binary\n',
                stderr:
                    'error: In commits 709ea377dcbd1bee43b8f603c23e7e6bbd9eaf875c308b185cc4b76e9e48b464: '
                    'fsck content object d32b89d111565f54716844e6c3fb5424926ad2a41ffc9827730e77ba09e58b50: '
                    'Corrupted file object; checksum expected=... actual=...\n',
                exitCode: 1,
              );
            }
            return null;
          },
        );
        final service = _buildManagementService(runner);

        final result = await service.repairOstreeRepository(
          logFilePath: '/tmp/linglong-ostree-repair.log',
        );

        expect(result.success, isFalse);
        expect(result.message, contains('32 个 partial commits'));
        expect(result.message, contains('重新拉取后复验仍未通过'));
        expect(result.message, contains('上游仓库数据'));
        expect(result.output, contains('fsck-detected corruption'));
        expect(
          result.output,
          contains('RE-PULL stable:main/org.deepin.calculator'),
        );
        expect(result.output, contains('Corrupted file object'));
        expect(runner.commands, [
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--all',
            '--delete',
          ],
          ['pkexec', 'bash', startsWith('/tmp/linglong-ostree-repull-')],
        ]);
      },
    );

    test(
      'repairOstreeRepository repulls when fsck marks commit partial before repository corruption error',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands(
          {
            'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
                const ShellCommandResult(
                  stdout:
                      'fsck objects (67125/67125) 100%\n'
                      '22 partial commits not verified\n',
                  stderr:
                      'In commits 709ea377dcbd1bee43b8f603c23e7e6bbd9eaf875c308b185cc4b76e9e48b464: '
                      'fsck content object 3010a52cfe8cc41bfce748d18ebcd333d9c8f2c0535294a3de5b32856aa5d200: '
                      'Corrupted file object; checksum expected=... actual=...\n'
                      'Marking commit as partial: 709ea377dcbd1bee43b8f603c23e7e6bbd9eaf875c308b185cc4b76e9e48b464\n'
                      'error: Repository corruption encountered\n',
                  exitCode: 1,
                ),
          },
          dynamicResult: (command) {
            if (command.length == 3 &&
                command[0] == 'pkexec' &&
                command[1] == 'bash' &&
                command[2].endsWith('.sh')) {
              return const ShellCommandResult(
                stdout:
                    'OSTree repo mode: bare-user-only\n'
                    'RE-PULL stable:main/org.deepin.calculator/6.5.34.1/loong64/binary\n',
                stderr:
                    'error: In commits 709ea377dcbd1bee43b8f603c23e7e6bbd9eaf875c308b185cc4b76e9e48b464: '
                    'fsck content object d32b89d111565f54716844e6c3fb5424926ad2a41ffc9827730e77ba09e58b50: '
                    'Corrupted file object; checksum expected=... actual=...\n',
                exitCode: 1,
              );
            }
            return null;
          },
        );
        final service = _buildManagementService(runner);

        final result = await service.repairOstreeRepository(
          logFilePath: '/tmp/linglong-ostree-repair.log',
        );

        expect(result.success, isFalse);
        expect(result.message, contains('22 个 partial commits'));
        expect(result.message, contains('重新拉取后复验仍未通过'));
        expect(result.output, contains('Repository corruption encountered'));
        expect(
          result.output,
          contains('RE-PULL stable:main/org.deepin.calculator'),
        );
        expect(runner.commands, [
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--all',
            '--delete',
          ],
          ['pkexec', 'bash', startsWith('/tmp/linglong-ostree-repull-')],
        ]);
      },
    );

    test(
      'repairOstreeRepository retries without all option for older ostree',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
              const ShellCommandResult(
                stdout: '',
                stderr: 'error: Unknown option --all\n',
                exitCode: 1,
              ),
          'pkexec ostree fsck --repo=/var/lib/linglong/repo --delete':
              const ShellCommandResult(
                stdout: 'Deleted corrupted object\n',
                stderr: '',
                exitCode: 0,
              ),
        });
        final service = _buildManagementService(runner);

        final result = await service.repairOstreeRepository(
          logFilePath: '/tmp/linglong-ostree-repair.log',
        );

        expect(result.success, isTrue);
        expect(result.message, contains('已兼容旧版 OSTree'));
        expect(runner.commands, [
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--all',
            '--delete',
          ],
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--delete',
          ],
        ]);
        expect(runner.logOptions.first?.overwrite, isTrue);
        expect(runner.logOptions.last?.overwrite, isFalse);
      },
    );

    test(
      'repairOstreeRepository reports unsupported delete option without pretending repair succeeded',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands({
          'pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete':
              const ShellCommandResult(
                stdout: '',
                stderr: 'error: Unrecognized option --delete\n',
                exitCode: 1,
              ),
        });
        final service = _buildManagementService(runner);

        final result = await service.repairOstreeRepository(
          logFilePath: '/tmp/linglong-ostree-repair.log',
        );

        expect(result.success, isFalse);
        expect(result.message, contains('不支持 --delete'));
        expect(result.message, contains('无法自动删除损坏对象'));
        expect(runner.commands, [
          [
            'pkexec',
            'ostree',
            'fsck',
            '--repo=/var/lib/linglong/repo',
            '--all',
            '--delete',
          ],
        ]);
      },
    );

    test('buildStorageMigrationScript uses systemd bind mount plan', () {
      final service = _buildManagementService(_FakeShellCommandRunner());

      final script = service.buildStorageMigrationScript('/data/linglong');

      expect(script, contains('rsync -aHAX --numeric-ids'));
      expect(script, contains('[Mount]'));
      expect(script, contains('What=/data/linglong'));
      expect(script, contains('Where=/var/lib/linglong'));
      expect(script, contains('Options=bind'));
      expect(script, contains(r'mv "$SRC" "$BACKUP"'));
      expect(script, contains(r'ostree fsck --repo="$SRC/repo" --quiet'));
      expect(script, contains(r'旧目录备份：$BACKUP'));
      expect(script, contains('systemctl enable --now var-lib-linglong.mount'));
    });

    test('buildStorageMigrationScript rejects unsafe target paths', () {
      final service = _buildManagementService(_FakeShellCommandRunner());

      expect(
        () => service.buildStorageMigrationScript('/'),
        throwsArgumentError,
      );
      expect(
        () => service.buildStorageMigrationScript('/var/lib/linglong/repo'),
        throwsArgumentError,
      );
    });

    test(
      'buildDataPermissionRepairScript restores linglong service ownership',
      () {
        final service = _buildManagementService(_FakeShellCommandRunner());

        final script = service.buildDataPermissionRepairScript();

        expect(script, contains("ROOT='/var/lib/linglong'"));
        expect(
          script,
          contains("SERVICE='org.deepin.linglong.PackageManager.service'"),
        );
        expect(script, contains("USER_NAME='deepin-linglong'"));
        expect(script, contains("GROUP_NAME='deepin-linglong'"));
        expect(
          script,
          contains(r'chown -R "$USER_NAME:$GROUP_NAME" "$ROOT/repo"'),
        );
        expect(
          script,
          contains(r'chown -R "$USER_NAME:$GROUP_NAME" "$ROOT/layers"'),
        );
        expect(
          script,
          contains(r'chown "$USER_NAME:$GROUP_NAME" "$ROOT/.version"'),
        );
        expect(script, contains(r'systemctl restart "$SERVICE"'));
        expect(script, contains('ll-cli --json repo show'));
      },
    );

    test('buildOstreePartialRepullScript repulls only fsck-marked commits', () {
      final service = _buildManagementService(_FakeShellCommandRunner());

      final script = service.buildOstreePartialRepullScript();

      expect(script, contains("ROOT='/var/lib/linglong'"));
      expect(script, contains("SERVICE_USER='deepin-linglong'"));
      expect(script, contains(r'ostree refs --repo="$REPO"'));
      expect(script, contains('.commitpartial'));
      expect(script, contains(r'[ "$reason" = "f" ] || continue'));
      expect(script, contains(r'RE-PULL $ref'));
      expect(script, contains(r'runuser -u "$SERVICE_USER"'));
      expect(script, contains('--disable-static-deltas'));
      expect(script, contains(r'ostree fsck --repo="$REPO" --quiet'));
    });

    test(
      'repairLinglongDataPermissions runs privileged repair script with log file',
      () async {
        final runner = _FakeShellCommandRunner.fromCommands(
          const {},
          dynamicResult: (command) {
            if (command.length == 3 &&
                command[0] == 'pkexec' &&
                command[1] == 'bash' &&
                command[2].endsWith('.sh')) {
              return const ShellCommandResult(
                stdout: '玲珑数据目录权限已修复。\n',
                stderr: '',
                exitCode: 0,
              );
            }
            return null;
          },
        );
        final service = _buildManagementService(runner);

        final result = await service.repairLinglongDataPermissions(
          logFilePath: '/tmp/linglong-permission-repair.log',
        );

        expect(result.success, isTrue);
        expect(
          result.action,
          LinglongEnvironmentRepairAction.fixDataPermissions,
        );
        expect(runner.commands.single.take(2), ['pkexec', 'bash']);
        expect(
          runner.logOptions.single?.filePath,
          '/tmp/linglong-permission-repair.log',
        );
      },
    );

    test('moveLinglongStorage refuses to run while apps are running', () async {
      final runner = _FakeShellCommandRunner.fromCommands({
        'll-cli --json ps': const ShellCommandResult(
          stdout:
              '[{"app":"cn.wps.wps-office","containerId":"abc","pid":1234}]',
          stderr: '',
          exitCode: 0,
        ),
      });
      final service = _buildManagementService(runner);

      final result = await service.moveLinglongStorage('/data/linglong');

      expect(result.success, isFalse);
      expect(result.action, LinglongEnvironmentRepairAction.moveStorageRoot);
      expect(result.message, contains('仍有 1 个玲珑应用正在运行'));
      expect(runner.commands, [
        ['ll-cli', '--json', 'ps'],
      ]);
    });

    test(
      'moveLinglongStorage refuses target filesystem with insufficient space',
      () async {
        final tempRoot = Directory.systemTemp.path;
        final runner = _FakeShellCommandRunner.fromCommands({
          'll-cli --json ps': const ShellCommandResult(
            stdout: '[]',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 /var/lib/linglong': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p5 2000000000 1000000000 1000000000 50% /var\n',
            stderr: '',
            exitCode: 0,
          ),
          'findmnt --json /var/lib/linglong': const ShellCommandResult(
            stdout:
                '{"filesystems":[{"target":"/var/lib/linglong","source":"/dev/nvme0n1p5","fstype":"ext4","options":"rw"}]}',
            stderr: '',
            exitCode: 0,
          ),
          'df -PB1 $tempRoot': const ShellCommandResult(
            stdout:
                'Filesystem 1-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p6 2000000000 1900000000 100000000 95% /tmp\n',
            stderr: '',
            exitCode: 0,
          ),
        });
        final service = _buildManagementService(runner);

        final result = await service.moveLinglongStorage(
          '$tempRoot/linglong-target-unit-test-not-existing',
        );

        expect(result.success, isFalse);
        expect(result.message, contains('目标路径可用空间不足'));
        expect(
          runner.commands.any(
            (command) => command.length >= 2 && command.first == 'pkexec',
          ),
          isFalse,
        );
      },
    );
  });
}

LinglongEnvironmentManagementService _buildManagementService(
  _FakeShellCommandRunner runner,
) {
  final executor = ShellCommandExecutor(runner: runner);
  final environmentService = LinglongEnvironmentService(
    executor: executor,
    osReleaseReader: () async => 'PRETTY_NAME="Deepin 23"\n',
    environmentReader: (name) => null,
    clock: () => 123,
  );
  return LinglongEnvironmentManagementService(
    executor: executor,
    environmentService: environmentService,
    clock: () => DateTime.fromMillisecondsSinceEpoch(123),
  );
}

Map<String, ShellCommandResult> _healthyEnvironmentCommands() {
  return const {
    'uname -m': ShellCommandResult(stdout: 'x86_64\n', stderr: '', exitCode: 0),
    'ldd --version': ShellCommandResult(
      stdout: 'ldd (GNU libc) 2.36\n',
      stderr: '',
      exitCode: 0,
    ),
    'uname -a': ShellCommandResult(
      stdout: 'Linux test 6.8.0\n',
      stderr: '',
      exitCode: 0,
    ),
    'bash -c dpkg -l | grep linglong': ShellCommandResult(
      stdout: 'ii linglong-bin 1.12.2\n',
      stderr: '',
      exitCode: 0,
    ),
    'll-cli --help': ShellCommandResult(
      stdout: 'Usage: ll-cli\n',
      stderr: '',
      exitCode: 0,
    ),
    'll-cli --json repo show': ShellCommandResult(
      stdout:
          '{"defaultRepo":"stable","repos":[{"name":"stable","url":"https://repo.example"}]}',
      stderr: '',
      exitCode: 0,
    ),
    'll-cli --json --version': ShellCommandResult(
      stdout: '{"version":"1.12.2"}',
      stderr: '',
      exitCode: 0,
    ),
    'stat -c %U:%G:%a:%n /var/lib/linglong /var/lib/linglong/.version /var/lib/linglong/config.yaml /var/lib/linglong/states.json /var/lib/linglong/repo /var/lib/linglong/layers /var/lib/linglong/entries /var/lib/linglong/merged':
        ShellCommandResult(
          stdout:
              'deepin-linglong:deepin-linglong:755:/var/lib/linglong\n'
              'deepin-linglong:deepin-linglong:644:/var/lib/linglong/.version\n'
              'deepin-linglong:deepin-linglong:644:/var/lib/linglong/config.yaml\n'
              'deepin-linglong:deepin-linglong:644:/var/lib/linglong/states.json\n'
              'deepin-linglong:deepin-linglong:755:/var/lib/linglong/repo\n'
              'deepin-linglong:deepin-linglong:755:/var/lib/linglong/layers\n'
              'deepin-linglong:deepin-linglong:755:/var/lib/linglong/entries\n'
              'deepin-linglong:deepin-linglong:755:/var/lib/linglong/merged\n',
          stderr: '',
          exitCode: 0,
        ),
    'apt-cache policy linglong-bin': ShellCommandResult(
      stdout: 'Installed: 1.12.2\n',
      stderr: '',
      exitCode: 0,
    ),
    'ostree refs --repo=/var/lib/linglong/repo': ShellCommandResult(
      stdout: 'stable:main/org.deepin.base/25.2.2.5/x86_64/binary\n',
      stderr: '',
      exitCode: 0,
    ),
  };
}

class _FakeShellCommandRunner implements ShellCommandRunner {
  _FakeShellCommandRunner() : _results = const {}, _dynamicResult = null;

  _FakeShellCommandRunner.fromCommands(
    this._results, {
    ShellCommandResult? Function(List<String> command)? dynamicResult,
  }) : _dynamicResult = dynamicResult;

  final Map<String, ShellCommandResult> _results;
  final ShellCommandResult? Function(List<String> command)? _dynamicResult;
  final List<List<String>> commands = [];
  final List<ShellCommandLogOptions?> logOptions = [];

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    commands.add(List<String>.from(command));
    this.logOptions.add(logOptions);
    final key = command.join(' ');
    final result = _results[key] ?? _dynamicResult?.call(command);
    if (result == null) {
      throw StateError('Unexpected command: $key');
    }
    return result;
  }
}
