// 特权 helper 真机验证驱动（docs/47 §13.1 门禁与 §13.3 真机验收矩阵）。
//
// 以普通用户运行，通过 `sudo -n env PKEXEC_UID=<uid> <helper>` 模拟 pkexec
// 完成授权后的 root 环境（等价环境：euid=0 + PKEXEC_UID 为真实普通用户），
// 驱动 release bundle 内的真实 helper 二进制完成协议会话。
//
// 用法（需先 `printf '<密码>\n' | sudo -S -v` 缓存票据，无 tty 票据跨进程共享）：
//   dart run build/scripts/verify-privileged-helper-live.dart double-install \
//       /path/to/linglong_store_helper org.deepin.draw org.deepin.editor
//   dart run build/scripts/verify-privileged-helper-live.dart cancel \
//       /path/to/linglong_store_helper org.deepin.movie
//   dart run build/scripts/verify-privileged-helper-live.dart reject \
//       /path/to/linglong_store_helper
//
// 退出码 0 表示场景通过；非 0 为失败（详见 stderr 逐事件日志）。
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 单个任务的输出行/事件统计。
class _TaskReport {
  int outputLines = 0;
  String lastLine = '';
  int exitCode = -1;
  bool cancelRequested = false;
  bool exitedSeen = false;
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('用法: verify-privileged-helper-live.dart '
        '<double-install|cancel|reject> <helper> [appId...]');
    exit(64);
  }
  final scenario = args[0];
  final helperPath = args[1];
  final appIds = args.skip(2).toList();

  // 以当前真实 UID 作为 PKEXEC_UID（等价 pkexec 完成授权后的环境）。
  final uidResult = await Process.run('id', ['-u']);
  final uid = (uidResult.stdout as String).trim();
  final isRoot = uid == '0';

  // 驱动自身已在 root 下（外层 bash `sudo -n dart run ...`）时直接启动，
  // 避免嵌套 sudo 的票据按父进程键控而失效；普通用户下回退 `sudo -n`。
  final Process process;
  if (isRoot) {
    // root 下无法从环境拿到原用户 UID，默认按常见桌面用户 1000；可用
    // VERIFY_UID 覆盖。
    final invokingUid =
        Platform.environment['VERIFY_UID'] ??
        (await _desktopUserId()) ??
        '1000';
    process = await Process.start(
      helperPath,
      const <String>[],
      environment: {'PKEXEC_UID': invokingUid},
    );
    stderr.writeln(
      '[driver] helper pid=${process.pid} (direct root, '
      'PKEXEC_UID=$invokingUid)',
    );
  } else {
    process = await Process.start('sudo', [
      '-n',
      'env',
      'PKEXEC_UID=$uid',
      helperPath,
    ]);
    stderr.writeln('[driver] helper pid=${process.pid} (PKEXEC_UID=$uid)');
  }

  final reports = <String, _TaskReport>{};
  final activeReport = <String, _TaskReport>{};
  final taskDone = <String, Completer<void>>{};
  final firstOutput = Completer<void>();
  late final Future<void> firstOutputFuture = firstOutput.future;
  _TaskReport? current;
  var readySeen = false;
  var fatalErrorSeen = false;
  final readyCompleter = Completer<void>();
  final taskTimeout = const Duration(minutes: 12);

  final timeoutTimer = Timer(const Duration(seconds: 15), () {
    if (!readyCompleter.isCompleted) {
      stderr.writeln('[driver] FAIL: ready 超时');
      process.kill();
      exit(2);
    }
  });

  final subs = <StreamSubscription<String>>[];
  subs.add(
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.trim().isEmpty) {
        return;
      }
      stderr.writeln('[helper→] $line');
      final Map<String, dynamic> event;
      try {
        event = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        stderr.writeln('[driver] FAIL: 非协议行');
        fatalErrorSeen = true;
        return;
      }
      switch (event['type']) {
        case 'ready':
          readySeen = true;
          timeoutTimer.cancel();
          if (!readyCompleter.isCompleted) {
            readyCompleter.complete();
          }
          unawaited(_onReady(scenario, appIds, process, taskDone, firstOutputFuture));
        case 'started':
          current = reports.putIfAbsent(
            event['requestId'] as String,
            _TaskReport.new,
          );
          activeReport[event['requestId'] as String] = current!;
        case 'output':
          final report =
              activeReport[event['requestId'] as String] ?? _TaskReport();
          report.outputLines++;
          report.lastLine = (event['line'] as String?) ?? '';
          if (!firstOutput.isCompleted) {
            firstOutput.complete();
          }
        case 'cancelAccepted':
          stderr.writeln('[driver] cancelAccepted: ${event['requestId']}');
        case 'exited':
          final requestId = event['requestId'] as String;
          final report = activeReport[requestId];
          if (report != null) {
            report.exitCode = (event['exitCode'] as num).toInt();
            report.cancelRequested = event['cancelRequested'] == true;
            report.exitedSeen = true;
          }
          taskDone.putIfAbsent(requestId, Completer<void>.new).complete();
        case 'error':
          stderr.writeln('[driver] error 事件: ${event['code']}');
          if (event['fatal'] == true) {
            fatalErrorSeen = true;
          }
      }
    }, onDone: () {
      stderr.writeln('[driver] helper stdout EOF');
      // 会话结束：解除所有等待，让主流程进入判定。
      for (final completer in taskDone.values) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }),
  );
  subs.add(
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => stderr.writeln('[helper-err] $line')),
  );

  final exitCode = await process.exitCode;
  for (final sub in subs) {
    await sub.cancel();
  }
  stderr.writeln('[driver] helper exit=$exitCode');

  // ---- 场景判定 ----
  if (!readySeen) {
    stderr.writeln('[driver] FAIL: 未收到 ready');
    exit(2);
  }
  switch (scenario) {
    case 'double-install':
      if (reports.length != appIds.length) {
        stderr.writeln('[driver] FAIL: 期望 ${appIds.length} 个任务，'
            '实际 ${reports.length}');
        exit(3);
      }
      for (final appId in appIds) {
        final report = reports['install_$appId'];
        if (report == null || !report.exitedSeen) {
          stderr.writeln('[driver] FAIL: $appId 未收到 exited');
          exit(3);
        }
        if (report.exitCode != 0) {
          stderr.writeln(
              '[driver] FAIL: $appId exitCode=${report.exitCode} '
              '${report.lastLine}');
          exit(3);
        }
        stderr.writeln('[driver] PASS 任务: $appId '
            '(output=${report.outputLines} 行, exit=0)');
      }
      stderr.writeln('[driver] PASS double-install: '
          '一次授权会话完成 ${appIds.length} 个安装，无嵌套授权');
    case 'cancel':
      final report = reports.values.firstOrNull;
      if (report == null || !report.exitedSeen) {
        stderr.writeln('[driver] FAIL: 未收到取消后的 exited');
        exit(3);
      }
      if (!report.cancelRequested) {
        stderr.writeln('[driver] FAIL: exited 未标记 cancelRequested');
        exit(3);
      }
      stderr.writeln('[driver] PASS cancel: cancelAccepted→exited('
          'cancelRequested=true, exit=${report.exitCode})');
    case 'reject':
      if (!fatalErrorSeen) {
        stderr.writeln('[driver] FAIL: 未收到致命 error 事件');
        exit(3);
      }
      stderr.writeln('[driver] PASS reject: 非白名单请求被拒绝');
    default:
      stderr.writeln('[driver] FAIL: 未知场景 $scenario');
      exit(64);
  }

  exit(0);
}

/// 解析当前图形会话用户的 UID（root 下运行时用于 PKEXEC_UID）。
Future<String?> _desktopUserId() async {
  final result = await Process.run('id', ['-u', 'han']);
  final output = (result.stdout as String).trim();
  if (output.isEmpty || !RegExp(r'^\d+$').hasMatch(output)) {
    return null;
  }
  return output;
}

/// ready 后按场景发送请求。
Future<void> _onReady(
  String scenario,
  List<String> appIds,
  Process process,
  Map<String, Completer<void>> taskDone,
  Future<void> firstOutputFuture,
) async {
  Future<void> send(Map<String, Object?> request) async {
    process.stdin.writeln(jsonEncode(request));
    await process.stdin.flush();
  }

  switch (scenario) {
    case 'double-install':
      for (final appId in appIds) {
        final requestId = 'install_$appId';
        await send({
          'v': 1,
          'type': 'start',
          'requestId': requestId,
          'operation': 'install',
          'appId': appId,
          'force': false,
        });
        // 串行约束（§8.1）：等上一个任务 exited 后再发下一个 start。
        final done = taskDone.putIfAbsent(requestId, Completer<void>.new);
        await done.future.timeout(const Duration(minutes: 12));
      }
      // 全部任务完成后主动收尾，避免驱动等待 5 分钟空闲超时。
      await send({'v': 1, 'type': 'shutdown'});
    case 'cancel':
      final appId = appIds.first;
      final requestId = 'install_$appId';
      await send({
        'v': 1,
        'type': 'start',
        'requestId': requestId,
        'operation': 'install',
        'appId': appId,
        'force': false,
      });
      // 首个 output 行到达后 800ms 取消：窗口固定在下载起始阶段，
      // 避免大缓存环境任务瞬间完成导致取消不可达。
      await firstOutputFuture.timeout(const Duration(seconds: 60));
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await send({'v': 1, 'type': 'cancel', 'requestId': requestId});
      // 取消后任务回到 idle，主动收尾会话。
      final done = taskDone.putIfAbsent(requestId, Completer<void>.new);
      await done.future.timeout(const Duration(minutes: 2));
      await send({'v': 1, 'type': 'shutdown'});
    case 'reject':
      // 白名单外：携带 executable 字段的 start，helper 必须致命拒绝。
      await send({
        'v': 1,
        'type': 'start',
        'requestId': 'evil',
        'operation': 'install',
        'appId': 'org.evil.app',
        'force': false,
        'executable': '/bin/sh',
      });
  }
}
