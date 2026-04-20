import 'dart:async';
import 'dart:io';

import '../logging/app_logger.dart';

/// 非 `ll-cli` 命令的统一执行结果。
class ShellCommandResult {
  const ShellCommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  final String stdout;
  final String stderr;
  final int exitCode;

  bool get success => exitCode == 0;

  String get primaryMessage {
    final trimmedStderr = stderr.trim();
    if (trimmedStderr.isNotEmpty) {
      return trimmedStderr;
    }
    return stdout.trim();
  }
}

/// 非 `ll-cli` 命令的底层执行器接口，便于测试替换。
abstract interface class ShellCommandRunner {
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
  });
}

class ProcessShellCommandRunner implements ShellCommandRunner {
  const ProcessShellCommandRunner();

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
  }) async {
    if (command.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command cannot be empty');
    }

    final executable = command.first;
    final arguments = command.skip(1).toList(growable: false);

    AppLogger.info('[Shell] 启动命令: ${command.join(' ')}');

    final result = await Process.run(
      executable,
      arguments,
      environment: environment,
    ).timeout(timeout);

    return ShellCommandResult(
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      exitCode: result.exitCode,
    );
  }
}

/// 通用 shell 命令执行器。
class ShellCommandExecutor {
  ShellCommandExecutor({ShellCommandRunner? runner})
    : _runner = runner ?? const ProcessShellCommandRunner();

  final ShellCommandRunner _runner;

  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
  }) {
    return _runner.run(command, timeout: timeout, environment: environment);
  }
}
