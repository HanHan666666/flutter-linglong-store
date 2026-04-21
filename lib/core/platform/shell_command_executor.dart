import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../logging/app_logger.dart';

/// shell 命令日志记录选项。
class ShellCommandLogOptions {
  const ShellCommandLogOptions({
    required this.filePath,
    this.overwrite = false,
  });

  final String filePath;
  final bool overwrite;
}

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
    ShellCommandLogOptions? logOptions,
  });
}

class ProcessShellCommandRunner implements ShellCommandRunner {
  const ProcessShellCommandRunner();

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    if (command.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command cannot be empty');
    }

    final executable = command.first;
    final arguments = command.skip(1).toList(growable: false);
    final commandLine = command.join(' ');

    AppLogger.info('[Shell] 启动命令: $commandLine');

    if (logOptions == null) {
      final result = await Process.run(
        executable,
        arguments,
        environment: environment,
      ).timeout(timeout);

      _logExit(commandLine, result.exitCode);
      return ShellCommandResult(
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        exitCode: result.exitCode,
      );
    }

    final logWriter = await _openLogWriter(logOptions, commandLine);
    Process? process;
    try {
      process = await Process.start(
        executable,
        arguments,
        environment: environment,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutFuture = _captureStream(
        stream: process.stdout,
        buffer: stdoutBuffer,
        commandLine: commandLine,
        logPrefix: '[Shell stdout]',
        logger: AppLogger.info,
        logWriter: logWriter,
      );
      final stderrFuture = _captureStream(
        stream: process.stderr,
        buffer: stderrBuffer,
        commandLine: commandLine,
        logPrefix: '[Shell stderr]',
        logger: AppLogger.warning,
        logWriter: logWriter,
      );

      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(timeout);
      } on TimeoutException {
        process.kill();
        await Future.wait([stdoutFuture, stderrFuture]);
        await logWriter.writeLine(
          '[Shell] 命令超时: $commandLine (timeout=${timeout.inSeconds}s)',
        );
        rethrow;
      }

      await Future.wait([stdoutFuture, stderrFuture]);

      _logExit(commandLine, exitCode);
      await logWriter.writeLine(
        '[Shell] 命令退出: $commandLine (exitCode=$exitCode)',
      );

      return ShellCommandResult(
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: exitCode,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[Shell] 命令执行失败: $commandLine', error, stackTrace);
      await logWriter.writeLine('[Shell] 命令执行失败: $commandLine | $error');
      rethrow;
    } finally {
      await logWriter.close();
    }
  }

  Future<_ShellCommandLogWriter> _openLogWriter(
    ShellCommandLogOptions logOptions,
    String commandLine,
  ) async {
    final writer = await _ShellCommandLogWriter.open(logOptions);
    await writer.writeLine('=== ${DateTime.now().toIso8601String()} ===');
    await writer.writeLine('[Shell] 启动命令: $commandLine');
    return writer;
  }

  Future<void> _captureStream({
    required Stream<List<int>> stream,
    required StringBuffer buffer,
    required String commandLine,
    required String logPrefix,
    required void Function(
      dynamic message, [
      dynamic error,
      StackTrace? stackTrace,
    ])
    logger,
    required _ShellCommandLogWriter logWriter,
  }) async {
    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      buffer.writeln(line);
      logger('$logPrefix $commandLine | $line');
      await logWriter.writeLine('$logPrefix $commandLine | $line');
    }
  }

  void _logExit(String commandLine, int exitCode) {
    final message = '[Shell] 命令退出: $commandLine (exitCode=$exitCode)';
    if (exitCode == 0) {
      AppLogger.info(message);
    } else {
      AppLogger.warning(message);
    }
  }
}

class _ShellCommandLogWriter {
  _ShellCommandLogWriter._(this._file);

  final File _file;
  Future<void> _pending = Future<void>.value();

  static Future<_ShellCommandLogWriter> open(
    ShellCommandLogOptions options,
  ) async {
    final file = File(options.filePath);
    await file.parent.create(recursive: true);

    if (options.overwrite) {
      await file.writeAsString('', flush: true);
    } else if (!await file.exists()) {
      await file.create(recursive: true);
    }

    return _ShellCommandLogWriter._(file);
  }

  Future<void> writeLine(String line) {
    _pending = _pending.then((_) {
      return _file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    });
    return _pending;
  }

  Future<void> close() => _pending;
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
    ShellCommandLogOptions? logOptions,
  }) {
    return _runner.run(
      command,
      timeout: timeout,
      environment: environment,
      logOptions: logOptions,
    );
  }
}
