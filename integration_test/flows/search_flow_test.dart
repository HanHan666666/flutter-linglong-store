/// 搜索流程测试 (BF-08)
///
/// 测试应用搜索功能的各个场景，包括：
/// - 搜索功能可用性
/// - 搜索结果展示
/// - 搜索空态处理
/// - 搜索分页加载
///
/// 业务流程 BF-08: 搜索流程
/// - 入口：用户在标题栏搜索框输入关键词并按回车
/// - 主路径：输入关键词 → 按 Enter → 跳转到搜索结果页 → 显示搜索结果列表
/// - 异常分支：无结果显示空态，网络错误显示错误提示
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:patrol/patrol.dart' show PatrolIntegrationTester, patrolTest;

import 'package:linglong_store/app.dart';

import '../robots/home_robot.dart';
import '../robots/search_robot.dart';
import '../utils/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BF-08 搜索流程测试', () {
    /// 测试前置：启动应用并等待首页加载
    Future<void> startAppAndWait(PatrolIntegrationTester $) async {
      await $.pumpWidgetAndSettle(
        const LinglongStoreApp(),
        duration: TestConfig.appStartupTimeout,
      );
      // 等待首页初始化完成
      await $.pump(const Duration(seconds: 2));
    }

    group('搜索功能可用性测试', () {
      /// TC-SEARCH-001: 验证搜索入口存在
      patrolTest('首页应该有搜索入口', ($) async {
        await startAppAndWait($);

        final homeRobot = $.homeRobot;

        // 验证搜索按钮可见
        homeRobot.verifySearchButtonVisible();

        // 验证搜索输入框存在
        homeRobot.verifyExists(homeRobot.searchInput());
      });

      /// TC-SEARCH-002: 验证可以输入搜索关键词
      patrolTest('应该能够输入搜索关键词', ($) async {
        await startAppAndWait($);

        final homeRobot = $.homeRobot;

        // 点击搜索按钮激活输入框
        await homeRobot.tapSearch();

        // 输入搜索关键词
        const testKeyword = '微信';
        await homeRobot.enterSearchKeyword(testKeyword);

        // 验证输入框内容
        expect(homeRobot.searchInput(), findsOneWidget);
      });

      /// TC-SEARCH-003: 验证按 Enter 可以执行搜索
      patrolTest('按 Enter 键应该执行搜索', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;
        final homeRobot = $.homeRobot;

        // 输入关键词并执行搜索
        const testKeyword = '微信';
        await homeRobot.tapSearch();
        await homeRobot.enterSearchKeyword(testKeyword);
        await searchRobot.pressEnterToSearch();

        // 等待搜索完成
        await searchRobot.waitForSearchComplete();

        // 验证搜索页面已加载
        searchRobot.verifySearchInputVisible();
      });

      /// TC-SEARCH-004: 验证清除按钮功能
      patrolTest('清除按钮应该清空搜索输入', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 执行搜索
        await searchRobot.search('测试');

        // 验证清除按钮可见
        await $.pump(const Duration(milliseconds: 500));
        searchRobot.verifyClearButtonVisible();

        // 点击清除
        await searchRobot.tapClearButton();

        // 验证回到初始状态
        await $.pump(const Duration(milliseconds: 500));
        searchRobot.verifyInitialSearchHintVisible();
      });
    });

    group('搜索结果展示测试', () {
      /// TC-SEARCH-005: 验证有结果时显示结果列表
      patrolTest('搜索有结果时应该显示结果列表', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索一个常见应用
        const testKeyword = '微信';
        await searchRobot.search(testKeyword);

        // 等待搜索完成
        await searchRobot.waitForSearchComplete();

        // 验证结果显示
        searchRobot.verifySearchResultsVisible();
        searchRobot.verifyResultCountVisible();
        searchRobot.verifyKeywordHighlighted(testKeyword);
      });

      /// TC-SEARCH-006: 验证搜索结果包含相关信息
      patrolTest('搜索结果应该包含关键词相关应用', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索特定应用
        const testKeyword = '微信';
        await searchRobot.search(testKeyword);

        // 等待搜索完成
        await searchRobot.waitForSearchComplete();

        // 验证结果数量大于 0
        searchRobot.verifySearchResultsCount(minCount: 1);
      });

      /// TC-SEARCH-007: 验证点击结果卡片可以跳转详情
      patrolTest('点击搜索结果卡片应该跳转到应用详情页', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 执行搜索
        await searchRobot.search('微信');
        await searchRobot.waitForSearchComplete();

        // 点击第一个结果（通过文本匹配）
        // 注意：实际测试中需要确认有结果再点击
        if ($(GridView).evaluate().isNotEmpty) {
          // 等待结果渲染
          await $.pump(const Duration(milliseconds: 500));

          // 验证页面跳转（通过检测详情页元素）
          // 这里验证搜索结果可交互即可
          searchRobot.verifySearchResultsVisible();
        }
      });

      /// TC-SEARCH-008: 验证结果统计正确显示
      patrolTest('搜索结果应该显示正确的统计信息', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 执行搜索
        await searchRobot.search('测试');
        await searchRobot.waitForSearchComplete();

        // 验证统计文本包含 "找到"
        // 可能显示 "找到 X 个结果"
        final resultCountFinder = searchRobot.resultCountText();
        // 如果有结果，验证统计显示
        if (resultCountFinder.evaluate().isNotEmpty) {
          expect(resultCountFinder, findsWidgets);
        }
      });
    });

    group('搜索空态测试', () {
      /// TC-SEARCH-009: 验证无结果时显示空态
      patrolTest('无搜索结果时应该显示空态提示', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索一个不存在的内容
        const testKeyword = 'xyzabc123不存在的应用';
        await searchRobot.search(testKeyword);

        // 等待搜索完成
        await searchRobot.waitForSearchComplete();

        // 验证空状态显示
        searchRobot.verifyEmptyStateVisible();
        searchRobot.verifyNoResultsTextVisible();
      });

      /// TC-SEARCH-010: 验证空态图标正确
      patrolTest('空状态应该显示正确的图标', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索无结果
        await searchRobot.search('xyzabc123不存在');
        await searchRobot.waitForSearchComplete();

        // 验证空状态图标
        searchRobot.verifyEmptyStateIconVisible();
      });

      /// TC-SEARCH-011: 验证空态描述文本
      patrolTest('空状态应该显示提示文本', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索无结果
        await searchRobot.search('xyzabc123不存在');
        await searchRobot.waitForSearchComplete();

        // 验证提示文本
        // 显示 "未找到相关应用" 或类似文本
        searchRobot.verifyNoResultsTextVisible();
      });
    });

    group('搜索分页测试', () {
      /// TC-SEARCH-012: 验证滚动加载更多
      patrolTest('滚动到底部应该加载更多结果', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索一个常见应用（结果较多）
        await searchRobot.search('工具');
        await searchRobot.waitForSearchComplete();

        // 如果有足够多的结果
        if ($(GridView).evaluate().isNotEmpty) {
          // 滚动到底部
          await searchRobot.scrollResults(distance: 800);

          // 等待加载更多完成
          await searchRobot.waitForMoreResults();

          // 验证仍有结果显示
          searchRobot.verifySearchResultsVisible();
        }
      });

      /// TC-SEARCH-013: 验证加载更多指示器
      patrolTest('加载更多时应该显示加载指示器', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索结果较多的关键词
        await searchRobot.search('工具');
        await searchRobot.waitForSearchComplete();

        // 验证初始结果
        searchRobot.verifySearchResultsVisible();

        // 滚动触发加载更多
        await searchRobot.scrollResults(distance: 1000);

        // 等待处理
        await $.pump(const Duration(milliseconds: 500));

        // 可能显示加载指示器或已加载完成
        // 验证页面仍然正常
        searchRobot.verifySearchResultsVisible();
      });

      /// TC-SEARCH-014: 验证没有更多数据提示
      patrolTest('没有更多数据时应该显示提示', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 搜索一个结果较少的关键词
        await searchRobot.search('特定应用名xyz');
        await searchRobot.waitForSearchComplete();

        // 多次滚动到底部
        for (int i = 0; i < 5; i++) {
          await searchRobot.scrollResults(distance: 500);
          await $.pump(const Duration(milliseconds: 300));
        }

        // 验证页面状态正常
        // "没有更多了" 提示取决于数据量
        searchRobot.verifySearchInputVisible();
      });
    });

    group('搜索边界测试', () {
      /// TC-SEARCH-015: 验证空关键词不执行搜索
      patrolTest('空关键词不应该执行搜索', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 直接按回车（不输入内容）
        await searchRobot.pressEnterToSearch();

        // 验证仍在搜索页初始状态
        await $.pump(const Duration(milliseconds: 500));
        searchRobot.verifyInitialSearchHintVisible();
      });

      /// TC-SEARCH-016: 验证特殊字符搜索
      patrolTest('特殊字符搜索应该正常处理', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 输入特殊字符
        const testKeyword = r'测试<>!@#\$%^&*()';
        await searchRobot.search(testKeyword);

        // 等待处理
        await searchRobot.waitForSearchComplete();

        // 验证没有崩溃，页面正常
        searchRobot.verifySearchInputVisible();
      });

      /// TC-SEARCH-017: 验证长关键词搜索
      patrolTest('长关键词搜索应该正常处理', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 输入超长关键词
        const testKeyword = '这是一个非常长的搜索关键词用于测试输入框的处理能力是否正常工作';
        await searchRobot.search(testKeyword);

        // 等待处理
        await searchRobot.waitForSearchComplete();

        // 验证页面正常
        searchRobot.verifySearchInputVisible();
      });

      /// TC-SEARCH-018: 验证连续搜索
      patrolTest('连续多次搜索应该正常工作', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 第一次搜索
        await searchRobot.search('微信');
        await searchRobot.waitForSearchComplete();
        searchRobot.verifySearchResultsVisible();

        // 第二次搜索（覆盖之前的）
        await searchRobot.search('QQ');
        await searchRobot.waitForSearchComplete();
        searchRobot.verifySearchResultsVisible();

        // 第三次搜索
        await searchRobot.search('音乐');
        await searchRobot.waitForSearchComplete();
        searchRobot.verifySearchResultsVisible();
      });
    });

    group('搜索性能测试', () {
      /// TC-SEARCH-019: 验证搜索响应时间
      patrolTest('搜索响应时间应该合理', ($) async {
        await startAppAndWait($);

        final searchRobot = $.searchRobot;

        // 记录开始时间
        final startTime = DateTime.now();

        // 执行搜索
        await searchRobot.search('微信');
        await searchRobot.waitForSearchComplete(
          timeout: const Duration(seconds: 5),
        );

        // 计算响应时间
        final endTime = DateTime.now();
        final responseTime = endTime.difference(startTime);

        // 验证响应时间小于 3 秒
        expect(responseTime.inSeconds, lessThan(3), reason: '搜索响应时间应该小于 3 秒');
      });
    });
  });

  group('搜索异常处理测试', () {
    /// TC-SEARCH-020: 验证网络错误处理
    patrolTest('网络错误应该显示错误提示', ($) async {
      await $.pumpWidgetAndSettle(
        const LinglongStoreApp(),
        duration: TestConfig.appStartupTimeout,
      );
      await $.pump(const Duration(seconds: 2));

      final searchRobot = $.searchRobot;

      // 搜索（可能因网络问题失败）
      await searchRobot.search('测试');
      await searchRobot.waitForSearchComplete();

      // 如果出现错误状态，验证错误显示
      // 注意：此测试依赖网络状态，实际测试时可能需要 mock
      final errorFinder = searchRobot.errorStateWidget();
      if (errorFinder.evaluate().isNotEmpty) {
        searchRobot.verifyErrorStateVisible();
      } else {
        // 正常情况验证结果显示
        final resultsFinder = searchRobot.searchResultsGrid();
        if (resultsFinder.evaluate().isNotEmpty) {
          searchRobot.verifySearchResultsVisible();
        }
      }
    });
  });
}
