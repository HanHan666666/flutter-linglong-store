/// 搜索页面 Robot
///
/// 封装搜索结果页的 UI 操作和验证逻辑。
/// 继承 BaseRobot 提供通用的查找和交互方法。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

import 'base_robot.dart';

/// 搜索页面 Robot
///
/// 用于测试搜索结果页的 UI 交互。
/// 包含搜索输入框、搜索结果列表、空状态、错误状态等元素的操作和验证。
class SearchRobot extends BaseRobot {
  /// 构造函数
  SearchRobot(super.$);

  // ============ 查找器 ============

  /// 查找搜索输入框
  ///
  /// 位于 AppBar 中的 TextField
  PatrolFinder searchInputField() => $(TextField);

  /// 查找搜索按钮
  ///
  /// AppBar 中的搜索图标按钮
  PatrolFinder searchIconButton() => iconButtonWidget(tooltip: '搜索');

  /// 查找清除按钮
  ///
  /// 输入框有内容时显示的清除图标按钮
  PatrolFinder clearButton() => iconButtonWidget(tooltip: '清除搜索');

  /// 查找搜索结果列表
  ///
  /// CustomScrollView 中的 GridView
  PatrolFinder searchResultsGrid() => gridViewWidget();

  /// 查找搜索结果卡片
  ///
  /// [appName] - 可选的应用名称
  PatrolFinder searchResultCard({String? appName}) {
    if (appName != null) {
      // 查找包含应用名称的卡片
      return $(GestureDetector).$(Text).containing(appName);
    }
    return $(GestureDetector);
  }

  /// 查找应用安装按钮
  ///
  /// 搜索结果卡片中的安装按钮
  PatrolFinder installButton() => $(#install_button);

  /// 查找空状态组件
  ///
  /// 无搜索结果时显示
  PatrolFinder emptyStateWidget() => textContaining('未找到');

  /// 查找错误状态组件
  ///
  /// 搜索出错时显示
  PatrolFinder errorStateWidget() => textContaining('出错了');

  /// 查找空状态图标
  ///
  /// 搜索无结果时的 search_off 图标
  PatrolFinder emptyStateIcon() => iconWidget(Icons.search_off);

  /// 查找错误状态图标
  ///
  /// 搜索出错时的 error_outline 图标
  PatrolFinder errorStateIcon() => iconWidget(Icons.error_outline);

  /// 查找结果统计文本
  ///
  /// 显示 "找到 X 个结果"
  PatrolFinder resultCountText() => textContaining('找到');

  /// 查找关键词高亮文本
  ///
  /// 显示搜索关键词
  PatrolFinder keywordText() => textContaining('"');

  /// 查找"未找到相关应用"文本
  PatrolFinder noResultsText() => textContaining('未找到');

  /// 查找"没有更多了"文本
  PatrolFinder noMoreDataText() => text('没有更多了');

  /// 查找下拉刷新指示器
  PatrolFinder refreshIndicator() => $(RefreshIndicator);

  /// 查找初始搜索提示
  ///
  /// 未搜索时显示的提示文字
  PatrolFinder initialSearchHint() => textContaining('输入关键词搜索应用');

  // ============ 操作方法 ============

  /// 输入搜索关键词
  ///
  /// [keyword] - 搜索关键词
  Future<void> enterSearchKeyword(String keyword) async {
    await enterText(searchInputField(), keyword);
  }

  /// 点击搜索按钮执行搜索
  Future<void> tapSearchButton() async {
    await tap(searchIconButton());
  }

  /// 点击清除按钮
  Future<void> tapClearButton() async {
    await tap(clearButton());
  }

  /// 按 Enter 键执行搜索
  Future<void> pressEnterToSearch() async {
    // 使用 tester.sendKeyEvent 发送回车键
    await $.tester.sendKeyEvent(LogicalKeyboardKey.enter);
  }

  /// 执行完整搜索流程
  ///
  /// [keyword] - 搜索关键词
  Future<void> search(String keyword) async {
    await enterSearchKeyword(keyword);
    await pressEnterToSearch();
  }

  /// 清空搜索
  Future<void> clearSearch() async {
    await tapClearButton();
  }

  /// 点击搜索结果卡片
  ///
  /// [appName] - 应用名称
  Future<void> tapSearchResultCard(String appName) async {
    await tap(searchResultCard(appName: appName));
  }

  /// 滚动搜索结果列表
  ///
  /// [distance] - 滚动距离
  Future<void> scrollResults({double distance = 500}) async {
    await scrollDown(scrollable: searchResultsGrid(), distance: distance);
  }

  /// 下拉刷新
  Future<void> pullToRefresh() async {
    // 使用 scrollDown 方法实现下拉刷新效果
    await $.tester.fling(searchResultsGrid(), const Offset(0, 300), 500);
    await $.pump(const Duration(milliseconds: 500));
  }

  /// 等待搜索加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForSearchComplete({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // 等待加载指示器消失
    await waitForLoadingToFinish(timeout: timeout);
    // 等待结果出现或空状态/错误状态出现
    await $.pump(const Duration(milliseconds: 500));
  }

  /// 等待更多结果加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForMoreResults({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 等待底部加载指示器消失
    await $.pumpAndSettle(timeout: timeout);
  }

  // ============ 验证方法 ============

  /// 验证搜索输入框可见
  void verifySearchInputVisible() {
    verifyExists(searchInputField());
  }

  /// 验证搜索按钮可见
  void verifySearchButtonVisible() {
    verifyExists(searchIconButton());
  }

  /// 验证清除按钮可见
  void verifyClearButtonVisible() {
    verifyExists(clearButton());
  }

  /// 验证清除按钮不可见
  void verifyClearButtonNotVisible() {
    verifyNotExists(clearButton());
  }

  /// 验证搜索结果可见
  void verifySearchResultsVisible() {
    verifyExists(searchResultsGrid());
  }

  /// 验证搜索结果数量
  ///
  /// [minCount] - 最小结果数量
  void verifySearchResultsCount({int minCount = 1}) {
    final results = searchResultsGrid();
    expect(results, findsWidgets);
  }

  /// 验证搜索结果包含指定应用
  ///
  /// [appName] - 应用名称
  void verifySearchResultContains(String appName) {
    verifyExists(searchResultCard(appName: appName));
  }

  /// 验证空状态显示
  void verifyEmptyStateVisible() {
    verifyExists(emptyStateWidget());
  }

  /// 验证空状态图标显示
  void verifyEmptyStateIconVisible() {
    verifyExists(emptyStateIcon());
  }

  /// 验证"未找到相关应用"文本显示
  void verifyNoResultsTextVisible() {
    verifyTextExists('未找到相关应用');
  }

  /// 验证错误状态显示
  void verifyErrorStateVisible() {
    verifyExists(errorStateWidget());
  }

  /// 验证错误状态图标显示
  void verifyErrorStateIconVisible() {
    verifyExists(errorStateIcon());
  }

  /// 验证结果统计显示
  ///
  /// [expectedCount] - 期望的结果数量
  void verifyResultCountVisible({int? expectedCount}) {
    if (expectedCount != null) {
      verifyTextExists('找到 $expectedCount 个');
    } else {
      verifyExists(resultCountText());
    }
  }

  /// 验证关键词高亮显示
  ///
  /// [keyword] - 搜索关键词
  void verifyKeywordHighlighted(String keyword) {
    verifyTextExists('"$keyword"');
  }

  /// 验证初始搜索提示显示
  void verifyInitialSearchHintVisible() {
    verifyExists(initialSearchHint());
  }

  /// 验证"没有更多了"文本显示
  void verifyNoMoreDataVisible() {
    verifyExists(noMoreDataText());
  }

  /// 验证搜索结果页面已加载
  void verifySearchPageLoaded() {
    verifySearchInputVisible();
    verifySearchButtonVisible();
  }

  /// 验证搜索输入框内容
  ///
  /// [expectedText] - 期望的文本内容
  void verifySearchInputText(String expectedText) {
    final textField = searchInputField().evaluate().first.widget as TextField;
    expect(textField.controller?.text, expectedText);
  }
}

/// 扩展方法：创建 SearchRobot
extension SearchRobotExtension on PatrolTester {
  /// 创建搜索页面 Robot
  SearchRobot get searchRobot => SearchRobot(this);
}
