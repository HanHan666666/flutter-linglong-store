// 特权 helper 会话客户端单测（docs/47 §13.2）。
//
// 用真实的假 helper 子进程（test/fixtures/privileged_helper/fake_helper.dart）
// 驱动完整管道：握手、任务事件流、取消、退出码映射、ready 超时、协议错误、
// 会话中断与并发 ensureStarted 单飞。dart 可执行文件不可解析时跳过本组。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_binary.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_client.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_exception.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_protocol.dart';


late String _dartExecutable;
late Directory _tempDir;

void main() {
  setUpAll(() async {
    await AppLogger.init();
    _dartExecutable = _resolveDartExecutable();
    _tempDir = await Directory.systemTemp.createTemp('ll-helper-client-test');
  });

  tearDownAll(() async {
    await _tempDir.delete(recursive: true);
  });

  /// 构建一个注入了假 helper 启动器的客户端。
  ///
  /// [mode] 传给 fake_helper.dart；非 FUSE 形态（根 ext4）避免引入暂存逻辑。
  PrivilegedHelperClient buildClient(
    String mode, {
    Duration readyTimeout = const Duration(seconds: 10),
    String? launchLog,
  }) {
    final binary = PrivilegedHelperBinary(
      mountinfoReader: () =>
          '36 35 98:0 /mnt1 / rw,noatime master:1 - ext4 /dev/root rw\n',
      appRuntimeDirResolver: () => _tempDir.path,
      bundleHelperPathOverride: _fakeBundleHelper().path,
    );
    return PrivilegedHelperClient(
      binary: binary,
      readyTimeout: readyTimeout,
      launcher: (command) {
        final args = <String>[
          _fakeHelperScriptAbs(),
          mode,
          ?launchLog,
        ];
        return Process.start(_dartExecutable, args);
      },
    );
  }

  group('normal session', () {
    test('handshake, task events and terminal exited', () async {
      final client = buildClient('normal');
      addTearDown(client.disposeSession);

      await client.ensureStarted();

      final events = await client
          .startTask(
            const PrivilegedHelperStartRequest(
              requestId: 'install_org.deepin.demo',
              operation: PrivilegedHelperOperation.install,
              appId: 'org.deepin.demo',
              force: false,
            ),
          )
          .toList();

      final lines = events.whereType<PrivilegedHelperTaskLine>().toList();
      final terminal =
          events.whereType<PrivilegedHelperTaskExited>().single;
      expect(lines, hasLength(2));
      expect(lines.first.line, contains('Downloading files'));
      expect(terminal.exitCode, 0);
      expect(terminal.cancelRequested, isFalse);
      expect(client.hasActiveTask, isFalse);
    });

    test('second startTask while active is rejected client-side', () async {
      // hold-task 模式让任务保持占位，直到取消才收尾，避免自动完结引入竞态。
      final client = buildClient('hold-task');
      addTearDown(client.disposeSession);
      await client.ensureStarted();

      final collected = <PrivilegedHelperTaskEvent>[];
      final done = Completer<void>();
      final subscription = client
          .startTask(
            const PrivilegedHelperStartRequest(
              requestId: 'install_a.b',
              operation: PrivilegedHelperOperation.install,
              appId: 'a.b',
              force: false,
            ),
          )
          .listen(collected.add, onDone: done.complete);
      await _waitForCondition(() => collected.isNotEmpty);
      expect(client.hasActiveTask, isTrue);

      await expectLater(
        client
            .startTask(
              const PrivilegedHelperStartRequest(
                requestId: 'install_a.b',
                operation: PrivilegedHelperOperation.install,
                appId: 'a.b',
                force: false,
              ),
            )
            .drain<void>(),
        throwsA(isA<PrivilegedHelperBusyException>()),
      );

      // 收尾：取消释放任务占位后结束会话。
      expect(await client.cancelTask('install_a.b'), isTrue);
      await done.future;
      await subscription.cancel();
      await client.disposeSession();
    });

    test('cancel routes through requestId and returns accepted', () async {
      final client = buildClient('hold-task');
      addTearDown(client.disposeSession);
      await client.ensureStarted();

      final collected = <PrivilegedHelperTaskEvent>[];
      final done = Completer<void>();
      final subscription = client
          .startTask(
            const PrivilegedHelperStartRequest(
              requestId: 'install_a.b',
              operation: PrivilegedHelperOperation.install,
              appId: 'a.b',
              force: false,
            ),
          )
          .listen(collected.add, onDone: done.complete);
      await _waitForCondition(() => collected.isNotEmpty);

      expect(await client.cancelTask('install_a.b'), isTrue);
      // 不匹配的 requestId：notRunning 错误事件映射为 false。
      expect(await client.cancelTask('update_x.y'), isFalse);

      // 取消被接受后流以 exited(cancelRequested=true) 终结。
      await done.future;
      final terminal = collected.whereType<PrivilegedHelperTaskExited>().single;
      expect(terminal.cancelRequested, isTrue);
      expect(client.hasActiveTask, isFalse);

      await subscription.cancel();
      await client.disposeSession();
    });

    test('disposeSession closes stdin and ends the fake helper', () async {
      final client = buildClient('normal');
      await client.ensureStarted();
      await client.disposeSession();
      // 幂等。
      await client.disposeSession();
    });
  });

  group('startup failures', () {
    test('exit 126 maps to authorization cancelled', () async {
      final client = buildClient('auth-cancel');
      addTearDown(client.disposeSession);
      await expectLater(
        client.ensureStarted(),
        throwsA(isA<PrivilegedHelperAuthorizationCancelledException>()),
      );
    });

    test('exit 127 maps to unavailable', () async {
      final client = buildClient('not-found');
      addTearDown(client.disposeSession);
      await expectLater(
        client.ensureStarted(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
    });

    test('ready timeout fails startup', () async {
      final client = buildClient(
        'no-ready',
        readyTimeout: const Duration(milliseconds: 300),
      );
      addTearDown(client.disposeSession);
      await expectLater(
        client.ensureStarted(),
        throwsA(isA<PrivilegedHelperStartupException>()),
      );
    });

    test('protocol junk tears down the session', () async {
      final client = buildClient('protocol-junk');
      addTearDown(client.disposeSession);
      await expectLater(
        client.ensureStarted(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
      // 会话作废后重新启动会拉起新进程（新会话同样输出 junk，只验证不悬挂）。
      final second = buildClient('protocol-junk');
      addTearDown(second.disposeSession);
      await expectLater(
        second.ensureStarted(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
    });
  });

  group('mid-session interruption', () {
    test('helper death during task surfaces transport failure', () async {
      final client = buildClient('die-mid-task');
      addTearDown(client.disposeSession);
      await client.ensureStarted();

      final events = <PrivilegedHelperTaskEvent>[];
      final errors = <Object>[];
      final done = Completer<void>();
      final subscription = client
          .startTask(
            const PrivilegedHelperStartRequest(
              requestId: 'install_a.b',
              operation: PrivilegedHelperOperation.install,
              appId: 'a.b',
              force: false,
            ),
          )
          .listen(events.add, onError: errors.add, onDone: done.complete);
      await done.future;
      await subscription.cancel();

      expect(errors, hasLength(1));
      expect(errors.single, isA<PrivilegedHelperTransportException>());
    });
  });

  group('single-flight ensureStarted', () {
    test('concurrent ensureStarted launches exactly one process', () async {
      final launchLog = File(
        '${_tempDir.path}/launch-${DateTime.now().microsecondsSinceEpoch}.log',
      );
      if (launchLog.existsSync()) {
        launchLog.deleteSync();
      }
      final client = buildClient('slow-ready', launchLog: launchLog.path);
      addTearDown(client.disposeSession);

      await Future.wait([
        client.ensureStarted(),
        client.ensureStarted(),
        client.ensureStarted(),
      ]);

      final lines = launchLog
          .readAsStringSync()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      expect(lines, hasLength(1),
          reason: '并发 ensureStarted 必须复用同一启动 Future（§4.3）');
    });
  });
}

String _fakeHelperScriptAbs() {
  final script = File(
    '${Directory.current.path}/test/fixtures/privileged_helper/fake_helper.dart',
  );
  if (!script.existsSync()) {
    throw StateError('fake helper script missing: ${script.path}');
  }
  return script.path;
}

File _fakeBundleHelper() {
  final file = File('${_tempDir.path}/bundle-helper');
  if (!file.existsSync()) {
    file.writeAsStringSync('#!/bin/sh\nexit 0\n');
  }
  return file;
}

/// 解析 dart 可执行文件：flutter test 的 PATH 中包含 flutter/bin。
String _resolveDartExecutable() {
  final pathEnv = Platform.environment['PATH'] ?? '';
  for (final dir in pathEnv.split(':')) {
    if (dir.isEmpty) {
      continue;
    }
    final candidate = File('$dir/dart');
    if (candidate.existsSync()) {
      return candidate.path;
    }
  }
  throw StateError('dart executable not found on PATH');
}

Future<void> _waitForCondition(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: '等待条件超时');
}
