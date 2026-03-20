import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';
import 'window_service.dart';

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

  /// 锁文件完整路径
  static String get _lockFilePath => p.join(Directory.systemTemp.path, _lockFileName);

  /// Socket 文件完整路径
  static String get _socketFilePath => p.join(Directory.systemTemp.path, _socketFileName);

  /// 确保单实例运行
  ///
  /// 返回值：
  /// - true: 是第一个实例，继续启动
  /// - false: 已有实例，当前实例应退出
  static Future<bool> ensure() async {
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
      await _activateExistingInstance();

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
          final message = utf8.decode(data).trim();
          AppLogger.info('[SingleInstance] Received message: $message');

          if (message == _activateCommand) {
            // 激活窗口
            await _activateWindow();
          }

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
  static Future<void> _activateExistingInstance() async {
    Socket? socket;
    try {
      // 连接到 Socket 服务端
      final address = InternetAddress(_socketFilePath, type: InternetAddressType.unix);
      socket = await Socket.connect(address, 0, timeout: const Duration(seconds: 3));

      // 发送激活命令
      socket.add(utf8.encode(_activateCommand));
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