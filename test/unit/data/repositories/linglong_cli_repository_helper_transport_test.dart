/// 特权 helper 传输接入 Repository 的行为测试（docs/47 §13.2）。
///
/// 用内存替身实现 [PrivilegedHelperTransport]，验证：
/// - helper 输出行继续进入现有 CliOutputParser 并产生既有语义的进度；
/// - ensureStarted 的授权取消/组件不可用映射为稳定失败事实；
/// - exited 无终态时走安装结果复验；
/// - 取消路由到 helper（免第二次授权），无活动任务时返回 false。
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_client.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_exception.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_protocol.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';
import 'package:linglong_store/domain/models/app_operation_failure.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';

/// 可编程的 helper 传输替身。
class _FakeHelperTransport implements PrivilegedHelperTransport {
  _FakeHelperTransport({
    this.ensureStartedError,
    this.taskEvents = const [],
    this.holdTaskOpen = false,
  });

  /// ensureStarted 抛出的异常；null 表示成功。
  final Object? ensureStartedError;

  /// startTask 后依次推送的事件；holdTaskOpen 为 false 时最后自动补 exited。
  final List<PrivilegedHelperTaskEvent> taskEvents;

  /// 任务事件发完后保持占位（不自动清 _active），由 cancelTask 收尾；
  /// 用于验证取消路由的确定性。
  final bool holdTaskOpen;

  /// 记录收到的 start 请求。
  final List<PrivilegedHelperStartRequest> startedRequests = [];

  /// 记录收到的取消请求。
  final List<String> cancelledRequestIds = [];

  /// cancelTask 的应答值；null 表示 notRunning(false)。
  bool? cancelReply = true;

  bool _active = false;

  StreamController<PrivilegedHelperTaskEvent>? _heldEvents;

  @override
  bool get hasActiveTask => _active;

  @override
  Future<void> ensureStarted() async {
    final error = ensureStartedError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Stream<PrivilegedHelperTaskEvent> startTask(
    PrivilegedHelperStartRequest request,
  ) async* {
    startedRequests.add(request);
    _active = true;
    for (final event in taskEvents) {
      yield event;
    }
    if (holdTaskOpen) {
      // 保持任务占位：缓存控制器，cancelTask 时补 exited 并结束。
      final held = StreamController<PrivilegedHelperTaskEvent>();
      _heldEvents = held;
      yield* held.stream;
      return;
    }
    _active = false;
  }

  @override
  Future<bool> cancelTask(String requestId) async {
    cancelledRequestIds.add(requestId);
    final reply = cancelReply;
    final held = _heldEvents;
    _heldEvents = null;
    _active = false;
    if (held != null && !held.isClosed) {
      held.add(
        const PrivilegedHelperTaskExited(exitCode: 1, cancelRequested: true),
      );
      await held.close();
    }
    if (reply == null) {
      return false;
    }
    return reply;
  }

  @override
  Future<void> disposeSession() async {}
}

/// 构造 Repository：list 命令返回空（安装前后快照均为空集）。
LinglongCliRepositoryImpl buildRepository(PrivilegedHelperTransport helper) {
  return LinglongCliRepositoryImpl.withExecutor(
    execute: (args, {timeout = kDefaultTimeout, processId, locale}) async {
      return const CliOutput(stdout: '[]', stderr: '', exitCode: 0);
    },
    executeWithProgressAndProcess: (args,
        {processId, locale, onProcessCreated}) async* {},
    cancelWithSystemKill: (processId, {required int pid, force = false}) async {
      return true;
    },
    privilegedHelper: helper,
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  test('helper output lines keep flowing through CliOutputParser', () async {
    final helper = _FakeHelperTransport(
      taskEvents: [
        const PrivilegedHelperTaskLine(
          isStderr: false,
          line: '{"message":"Downloading files","percentage":38.4}',
        ),
        const PrivilegedHelperTaskLine(
          isStderr: false,
          line: '{"message":"Installing application","percentage":90}',
        ),
        const PrivilegedHelperTaskLine(
          isStderr: false,
          line: '{"message":"Install success"}',
        ),
        const PrivilegedHelperTaskExited(exitCode: 0, cancelRequested: false),
      ],
    );
    final repository = buildRepository(helper);

    final progressList = await repository
        .installApp('org.deepin.demo')
        .toList();

    // preparing + downloading + installing + success（completed 终态后不再复验）。
    expect(progressList.map((event) => event.status).toList(), [
      InstallStatus.pending,
      InstallStatus.downloading,
      InstallStatus.installing,
      InstallStatus.success,
    ]);
    final request = helper.startedRequests.single;
    expect(request.requestId, 'install_org.deepin.demo');
    expect(request.operation, PrivilegedHelperOperation.install);
    expect(request.appId, 'org.deepin.demo');
  });

  test('authorization cancelled maps to stable failure fact', () async {
    final helper = _FakeHelperTransport(
      ensureStartedError: const PrivilegedHelperAuthorizationCancelledException(),
    );
    final repository = buildRepository(helper);

    final progressList = await repository
        .installApp('org.deepin.demo')
        .toList();

    final failed = progressList.last;
    expect(failed.status, InstallStatus.failed);
    expect(
      failed.failure?.kind,
      AppOperationFailureKind.authorizationCancelled,
    );
  });

  test('helper unavailable maps to stable failure fact', () async {
    final helper = _FakeHelperTransport(
      ensureStartedError: const PrivilegedHelperUnavailableException('missing'),
    );
    final repository = buildRepository(helper);

    final progressList = await repository.updateApp('org.deepin.demo').toList();
    final failed = progressList.last;
    expect(failed.status, InstallStatus.failed);
    expect(failed.failure?.kind, AppOperationFailureKind.helperUnavailable);
  });

  test('exited without terminal triggers install confirmation', () async {
    // 只有一行非终态输出 + exited(0)：无法证明成功，list 为空 → 复验失败。
    final helper = _FakeHelperTransport(
      taskEvents: [
        const PrivilegedHelperTaskLine(
          isStderr: false,
          line: '{"message":"Downloading files","percentage":10}',
        ),
        const PrivilegedHelperTaskExited(exitCode: 0, cancelRequested: false),
      ],
    );
    final repository = buildRepository(helper);

    final progressList = await repository
        .installApp('org.deepin.demo')
        .toList();

    final last = progressList.last;
    expect(last.status, InstallStatus.failed);
    expect(
      last.failure?.kind,
      AppOperationFailureKind.resultUnconfirmed,
      reason: 'exited 无终态时必须走安装结果复验（§8.2）',
    );
  });

  test('cancel routes to helper while task active', () async {
    // 未启动任务时：无可取消对象。
    final idleHelper = _FakeHelperTransport();
    final idleRepo = buildRepository(idleHelper);
    expect(
      await idleRepo.cancelOperation(
        'org.deepin.demo',
        kind: InstallTaskKind.install,
      ),
      isFalse,
    );
    expect(idleHelper.cancelledRequestIds, isEmpty);

    // 有活动任务时：取消经 helper 的 requestId 通道，不再触发 pkexec。
    final activeHelper = _FakeHelperTransport(holdTaskOpen: true);
    final repoWithActive = buildRepository(activeHelper);
    final taskDone = Completer<void>();
    final subscription = repoWithActive
        .installApp('org.deepin.demo')
        .listen((_) {}, onDone: taskDone.complete);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(activeHelper.hasActiveTask, isTrue);

    expect(
      await repoWithActive.cancelOperation(
        'org.deepin.demo',
        kind: InstallTaskKind.install,
      ),
      isTrue,
    );
    expect(
      activeHelper.cancelledRequestIds,
      ['install_org.deepin.demo'],
      reason: '取消必须经 helper 的 requestId 通道（§8.2）',
    );

    await subscription.cancel();
  });
}
