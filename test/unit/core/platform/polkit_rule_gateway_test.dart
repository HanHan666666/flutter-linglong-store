/// 免密安装规则平台 Gateway 测试（docs/50 §6、§10.1）。
///
/// 分两组：
/// 1. 事务脚本在隔离目录中真实执行（`LL_STORE_POLKIT_RULES_DIR` 只在非 root 时
///    生效），覆盖原子发布、幂等、冲突保护、临时文件命名与清理、非 root 拒绝、
///    跨实例串行与锁超时；**不会触碰开发机真实的 polkit 策略目录**；
/// 2. Gateway 自身的命令构造、stdout 严格解析、退出码映射与工作区清理，
///    通过注入假执行器验证，不需要真实 pkexec。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/polkit_rule_gateway.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';

/// 记录命令并可在执行期间读取脚本的假执行器。
class _RecordingShellRunner implements ShellCommandRunner {
  _RecordingShellRunner(this.result);

  ShellCommandResult result;
  final List<List<String>> commands = <List<String>>[];
  String? scriptContentAtRun;
  bool? scriptExistedAtRun;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    commands.add(List<String>.from(command));
    final script = File(command[3]);
    scriptExistedAtRun = await script.exists();
    if (scriptExistedAtRun == true) {
      scriptContentAtRun = await script.readAsString();
    }
    return result;
  }
}

/// 隔离目录中一次脚本执行的结果。
class _ScriptRun {
  const _ScriptRun(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;

  /// 解析 stdout 中的结构化结果；无结果时返回 null。
  Map<String, dynamic>? get result {
    for (final line in stdout.trim().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('{')) {
        return Map<String, dynamic>.from(
          jsonDecode(trimmed) as Map<String, dynamic>,
        );
      }
    }
    return null;
  }
}

void main() {
  late Directory scriptWorkspace;

  setUpAll(() async {
    scriptWorkspace = await Directory.systemTemp.createTemp(
      'polkit-script-workspace-',
    );
  });

  tearDownAll(() async {
    if (await scriptWorkspace.exists()) {
      await scriptWorkspace.delete(recursive: true);
    }
  });

  /// 在隔离规则目录中执行一次事务脚本。
  Future<_ScriptRun> runTransaction(
    Directory rulesDir,
    String action, {
    Map<String, String>? environment,
  }) async {
    final script = File('${scriptWorkspace.path}/transaction.sh');
    await script.writeAsString(buildPolkitRuleTransactionScript());
    final result = await Process.run(
      '/bin/bash',
      <String>[script.path, action],
      environment: environment ?? <String, String>{
        'LL_STORE_POLKIT_RULES_DIR': rulesDir.path,
      },
    );
    return _ScriptRun(
      result.exitCode,
      result.stdout.toString(),
      result.stderr.toString(),
    );
  }

  Future<Directory> createRulesDir() async {
    final dir = await Directory.systemTemp.createTemp('polkit-rules-dir-');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    return dir;
  }

  File ruleFileIn(Directory dir) =>
      File('${dir.path}/60-linglong-store.rules');

  group('事务脚本（隔离目录真实执行）', () {
    test('脚本语法合法且模板使用大写 polkit.Result.YES', () async {
      final script = File('${scriptWorkspace.path}/syntax-check.sh');
      await script.writeAsString(buildPolkitRuleTransactionScript());
      final check = await Process.run('/bin/bash', <String>[
        '-n',
        script.path,
      ]);

      expect(check.exitCode, 0, reason: check.stderr.toString());
      expect(
        kPasswordFreeInstallRuleTemplate,
        contains('polkit.Result.YES'),
      );
      expect(kPasswordFreeInstallRuleTemplate, isNot(contains('.yes')));
      expect(kPolkitRuleFilePath, endsWith('60-linglong-store.rules'));
      expect(
        kPasswordFreeInstallRuleTemplate,
        contains('org.deepin.linglong.PackageManager1.install-from-file'),
      );
      // 模板末尾必须恰好一个换行，写入与比对都依赖这个口径。
      expect(kPasswordFreeInstallRuleTemplate, endsWith('});\n'));
    });

    test('非 root 且未指定隔离目录时拒绝执行（退出码 66）', () async {
      final rulesDir = await createRulesDir();
      final run = await runTransaction(
        rulesDir,
        'enable',
        environment: const <String, String>{},
      );

      expect(run.exitCode, 66);
      expect(run.result, isNull);
      expect(await ruleFileIn(rulesDir).exists(), isFalse);
    });

    test('非法动作参数被拒绝（退出码 64）', () async {
      final rulesDir = await createRulesDir();
      final run = await runTransaction(rulesDir, 'install');

      expect(run.exitCode, 64);
      expect(run.result, isNull);
    });

    test('开启：原子发布完整模板、权限 0644、回读 applied', () async {
      final rulesDir = await createRulesDir();

      final run = await runTransaction(rulesDir, 'enable');

      expect(run.exitCode, 0, reason: run.stderr);
      expect(run.result, <String, dynamic>{
        'version': 1,
        'requestedEnabled': true,
        'before': 'disabled',
        'after': 'enabled',
        'outcome': 'applied',
        'reason': 'none',
      });
      final ruleFile = ruleFileIn(rulesDir);
      expect(await ruleFile.exists(), isTrue);
      expect(await ruleFile.readAsString(), kPasswordFreeInstallRuleTemplate);
      final mode = await Process.run('stat', <String>['-c', '%a', ruleFile.path]);
      expect(mode.stdout.toString().trim(), '644');
      // 规则目录内不残留临时文件。
      final leftovers = await rulesDir
          .list()
          .map((entity) => entity.path.split('/').last)
          .toList();
      expect(leftovers, <String>['60-linglong-store.rules']);
    });

    test('重复开启：真实状态已等于目标时按幂等成功结束', () async {
      final rulesDir = await createRulesDir();
      await runTransaction(rulesDir, 'enable');

      final second = await runTransaction(rulesDir, 'enable');

      expect(second.exitCode, 0);
      expect(second.result?['outcome'], 'unchanged');
      expect(second.result?['after'], 'enabled');
      expect(
        await ruleFileIn(rulesDir).readAsString(),
        kPasswordFreeInstallRuleTemplate,
      );
    });

    test('关闭：删除本功能规则，重复关闭幂等成功', () async {
      final rulesDir = await createRulesDir();
      await runTransaction(rulesDir, 'enable');

      final disabled = await runTransaction(rulesDir, 'disable');
      expect(disabled.exitCode, 0);
      expect(disabled.result?['outcome'], 'applied');
      expect(disabled.result?['after'], 'disabled');
      expect(await ruleFileIn(rulesDir).exists(), isFalse);

      final again = await runTransaction(rulesDir, 'disable');
      expect(again.result?['outcome'], 'unchanged');
    });

    test('同名文件内容不同：报告冲突且不覆盖、不删除', () async {
      final rulesDir = await createRulesDir();
      final ruleFile = ruleFileIn(rulesDir);
      await ruleFile.writeAsString('// 管理员自定义规则\n');

      final enabled = await runTransaction(rulesDir, 'enable');
      expect(enabled.result?['outcome'], 'conflict');
      expect(enabled.result?['after'], 'conflict');
      expect(await ruleFile.readAsString(), '// 管理员自定义规则\n');

      final disabled = await runTransaction(rulesDir, 'disable');
      expect(disabled.result?['outcome'], 'conflict');
      expect(await ruleFile.exists(), isTrue);
    });

    test('同名符号链接与目录：报告冲突且不删除', () async {
      final linkDir = await createRulesDir();
      final target = File('${linkDir.path}/elsewhere.rules');
      await target.writeAsString('// target\n');
      final link = Link('${linkDir.path}/60-linglong-store.rules');
      await link.create(target.path);

      final viaLink = await runTransaction(linkDir, 'enable');
      expect(viaLink.result?['outcome'], 'conflict');
      expect(await link.exists(), isTrue);
      expect(await target.readAsString(), '// target\n');

      final dirDir = await createRulesDir();
      await Directory(
        '${dirDir.path}/60-linglong-store.rules',
      ).create();
      final viaDir = await runTransaction(dirDir, 'disable');
      expect(viaDir.result?['outcome'], 'conflict');
      expect(
        await Directory('${dirDir.path}/60-linglong-store.rules').exists(),
        isTrue,
      );
    });

    test('权限异常（0600）视为冲突，不覆盖也不删除', () async {
      final rulesDir = await createRulesDir();
      final ruleFile = ruleFileIn(rulesDir);
      await ruleFile.writeAsString(kPasswordFreeInstallRuleTemplate);
      await Process.run('chmod', <String>['600', ruleFile.path]);

      final run = await runTransaction(rulesDir, 'enable');

      expect(run.result?['outcome'], 'conflict');
      expect(await ruleFile.exists(), isTrue);
      final mode = await Process.run('stat', <String>['-c', '%a', ruleFile.path]);
      expect(mode.stdout.toString().trim(), '600');
    });

    test('只清理本功能命名的临时文件，不动其他规则', () async {
      final rulesDir = await createRulesDir();
      final stale = File('${rulesDir.path}/.ll-store-polkit-rule.stale');
      await stale.writeAsString('leftover');
      final foreign = File('${rulesDir.path}/50-other.rules');
      await foreign.writeAsString('// other\n');

      final run = await runTransaction(rulesDir, 'enable');

      expect(run.result?['outcome'], 'applied');
      expect(await stale.exists(), isFalse);
      expect(await foreign.readAsString(), '// other\n');
    });

    test('规则目录缺失时明确失败，不创建目录（退出码 65）', () async {
      final parent = await Directory.systemTemp.createTemp('polkit-missing-');
      addTearDown(() async {
        if (await parent.exists()) {
          await parent.delete(recursive: true);
        }
      });
      final missing = Directory('${parent.path}/rules.d');

      final run = await runTransaction(missing, 'enable');

      expect(run.exitCode, 65);
      expect(await missing.exists(), isFalse);
    });

    test('多个实例串行：并发开启后结果一致且无残留', () async {
      final rulesDir = await createRulesDir();

      final results = await Future.wait(<Future<_ScriptRun>>[
        runTransaction(rulesDir, 'enable'),
        runTransaction(rulesDir, 'enable'),
      ]);

      for (final run in results) {
        expect(run.exitCode, 0, reason: run.stderr);
      }
      final outcomes = results.map((run) => run.result?['outcome']).toSet();
      expect(outcomes.contains('applied'), isTrue);
      expect(
        await ruleFileIn(rulesDir).readAsString(),
        kPasswordFreeInstallRuleTemplate,
      );
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('锁被外部占用时等待超时并以退出码 67 失败', () async {
      final rulesDir = await createRulesDir();
      final holder = await Process.start('flock', <String>[
        '-x',
        rulesDir.path,
        '-c',
        'sleep 15',
      ]);
      // 给 holder 一点时间拿到锁，避免与脚本竞态。
      await Future<void>.delayed(const Duration(milliseconds: 300));

      try {
        final run = await runTransaction(rulesDir, 'enable');
        expect(run.exitCode, 67);
        expect(await ruleFileIn(rulesDir).exists(), isFalse);
      } finally {
        holder.kill(ProcessSignal.sigkill);
        await holder.exitCode;
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('Gateway 命令构造、解析与清理', () {
    late Directory workspaceRoot;

    setUp(() async {
      workspaceRoot = await Directory.systemTemp.createTemp(
        'polkit-gateway-root-',
      );
    });

    tearDown(() async {
      if (await workspaceRoot.exists()) {
        await workspaceRoot.delete(recursive: true);
      }
    });

    String okResult({
      bool requested = true,
      String before = 'disabled',
      String after = 'enabled',
      String outcome = 'applied',
      String reason = 'none',
    }) {
      return '{"version":1,"requestedEnabled":$requested,"before":"$before",'
          '"after":"$after","outcome":"$outcome","reason":"$reason"}\n';
    }

    PolkitRuleScriptGateway buildGateway(ShellCommandRunner runner) {
      return PolkitRuleScriptGateway(
        executor: ShellCommandExecutor(runner: runner),
        workspaceRoot: workspaceRoot,
      );
    }

    test('使用参数数组调用 pkexec，脚本内容来自固定模板，退出后清理工作区', () async {
      final runner = _RecordingShellRunner(
        ShellCommandResult(stdout: okResult(), stderr: '', exitCode: 0),
      );
      final gateway = buildGateway(runner);

      final result = await gateway.apply(enabled: true);

      expect(result.outcome, PolkitRuleOutcome.applied);
      expect(result.after, PolkitRuleSystemState.enabled);
      final command = runner.commands.single;
      expect(command.take(4).toList(), <String>[
        'pkexec',
        '--disable-internal-agent',
        '/bin/bash',
        command[3],
      ]);
      expect(command.last, 'enable');
      expect(command[3], endsWith('/transaction.sh'));
      expect(runner.scriptExistedAtRun, isTrue);
      expect(
        runner.scriptContentAtRun,
        contains(kPasswordFreeInstallRuleTemplate.trim()),
      );
      expect(
        await Directory(File(command[3]).parent.path).exists(),
        isFalse,
        reason: '命令退出后必须清理临时工作区',
      );
    });

    test('关闭方向传递 disable 动作', () async {
      final runner = _RecordingShellRunner(
        ShellCommandResult(
          stdout: okResult(
            requested: false,
            before: 'enabled',
            after: 'disabled',
          ),
          stderr: '',
          exitCode: 0,
        ),
      );

      final result = await buildGateway(runner).apply(enabled: false);

      expect(result.outcome, PolkitRuleOutcome.applied);
      expect(runner.commands.single.last, 'disable');
    });

    test('执行失败时同样清理工作区', () async {
      final runner = _RecordingShellRunner(
        const ShellCommandResult(stdout: '', stderr: 'boom', exitCode: 68),
      );

      await expectLater(
        buildGateway(runner).apply(enabled: true),
        throwsA(isA<PolkitRuleException>()),
      );

      final scriptPath = runner.commands.single[3];
      expect(await Directory(File(scriptPath).parent.path).exists(), isFalse);
    });

    test('严格解析 stdout：合法结果映射到模型字段', () async {
      final runner = _RecordingShellRunner(
        ShellCommandResult(
          stdout:
              'diagnostic\n${okResult(before: 'conflict', after: 'conflict', outcome: 'conflict', reason: 'conflict')}',
          stderr: '',
          exitCode: 0,
        ),
      );

      final result = await buildGateway(runner).apply(enabled: true);

      expect(result.before, PolkitRuleSystemState.conflict);
      expect(result.after, PolkitRuleSystemState.conflict);
      expect(result.outcome, PolkitRuleOutcome.conflict);
      expect(result.reason, PolkitRuleFailureReason.conflict);
      expect(result.matchesRequestedTarget, isFalse);
    });

    test('版本、枚举、字段或 requestedEnabled 不符时按无可靠结果处理', () async {
      final invalidOutputs = <String>[
        '',
        'not json',
        '{"version":2,"requestedEnabled":true,"before":"disabled","after":"enabled","outcome":"applied","reason":"none"}',
        '{"version":1,"requestedEnabled":true,"before":"disabled","after":"enabled","outcome":"applied"}',
        '{"version":1,"requestedEnabled":true,"before":"bogus","after":"enabled","outcome":"applied","reason":"none"}',
        '{"version":1,"requestedEnabled":true,"before":"disabled","after":"enabled","outcome":"bogus","reason":"none"}',
        '{"version":1,"requestedEnabled":false,"before":"disabled","after":"enabled","outcome":"applied","reason":"none"}',
      ];

      for (final output in invalidOutputs) {
        final runner = _RecordingShellRunner(
          ShellCommandResult(stdout: output, stderr: '', exitCode: 0),
        );
        await expectLater(
          buildGateway(runner).apply(enabled: true),
          throwsA(
            isA<PolkitRuleException>().having(
              (error) => error.kind,
              'kind',
              PolkitRuleFailureKind.invalidResult,
            ),
          ),
          reason: '输出: $output',
        );
      }
    });

    test('退出码映射到稳定失败类型，且不透传为成功', () async {
      const expectations = <int, PolkitRuleFailureKind>{
        126: PolkitRuleFailureKind.authorizationCancelled,
        127: PolkitRuleFailureKind.authorizationUnavailable,
        65: PolkitRuleFailureKind.unsupportedEnvironment,
        66: PolkitRuleFailureKind.unsupportedEnvironment,
        67: PolkitRuleFailureKind.timeout,
        68: PolkitRuleFailureKind.unexpected,
        1: PolkitRuleFailureKind.unexpected,
      };

      for (final entry in expectations.entries) {
        final runner = _RecordingShellRunner(
          ShellCommandResult(
            stdout: '',
            stderr: 'failure detail',
            exitCode: entry.key,
          ),
        );
        await expectLater(
          buildGateway(runner).apply(enabled: true),
          throwsA(
            isA<PolkitRuleException>()
                .having((error) => error.kind, 'kind', entry.value)
                .having((error) => error.exitCode, 'exitCode', entry.key)
                .having(
                  (error) => error.diagnostic,
                  'diagnostic',
                  contains('failure detail'),
                ),
          ),
          reason: '退出码 ${entry.key}',
        );
      }
    });

    test('执行器超时映射为 timeout，启动失败映射为授权组件不可用', () async {
      await expectLater(
        buildGateway(_ThrowingShellRunner(TimeoutException('超时'))).apply(
          enabled: true,
        ),
        throwsA(
          isA<PolkitRuleException>().having(
            (error) => error.kind,
            'kind',
            PolkitRuleFailureKind.timeout,
          ),
        ),
      );

      await expectLater(
        buildGateway(
          _ThrowingShellRunner(const ProcessException('pkexec', <String>[])),
        ).apply(enabled: true),
        throwsA(
          isA<PolkitRuleException>().having(
            (error) => error.kind,
            'kind',
            PolkitRuleFailureKind.authorizationUnavailable,
          ),
        ),
      );
    });
  });
}

/// 抛出指定异常的执行器。
class _ThrowingShellRunner implements ShellCommandRunner {
  _ThrowingShellRunner(this.error);

  final Object error;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    throw error;
  }
}
