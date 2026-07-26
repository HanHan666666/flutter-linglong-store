import 'dart:async';
import 'dart:collection';
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

/// Shell 输出来源。
enum ShellOutputChannel {
  /// 标准输出。
  stdout,

  /// 标准错误。
  stderr,
}

/// Shell 进程实时输出的单行事件。
class ShellOutputLine {
  /// 创建实时输出事件。
  const ShellOutputLine({required this.channel, required this.line});

  /// 当前行来自 stdout 还是 stderr。
  final ShellOutputChannel channel;

  /// 去除换行分隔符后的原始文本。
  final String line;
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

/// 支持实时输出的底层执行器扩展接口。
///
/// 该接口与 [ShellCommandRunner] 分离，避免既有测试替身和只关心最终结果的调用方
/// 被迫实现流式能力；[ShellCommandExecutor] 会为不支持该接口的替身提供兼容回退。
abstract interface class StreamingShellCommandRunner {
  /// 执行命令并实时回调 stdout/stderr 的每一行。
  Future<ShellCommandResult> runStreaming(
    List<String> command, {
    required void Function(ShellOutputLine output) onOutput,
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  });
}

/// 基于系统进程的 Shell 命令执行器。
class ProcessShellCommandRunner
    implements ShellCommandRunner, StreamingShellCommandRunner {
  /// 流式调用每个输出通道最多保留的尾部字节数。
  ///
  /// 完整输出由日志文件承载；最终结果只保留少量尾部用于错误摘要，避免长时间运行
  /// 的命令在 UI 已做截断的情况下仍被底层无限聚合。
  static const int _maxStreamingCaptureBytesPerChannel = 64 * 1024;

  /// 看门狗触发后等待输出管道自然关闭的最长时间。
  static const Duration _streamDrainGracePeriod = Duration(seconds: 2);

  /// 创建无状态进程执行器。
  const ProcessShellCommandRunner();

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    return _runProcess(
      command,
      timeout: timeout,
      environment: environment,
      logOptions: logOptions,
    );
  }

  @override
  Future<ShellCommandResult> runStreaming(
    List<String> command, {
    required void Function(ShellOutputLine output) onOutput,
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    return _runProcess(
      command,
      timeout: timeout,
      environment: environment,
      logOptions: logOptions,
      onOutput: onOutput,
    );
  }

  /// 统一实现普通执行与流式执行，确保超时、日志和清理行为完全一致。
  Future<ShellCommandResult> _runProcess(
    List<String> command, {
    required Duration timeout,
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
    void Function(ShellOutputLine output)? onOutput,
  }) async {
    if (command.isEmpty) {
      throw ArgumentError.value(command, 'command', 'Command cannot be empty');
    }

    final executable = command.first;
    final arguments = command.skip(1).toList(growable: false);
    final commandLine = command.join(' ');

    AppLogger.info('[Shell] 启动命令: $commandLine');

    if (logOptions == null && onOutput == null) {
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

    final logWriter = logOptions == null
        ? null
        : await _openLogWriter(logOptions, commandLine);
    Process? process;
    try {
      process = await Process.start(
        executable,
        arguments,
        environment: environment,
      );

      final captureLimit = onOutput == null
          ? null
          : _maxStreamingCaptureBytesPerChannel;
      final stdoutBuffer = _ShellOutputBuffer(maxBytes: captureLimit);
      final stderrBuffer = _ShellOutputBuffer(maxBytes: captureLimit);

      final stdoutCapture = _captureStream(
        stream: process.stdout,
        buffer: stdoutBuffer,
        commandLine: commandLine,
        logPrefix: '[Shell stdout]',
        logger: AppLogger.info,
        logWriter: logWriter,
        channel: ShellOutputChannel.stdout,
        onOutput: onOutput,
      );
      final stderrCapture = _captureStream(
        stream: process.stderr,
        buffer: stderrBuffer,
        commandLine: commandLine,
        logPrefix: '[Shell stderr]',
        logger: AppLogger.warning,
        logWriter: logWriter,
        channel: ShellOutputChannel.stderr,
        onOutput: onOutput,
      );

      int exitCode;
      try {
        exitCode = await process.exitCode.timeout(timeout);
      } on TimeoutException {
        final signalSent = process.kill(ProcessSignal.sigterm);
        if (!signalSent) {
          AppLogger.warning(
            '[Shell] 本地进程无权接收 SIGTERM，等待特权侧超时器收尾: $commandLine',
          );
        }
        await _finishTimedOutCaptures(
          commandLine,
          stdoutCapture,
          stderrCapture,
        );
        await logWriter?.writeLine(
          '[Shell] 命令超时: $commandLine (timeout=${timeout.inSeconds}s)',
        );
        rethrow;
      }

      await Future.wait([stdoutCapture.done, stderrCapture.done]);

      _logExit(commandLine, exitCode);
      await logWriter?.writeLine(
        '[Shell] 命令退出: $commandLine (exitCode=$exitCode)',
      );

      return ShellCommandResult(
        stdout: stdoutBuffer.text,
        stderr: stderrBuffer.text,
        exitCode: exitCode,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[Shell] 命令执行失败: $commandLine', error, stackTrace);
      await logWriter?.writeLine('[Shell] 命令执行失败: $commandLine | $error');
      rethrow;
    } finally {
      await logWriter?.close();
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

  _ShellStreamCapture _captureStream({
    required Stream<List<int>> stream,
    required _ShellOutputBuffer buffer,
    required String commandLine,
    required String logPrefix,
    required void Function(
      dynamic message, [
      dynamic error,
      StackTrace? stackTrace,
    ])
    logger,
    required _ShellCommandLogWriter? logWriter,
    required ShellOutputChannel channel,
    required void Function(ShellOutputLine output)? onOutput,
  }) {
    return _ShellStreamCapture.start(
      stream: stream.transform(utf8.decoder).transform(const LineSplitter()),
      onLine: (line) async {
        buffer.addLine(line);
        // 有专用日志时避免再逐行写全局日志；否则高输出脚本会重复 IO 并拖慢管道。
        if (logWriter == null) {
          logger('$logPrefix $commandLine | $line');
        }
        onOutput?.call(ShellOutputLine(channel: channel, line: line));
        await logWriter?.writeLine('$logPrefix $commandLine | $line');
      },
    );
  }

  /// 看门狗触发后有界等待输出收尾，并主动取消本地管道订阅。
  ///
  /// 特权修复命令自身使用 root 身份的 GNU timeout 管理整个脚本进程组；这里的
  /// 取消仅用于确保即使提权进程异常未关闭管道，Flutter 也不会永久等待。
  Future<void> _finishTimedOutCaptures(
    String commandLine,
    _ShellStreamCapture stdoutCapture,
    _ShellStreamCapture stderrCapture,
  ) async {
    try {
      await Future.wait([
        stdoutCapture.done,
        stderrCapture.done,
      ]).timeout(_streamDrainGracePeriod);
    } catch (error, stackTrace) {
      AppLogger.warning(
        '[Shell] 超时后的输出管道未自然结束，停止本地读取: $commandLine',
        error,
        stackTrace,
      );
    } finally {
      await Future.wait([stdoutCapture.cancel(), stderrCapture.cancel()]);
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
  _ShellCommandLogWriter._(this._sink);

  /// 单批日志达到该大小时落盘，在吞吐量和故障时可见性之间取平衡。
  static const int _flushThresholdBytes = 64 * 1024;

  final IOSink _sink;
  Future<void> _pending = Future<void>.value();
  int _unflushedBytes = 0;

  static Future<_ShellCommandLogWriter> open(
    ShellCommandLogOptions options,
  ) async {
    final file = File(options.filePath);
    await file.parent.create(recursive: true);
    final sink = file.openWrite(
      mode: options.overwrite ? FileMode.write : FileMode.append,
      encoding: utf8,
    );
    return _ShellCommandLogWriter._(sink);
  }

  /// 串行写入一行日志，并按批次刷新，避免逐行打开文件和强制 fsync。
  Future<void> writeLine(String line) {
    _pending = _pending.then((_) async {
      _sink.writeln(line);
      _unflushedBytes += utf8.encode(line).length + 1;
      if (_unflushedBytes >= _flushThresholdBytes) {
        await _sink.flush();
        _unflushedBytes = 0;
      }
    });
    return _pending;
  }

  /// 等待所有排队内容后关闭文件，确保返回结果时完整日志已经可读。
  Future<void> close() async {
    try {
      await _pending;
      await _sink.flush();
    } finally {
      await _sink.close();
    }
  }
}

/// Shell 最终结果使用的输出缓冲。
///
/// 普通命令保持完整结果；流式命令只保留固定字节数的尾部。每次按完整行淘汰，
/// 不会在 UTF-8 字符中间截断。
class _ShellOutputBuffer {
  /// 创建可选上限的输出缓冲。
  _ShellOutputBuffer({required this.maxBytes});

  /// `null` 表示普通命令需要保留完整输出。
  final int? maxBytes;

  final StringBuffer _unbounded = StringBuffer();
  final ListQueue<_CapturedOutputLine> _bounded =
      ListQueue<_CapturedOutputLine>();
  int _boundedBytes = 0;

  /// 追加一行输出。
  void addLine(String line) {
    final limit = maxBytes;
    if (limit == null) {
      _unbounded.writeln(line);
      return;
    }

    final byteLength = utf8.encode(line).length + 1;
    if (byteLength > limit) {
      // 单行超过上限时不保留该行，完整内容仍然存在专用日志中。
      _bounded.clear();
      _boundedBytes = 0;
      return;
    }

    _bounded.add(_CapturedOutputLine(line: line, byteLength: byteLength));
    _boundedBytes += byteLength;
    while (_boundedBytes > limit && _bounded.isNotEmpty) {
      _boundedBytes -= _bounded.removeFirst().byteLength;
    }
  }

  /// 当前保留的文本。
  String get text {
    if (maxBytes == null) {
      return _unbounded.toString();
    }
    return _bounded.map((item) => item.line).join('\n') +
        (_bounded.isEmpty ? '' : '\n');
  }
}

/// 有界输出缓冲中的单行及其 UTF-8 占用。
class _CapturedOutputLine {
  /// 创建缓冲行。
  const _CapturedOutputLine({required this.line, required this.byteLength});

  /// 不含换行符的原始行。
  final String line;

  /// 包含单个换行符的 UTF-8 字节数。
  final int byteLength;
}

/// 可取消的单路输出读取。
class _ShellStreamCapture {
  _ShellStreamCapture._();

  late final StreamSubscription<String> _subscription;
  final Completer<void> _doneCompleter = Completer<void>();
  bool _cancelled = false;

  /// 以逐行背压方式启动读取，日志批次落盘期间不会继续无限读取管道。
  static _ShellStreamCapture start({
    required Stream<String> stream,
    required Future<void> Function(String line) onLine,
  }) {
    final capture = _ShellStreamCapture._();
    capture._subscription = stream.listen(
      null,
      onError: (Object error, StackTrace stackTrace) {
        if (!capture._doneCompleter.isCompleted) {
          capture._doneCompleter.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!capture._doneCompleter.isCompleted) {
          capture._doneCompleter.complete();
        }
      },
      cancelOnError: true,
    );
    capture._subscription.onData((line) {
      capture._subscription.pause();
      onLine(line).then(
        (_) {
          if (!capture._cancelled && !capture._doneCompleter.isCompleted) {
            capture._subscription.resume();
          }
        },
        onError: (Object error, StackTrace stackTrace) async {
          capture._cancelled = true;
          await capture._subscription.cancel();
          if (!capture._doneCompleter.isCompleted) {
            capture._doneCompleter.completeError(error, stackTrace);
          }
        },
      );
    });
    return capture;
  }

  /// 输出流自然结束或发生错误时完成。
  Future<void> get done => _doneCompleter.future;

  /// 停止本地读取；即使底层 IO 取消异常，也不让看门狗路径再次挂住。
  Future<void> cancel() async {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    try {
      await _subscription.cancel().timeout(const Duration(seconds: 1));
    } catch (_) {
      // 看门狗清理必须有界；底层管道异常只能记录在命令日志中。
    } finally {
      if (!_doneCompleter.isCompleted) {
        _doneCompleter.complete();
      }
    }
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
    ShellCommandLogOptions? logOptions,
  }) {
    return _runner.run(
      command,
      timeout: timeout,
      environment: environment,
      logOptions: logOptions,
    );
  }

  /// 执行命令并逐行返回 stdout/stderr。
  ///
  /// 生产执行器会真实流式回调；仅实现旧接口的测试替身会在命令结束后按行回放，
  /// 使业务服务可测试且不破坏已有替身。
  Future<ShellCommandResult> runStreaming(
    List<String> command, {
    required void Function(ShellOutputLine output) onOutput,
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    final runner = _runner;
    if (runner is StreamingShellCommandRunner) {
      return (runner as StreamingShellCommandRunner).runStreaming(
        command,
        onOutput: onOutput,
        timeout: timeout,
        environment: environment,
        logOptions: logOptions,
      );
    }

    final result = await runner.run(
      command,
      timeout: timeout,
      environment: environment,
      logOptions: logOptions,
    );
    for (final line in const LineSplitter().convert(result.stdout)) {
      onOutput(ShellOutputLine(channel: ShellOutputChannel.stdout, line: line));
    }
    for (final line in const LineSplitter().convert(result.stderr)) {
      onOutput(ShellOutputLine(channel: ShellOutputChannel.stderr, line: line));
    }
    return result;
  }
}
