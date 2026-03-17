import 'dart:async';
import 'dart:io';
import 'dart:convert';

import '../logging/app_logger.dart';
import 'nvidia_workaround.dart';

/// ll-cli 命令路径
const String kLlCliPath = 'll-cli';

/// 默认超时时间
const Duration kDefaultTimeout = Duration(minutes: 30);

/// 安装操作超时时间（较长）
const Duration kInstallTimeout = Duration(minutes: 60);

/// 查询操作超时时间（较短）
const Duration kQueryTimeout = Duration(seconds: 30);

/// CLI 执行输出
class CliOutput {
  const CliOutput({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  final String stdout;
  final String stderr;
  final int exitCode;

  bool get success => exitCode == 0;

  @override
  String toString() => 'CliOutput(exitCode: $exitCode, stdout: ${stdout.length} chars, stderr: ${stderr.length} chars)';
}

/// CLI 执行结果（带进程引用）
class CliResult {
  const CliResult({
    required this.output,
    this.process,
  });

  final CliOutput output;
  final Process? process;

  bool get success => output.success;
  String get stdout => output.stdout;
  String get stderr => output.stderr;
  int get exitCode => output.exitCode;
}

/// 进度事件
class ProgressEvent {
  const ProgressEvent({
    required this.line,
    required this.type,
  });

  final String line;
  final ProgressEventType type;

  /// 尝试解析进度百分比
  double? get progress {
    // 尝试匹配 "xx%" 格式
    final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(line);
    if (percentMatch != null) {
      return double.tryParse(percentMatch.group(1)!) ?? 0.0;
    }

    // 尝试匹配下载进度 "downloaded/total" 格式
    final downloadMatch = RegExp(r'(\d+)/(\d+)').firstMatch(line);
    if (downloadMatch != null) {
      final downloaded = int.tryParse(downloadMatch.group(1)!) ?? 0;
      final total = int.tryParse(downloadMatch.group(2)!) ?? 1;
      if (total > 0) {
        return (downloaded / total) * 100;
      }
    }

    return null;
  }
}

/// 进度事件类型
enum ProgressEventType {
  stdout,
  stderr,
  error,
}

/// CLI 命令执行器
///
/// 提供统一的 ll-cli 命令执行接口，支持：
/// - 同步执行（等待完成）
/// - 流式执行（实时输出）
/// - 超时控制
/// - 进程取消
/// - NVIDIA 驱动兼容性
class CliExecutor {
  CliExecutor._();

  /// 活跃进程映射（用于取消）
  static final Map<String, Process> _activeProcesses = {};

  /// 活跃进程的取消信号
  static final Map<String, Completer<void>> _cancelSignals = {};

  /// 强制英文 locale 环境变量（确保输出可解析）
  static Map<String, String> get _englishLocaleEnv => {
    'LC_ALL': 'C.UTF-8',
    'LANG': 'C.UTF-8',
    'LANGUAGE': 'C.UTF-8',
    'LC_MESSAGES': 'C.UTF-8',
    ...NvidiaWorkaround.getEnvVars(),
  };

  /// 执行 ll-cli 命令（同步等待）
  ///
  /// [args] 命令参数
  /// [timeout] 超时时间
  /// [processId] 进程标识（用于取消）
  /// [locale] 语言环境（默认英文）
  static Future<CliOutput> execute(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
    String? locale,
  }) async {
    final result = await executeWithProcess(
      args,
      timeout: timeout,
      processId: processId,
      locale: locale,
    );
    return result.output;
  }

  /// 执行 ll-cli 命令并返回进程引用
  ///
  /// [args] 命令参数
  /// [timeout] 超时时间
  /// [processId] 进程标识（用于取消）
  /// [locale] 语言环境
  static Future<CliResult> executeWithProcess(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
    String? locale,
  }) async {
    final commandStr = 'll-cli ${args.join(' ')}';
    AppLogger.debug('[CLI] 执行命令: $commandStr');

    Process? process;
    try {
      // 启动进程
      process = await Process.start(
        kLlCliPath,
        args,
        environment: _englishLocaleEnv,
      );

      // 注册活跃进程
      if (processId != null) {
        _activeProcesses[processId] = process;
        _cancelSignals[processId] = Completer<void>();
      }

      // 收集输出
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stdoutBuffer.writeln(line);
        AppLogger.debug('[CLI stdout] $line');
      });

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stderrBuffer.writeln(line);
        AppLogger.warning('[CLI stderr] $line');
      });

      // 等待进程完成或超时
      final exitCode = await _waitForExit(
        process,
        stdoutFuture,
        stderrFuture,
        timeout,
        processId,
      );

      final output = CliOutput(
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: exitCode,
      );

      AppLogger.info('[CLI] 命令完成: exitCode=$exitCode');
      return CliResult(output: output, process: process);

    } on TimeoutException {
      AppLogger.error('[CLI] 命令超时: $commandStr');
      process?.kill(ProcessSignal.sigkill);
      throw CliTimeoutException(
        '命令执行超时 (${timeout.inSeconds}s)',
        commandStr,
      );
    } catch (e, stack) {
      AppLogger.error('[CLI] 命令执行异常', e, stack);
      rethrow;
    } finally {
      // 清理活跃进程记录
      if (processId != null) {
        _activeProcesses.remove(processId);
        _cancelSignals.remove(processId);
      }
    }
  }

  /// 执行 ll-cli 命令（流式输出）
  ///
  /// 返回进度事件流，适合长时间运行的操作（如安装）
  ///
  /// [args] 命令参数
  /// [processId] 进程标识（用于取消）
  /// [locale] 语言环境
  static Stream<ProgressEvent> executeWithProgress(
    List<String> args, {
    String? processId,
    String? locale,
  }) async* {
    yield* executeWithProgressAndProcess(
      args,
      processId: processId,
      locale: locale,
    );
  }

  /// 执行 ll-cli 命令（流式输出，带进程回调）
  ///
  /// 返回进度事件流，适合长时间运行的操作（如安装）
  /// 通过 [onProcessCreated] 回调可获取进程引用，用于记录 PID 等
  ///
  /// [args] 命令参数
  /// [processId] 进程标识（用于取消）
  /// [locale] 语言环境
  /// [onProcessCreated] 进程创建后的回调，可用于获取 PID
  static Stream<ProgressEvent> executeWithProgressAndProcess(
    List<String> args, {
    String? processId,
    String? locale,
    void Function(Process process)? onProcessCreated,
  }) async* {
    final commandStr = 'll-cli ${args.join(' ')}';
    AppLogger.debug('[CLI] 执行命令(流式): $commandStr');

    Process? process;
    try {
      // 启动进程
      process = await Process.start(
        kLlCliPath,
        args,
        environment: _englishLocaleEnv,
      );

      // 回调通知进程已创建（可用于记录 PID）
      onProcessCreated?.call(process);

      // 注册活跃进程
      if (processId != null) {
        _activeProcesses[processId] = process;
        _cancelSignals[processId] = Completer<void>();
      }

      // 创建流控制器
      final controller = StreamController<ProgressEvent>();

      // 处理 stdout
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              AppLogger.debug('[CLI stdout] $line');
              controller.add(ProgressEvent(
                line: line,
                type: ProgressEventType.stdout,
              ));
            },
            onError: (error) {
              controller.add(ProgressEvent(
                line: error.toString(),
                type: ProgressEventType.error,
              ));
            },
          );

      // 处理 stderr
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              AppLogger.warning('[CLI stderr] $line');
              controller.add(ProgressEvent(
                line: line,
                type: ProgressEventType.stderr,
              ));
            },
            onError: (error) {
              controller.add(ProgressEvent(
                line: error.toString(),
                type: ProgressEventType.error,
              ));
            },
          );

      // 等待进程完成
      process.exitCode.then((exitCode) {
        AppLogger.info('[CLI] 流式命令完成: exitCode=$exitCode');
        controller.close();
      });

      // 监听取消信号
      if (processId != null) {
        _cancelSignals[processId]!.future.then((_) {
          AppLogger.info('[CLI] 收到取消信号，终止进程: $processId');
          process?.kill(ProcessSignal.sigterm);
        });
      }

      // 返回事件流
      yield* controller.stream;

    } catch (e, stack) {
      AppLogger.error('[CLI] 流式命令执行异常', e, stack);
      rethrow;
    } finally {
      // 清理活跃进程记录
      if (processId != null) {
        _activeProcesses.remove(processId);
        _cancelSignals.remove(processId);
      }
    }
  }

  /// 执行 ll-cli 命令，失败时抛出异常
  ///
  /// [args] 命令参数
  /// [timeout] 超时时间
  /// [processId] 进程标识
  static Future<String> executeOrThrow(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
  }) async {
    final output = await execute(
      args,
      timeout: timeout,
      processId: processId,
    );

    if (!output.success) {
      throw CliExecutionException(
        output.stderr.isNotEmpty ? output.stderr : '命令执行失败',
        output.exitCode,
        'll-cli ${args.join(' ')}',
      );
    }

    return output.stdout;
  }

  /// 取消正在执行的进程
  ///
  /// [processId] 进程标识
  /// [force] 是否强制终止（SIGKILL）
  static bool cancel(String processId, {bool force = false}) {
    final process = _activeProcesses[processId];
    if (process == null) {
      AppLogger.warning('[CLI] 未找到进程: $processId');
      return false;
    }

    try {
      // 发送取消信号
      _cancelSignals[processId]?.complete();

      // 终止进程
      if (force) {
        process.kill(ProcessSignal.sigkill);
      } else {
        process.kill(ProcessSignal.sigterm);
      }

      AppLogger.info('[CLI] 已取消进程: $processId');
      return true;
    } catch (e) {
      AppLogger.error('[CLI] 取消进程失败: $processId', e);
      return false;
    }
  }

  /// 取消正在执行的进程（增强版，参考 Rust 版本实现）
  ///
  /// 1. 先通过内部机制终止 Dart 进程
  /// 2. 使用 pkexec killall 终止 ll-cli 和 ll-package-manager 进程
  ///
  /// 这样可以确保安装相关的所有进程都被正确终止。
  ///
  /// [processId] 进程标识
  /// [force] 是否强制终止（SIGKILL）
  /// [killPackageMananger] 是否同时终止 ll-package-manager（默认 true）
  static Future<bool> cancelWithSystemKill(
    String processId, {
    bool force = false,
    bool killPackageMananger = true,
  }) async {
    AppLogger.info('[CLI] 开始系统级取消: $processId');

    // 1. 先通过内部机制终止 Dart 进程
    final internalCancelled = cancel(processId, force: force);

    // 2. 使用 pkexec killall 终止 ll-cli 和 ll-package-manager
    // 参考 Rust 版本: pkexec killall -15 ll-cli ll-package-manager
    try {
      final args = <String>['killall', '-15']; // SIGTERM 优雅终止
      args.add('ll-cli');
      if (killPackageMananger) {
        args.add('ll-package-manager');
      }

      AppLogger.info('[CLI] 执行系统级进程终止: pkexec ${args.join(' ')}');

      final result = await Process.run('pkexec', args);

      if (result.exitCode == 0) {
        AppLogger.info('[CLI] 系统级进程终止成功');
      } else {
        // pkexec 可能返回非 0（如无匹配进程），记录但不视为错误
        AppLogger.debug(
          '[CLI] 系统级进程终止返回: exitCode=${result.exitCode}, '
          'stdout=${result.stdout}, stderr=${result.stderr}',
        );
      }
    } on ProcessException catch (e) {
      // pkexec 不存在或执行失败，记录警告但不阻断
      AppLogger.warning('[CLI] pkexec killall 执行失败: $e');
    } catch (e, stack) {
      AppLogger.error('[CLI] 系统级进程终止异常', e, stack);
    }

    AppLogger.info('[CLI] 系统级取消完成: $processId (内部取消: $internalCancelled)');
    return internalCancelled;
  }

  /// 检查进程是否正在运行
  static bool isRunning(String processId) {
    return _activeProcesses.containsKey(processId);
  }

  /// 获取所有活跃进程ID
  static List<String> get activeProcessIds => _activeProcesses.keys.toList();

  /// 等待进程退出
  static Future<int> _waitForExit(
    Process process,
    Future<void> stdoutFuture,
    Future<void> stderrFuture,
    Duration timeout,
    String? processId,
  ) async {
    // 创建超时 Future
    final timeoutFuture = Future.delayed(timeout);

    // 创建取消 Future
    final cancelFuture = processId != null
        ? _cancelSignals[processId]!.future
        : Completer<void>().future;

    // 等待任一条件触发
    final result = await Future.any([
      process.exitCode,
      timeoutFuture.then((_) => -1), // 超时返回 -1
      cancelFuture.then((_) => -2),  // 取消返回 -2
    ]);

    // 处理超时
    if (result == -1) {
      process.kill(ProcessSignal.sigkill);
      throw TimeoutException('命令执行超时', timeout);
    }

    // 处理取消
    if (result == -2) {
      process.kill(ProcessSignal.sigterm);
      throw const CliCancelledException('命令已取消');
    }

    // 等待输出收集完成
    await stdoutFuture;
    await stderrFuture;

    return result;
  }
}

/// CLI 执行超时异常
class CliTimeoutException implements Exception {
  const CliTimeoutException(this.message, this.command);

  final String message;
  final String command;

  @override
  String toString() => 'CliTimeoutException: $message (command: $command)';
}

/// CLI 执行失败异常
class CliExecutionException implements Exception {
  const CliExecutionException(this.message, this.exitCode, this.command);

  final String message;
  final int exitCode;
  final String command;

  @override
  String toString() => 'CliExecutionException: $message (exitCode: $exitCode, command: $command)';
}

/// CLI 取消异常
class CliCancelledException implements Exception {
  const CliCancelledException(this.message);

  final String message;

  @override
  String toString() => 'CliCancelledException: $message';
}