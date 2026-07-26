import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/guided_repair_service.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/core/security/trusted_content_signature.dart';

/// 一键修复服务测试。
///
/// 验证安全复验、精确脚本落盘、固定 pkexec 参数、实时输出、30 分钟超时和
/// 临时文件清理都收敛在服务层，而不是依赖 UI 自觉遵守。
void main() {
  late Directory temporaryRoot;
  late Directory logRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'guided-repair-temp-test-',
    );
    logRoot = await Directory.systemTemp.createTemp('guided-repair-log-test-');
  });

  tearDown(() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
    if (await logRoot.exists()) {
      await logRoot.delete(recursive: true);
    }
  });

  test('验签后原样落盘并通过 pkexec bash 流式执行', () async {
    const script = '#!/usr/bin/env bash\necho "保持末尾换行"\n';
    final runner = _RecordingStreamingRunner();
    final service = GuidedRepairService(
      executor: ShellCommandExecutor(runner: runner),
      signatureVerifier: const _FixedSignatureVerifier(true),
      temporaryDirectoryPath: temporaryRoot.path,
      logDirectoryPath: logRoot.path,
      clock: () => DateTime(2026, 7, 25, 12, 30),
    );
    final outputs = <ShellOutputLine>[];

    final result = await service.execute(
      script: script,
      signature: 'valid',
      onOutput: outputs.add,
    );

    expect(result.status, GuidedRepairStatus.success);
    expect(result.exitCode, 0);
    expect(runner.command?.take(6), [
      'pkexec',
      'timeout',
      '--signal=TERM',
      '--kill-after=10s',
      '1800s',
      'bash',
    ]);
    expect(runner.scriptContent, script);
    expect(runner.timeout, const Duration(minutes: 30, seconds: 30));
    expect(
      outputs.map((item) => item.line),
      containsAllInOrder(['stdout line', 'stderr line']),
    );
    expect(await temporaryRoot.list().toList(), isEmpty);
    expect(result.logFilePath, contains('guided-repair-20260725-123000'));
  });

  test('签名无效时不创建进程也不落盘', () async {
    final runner = _RecordingStreamingRunner();
    final service = GuidedRepairService(
      executor: ShellCommandExecutor(runner: runner),
      signatureVerifier: const _FixedSignatureVerifier(false),
      temporaryDirectoryPath: temporaryRoot.path,
      logDirectoryPath: logRoot.path,
    );

    expect(
      () => service.execute(
        script: 'echo unsafe',
        signature: 'invalid',
        onOutput: (_) {},
      ),
      throwsA(isA<InvalidTrustedContentSignatureException>()),
    );
    expect(runner.callCount, 0);
    expect(await temporaryRoot.list().toList(), isEmpty);
  });

  test('执行器超时时返回 timedOut，实时输出仍由回调交付', () async {
    final runner = _RecordingStreamingRunner(shouldTimeOut: true);
    final service = GuidedRepairService(
      executor: ShellCommandExecutor(runner: runner),
      signatureVerifier: const _FixedSignatureVerifier(true),
      temporaryDirectoryPath: temporaryRoot.path,
      logDirectoryPath: logRoot.path,
    );

    final outputs = <ShellOutputLine>[];
    final result = await service.execute(
      script: 'echo slow\n',
      signature: 'valid',
      onOutput: outputs.add,
    );

    expect(result.status, GuidedRepairStatus.timedOut);
    expect(result.exitCode, isNull);
    expect(
      outputs.map((item) => item.line),
      containsAllInOrder(['stdout line', 'stderr line']),
    );
    expect(await temporaryRoot.list().toList(), isEmpty);
  });

  test('执行器异常携带日志路径并清理临时脚本', () async {
    final runner = _RecordingStreamingRunner(
      executionError: const ProcessException('pkexec', [], 'not found'),
    );
    final service = GuidedRepairService(
      executor: ShellCommandExecutor(runner: runner),
      signatureVerifier: const _FixedSignatureVerifier(true),
      temporaryDirectoryPath: temporaryRoot.path,
      logDirectoryPath: logRoot.path,
    );

    final future = service.execute(
      script: 'echo unavailable\n',
      signature: 'valid',
      onOutput: (_) {},
    );

    await expectLater(
      future,
      throwsA(
        isA<GuidedRepairExecutionException>().having(
          (error) => error.logFilePath,
          'logFilePath',
          contains(logRoot.path),
        ),
      ),
    );
    expect(await temporaryRoot.list().toList(), isEmpty);
  });
}

/// 固定返回值的签名验证器。
class _FixedSignatureVerifier implements TrustedContentSignatureVerifier {
  /// 创建固定结果验证器。
  const _FixedSignatureVerifier(this.isValid);

  /// 固定验签结果。
  final bool isValid;

  @override
  Future<bool> verify({
    required TrustedContentPurpose purpose,
    required String content,
    required String signature,
  }) async {
    return isValid;
  }
}

/// 记录脚本内容和执行参数的流式 Shell 替身。
class _RecordingStreamingRunner
    implements ShellCommandRunner, StreamingShellCommandRunner {
  /// 创建可选超时行为的执行器。
  _RecordingStreamingRunner({this.shouldTimeOut = false, this.executionError});

  /// 是否在输出后抛出超时。
  final bool shouldTimeOut;

  /// 可选固定执行异常。
  final Object? executionError;

  /// 调用次数。
  int callCount = 0;

  /// 最近执行命令。
  List<String>? command;

  /// 最近读取到的脚本原文。
  String? scriptContent;

  /// 最近收到的超时。
  Duration? timeout;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    throw UnsupportedError('该测试只允许流式执行');
  }

  @override
  Future<ShellCommandResult> runStreaming(
    List<String> command, {
    required void Function(ShellOutputLine output) onOutput,
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    callCount += 1;
    this.command = command;
    this.timeout = timeout;
    scriptContent = await File(command.last).readAsString();
    onOutput(
      const ShellOutputLine(
        channel: ShellOutputChannel.stdout,
        line: 'stdout line',
      ),
    );
    onOutput(
      const ShellOutputLine(
        channel: ShellOutputChannel.stderr,
        line: 'stderr line',
      ),
    );
    if (shouldTimeOut) {
      throw TimeoutException('timeout');
    }
    if (executionError != null) {
      throw executionError!;
    }
    return const ShellCommandResult(
      stdout: 'stdout line\n',
      stderr: 'stderr line\n',
      exitCode: 0,
    );
  }
}
