import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理封装
class WindowService {
  WindowService._();

  /// 最小窗口宽度
  static const double minWidth = 1280.0;

  /// 最小窗口高度
  static const double minHeight = 720.0;

  /// 默认窗口宽度
  static const double defaultWidth = 1280.0;

  /// 默认窗口高度
  static const double defaultHeight = 800.0;

  /// 初始化窗口
  static Future<void> init() async {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(defaultWidth, defaultHeight),
      minimumSize: Size(minWidth, minHeight),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: '玲珑应用商店社区版',
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions);
  }

  /// 显示窗口
  static Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  /// 聚焦窗口
  static Future<void> focus() async {
    await windowManager.focus();
  }

  /// 隐藏窗口
  static Future<void> hide() async {
    await windowManager.hide();
  }

  /// 最小化窗口
  static Future<void> minimize() async {
    await windowManager.minimize();
  }

  /// 最大化窗口
  static Future<void> maximize() async {
    await windowManager.maximize();
  }

  /// 取消最大化
  static Future<void> unmaximize() async {
    await windowManager.unmaximize();
  }

  /// 切换最大化状态
  static Future<void> toggleMaximize() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  /// 关闭窗口
  static Future<void> close() async {
    await windowManager.close();
  }

  /// 检查窗口是否最大化
  static Future<bool> isMaximized() async {
    return await windowManager.isMaximized();
  }

  /// 检查窗口是否最小化
  static Future<bool> isMinimized() async {
    return await windowManager.isMinimized();
  }

  /// 检查窗口是否可见
  static Future<bool> isVisible() async {
    return await windowManager.isVisible();
  }

  /// 检查窗口是否聚焦
  static Future<bool> isFocused() async {
    return await windowManager.isFocused();
  }

  /// 获取窗口大小
  static Future<Size> getSize() async {
    return await windowManager.getSize();
  }

  /// 设置窗口大小
  static Future<void> setSize(Size size) async {
    // 确保不小于最小尺寸
    final width = size.width < minWidth ? minWidth : size.width;
    final height = size.height < minHeight ? minHeight : size.height;
    await windowManager.setSize(Size(width, height));
  }

  /// 获取窗口位置
  static Future<Offset> getPosition() async {
    return await windowManager.getPosition();
  }

  /// 设置窗口位置
  static Future<void> setPosition(Offset position) async {
    await windowManager.setPosition(position);
  }

  /// 居中窗口
  static Future<void> center() async {
    await windowManager.center();
  }

  /// 开始拖拽窗口
  static Future<void> startDragging() async {
    await windowManager.startDragging();
  }

  /// 开始调整窗口大小
  static Future<void> startResizing(ResizeEdge edge) async {
    await windowManager.startResizing(edge);
  }

  /// 设置窗口标题
  static Future<void> setTitle(String title) async {
    await windowManager.setTitle(title);
  }

  /// 设置是否显示在任务栏
  static Future<void> setSkipTaskbar(bool skip) async {
    await windowManager.setSkipTaskbar(skip);
  }
}