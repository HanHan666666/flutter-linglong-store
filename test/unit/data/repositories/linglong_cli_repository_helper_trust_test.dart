/// helper 来源信任判定与直连回退测试（docs/51 §4.2、§4.3）。
///
/// 验证：仅当信任解析器证明当前 bundle 由系统包管理器安装时才使用特权
/// helper；不可信时回退普通用户 ll-cli 直连（不启动 helper）；探测失败按
/// 不可信处理（不得失败开放）；免密开启优先且不执行探测；回退任务的取消
/// 只向本进程自己启动的 ll-cli 发 SIGTERM。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_client.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_protocol.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';
import 'package:linglong_store/domain/models/privileged_helper_trust.dart';

/// 可编程的 CLI 执行器替身：记录普通路径调用与两类取消通道。
class _RecordingCliExecutor {
  final List<List<String>> progressCalls = <List<String>>[];
  final List<String> cancelProcessIds = <String>[];
  final List<String> systemKillProcessIds = <String>[];

  /// 非空时安装流挂起，直到测试关闭控制器。
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
    return true;
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

  /// 默认给出成功终态；需要挂起时可覆写为自定义事件序列。
  List<PrivilegedHelperTaskEvent> taskEvents = const <PrivilegedHelperTaskEvent>[
    PrivilegedHelperTaskLine(
      isStderr: false,
      line: '{"message":"Install success"}',
    ),
    PrivilegedHelperTaskExited(exitCode: 0, cancelRequested: false),
  ];

  @override
  bool get hasActiveTask => false;

  @override
  Future<void> ensureStarted() async {
    ensureStartedCalls += 1;
  }

  @override
  Stream<PrivilegedHelperTaskEvent> startTask(
    PrivilegedHelperStartRequest request,
  ) async* {
    startedRequests.add(request);
    for (final event in taskEvents) {
      yield event;
    }
  }

  @override
  Future<bool> cancelTask(String requestId) async {
    cancelledRequestIds.add(requestId);
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
  PrivilegedHelperTrustResolver? resolver,
}) {
  return LinglongCliRepositoryImpl.withExecutor(
    execute: executor.execute,
    executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
    cancelWithSystemKill: executor.cancelWithSystemKill,
    cancelProcess: executor.cancelProcess,
    privilegedHelper: helper,
    passwordFreeInstallModeReader: reader,
    helperTrustResolver: resolver,
  );
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('helper 来源信任判定（docs/51）', () {
    test('来源可信时沿用特权 helper', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        resolver: () async => true,
      );

      final progressList = await repository
          .installApp('org.example.demo')
          .toList();

      expect(progressList.last.status, InstallStatus.success);
      expect(helper.ensureStartedCalls, 1);
      expect(helper.startedRequests.single.appId, 'org.example.demo');
      expect(executor.progressCalls, isEmpty);
    });

    test('来源不可信时回退普通用户直连，不启动 helper', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        resolver: () async => false,
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

    test('信任探测异常时按不可信回退直连（不得失败开放）', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        resolver: () async => throw StateError('probe failure'),
      );

      await repository.installApp('org.example.demo').drain<void>();

      expect(executor.progressCalls.single.first, 'install');
      expect(helper.ensureStartedCalls, 0);
      expect(helper.startedRequests, isEmpty);
    });

    test('未注入信任解析器时保持 helper 路径（过渡装配语义）', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(executor: executor, helper: helper);

      await repository.installApp('org.example.demo').drain<void>();

      expect(helper.ensureStartedCalls, 1);
      expect(executor.progressCalls, isEmpty);
    });

    test('更新任务同样按信任判定选择路径', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        resolver: () async => false,
      );

      await repository.updateApp('org.example.demo').drain<void>();

      expect(executor.progressCalls.single, <String>[
        'upgrade',
        '--json',
        'org.example.demo',
      ]);
      expect(helper.ensureStartedCalls, 0);
    });

    test('免密开启时优先直连且不执行信任探测', () async {
      final executor = _RecordingCliExecutor();
      final helper = _FakeHelperTransport();
      var resolverCalls = 0;
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        reader: () => true,
        resolver: () async {
          resolverCalls += 1;
          return true;
        },
      );

      await repository.installApp('org.example.demo').drain<void>();

      expect(executor.progressCalls, isNotEmpty);
      expect(helper.ensureStartedCalls, 0);
      expect(resolverCalls, 0, reason: '免密路径与 helper 无关，不应做探测');
    });
  });

  group('信任回退任务的取消路由', () {
    test('只向本进程自己启动的 ll-cli 发 SIGTERM', () async {
      final executor = _RecordingCliExecutor()
        ..heldProgress = StreamController<ProgressEvent>();
      final helper = _FakeHelperTransport();
      final repository = _buildRepository(
        executor: executor,
        helper: helper,
        resolver: () async => false,
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
      expect(
        executor.systemKillProcessIds,
        isEmpty,
        reason: '回退路径不得复用旧 pkexec kill 分支（docs/51 §4.3）',
      );
      expect(helper.cancelledRequestIds, isEmpty);

      await executor.heldProgress!.close();
    });
  });
}
