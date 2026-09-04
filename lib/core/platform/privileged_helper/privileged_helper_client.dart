/// 特权 helper 会话客户端：pkexec 启动、握手、复用、任务事件流与收尾
/// （docs/47 §9）。
///
/// 本类必须是应用生命周期单例，不能放入会被 autoDispose 重建的 Repository；
/// 并发 `ensureStarted()` 复用同一个启动 Future，防止快速入队时同时拉起多个
/// pkexec（§4.3）。Repository 依赖 [PrivilegedHelperTransport] 抽象，测试可
/// 注入替身。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../logging/app_logger.dart';
import '../bounded_output_buffer.dart';
import 'privileged_helper_binary.dart';
import 'privileged_helper_exception.dart';
import 'privileged_helper_protocol.dart';

/// 单任务执行期间推送给上层的事件。
sealed class PrivilegedHelperTaskEvent {
  const PrivilegedHelperTaskEvent();
}

/// 一行原始 ll-cli 输出（stdout 或 stderr），仍交由 CliOutputParser 解析。
class PrivilegedHelperTaskLine extends PrivilegedHelperTaskEvent {
  const PrivilegedHelperTaskLine({required this.isStderr, required this.line});

  final bool isStderr;
  final String line;
}

/// 任务终态：子进程已被真实回收；业务成败由输出解析与安装前后快照决定。
class PrivilegedHelperTaskExited extends PrivilegedHelperTaskEvent {
  const PrivilegedHelperTaskExited({
    required this.exitCode,
    required this.cancelRequested,
  });

  final int exitCode;
  final bool cancelRequested;
}

/// Repository 依赖的传输端口；由 [PrivilegedHelperClient] 实现，测试注入替身。
abstract class PrivilegedHelperTransport {
  /// 是否有任务经本传输启动且尚未收到终态。
  bool get hasActiveTask;

  /// 确保 helper 会话可用（首次会触发一次 pkexec 授权）。
  ///
  /// 抛出 [PrivilegedHelperAuthorizationCancelledException]（用户取消授权）、
  /// [PrivilegedHelperUnavailableException]（授权组件不可用）或
  /// [PrivilegedHelperStartupException]（ready 超时/通道异常）。
  Future<void> ensureStarted();

  /// 启动一个任务并返回事件流；流以 [PrivilegedHelperTaskExited] 结束，
  /// 或以 [PrivilegedHelperException] 异常结束。
  Stream<PrivilegedHelperTaskEvent> startTask(
    PrivilegedHelperStartRequest request,
  );

  /// 请求取消当前任务。
  ///
  /// 返回 true 表示 helper 已接受（SIGTERM 已发出）；false 表示没有匹配的
  /// 运行中任务。传输异常按 false 处理并记录日志，不向上抛。
  Future<bool> cancelTask(String requestId);

  /// 主动收尾会话（应用退出路径）：关闭 stdin 触发 helper 协作取消与退出。
  Future<void> disposeSession();
}

/// helper 会话的运行状态。
enum _SessionState { notStarted, starting, ready }

/// helper 会话的启动命令；默认 `pkexec --disable-internal-agent <helper>`。
typedef PrivilegedHelperLauncher =
    Future<Process> Function(List<String> command);

class PrivilegedHelperClient implements PrivilegedHelperTransport {
  /// 创建客户端。
  ///
  /// [readyTimeout] 是 pkexec 启动到收到 ready 的上限；认证对话框可能等待
  /// 用户输入，取值需覆盖 polkit 代理自身的自动关闭窗口。
  /// [launcher] 为测试注入缝：默认启动 pkexec，测试用它替换为假 helper 进程。
  PrivilegedHelperClient({
    PrivilegedHelperBinary? binary,
    this.readyTimeout = const Duration(minutes: 5),
    @visibleForTesting PrivilegedHelperLauncher? launcher,
  }) : _binary = binary ?? PrivilegedHelperBinary(),
       _launcher = launcher ?? _launchPkexec;

  final PrivilegedHelperBinary _binary;
  final Duration readyTimeout;
  final PrivilegedHelperLauncher _launcher;

  _SessionState _state = _SessionState.notStarted;
  Process? _process;
  PreparedHelperPath? _preparedPath;
  StreamSubscription<String>? _stdoutLines;
  StreamSubscription<String>? _stderrLines;
  final BoundedOutputBuffer _helperStderr = BoundedOutputBuffer(
    maxBytes: 64 * 1024,
  );

  /// 当前启动轮次的 ready 完成器；由 ready 事件完成，由 stdout 读错误取消。
  Completer<void>? _readyCompleter;

  /// 并发 ensureStarted 的单飞 Future（§4.3）。
  Future<void>? _starting;

  /// 当前任务的事件控制器与 requestId。
  StreamController<PrivilegedHelperTaskEvent>? _taskEvents;
  String? _activeRequestId;

  /// cancelTask 的应答完成器，按 requestId 匹配一次。
  Completer<bool>? _cancelCompleter;
  String? _cancelRequestId;

  @override
  bool get hasActiveTask => _activeRequestId != null;

  @override
  Future<void> ensureStarted() {
    if (_state == _SessionState.ready && _process != null) {
      // 空闲自退/崩溃由 stdout EOF 监听负责回收 _process；能走到这里即为
      // 可用会话（§9.1 第 5 步：同会话后续任务复用，不再调用 pkexec）。
      return Future.value();
    }
    return _starting ??= _startSession();
  }

  Future<void> _startSession() async {
    // 每次启动都重新 resolve 路径：非 FUSE 直启 bundle 路径；FUSE 先清扫
    // 上次遗留再创建新暂存副本（§5.2.1）。
    final prepared = await _binary.prepare();
    _preparedPath = prepared;

    final Process process;
    try {
      // --disable-internal-agent：无桌面代理时明确失败，避免文本代理占用
      // helper stdin 与协议通道争抢输入（§6.1）。
      process = await _launcher(
        ['pkexec', '--disable-internal-agent', prepared.path],
      );
    } catch (error) {
      await prepared.release();
      throw PrivilegedHelperUnavailableException('pkexec 启动失败: $error');
    }
    _process = process;
    _state = _SessionState.starting;

    final readyCompleter = Completer<void>();
    _readyCompleter = readyCompleter;
    _observeStdout(process, readyCompleter);
    _stderrLines = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_helperStderr.addLine);

    // 竞速结果用标签区分：ready / exit:<code> / timeout。进程退出必须由
    // exitCode 路径判定（126/127 映射依赖退出码），stdout EOF 不单独定因。
    String outcome;
    try {
      outcome = await Future.any<String>([
        readyCompleter.future.then((_) => 'ready'),
        process.exitCode.then<String>((code) => 'exit:$code'),
        Future<String>.delayed(readyTimeout, () => 'timeout'),
      ]);
    } catch (error) {
      await _teardownSession();
      if (error is PrivilegedHelperException) {
        rethrow;
      }
      throw PrivilegedHelperStartupException('helper 启动失败: $error');
    }

    if (outcome != 'ready') {
      await _teardownSession();
      switch (outcome) {
        case 'exit:126':
          throw const PrivilegedHelperAuthorizationCancelledException();
        case 'exit:127':
          throw const PrivilegedHelperUnavailableException(
            '无法执行 helper（pkexec 退出码 127：文件缺失或不可执行）',
          );
        case 'timeout':
          // 超时主动收掉残留进程，避免悬挂的 pkexec 认证窗。
          process.kill(ProcessSignal.sigterm);
          throw PrivilegedHelperStartupException(
            '等待 helper ready 超时（${readyTimeout.inSeconds}s）',
          );
        default:
          final code = int.tryParse(outcome.substring(5)) ?? -1;
          throw PrivilegedHelperStartupException(
            'helper 启动前退出（exitCode=$code）',
          );
      }
    }

    _state = _SessionState.ready;
    AppLogger.info('特权 helper 会话已建立（staged=${prepared.staged}）');
    // FUSE 形态：收到 ready 后立即删除暂存文件（§9.1 第 4 步）；删除运行中
    // 进程的 exe 无害，且 pkexec 认证期间路径必须存在，因此不能更早。
    unawaited(prepared.release());
  }

  void _observeStdout(Process process, Completer<void> readyCompleter) {
    _stdoutLines = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _handleEventLine,
          onError: (Object error) {
            if (!readyCompleter.isCompleted) {
              readyCompleter.completeError(
                const PrivilegedHelperStartupException('helper stdout 读取失败'),
              );
            }
          },
          onDone: _handleSessionEof,
        );
  }

  /// helper stdout 的一行事件。
  void _handleEventLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    final PrivilegedHelperEvent event;
    try {
      event = decodePrivilegedHelperEvent(line);
    } catch (error) {
      unawaited(_handleProtocolFailure(error));
      return;
    }
    switch (event) {
      case PrivilegedHelperReadyEvent():
        final completer = _readyCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      case PrivilegedHelperStartedEvent():
        // started 只作诊断，任务流由 output/exited 驱动；pid 不作取消凭据。
        AppLogger.debug(
          '特权 helper 任务已启动: ${event.requestId} (pid=${event.pid})',
        );
      case PrivilegedHelperOutputEvent():
        final events = _taskEvents;
        if (events != null && !events.isClosed) {
          events.add(
            PrivilegedHelperTaskLine(
              isStderr: event.isStderr,
              line: event.line,
            ),
          );
        }
      case PrivilegedHelperCancelAcceptedEvent():
        _resolveCancel(event.requestId, true);
      case PrivilegedHelperExitedEvent():
        _onTaskExited(event);
      case PrivilegedHelperErrorEvent():
        _onErrorEvent(event);
    }
  }

  void _onTaskExited(PrivilegedHelperExitedEvent event) {
    final events = _taskEvents;
    if (event.requestId != _activeRequestId || events == null) {
      return;
    }
    _activeRequestId = null;
    if (!events.isClosed) {
      events.add(
        PrivilegedHelperTaskExited(
          exitCode: event.exitCode,
          cancelRequested: event.cancelRequested,
        ),
      );
      unawaited(events.close());
    }
  }

  void _onErrorEvent(PrivilegedHelperErrorEvent event) {
    final requestId = event.requestId;
    switch (event.code) {
      case PrivilegedHelperErrorCodes.busy:
        // busy 是可恢复错误：只结束对应请求，会话继续（§6.4）。
        if (requestId != null && requestId == _activeRequestId) {
          _failActiveTask(
            PrivilegedHelperBusyException('helper 拒绝并发任务: ${event.message}'),
          );
        }
      case PrivilegedHelperErrorCodes.notRunning:
        _resolveCancel(requestId, false);
      case PrivilegedHelperErrorCodes.spawnFailed:
        // ll-cli 从未启动，按任务失败结束当前流；会话仍可复用。
        if (requestId != null && requestId == _activeRequestId) {
          _failActiveTask(
            const PrivilegedHelperStartupException('无法启动 /usr/bin/ll-cli'),
          );
        }
      default:
        // invalidRequest/protocolMismatch/outputTooLarge/internal 均为致命
        // 错误：会话不可继续（§6.4）。
        unawaited(_handleProtocolFailure(
          PrivilegedHelperProtocolException(
            'helper fatal error (${event.code}): ${event.message}',
            code: event.code,
          ),
        ));
    }
  }

  void _failActiveTask(PrivilegedHelperException error) {
    final events = _taskEvents;
    _activeRequestId = null;
    if (events != null && !events.isClosed) {
      events.addError(error);
      unawaited(events.close());
    }
  }

  /// 致命协议错误：当前任务按传输失败结束，会话整体作废。
  Future<void> _handleProtocolFailure(Object error) async {
    AppLogger.error('特权 helper 协议错误', error);
    final protocolError = error is PrivilegedHelperException
        ? error
        : PrivilegedHelperProtocolException(error.toString());
    // 启动期收到非协议文本：立即让启动竞速以协议错误收场，而不是继续等
    // ready 超时或进程退出（两种结果都会掩盖真实的协议故障原因）。
    final ready = _readyCompleter;
    if (_state == _SessionState.starting &&
        ready != null &&
        !ready.isCompleted) {
      ready.completeError(protocolError);
    }
    _failActiveTask(protocolError);
    await _teardownSession();
  }

  /// helper stdout EOF：会话结束。
  ///
  /// 任务执行中遇到 EOF 时结果不确定，按传输失败报告（§8.2）；空闲期 EOF
  /// （helper 5 分钟空闲自退）是正常生命周期，静默回收（§9.2）。
  void _handleSessionEof() {
    if (_state == _SessionState.starting) {
      // 启动期的退出原因由 exitCode 竞速统一判定，这里不做额外定因。
      return;
    }
    if (_activeRequestId != null) {
      _failActiveTask(
        const PrivilegedHelperTransportException('helper 会话在任务执行中中断'),
      );
    }
    unawaited(_teardownSession());
  }

  void _resolveCancel(String? requestId, bool accepted) {
    if (requestId != null &&
        _cancelCompleter != null &&
        requestId == _cancelRequestId &&
        !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete(accepted);
    }
  }

  @override
  Stream<PrivilegedHelperTaskEvent> startTask(
    PrivilegedHelperStartRequest request,
  ) async* {
    // 前置条件：会话 ready 且无活动任务。队列串行保证正常路径不会触发
    // busy；此处提前失败避免把违规请求写进协议通道。
    if (_state != _SessionState.ready || _process == null) {
      throw StateError('startTask 调用前必须 ensureStarted 成功');
    }
    if (_activeRequestId != null) {
      throw const PrivilegedHelperBusyException('客户端已有活动任务');
    }

    final events = StreamController<PrivilegedHelperTaskEvent>();
    _taskEvents = events;
    _activeRequestId = request.requestId;
    try {
      _process!.stdin.writeln(request.encode());
      await _process!.stdin.flush();
    } catch (error) {
      AppLogger.warning('向 helper 写入 start 失败', error);
      _failActiveTask(
        PrivilegedHelperTransportException('向 helper 写入 start 失败: $error'),
      );
    }

    yield* events.stream;
  }

  @override
  Future<bool> cancelTask(String requestId) async {
    if (_state != _SessionState.ready || _process == null) {
      return false;
    }
    final completer = Completer<bool>();
    _cancelCompleter = completer;
    _cancelRequestId = requestId;
    try {
      _process!.stdin.writeln(
        PrivilegedHelperCancelRequest(requestId: requestId).encode(),
      );
      await _process!.stdin.flush();
    } catch (error) {
      AppLogger.warning('特权 helper 取消请求写入失败', error);
      return false;
    }
    // 应答窗口：cancelAccepted / notRunning；会话中断或超时按 false 处理。
    return completer.future
        .timeout(const Duration(seconds: 10))
        .catchError((Object error) {
          AppLogger.warning('特权 helper 取消应答超时或失败', error);
          return false;
        })
        .whenComplete(() {
          if (identical(_cancelCompleter, completer)) {
            _cancelCompleter = null;
            _cancelRequestId = null;
          }
        });
  }

  @override
  Future<void> disposeSession() => _teardownSession();

  /// 关闭会话：stdin 关闭触发 helper 协作取消当前任务并退出（§9.3）；
  /// 幂等，可重复调用。
  Future<void> _teardownSession() async {
    _state = _SessionState.notStarted;
    _starting = null;
    _readyCompleter = null;
    final process = _process;
    _process = null;
    try {
      await process?.stdin.close();
    } catch (_) {
      // 进程已退出时关闭失败无需处理。
    }
    // EOF 后再补 SIGTERM：等价于 helper 自身的 SIGTERM 收尾路径（§9.3 表），
    // 保证不依赖对端“看到 EOF 就退出”的实现细节；对已退出进程无害。
    process?.kill(ProcessSignal.sigterm);
    await _stdoutLines?.cancel();
    _stdoutLines = null;
    await _stderrLines?.cancel();
    _stderrLines = null;
    final stderrTail = _helperStderr.text.trim();
    if (stderrTail.isNotEmpty) {
      AppLogger.info('特权 helper stderr 尾部: $stderrTail');
    }
    await _preparedPath?.release();
    _preparedPath = null;
  }

  /// 默认启动器：pkexec 执行 helper（command[0] 固定为 pkexec）。
  static Future<Process> _launchPkexec(List<String> command) {
    return Process.start(command[0], command.sublist(1));
  }
}
