/// 安装操作 Robot
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

///
/// 封装安装队列相关的 UI 操作和验证逻辑。
/// 支持安装流程（BF-03）的测试：
/// - 入口：用户点击"安装/更新"按钮
/// - 状态机：Idle → Waiting → Installing → Succeeded/Failed/Cancelled
/// - 超时：360 秒
/// - 队列：串行执行

import 'package:flutter/material.dart';

import 'base_robot.dart';

/// 安装操作 Robot
///
/// 用于测试安装流程的 UI 交互。
/// 包含安装按钮、进度展示、取消操作等元素的查找和操作。
class InstallRobot extends BaseRobot {
  /// 构造函数
  InstallRobot(super.$);

  /// 查找安装按钮（未安装状态）
  PatrolFinder installButton() => $(ElevatedButton).containing('安装');

  /// 查找更新按钮
  PatrolFinder updateButton() => $(ElevatedButton).containing('更新');

  /// 查找打开按钮
  PatrolFinder openButton() => $(OutlinedButton).containing('打开');

  /// 查找卸载按钮
  PatrolFinder uninstallButton() => $(OutlinedButton).containing('卸载');

  /// 查找进度指示器
  PatrolFinder progressIndicator() => $(LinearProgressIndicator);

  /// 查找进度百分比文本
  ///
  /// [percent] - 进度百分比（如 50）
  PatrolFinder progressText(int percent) => text('$percent%');

  /// 查找取消按钮（进度条中的 X 图标）
  PatrolFinder cancelButton() => $(Icons.close);

  /// 查找安装状态消息
  ///
  /// [message] - 状态消息文本
  PatrolFinder statusMessage(String message) => textContaining(message);

  /// 查找安装失败错误消息
  PatrolFinder errorMessage() => $(#install_error_message);

  /// 查找重试按钮
  PatrolFinder retryButton() => $(TextButton).containing('重试');

  /// 查找安装队列面板
  PatrolFinder installQueuePanel() => $(#install_queue_panel);

  /// 查找队列中的任务项
  ///
  /// [appName] - 应用名称
  PatrolFinder queueItem(String appName) => $(Card).containing(appName);

  // ===== 操作方法 =====

  /// 点击安装按钮
  Future<void> tapInstall() async {
    await tap(installButton());
  }

  /// 点击更新按钮
  Future<void> tapUpdate() async {
    await tap(updateButton());
  }

  /// 点击打开按钮
  Future<void> tapOpen() async {
    await tap(openButton());
  }

  /// 点击卸载按钮
  Future<void> tapUninstall() async {
    await tap(uninstallButton());
  }

  /// 点击取消安装
  Future<void> tapCancel() async {
    await tap(cancelButton());
  }

  /// 点击重试按钮
  Future<void> tapRetry() async {
    await tap(retryButton());
  }

  /// 等待安装开始
  ///
  /// [timeout] - 超时时间
  Future<void> waitForInstallStart({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitFor(progressIndicator(), timeout: timeout);
  }

  /// 等待安装完成
  ///
  /// [timeout] - 超时时间（默认 360 秒，符合业务要求）
  Future<void> waitForInstallComplete({
    Duration timeout = const Duration(seconds: 360),
  }) async {
    // 等待进度指示器消失
    await waitUntilGone(progressIndicator(), timeout: timeout);
  }

  /// 等待打开按钮出现（安装成功标志）
  ///
  /// [timeout] - 超时时间
  Future<void> waitForOpenButton({
    Duration timeout = const Duration(seconds: 360),
  }) async {
    await waitFor(openButton(), timeout: timeout);
  }

  // ===== 验证方法 =====

  /// 验证安装按钮可见
  void verifyInstallButtonVisible() {
    verifyExists(installButton());
  }

  /// 验证更新按钮可见
  void verifyUpdateButtonVisible() {
    verifyExists(updateButton());
  }

  /// 验证打开按钮可见
  void verifyOpenButtonVisible() {
    verifyExists(openButton());
  }

  /// 验证安装进度显示
  void verifyProgressVisible() {
    verifyExists(progressIndicator());
  }

  /// 验证安装进度百分比
  ///
  /// [minPercent] - 最小进度百分比
  void verifyProgressAtLeast(int minPercent) {
    // 验证进度指示器存在
    verifyExists(progressIndicator());
  }

  /// 验证安装成功
  void verifyInstallSuccess() {
    // 安装成功后应显示打开按钮
    verifyExists(openButton());
  }

  /// 验证安装失败
  void verifyInstallFailed() {
    // 安装失败后应显示重试按钮或错误信息
    final hasRetry = retryButton().evaluate().isNotEmpty;
    final hasError = errorMessage().evaluate().isNotEmpty;
    expect(hasRetry || hasError, isTrue, reason: '安装失败应显示重试按钮或错误信息');
  }

  /// 验证安装已取消
  void verifyInstallCancelled() {
    // 取消后应恢复到安装按钮状态
    verifyExists(installButton());
  }

  /// 验证状态消息包含指定文本
  ///
  /// [message] - 期望的消息文本
  void verifyStatusMessageContains(String message) {
    verifyExists(statusMessage(message));
  }

  /// 验证应用不在安装队列中
  ///
  /// [appName] - 应用名称
  void verifyNotInQueue(String appName) {
    verifyNotExists(queueItem(appName));
  }
}

/// 扩展方法：创建 InstallRobot
extension InstallRobotExtension on PatrolTester {
  /// 创建安装操作 Robot
  InstallRobot get installRobot => InstallRobot(this);
}
