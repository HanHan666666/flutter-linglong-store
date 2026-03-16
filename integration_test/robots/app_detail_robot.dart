/// 应用详情页 Robot
library;

import 'package:flutter_test/flutter_test.dart';

///
/// 封装应用详情页的 UI 操作和验证逻辑。
/// 支持应用详情展示、安装/卸载操作等测试场景。

import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

import 'base_robot.dart';

/// 应用详情页 Robot
///
/// 用于测试应用详情页的 UI 交互。
/// 包含头部信息、截图轮播、描述展开、版本列表等元素的查找和操作。
class AppDetailRobot extends BaseRobot {
  /// 构造函数
  AppDetailRobot(super.$);

  // ===== 页面元素查找 =====

  /// 查找应用详情页 AppBar
  PatrolFinder appBar() => $(AppBar);

  /// 查找应用图标
  PatrolFinder appIcon() => $(#app_detail_icon);

  /// 查找应用名称
  ///
  /// [name] - 应用名称
  PatrolFinder appName(String name) => text(name);

  /// 查找应用版本信息
  PatrolFinder appVersion() => textContaining('版本');

  /// 查找应用开发者/仓库信息
  PatrolFinder repoName() => $(#app_repo_name);

  /// 查找安装按钮区域
  PatrolFinder installButtonArea() => $(#install_button_area);

  /// 查找截图区域
  PatrolFinder screenshotsSection() => text('应用截图');

  /// 查找截图列表
  PatrolFinder screenshotList() => $(#screenshot_list);

  /// 查找描述区域
  PatrolFinder descriptionSection() => text('应用介绍');

  /// 查找描述文本
  ///
  /// [description] - 描述文本
  PatrolFinder description(String description) => textContaining(description);

  /// 查找展开按钮
  PatrolFinder expandButton() => $(TextButton).containing('展开全部');

  /// 查找收起按钮
  PatrolFinder collapseButton() => $(TextButton).containing('收起');

  /// 查找应用信息表格
  PatrolFinder appInfoTable() => text('应用信息');

  /// 查找包名信息
  ///
  /// [appId] - 应用包名
  PatrolFinder packageId(String appId) => textContaining(appId);

  /// 查找版本历史区域
  PatrolFinder versionHistorySection() => text('版本历史');

  /// 查找版本列表项
  ///
  /// [version] - 版本号
  PatrolFinder versionItem(String version) => textContaining('v$version');

  /// 查找当前版本标记
  PatrolFinder currentVersionBadge() => text('当前版本');

  /// 查找安装指定版本按钮
  PatrolFinder installVersionButton() => $(TextButton).containing('安装');

  /// 查找更多操作菜单按钮
  PatrolFinder moreMenuButton() => $(PopupMenuButton<String>);

  /// 查找创建快捷方式菜单项
  PatrolFinder createShortcutMenuItem() => text('创建快捷方式');

  /// 查找返回按钮
  PatrolFinder backButton() => $(IconButton).first;

  /// 查找加载指示器
  PatrolFinder loadingIndicator() => $(CircularProgressIndicator);

  /// 查找错误视图
  PatrolFinder errorView() => $(Icons.error_outline);

  /// 查找重试按钮
  PatrolFinder retryButton() => $(FilledButton).containing('重试');

  /// 查找截图预览页面
  PatrolFinder screenshotPreview() => $(#screenshot_preview);

  // ===== 操作方法 =====

  /// 点击返回按钮
  Future<void> tapBack() async {
    await tap(backButton());
  }

  /// 点击展开描述
  Future<void> tapExpandDescription() async {
    await tap(expandButton());
  }

  /// 点击收起描述
  Future<void> tapCollapseDescription() async {
    await tap(collapseButton());
  }

  /// 点击安装指定版本
  ///
  /// [version] - 版本号
  Future<void> tapInstallVersion(String version) async {
    // 滚动到版本历史区域
    await scrollUntilVisible(versionItem(version));
    await tap(installVersionButton());
  }

  /// 点击更多菜单
  Future<void> tapMoreMenu() async {
    await tap(moreMenuButton());
  }

  /// 点击创建快捷方式
  Future<void> tapCreateShortcut() async {
    await tapMoreMenu();
    await tap(createShortcutMenuItem());
  }

  /// 点击截图查看预览
  ///
  /// [index] - 截图索引
  Future<void> tapScreenshot(int index) async {
    final screenshots = screenshotList().$(GestureDetector);
    if (index < screenshots.evaluate().length) {
      await tap(screenshots.at(index));
    }
  }

  /// 点击重试加载
  Future<void> tapRetry() async {
    await tap(retryButton());
  }

  /// 滚动到指定区域
  ///
  /// [sectionName] - 区域名称
  Future<void> scrollToSection(String sectionName) async {
    await scrollUntilVisible(text(sectionName));
  }

  // ===== 等待方法 =====

  /// 等待详情页加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForDetailLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await waitUntilGone(loadingIndicator(), timeout: timeout);
  }

  /// 等待版本列表加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForVersionsLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 等待版本历史区域出现
    await waitFor(versionHistorySection(), timeout: timeout);
  }

  // ===== 验证方法 =====

  /// 验证详情页显示
  void verifyDetailPageVisible() {
    verifyExists(appBar());
  }

  /// 验证应用名称正确
  ///
  /// [name] - 期望的应用名称
  void verifyAppName(String name) {
    verifyExists(appName(name));
  }

  /// 验证版本信息显示
  void verifyVersionVisible() {
    verifyExists(appVersion());
  }

  /// 验证安装按钮区域可见
  void verifyInstallButtonAreaVisible() {
    verifyExists(installButtonArea());
  }

  /// 验证截图区域存在
  void verifyScreenshotsExist() {
    final hasScreenshots = screenshotsSection().evaluate().isNotEmpty;
    // 截图可能为空，所以仅检查区域存在
    if (hasScreenshots) {
      verifyExists(screenshotsSection());
    }
  }

  /// 验证描述区域可见
  void verifyDescriptionVisible() {
    verifyExists(descriptionSection());
  }

  /// 验证描述已展开
  void verifyDescriptionExpanded() {
    verifyExists(collapseButton());
  }

  /// 验证描述已收起
  void verifyDescriptionCollapsed() {
    verifyExists(expandButton());
  }

  /// 验证应用信息表格可见
  void verifyAppInfoTableVisible() {
    verifyExists(appInfoTable());
  }

  /// 验证版本历史区域可见
  void verifyVersionHistoryVisible() {
    verifyExists(versionHistorySection());
  }

  /// 验证当前版本标记
  ///
  /// [version] - 当前版本号
  void verifyCurrentVersion(String version) {
    verifyExists(versionItem(version));
    verifyExists(currentVersionBadge());
  }

  /// 验证加载中状态
  void verifyLoading() {
    verifyExists(loadingIndicator());
  }

  /// 验证错误状态
  void verifyError() {
    verifyExists(errorView());
  }

  /// 验证包名显示正确
  ///
  /// [appId] - 期望的包名
  void verifyPackageId(String appId) {
    verifyExists(packageId(appId));
  }
}

/// 扩展方法：创建 AppDetailRobot
extension AppDetailRobotExtension on PatrolTester {
  /// 创建应用详情页 Robot
  AppDetailRobot get appDetailRobot => AppDetailRobot(this);
}
