import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';
import '../protocol/og_protocol_request.dart';
import 'window_service.dart';

/// 单实例消息类型。
///
/// `activate` 保持旧的“只聚焦窗口”语义；`openUrl` 用于第二个进程把
/// XDG 传入的 `og://appId` 原始链接转交给已经运行的主实例。
enum SingleInstanceMessageKind {
  /// 只激活已运行窗口，不触发业务动作。
  activate,

  /// 激活窗口并交给业务层处理指定 URL。
  openUrl,
}

/// 单实例进程间通信消息。
///
/// 该对象兼容历史的纯文本 `ACTIVATE` 命令，同时为协议拉起提供结构化
/// JSON 载荷，避免后续在 socket 层继续追加多种临时字符串格式。
class SingleInstanceMessage {
  const SingleInstanceMessage._({
    required this.kind,
    this.url,
  });

  /// 创建只激活窗口的消息。
  const SingleInstanceMessage.activate()
      : this._(kind: SingleInstanceMessageKind.activate);

  /// 创建打开 URL 的消息。
  ///
  /// 这里不解析 URL，调用侧负责只传入客户端支持的协议，socket 层只承担
  /// 可靠转发职责，避免平台模块耦合具体业务规则。
  const SingleInstanceMessage.openUrl(String url)
      : this._(
          kind: SingleInstanceMessageKind.openUrl,
          url: url,
        );

  /// 消息语义。
  final SingleInstanceMessageKind kind;

  /// 需要主实例继续处理的原始 URL。
  final String? url;

  /// 从 socket 文本恢复消息。
  ///
  /// malformed JSON 或未知消息统一降级成 [SingleInstanceMessage.activate]，
  /// 这是单实例通信的最低可用行为：至少把已运行窗口带到用户面前。
  static SingleInstanceMessage fromWire(String rawMessage) {
    final message = rawMessage.trim();
    if (message == SingleInstance._activateCommand) {
      return const SingleInstanceMessage.activate();
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) {
        return const SingleInstanceMessage.activate();
      }

      final kind = decoded['kind'];
      if (kind == SingleInstanceMessageKind.openUrl.name) {
        final url = decoded['url'];
        if (url is String && url.trim().isNotEmpty) {
          return SingleInstanceMessage.openUrl(url.trim());
        }
      }

      if (kind == SingleInstanceMessageKind.activate.name) {
        return const SingleInstanceMessage.activate();
      }
    } catch (_) {
      return const SingleInstanceMessage.activate();
    }

    return const SingleInstanceMessage.activate();
  }

  /// 编码为 socket 文本。
  ///
  /// 使用 JSON 是为了保留向后兼容空间；历史纯文本 `ACTIVATE` 仍由
  /// [fromWire] 接受，但新的客户端统一发送结构化消息。
  String toWire() {
    return jsonEncode({
      'kind': kind.name,
      if (url != null) 'url': url,
    });
  }
}

/// 单实例控制
///
/// 使用文件锁 + Unix Socket 实现单实例检测：
/// 1. 尝试获取文件锁 (`/tmp/linglong-store.lock`)
/// 2. 成功：创建 Socket 服务端，监听激活请求
/// 3. 失败：连接 Socket 服务端，发送激活命令，退出当前实例
class SingleInstance {
  SingleInstance._();

  /// 锁文件路径
  static const String _lockFileName = 'linglong-store.lock';

  /// Socket 文件路径
  static const String _socketFileName = 'linglong-store.sock';

  /// 激活命令
  static const String _activateCommand = 'ACTIVATE';

  /// 文件锁
  static RandomAccessFile? _lockFile;

  /// Socket 服务端
  static ServerSocket? _serverSocket;

  /// 是否是第一个实例
  static bool _isFirstInstance = true;

  /// 主实例接收到的 og 协议链接流。
  ///
  /// App 层订阅该流后再进入安装编排；平台层只负责转发，不直接读 Provider
  /// 或操作安装队列，保持单实例模块的职责边界清晰。
  static final StreamController<String> _urlController =
      StreamController<String>.broadcast();

  /// 锁文件完整路径
  static String get _lockFilePath => p.join(Directory.systemTemp.path, _lockFileName);

  /// Socket 文件完整路径
  static String get _socketFilePath => p.join(Directory.systemTemp.path, _socketFileName);

  /// 已运行主实例收到的 og 协议链接。
  static Stream<String> get protocolUrls => _urlController.stream;

  /// 确保单实例运行
  ///
  /// 返回值：
  /// - true: 是第一个实例，继续启动
  /// - false: 已有实例，当前实例应退出
  static Future<bool> ensure([List<String> arguments = const []]) async {
    try {
      // 1. 尝试获取文件锁
      final lockResult = await _tryAcquireLock();
      if (lockResult) {
        // 是第一个实例，创建 Socket 服务端
        await _startSocketServer();
        _isFirstInstance = true;
        AppLogger.info('[SingleInstance] First instance, lock acquired');
        return true;
      }

      // 2. 已有实例，尝试激活已有窗口
      AppLogger.info('[SingleInstance] Another instance detected, activating existing window');
      await _activateExistingInstance(arguments);

      _isFirstInstance = false;
      return false;
    } catch (e, s) {
      // 异常情况：允许启动，避免阻塞应用
      AppLogger.error('[SingleInstance] Error during single instance check', e, s);
      _isFirstInstance = true;
      return true;
    }
  }

  /// 是否是第一个实例
  static bool get isFirstInstance => _isFirstInstance;

  /// 尝试获取文件锁
  ///
  /// 返回值：
  /// - true: 成功获取锁（第一个实例）
  /// - false: 锁已被占用（已有实例）
  static Future<bool> _tryAcquireLock() async {
    try {
      // 创建或打开锁文件
      final lockFile = File(_lockFilePath);

      // 确保父目录存在
      if (!await lockFile.parent.exists()) {
        await lockFile.parent.create(recursive: true);
      }

      // 以读写模式打开文件
      final raf = await lockFile.open(mode: FileMode.append);

      // 尝试获取排他锁（非阻塞）
      // Linux 下使用 flock，通过 File.lock() 实现
      try {
        await raf.lock(FileLock.exclusive);
        _lockFile = raf;

        // 写入当前进程 PID，便于调试
        await raf.writeString('\nPID: $pid - ${DateTime.now().toIso8601String()}');

        return true;
      } on FileSystemException catch (e) {
        // 锁定失败，说明已有实例
        AppLogger.debug('[SingleInstance] Lock failed: ${e.message}');
        await raf.close();
        return false;
      }
    } catch (e) {
      AppLogger.warning('[SingleInstance] Error acquiring lock', e);
      return false;
    }
  }

  /// 启动 Socket 服务端
  ///
  /// 监听 Unix Socket，接收来自后续实例的激活请求
  static Future<void> _startSocketServer() async {
    try {
      // 删除可能存在的旧 Socket 文件
      final socketFile = File(_socketFilePath);
      if (await socketFile.exists()) {
        await socketFile.delete();
      }

      // 创建 Unix Socket 服务端
      final address = InternetAddress(_socketFilePath, type: InternetAddressType.unix);
      _serverSocket = await ServerSocket.bind(address, 0);

      AppLogger.info('[SingleInstance] Socket server started at $_socketFilePath');

      // 监听连接
      _serverSocket!.listen(
        _handleSocketConnection,
        onError: (error) {
          AppLogger.error('[SingleInstance] Socket server error', error);
        },
      );
    } catch (e, s) {
      AppLogger.error('[SingleInstance] Failed to start socket server', e, s);
    }
  }

  /// 处理 Socket 连接
  static void _handleSocketConnection(Socket socket) {
    AppLogger.debug('[SingleInstance] Received socket connection');

    socket.listen(
      (data) async {
        try {
          final rawMessage = utf8.decode(data).trim();
          final message = SingleInstanceMessage.fromWire(rawMessage);
          AppLogger.info(
            '[SingleInstance] Received message: ${message.kind.name}',
          );

          if (message.kind == SingleInstanceMessageKind.openUrl &&
              message.url != null) {
            _urlController.add(message.url!);
          }

          // 无论是否带 URL，都先激活窗口，保证浏览器跳转后的用户反馈明确。
          await _activateWindow();

          // 发送确认
          socket.add(utf8.encode('OK'));
          await socket.flush();
        } catch (e) {
          AppLogger.error('[SingleInstance] Error handling socket message', e);
        }
      },
      onDone: () {
        socket.destroy();
      },
      onError: (error) {
        AppLogger.error('[SingleInstance] Socket connection error', error);
        socket.destroy();
      },
    );
  }

  /// 激活已有实例
  ///
  /// 通过 Unix Socket 发送激活命令给第一个实例
  static Future<void> _activateExistingInstance(List<String> arguments) async {
    Socket? socket;
    try {
      // 连接到 Socket 服务端
      final address = InternetAddress(_socketFilePath, type: InternetAddressType.unix);
      socket = await Socket.connect(address, 0, timeout: const Duration(seconds: 3));

      // 发送激活或协议打开命令。
      final message = _messageFromArguments(arguments);
      socket.add(utf8.encode(message.toWire()));
      await socket.flush();

      // 等待确认（带超时）
      await socket.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => Uint8List(0),
      );

      AppLogger.info('[SingleInstance] Activation command sent successfully');
    } catch (e) {
      AppLogger.warning('[SingleInstance] Failed to activate existing instance', e);

      // 如果 Socket 通信失败，可能是旧的 Socket 文件残留
      // 尝试清理并重新检测
      await _cleanupStaleSocket();
    } finally {
      socket?.destroy();
    }
  }

  /// 根据新进程启动参数生成单实例消息。
  ///
  /// 只有可被旧 og 协议解析器识别的 URL 才会转交给主实例，其他启动参数
  /// 继续保持“激活窗口”行为，避免误把普通 CLI 参数当成安装请求。
  static SingleInstanceMessage _messageFromArguments(List<String> arguments) {
    for (final argument in arguments) {
      final request = OgProtocolRequest.tryParse(argument);
      if (request != null) {
        return SingleInstanceMessage.openUrl(request.rawUrl);
      }
    }

    return const SingleInstanceMessage.activate();
  }

  /// 激活窗口
  ///
  /// 显示、取消最小化并聚焦窗口
  static Future<void> _activateWindow() async {
    try {
      AppLogger.info('[SingleInstance] Activating window');

      // 检查窗口是否最小化
      final isMinimized = await WindowService.isMinimized();
      if (isMinimized) {
        await WindowService.show();
      }

      // 检查窗口是否可见
      final isVisible = await WindowService.isVisible();
      if (!isVisible) {
        await WindowService.show();
      }

      // 设置焦点
      await WindowService.focus();
    } catch (e, s) {
      AppLogger.error('[SingleInstance] Failed to activate window', e, s);
    }
  }

  /// 清理过期的 Socket 文件
  static Future<void> _cleanupStaleSocket() async {
    try {
      final socketFile = File(_socketFilePath);
      if (await socketFile.exists()) {
        await socketFile.delete();
        AppLogger.info('[SingleInstance] Cleaned up stale socket file');
      }
    } catch (e) {
      AppLogger.warning('[SingleInstance] Failed to cleanup stale socket', e);
    }
  }

  /// 释放资源
  ///
  /// 应用退出时调用，清理锁文件和 Socket 文件
  static Future<void> dispose() async {
    try {
      // 关闭 Socket 服务端
      await _serverSocket?.close();
      _serverSocket = null;

      // 删除 Socket 文件
      final socketFile = File(_socketFilePath);
      if (await socketFile.exists()) {
        await socketFile.delete();
      }

      // 释放文件锁并关闭文件
      await _lockFile?.close();
      _lockFile = null;

      AppLogger.info('[SingleInstance] Resources disposed');
    } catch (e, s) {
      AppLogger.error('[SingleInstance] Error during dispose', e, s);
    }
  }
}
