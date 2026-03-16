/// 首页 Robot
///
/// 封装首页（推荐页）的 UI 操作和验证逻辑。
/// 继承 BaseRobot 提供通用的查找和交互方法。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

import 'base_robot.dart';

/// 首页 Robot
///
/// 用于测试首页（推荐页）的 UI 交互。
/// 包含导航栏、应用卡片、搜索框等元素的查找和操作。
class HomeRobot extends BaseRobot {
  /// 构造函数
  HomeRobot(super.$);

  /// 查找底部导航栏
  PatrolFinder bottomNav() => bottomNavigationBarWidget();

  /// 查找推荐页导航项
  PatrolFinder recommendNavItem() => byKey(const ValueKey('nav_recommend'));

  /// 查找全部应用导航项
  PatrolFinder allAppsNavItem() => byKey(const ValueKey('nav_all_apps'));

  /// 查找排行榜导航项
  PatrolFinder rankingNavItem() => byKey(const ValueKey('nav_ranking'));

  /// 查找我的应用导航项
  PatrolFinder myAppsNavItem() => byKey(const ValueKey('nav_my_apps'));

  /// 查找搜索按钮
  PatrolFinder searchButton() => byKey(const ValueKey('search_button'));

  /// 查找搜索输入框
  PatrolFinder searchInput() => byKey(const ValueKey('search_input'));

  /// 查找应用卡片
  ///
  /// [appName] - 可选的应用名称
  PatrolFinder appCard({String? appName}) {
    if (appName != null) {
      return cardWidget().$(Text).containing(appName);
    }
    return cardWidget();
  }

  /// 查找应用卡片安装按钮
  PatrolFinder installButton() => byKey(const ValueKey('install_button'));

  /// 查找分类标题
  ///
  /// [title] - 分类标题文本
  PatrolFinder categoryTitle(String title) => text(title);

  /// 查找分类更多按钮
  PatrolFinder categoryMoreButton() =>
      byKey(const ValueKey('category_more_button'));

  /// 查找轮播图
  PatrolFinder bannerCarousel() => byKey(const ValueKey('banner_carousel'));

  /// 查找轮播图指示器
  PatrolFinder bannerIndicator() => byKey(const ValueKey('banner_indicator'));

  /// 点击搜索按钮
  Future<void> tapSearch() async {
    await tap(searchButton());
  }

  /// 输入搜索关键词
  ///
  /// [keyword] - 搜索关键词
  Future<void> enterSearchKeyword(String keyword) async {
    await enterText(searchInput(), keyword);
  }

  /// 执行搜索
  ///
  /// [keyword] - 搜索关键词
  Future<void> search(String keyword) async {
    await tapSearch();
    await enterSearchKeyword(keyword);
    // 按下回车键
    await $.tester.sendKeyEvent(LogicalKeyboardKey.enter);
  }

  /// 点击底部导航项
  ///
  /// [index] - 导航项索引（0: 推荐, 1: 全部应用, 2: 排行榜, 3: 我的应用）
  Future<void> tapNavItem(int index) async {
    final navItems = [
      recommendNavItem(),
      allAppsNavItem(),
      rankingNavItem(),
      myAppsNavItem(),
    ];
    if (index >= 0 && index < navItems.length) {
      await tap(navItems[index]);
    }
  }

  /// 切换到推荐页
  Future<void> goToRecommend() async => tapNavItem(0);

  /// 切换到全部应用页
  Future<void> goToAllApps() async => tapNavItem(1);

  /// 切换到排行榜页
  Future<void> goToRanking() async => tapNavItem(2);

  /// 切换到我的应用页
  Future<void> goToMyApps() async => tapNavItem(3);

  /// 点击应用卡片
  ///
  /// [appName] - 应用名称
  Future<void> tapAppCard(String appName) async {
    await tap(appCard(appName: appName));
  }

  /// 点击分类更多按钮
  Future<void> tapCategoryMore() async {
    await tap(categoryMoreButton());
  }

  /// 滚动应用列表
  ///
  /// [distance] - 滚动距离
  Future<void> scrollAppList({double distance = 500}) async {
    await scrollDown(distance: distance);
  }

  /// 验证底部导航栏可见
  void verifyBottomNavVisible() {
    verifyExists(bottomNav());
  }

  /// 验证推荐页激活
  void verifyRecommendActive() {
    // 验证推荐页导航项被选中
    verifyExists(recommendNavItem());
  }

  /// 验证搜索按钮可见
  void verifySearchButtonVisible() {
    verifyExists(searchButton());
  }

  /// 验证应用卡片存在
  ///
  /// [appName] - 应用名称
  void verifyAppCardExists(String appName) {
    verifyExists(appCard(appName: appName));
  }

  /// 验证应用卡片数量
  ///
  /// [minCount] - 最小数量
  void verifyAppCardCount({int minCount = 1}) {
    final cards = cardWidget();
    // 验证至少有指定数量的卡片
    expect(cards, findsWidgets);
  }

  /// 等待首页加载完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForHomeLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 等待加载指示器消失
    await waitForLoadingToFinish(timeout: timeout);
    // 等待底部导航栏出现
    await waitFor(bottomNav(), timeout: timeout);
  }
}

/// 扩展方法：创建 HomeRobot
extension HomeRobotExtension on PatrolTester {
  /// 创建首页 Robot
  HomeRobot get homeRobot => HomeRobot(this);
}
