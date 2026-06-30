import 'dart:async';
import 'dart:io';
import 'dart:convert';

import '../logging/app_logger.dart';
import '../network/api_exceptions.dart';

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

  /// 失败文案优先取 stderr，缺失时回退到 stdout，避免丢掉 CLI 主输出。
  String get primaryMessage {
    final trimmedStderr = stderr.trim();
    if (trimmedStderr.isNotEmpty) {
      return trimmedStderr;
    }

    return stdout.trim();
  }

  @override
  String toString() =>
      'CliOutput(exitCode: $exitCode, stdout: ${stdout.length} chars, stderr: ${stderr.length} chars)';
}

/// CLI 执行结果（带进程引用）
class CliResult {
  const CliResult({required this.output, this.process});

  final CliOutput output;
  final Process? process;

  bool get success => output.success;
  String get stdout => output.stdout;
  String get stderr => output.stderr;
  int get exitCode => output.exitCode;
}

/// 进度事件
class ProgressEvent {
  const ProgressEvent({required this.line, required this.type});

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
enum ProgressEventType { stdout, stderr, error }

/// CLI 命令执行器
///
/// 提供统一的 ll-cli 命令执行接口，支持：
/// - 同步执行（等待完成）
/// - 流式执行（实时输出）
/// - 超时控制
/// - 进程取消
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
    final commandStr = _buildCommandString(args);
    _logCommandStart(commandStr);

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
            _logCommandStdout(commandStr, line);
          });

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
            stderrBuffer.writeln(line);
            _logCommandStderr(commandStr, line);
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

      _logCommandExit(commandStr, exitCode);
      return CliResult(output: output, process: process);
    } on TimeoutException {
      AppLogger.error('[CLI] 命令超时: $commandStr');
      process?.kill(ProcessSignal.sigkill);
      throw const CliTimeoutException('命令执行超时', 'll-cli');
    } catch (e, stack) {
      AppLogger.error('[CLI] 命令执行异常: $commandStr', e, stack);
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
    final commandStr = _buildCommandString(args);
    _logCommandStart(commandStr, streaming: true);

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
              _logCommandStdout(commandStr, line, streaming: true);
              controller.add(
                ProgressEvent(line: line, type: ProgressEventType.stdout),
              );
            },
            onError: (error) {
              AppLogger.error('[CLI][stdout] 读取异常: $commandStr', error);
              controller.add(
                ProgressEvent(
                  line: error.toString(),
                  type: ProgressEventType.error,
                ),
              );
            },
          );

      // 处理 stderr
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              _logCommandStderr(commandStr, line, streaming: true);
              controller.add(
                ProgressEvent(line: line, type: ProgressEventType.stderr),
              );
            },
            onError: (error) {
              AppLogger.error('[CLI][stderr] 读取异常: $commandStr', error);
              controller.add(
                ProgressEvent(
                  line: error.toString(),
                  type: ProgressEventType.error,
                ),
              );
            },
          );

      // 等待进程完成
      process.exitCode.then((exitCode) {
        _logCommandExit(commandStr, exitCode, streaming: true);
        controller.close();
      });

      // 监听取消信号
      if (processId != null) {
        _cancelSignals[processId]!.future.then((_) {
          AppLogger.info('[CLI] 收到取消信号，终止进程: $processId ($commandStr)');
          process?.kill(ProcessSignal.sigterm);
        });
      }

      // 返回事件流
      yield* controller.stream;
    } catch (e, stack) {
      AppLogger.error('[CLI] 流式命令执行异常: $commandStr', e, stack);
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
    final output = await execute(args, timeout: timeout, processId: processId);

    if (!output.success) {
      throw CliExecutionException(
        output.primaryMessage.isNotEmpty ? output.primaryMessage : '命令执行失败',
        output.exitCode,
        'll-cli',
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

  /// 取消正在执行的安装进程（精确 PID + SIGTERM 协作取消）
  ///
  /// 设计原理（详见 docs/23-install-cancel-sigterm-plan.md）：
  /// 商店通过 [Process.start('ll-cli')] 启动安装，ll-cli 内部 `ensureAuthorized()`
  /// 失败后会用 `execvp("pkexec", ["ll-cli", ...])` 替换自身进程映像（PID 不变，
  /// 属主变 root）。因此 [processId] 对应的 [pid] 精确绑定到这一次安装任务，
  /// 经过 `ll-cli → pkexec → root ll-cli` 全程 PID 连续，[pid] 就是 root 进程的 PID。
  ///
  /// 向该 root 进程发 SIGTERM（与命令行 Ctrl+C 走同一个 signal handler，
  /// 见 linyaps `initialize.cpp:122` 的 `catchUnixSignals({SIGTERM, SIGQUIT,
  /// SIGINT, SIGHUP})`），触发 `aboutToQuit → cancelCurrentTask → D-Bus Cancel`，
  /// daemon 收到 Cancel 后 `g_cancellable_cancel()` 中断 OSTree 下载，任务以
  /// `canceled` 结束（daemon journal 会打印 `has been canceled by user`）。
  /// **不杀 ll-package-manager daemon**：daemon 由协作取消优雅停止，避免被
  /// 强杀后 systemd 重启带来的状态脏污。
  ///
  /// 相比旧的 `pkexec killall -15 ll-cli ll-package-manager`（全局杀所有同名
  /// 进程 + 杀常驻 daemon），本实现精确到单次任务的 PID，消除误杀风险。
  ///
  /// [processId] 进程标识（用于清理 Dart 侧 [_activeProcesses] 引用）
  /// [pid] 目标 root ll-cli 进程的 PID，必须由调用方从 `_activeProcessPids`
  ///   读取（该 PID 在 `onProcessCreated` 时记录，execvp/pkexec 后仍指向 root 进程）
  /// [force] 内部 Dart 侧 [Process] 引用收尾是否用 SIGKILL（不参与成功判定）
  ///
  /// 返回：
  /// - `true` - `pkexec kill -15 <pid>` 成功发送信号，协作取消已触发
  /// - `false` - pkexec 授权被取消、发信号失败，或目标进程已退出
  static Future<bool> cancelWithSystemKill(
    String processId, {
    required int pid,
    bool force = false,
  }) async {
    AppLogger.info('[CLI] 开始精确 PID 取消: $processId (pid=$pid)');

    // 用 pkexec 提权向 root 的 ll-cli 进程发 SIGTERM（信号 15）。
    // pkexec.exec 是独立的 polkit action（auth_admin），会弹一次授权框，
    // 这无法避免（除非新增 polkit 免密规则，需单独评估安全性）。
    bool signalSent = false;
    try {
      AppLogger.info('[CLI] 执行: pkexec kill -15 $pid');
      final result = await Process.run('pkexec', ['kill', '-15', '$pid']);

      // kill 退出码 0 表示成功发送信号。
      if (result.exitCode == 0) {
        signalSent = true;
        AppLogger.info('[CLI] SIGTERM 已发送: pid=$pid');
      } else {
        // 非 0 退出码：进程不存在（可能已结束）、权限不足或用户取消授权。
        AppLogger.warning(
          '[CLI] pkexec kill 失败: exitCode=${result.exitCode}, '
          'stdout=${result.stdout}, stderr=${result.stderr}',
        );
      }
    } on ProcessException catch (e) {
      // pkexec 不存在或执行失败。
      AppLogger.warning('[CLI] pkexec kill 执行失败: $e');
    } catch (e, stack) {
      AppLogger.error('[CLI] pkexec kill 异常', e, stack);
    }

    // 信号发送成功后，清理 Dart 侧 Process 引用（仅资源收尾，不参与成功判定）。
    bool internalCancelled = false;
    if (signalSent) {
      internalCancelled = cancel(processId, force: force);
    }

    AppLogger.info(
      '[CLI] 精确 PID 取消完成: $processId (内部收尾: $internalCancelled, 结果: $signalSent)',
    );

    return signalSent;
  }

  /// 检查进程是否正在运行
  static bool isRunning(String processId) {
    return _activeProcesses.containsKey(processId);
  }

  /// 获取所有活跃进程ID
  static List<String> get activeProcessIds => _activeProcesses.keys.toList();

  static String _buildCommandString(List<String> args) {
    return '$kLlCliPath ${args.join(' ')}';
  }

  static void _logCommandStart(String commandStr, {bool streaming = false}) {
    final modeSuffix = streaming ? '(流式)' : '';
    AppLogger.info('[CLI] 启动命令$modeSuffix: $commandStr');
  }

  static void _logCommandStdout(
    String commandStr,
    String line, {
    bool streaming = false,
  }) {
    final modeSuffix = streaming ? '(流式)' : '';
    AppLogger.debug('[CLI stdout]$modeSuffix $commandStr | $line');
  }

  static void _logCommandStderr(
    String commandStr,
    String line, {
    bool streaming = false,
  }) {
    final modeSuffix = streaming ? '(流式)' : '';
    AppLogger.warning('[CLI stderr]$modeSuffix $commandStr | $line');
  }

  static void _logCommandExit(
    String commandStr,
    int exitCode, {
    bool streaming = false,
  }) {
    final modeSuffix = streaming ? '(流式)' : '';
    final message = '[CLI] 命令退出$modeSuffix: $commandStr (exitCode=$exitCode)';
    if (exitCode == 0) {
      AppLogger.info(message);
      return;
    }

    AppLogger.warning(message);
  }

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
      cancelFuture.then((_) => -2), // 取消返回 -2
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
