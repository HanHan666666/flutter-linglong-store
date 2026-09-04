// 特权 helper 客户端单测用的假 helper 进程（docs/47 §13.2）。
//
// 由 test/unit/core/platform/privileged_helper/privileged_helper_client_test.dart
// 以独立 `dart` 进程启动，通过注入的 launcher 替换 pkexec。脚本按首个参数
// 选择行为模式，在真实 stdin/stdout 管道上模拟 root helper 的协议行为。
//
// 模式：
// - normal        ：ready 后响应 start（started + 输出行 + exited）、cancel
//                   （cancelAccepted + exited(cancelRequested)）、shutdown。
// - hold-task     ：start 只回 started 并保持任务占位，等待 cancel 才收尾；
//                   用于验证客户端 busy 拒绝与取消路由的确定性。
// - auth-cancel   ：立即以退出码 126 结束（模拟用户关闭授权对话框）。
// - not-found     ：立即以退出码 127 结束（模拟 helper 不可执行）。
// - no-ready      ：长时间静默（模拟 ready 超时）。
// - protocol-junk ：输出一行非协议文本（模拟协议错误）。
// - die-mid-task  ：ready 后响应 start（started + 一行输出）后直接退出，
//                   不发送 exited（模拟会话中断）。
// - slow-ready    ：延迟 400ms 再 ready；第二参数为启动标记文件路径，
//                   启动时追加本进程 PID（用于验证并发 ensureStarted 单飞）。
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final mode = args.isNotEmpty ? args[0] : 'normal';
  final launchLog = args.length > 1 ? args[1] : null;

  switch (mode) {
    case 'auth-cancel':
      exit(126);
    case 'not-found':
      exit(127);
    case 'no-ready':
      await Future<void>.delayed(const Duration(minutes: 5));
      exit(0);
    case 'protocol-junk':
      stdout.writeln('this is not a protocol line');
      await stdout.flush();
      await Future<void>.delayed(const Duration(seconds: 30));
      exit(0);
    default:
      break;
  }

  if (mode == 'slow-ready') {
    if (launchLog != null) {
      try {
        File(launchLog).writeAsStringSync(
          '${DateTime.now().millisecondsSinceEpoch}:$pid\n',
          mode: FileMode.append,
        );
      } catch (error) {
        stderr.writeln('fake helper launch log write failed: $error');
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  final out = stdout;
  String? activeRequestId;
  var cancelled = false;

  Future<void> send(Map<String, Object?> event) async {
    out.writeln(jsonEncode(event));
    await out.flush();
  }

  await send({'v': 1, 'type': 'ready'});

  final lines = stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
    if (line.trim().isEmpty) {
      return;
    }
    final Map<String, dynamic> request;
    try {
      request = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = request['type'] as String?;
    final requestId = request['requestId'] as String?;
    switch (type) {
      case 'start':
        if (activeRequestId != null) {
          await send({
            'v': 1,
            'type': 'error',
            'requestId': requestId,
            'code': 'busy',
            'message': 'another task is running',
            'fatal': false,
          });
          return;
        }
        activeRequestId = requestId;
        await send({'v': 1, 'type': 'started', 'requestId': requestId, 'pid': pid});
        if (mode == 'die-mid-task') {
          await send({
            'v': 1,
            'type': 'output',
            'requestId': requestId,
            'stream': 'stdout',
            'line': '{"message":"Downloading files","percentage":10}',
          });
          exit(0);
        }
        if (mode == 'hold-task') {
          // 保持任务占位：started 后补一行输出作为“任务已占位”的可观测信号，
          // 等待 cancel 或 shutdown 后退出。
          await send({
            'v': 1,
            'type': 'output',
            'requestId': requestId,
            'stream': 'stdout',
            'line': '{"message":"hold"}',
          });
          return;
        }
        await send({
          'v': 1,
          'type': 'output',
          'requestId': requestId,
          'stream': 'stdout',
          'line': '{"message":"Downloading files","percentage":38.4}',
        });
        await send({
          'v': 1,
          'type': 'output',
          'requestId': requestId,
          'stream': 'stdout',
          'line': '{"message":"Install success"}',
        });
        await send({
          'v': 1,
          'type': 'exited',
          'requestId': requestId,
          'exitCode': 0,
          'cancelRequested': cancelled,
        });
        activeRequestId = null;
      case 'cancel':
        if (requestId != null && requestId == activeRequestId) {
          cancelled = true;
          await send({'v': 1, 'type': 'cancelAccepted', 'requestId': requestId});
          if (mode == 'hold-task') {
            // 取消后补发终态并释放任务占位，与真实 helper 的 SIGTERM 收尾一致。
            await send({
              'v': 1,
              'type': 'exited',
              'requestId': requestId,
              'exitCode': 1,
              'cancelRequested': true,
            });
            activeRequestId = null;
          }
        } else {
          await send({
            'v': 1,
            'type': 'error',
            'requestId': requestId,
            'code': 'notRunning',
            'message': 'no matching running task',
            'fatal': false,
          });
        }
      case 'shutdown':
        if (activeRequestId == null) {
          exit(0);
        }
        if (mode == 'hold-task') {
          // 任务运行中的 shutdown 被忽略（§6.4：helper 只在空闲时退出）。
          stderr.writeln('fake helper: shutdown ignored while task running');
        }
    }
  });

  // stdin EOF（客户端 disposeSession）时退出，模拟 helper 的生命周期收尾。
  await lines.asFuture<void>();
  exit(0);
}
