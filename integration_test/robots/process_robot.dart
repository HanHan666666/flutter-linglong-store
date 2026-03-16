/// 进程管理页面 Robot
library;

import 'package:flutter_test/flutter_test.dart';

///
/// 封装进程管理页面的 UI 操作和验证逻辑。
/// 继承 BaseRobot 提供通用的查找和交互方法。

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

import 'base_robot.dart';

/// 进程管理页面 Robot
///
/// 用于测试进程管理页面的 UI 交互。
/// 包含进程列表、刷新、停止进程等操作的查找和验证。
class ProcessRobot extends BaseRobot {
  /// 构造函数
  ProcessRobot(super.$);

  // ========== 页面元素 Finder ==========

  /// 查找页面标题 "运行中应用"
  PatrolFinder pageTitle() => text('运行中应用');

  /// 查找进程数量徽章
  PatrolFinder processCountBadge() => $(#process_count_badge);

  /// 查找刷新按钮
  PatrolFinder refreshButton() => iconButtonWidget(tooltip: '刷新');

  /// 查找自动刷新开关按钮
  PatrolFinder autoRefreshToggleButton() => iconButtonWidget(tooltip: '暂停自动刷新');

  /// 查找开始自动刷新按钮
  PatrolFinder startAutoRefreshButton() => iconButtonWidget(tooltip: '开始自动刷新');

  /// 查找自动刷新指示器文本
  PatrolFinder autoRefreshIndicator() => text('自动刷新');

  /// 查找同步图标（自动刷新时的图标）
  PatrolFinder syncIcon() => iconWidget(Icons.sync);

  /// 查找空状态提示
  PatrolFinder emptyStateIcon() => iconWidget(Icons.layers_clear);

  /// 查找空状态标题
  PatrolFinder emptyStateTitle() => text('没有运行中的应用');

  /// 查找加载指示器
  PatrolFinder loadingIndicator() => circularProgressIndicatorWidget();

  /// 查找错误状态图标
  PatrolFinder errorStateIcon() => iconWidget(Icons.error_outline);

  /// 查找进程列表
  PatrolFinder processList() => listViewWidget();

  /// 查找进程卡片
  ///
  /// [appName] - 可选的应用名称
  PatrolFinder processCard({String? appName}) {
    if (appName != null) {
      // 通过应用名称查找包含该名称的 Card
      return $(Card).containing(text(appName));
    }
    return cardWidget();
  }

  /// 查找运行状态指示器（绿色竖条）
  PatrolFinder runningIndicator() => $(#running_indicator);

  /// 查找应用图标
  PatrolFinder appIcon() => $(#app_icon);

  /// 查找默认应用图标
  PatrolFinder defaultAppIcon() => iconWidget(Icons.apps);

  /// 查找 PID 显示文本
  ///
  /// [pid] - 进程ID
  PatrolFinder pidText(String pid) => textContaining('PID: $pid');

  /// 查找任意 PID 文本
  PatrolFinder anyPidText() => textContaining('PID:');

  /// 查找停止按钮
  PatrolFinder stopButton() => iconButtonWidget(tooltip: '停止应用');

  /// 查找停止按钮图标
  PatrolFinder stopButtonIcon() => iconWidget(Icons.stop_circle_outlined);

  // ========== 对话框 Finder ==========

  /// 查找确认停止对话框
  PatrolFinder confirmStopDialog() => $(AlertDialog);

  /// 查找确认停止对话框标题
  PatrolFinder confirmStopDialogTitle() => text('确认停止');

  /// 查找取消按钮
  PatrolFinder cancelButton() => textButtonWidget(text: '取消');

  /// 查找停止确认按钮
  PatrolFinder confirmStopButton() => filledButtonWidget(text: '停止');

  /// 查找 SnackBar
  PatrolFinder snackBar() => $(SnackBar);

  /// 查找停止成功消息
  PatrolFinder stopSuccessMessage(String appName) =>
      textContaining('$appName 已停止');

  /// 查找停止失败消息
  PatrolFinder stopFailureMessage(String appName) =>
      textContaining('停止 $appName 失败');

  // ========== 操作方法 ==========

  /// 点击刷新按钮
  Future<void> tapRefresh() async {
    await tap(refreshButton());
  }

  /// 点击自动刷新开关
  Future<void> toggleAutoRefresh() async {
    // 点击暂停或开始按钮
    final pauseBtn = iconButtonWidget(tooltip: '暂停自动刷新');
    final startBtn = iconButtonWidget(tooltip: '开始自动刷新');

    // 尝试点击存在的按钮
    try {
      await tap(pauseBtn);
    } catch (_) {
      await tap(startBtn);
    }
  }

  /// 点击进程卡片的停止按钮
  ///
  /// [index] - 进程列表索引，默认为第一个
  Future<void> tapStopButton({int index = 0}) async {
    final buttons = $(IconButton);
    // 找到停止按钮（带有 stop_circle_outlined 图标）
    final stopButtons = buttons.evaluate().where((element) {
      final widget = element.widget as IconButton;
      return widget.icon is Icon &&
          (widget.icon as Icon).icon == Icons.stop_circle_outlined;
    }).toList();

    if (index < stopButtons.length) {
      await $(stopButtons[index]).tap();
    }
  }

  /// 在确认对话框中点击取消
  Future<void> cancelStop() async {
    await tap(cancelButton());
  }

  /// 在确认对话框中确认停止
  Future<void> confirmStop() async {
    await tap(confirmStopButton());
  }

  /// 执行停止进程的完整流程
  ///
  /// [confirm] - 是否确认停止，默认为 true
  Future<void> stopProcess({bool confirm = true}) async {
    await tapStopButton();
    await waitFor(confirmStopDialog());
    if (confirm) {
      await confirmStop();
    } else {
      await cancelStop();
    }
  }

  /// 等待进程列表加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForProcessListLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 等待加载指示器消失
    await waitUntilGone(loadingIndicator(), timeout: timeout);
  }

  /// 等待页面可见
  ///
  /// [timeout] - 超时时间
  Future<void> waitForPageVisible({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitFor(pageTitle(), timeout: timeout);
  }

  // ========== 验证方法 ==========

  /// 验证页面标题可见
  void verifyPageTitleVisible() {
    verifyExists(pageTitle());
  }

  /// 验证刷新按钮可见
  void verifyRefreshButtonVisible() {
    verifyExists(refreshButton());
  }

  /// 验证自动刷新开关可见
  void verifyAutoRefreshToggleVisible() {
    final pauseBtn = iconButtonWidget(tooltip: '暂停自动刷新');
    final startBtn = iconButtonWidget(tooltip: '开始自动刷新');
    // 至少有一个按钮存在
    expect(
      pauseBtn.evaluate().isNotEmpty || startBtn.evaluate().isNotEmpty,
      isTrue,
      reason: '自动刷新开关按钮应该可见',
    );
  }

  /// 验证空状态显示
  void verifyEmptyStateVisible() {
    verifyExists(emptyStateTitle());
  }

  /// 验证加载状态显示
  void verifyLoadingStateVisible() {
    verifyExists(loadingIndicator());
  }

  /// 验证进程列表可见
  void verifyProcessListVisible() {
    verifyExists(processList());
  }

  /// 验证进程卡片数量
  ///
  /// [minCount] - 最小数量
  void verifyProcessCardCount({int minCount = 1}) {
    final cards = cardWidget();
    final count = cards.evaluate().length;
    expect(
      count >= minCount,
      isTrue,
      reason: '进程卡片数量应该至少为 $minCount，实际为 $count',
    );
  }

  /// 验证指定进程存在
  ///
  /// [appName] - 应用名称
  void verifyProcessExists(String appName) {
    verifyExists(processCard(appName: appName));
  }

  /// 验证指定进程不存在
  ///
  /// [appName] - 应用名称
  void verifyProcessNotExists(String appName) {
    verifyNotExists(processCard(appName: appName));
  }

  /// 验证确认停止对话框显示
  void verifyConfirmDialogVisible() {
    verifyExists(confirmStopDialog());
    verifyExists(confirmStopDialogTitle());
  }

  /// 验证确认停止对话框消失
  void verifyConfirmDialogGone() {
    verifyNotExists(confirmStopDialog());
  }

  /// 验证停止成功消息显示
  ///
  /// [appName] - 应用名称
  void verifyStopSuccessMessage(String appName) {
    verifyExists(stopSuccessMessage(appName));
  }

  /// 验证自动刷新已开启
  void verifyAutoRefreshEnabled() {
    verifyExists(autoRefreshIndicator());
  }

  /// 验证自动刷新已关闭
  void verifyAutoRefreshDisabled() {
    verifyNotExists(autoRefreshIndicator());
  }

  /// 验证 PID 显示正确
  ///
  /// [pid] - 进程ID
  void verifyPidDisplayed(String pid) {
    verifyExists(pidText(pid));
  }
}

/// 扩展方法：创建 ProcessRobot
extension ProcessRobotExtension on PatrolTester {
  /// 创建进程管理页面 Robot
  ProcessRobot get processRobot => ProcessRobot(this);
}
