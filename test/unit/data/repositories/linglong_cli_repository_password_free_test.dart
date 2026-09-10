/// 免密安装执行路径与取消路由测试（docs/50 §7.1、§7.2）。
///
/// 验证：本地模式快照决定任务路径且只取一次、设置改变不切换正在运行的任务、
/// 取消严格按任务启动时绑定的路径路由（helper requestId / 普通 CLI SIGTERM /
/// 旧 pkexec 路径互不串线），信号失败不伪造取消成功。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_client.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_protocol.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';

/// 可编程的 CLI 执行器替身：区分普通路径与旧系统级取消。
class _RecordingCliExecutor {
  final List<List<String>> progressCalls = <List<String>>[];
  final List<String> cancelProcessIds = <String>[];
  final List<bool> cancelProcessForces = <bool>[];
  final List<String> systemKillProcessIds = <String>[];

  /// 普通 CLI 取消（SIGTERM）的返回值。
  bool cancelProcessResult = true;

  /// 非空时安装流挂起，直到测试完成控制器。
  StreamController<ProgressEvent>? heldProgress;

  List<ProgressEvent> progressEvents = const <ProgressEvent>[
    ProgressEvent(
      line: '{"message":"Install success"}',
      type: ProgressEventType.stdout,
    ),
  ];

  Future<CliOutput> execute(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
    String? locale,
  }) async {
    return const CliOutput(stdout: '[]', stderr: '', exitCode: 0);
  }

  Stream<ProgressEvent> executeWithProgressAndProcess(
    List<String> args, {
    String? processId,
    String? locale,
    void Function(Process process)? onProcessCreated,
  }) async* {
    progressCalls.add(List<String>.from(args));
    final held = heldProgress;
    if (held != null) {
      yield* held.stream;
      return;
    }
    for (final event in progressEvents) {
      yield event;
    }
  }

  bool cancelProcess(String processId, {bool force = false}) {
    cancelProcessIds.add(processId);
    cancelProcessForces.add(force);
    return cancelProcessResult;
  }

  Future<bool> cancelWithSystemKill(
    String processId, {
    required int pid,
    bool force = false,
  }) async {
    systemKillProcessIds.add(processId);
    return true;
  }
}

/// 可编程的 helper 传输替身，记录是否被拉起与取消请求。
class _FakeHelperTransport implements PrivilegedHelperTransport {
  int ensureStartedCalls = 0;
  final List<PrivilegedHelperStartRequest> startedRequests =
      <PrivilegedHelperStartRequest>[];
  final List<String> cancelledRequestIds = <String>[];
  bool _active = false;

  /// 非空时任务流挂起，用于在任务运行中切换开关。
  StreamController<PrivilegedHelperTaskEvent>? heldTask;

  @override
  bool get hasActiveTask => _active;

  @override
  Future<void> ensureStarted() async {
    ensureStartedCalls += 1;
  }

  @override
  Stream<PrivilegedHelperTaskEvent> startTask(
    PrivilegedHelperStartRequest request,
  ) async* {
    startedRequests.add(request);
    _active = true;
    final held = heldTask;
    if (held != null) {
      yield* held.stream;
    }
    _active = false;
  }

  @override
  Future<bool> cancelTask(String requestId) async {
    cancelledRequestIds.add(requestId);
    final held = heldTask;
    heldTask = null;
    _active = false;
    if (held != null && !held.isClosed) {
      held.add(
        const PrivilegedHelperTaskExited(exitCode: 1, cancelRequested: true),
      );
      await held.close();
    }
    return true;
  }

  @override
  Future<void> disposeSession() async {}
}

/// 轮询等待条件成立（每 10ms 一次，最多 3s）。
Future<bool> _eventually(bool Function() condition) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    if (condition()) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return false;
}

LinglongCliRepositoryImpl _buildRepository({
  required _RecordingCliExecutor executor,
  PrivilegedHelperTransport? helper,
  PasswordFreeInstallModeReader? reader,
}) {
  return LinglongCliRepositoryImpl.withExecutor(
    execute: executor.execute,
    executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
    cancelWithSystemKill: executor.cancelWithSystemKill,
    cancelProcess: executor.cancelProcess,
    privilegedHelper: helper,
    passwordFreeInstallModeReader: reader,
    // docs/51：本文件覆盖免密路径与 helper 回归，helper 场景显式模拟可信来源。
    helperTrustResolver: () async => true,
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('执行路径选择', () {
    test('免密开启且无待同步时以普通用户执行，不启动 helper', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => true,
      );

      await repository.installApp('org.example.demo').drain<void>();

      expect(executor.progressCalls.single, <String>[
        'install',
        '--json',
        'org.example.demo',
      ]);
      expect(helper.ensureStartedCalls, 0);
      expect(helper.startedRequests, isEmpty);
    });

    test('免密关闭时沿用特权 helper', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => false,
      );

      await repository.installApp('org.example.demo').drain<void>();

      expect(helper.ensureStartedCalls, 1);
      expect(helper.startedRequests.single.appId, 'org.example.demo');
      expect(executor.progressCalls, isEmpty);
    });

    test('未注入模式读取器时保持 helper 路径', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(executor: executor, helper: helper);

      await repository.installApp('org.example.demo').drain<void>();

      expect(helper.ensureStartedCalls, 1);
      expect(executor.progressCalls, isEmpty);
    });

    test('更新任务同样按模式快照选择路径', () async {
      final executor = _RecordingCliExecutor();
      final repository = _buildRepository(
        executor: executor,
        reader: () => true,
      );

      await repository.updateApp('org.example.demo').drain<void>();

      expect(executor.progressCalls.single, <String>[
        'upgrade',
        '--json',
        'org.example.demo',
      ]);
    });
  });

  group('取消按实际任务路由', () {
    test('免密任务取消只向自己启动的进程发 SIGTERM', () async {
      final executor = _RecordingCliExecutor()
        ..heldProgress = StreamController<ProgressEvent>();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => true,
      );

      final subscription = repository
          .installApp('org.example.demo')
          .listen((_) {});
      addTearDown(subscription.cancel);
      await _eventually(() => executor.progressCalls.isNotEmpty);

      final accepted = await repository.cancelOperation(
        'org.example.demo',
        kind: InstallTaskKind.install,
      );

      expect(accepted, isTrue);
      expect(executor.cancelProcessIds, <String>['install_org.example.demo']);
      expect(executor.cancelProcessForces, <bool>[false]);
      expect(executor.systemKillProcessIds, isEmpty);
      expect(helper.cancelledRequestIds, isEmpty);

      await executor.heldProgress!.close();
    });

    test('免密任务取消信号失败时不伪造取消成功', () async {
      final executor = _RecordingCliExecutor()
        ..heldProgress = StreamController<ProgressEvent>()
        ..cancelProcessResult = false;
      final repository = _buildRepository(
        executor: executor,
        reader: () => true,
      );

      final subscription = repository
          .installApp('org.example.demo')
          .listen((_) {});
      addTearDown(subscription.cancel);
      await _eventually(() => executor.progressCalls.isNotEmpty);

      final accepted = await repository.cancelOperation(
        'org.example.demo',
        kind: InstallTaskKind.install,
      );

      expect(accepted, isFalse);
      expect(executor.systemKillProcessIds, isEmpty);

      await executor.heldProgress!.close();
    });

    test('运行中切换开关不改变已绑定任务的取消路径', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport()
        ..heldTask = StreamController<PrivilegedHelperTaskEvent>();
      var passwordFreeEnabled = false;
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => passwordFreeEnabled,
      );

      final subscription = repository
          .installApp('org.example.demo')
          .listen((_) {});
      addTearDown(subscription.cancel);
      await _eventually(() => helper.startedRequests.isNotEmpty);

      // 任务已用 helper 启动，之后用户打开免密：取消仍必须走 helper。
      passwordFreeEnabled = true;
      final accepted = await repository.cancelOperation(
        'org.example.demo',
        kind: InstallTaskKind.install,
      );

      expect(accepted, isTrue);
      expect(helper.cancelledRequestIds, <String>['install_org.example.demo']);
      expect(executor.cancelProcessIds, isEmpty);
      expect(executor.systemKillProcessIds, isEmpty);
    });

    test('helper 任务取消仍走 requestId，不触发普通 CLI 信号', () async {
      final executor = _RecordingCliExecutor()
        ..heldProgress = StreamController<ProgressEvent>();
      final helper = _FakeHelperTransport()
        ..heldTask = StreamController<PrivilegedHelperTaskEvent>();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => false,
      );

      final subscription = repository
          .installApp('org.example.demo')
          .listen((_) {});
      addTearDown(subscription.cancel);
      await _eventually(() => helper.startedRequests.isNotEmpty);

      final accepted = await repository.cancelOperation(
        'org.example.demo',
        kind: InstallTaskKind.install,
      );

      expect(accepted, isTrue);
      expect(helper.cancelledRequestIds, <String>['install_org.example.demo']);
      expect(executor.cancelProcessIds, isEmpty);
      expect(executor.systemKillProcessIds, isEmpty);
    });
  });
}
