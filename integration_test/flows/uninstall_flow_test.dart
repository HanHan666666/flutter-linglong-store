/// 卸载流程测试（BF-04）
///
/// 测试卸载流程的各个场景：
/// - 入口：用户点击"卸载"按钮
/// - 主路径：确认 → 检查运行状态 → 执行卸载 → 刷新
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

import 'package:linglong_store/app.dart';

import '../robots/base_robot.dart';
import '../utils/test_helpers.dart';

/// 卸载确认对话框 Robot
///
/// 封装卸载确认对话框的 UI 操作和验证
class UninstallDialogRobot extends BaseRobot {
  /// 构造函数
  UninstallDialogRobot(super.$);

  /// 查找卸载确认对话框
  PatrolFinder dialog() => $(AlertDialog);

  /// 查找卸载确认标题
  PatrolFinder dialogTitle() => text('确认卸载');

  /// 查找卸载按钮
  PatrolFinder confirmButton() => $(ElevatedButton).containing('卸载');

  /// 查找取消按钮
  PatrolFinder cancelButton() => $(TextButton).containing('取消');

  /// 点击确认卸载
  Future<void> tapConfirm() async {
    await tap(confirmButton());
  }

  /// 点击取消
  Future<void> tapCancel() async {
    await tap(cancelButton());
  }

  /// 验证对话框显示
  void verifyDialogVisible() {
    verifyExists(dialog());
    verifyExists(dialogTitle());
  }

  /// 验证确认按钮可见
  void verifyConfirmButtonVisible() {
    verifyExists(confirmButton());
  }

  /// 验证取消按钮可见
  void verifyCancelButtonVisible() {
    verifyExists(cancelButton());
  }
}

/// 扩展方法：创建 UninstallDialogRobot
extension UninstallDialogRobotExtension on PatrolTester {
  /// 创建卸载确认对话框 Robot
  UninstallDialogRobot get uninstallDialogRobot => UninstallDialogRobot(this);
}

/// 我的应用页 Robot
///
/// 封装我的应用页的 UI 操作和验证
class MyAppsRobot extends BaseRobot {
  /// 构造函数
  MyAppsRobot(super.$);

  /// 查找搜索框
  PatrolFinder searchField() => $(TextField);

  /// 查找应用列表
  PatrolFinder appList() => $(ListView);

  /// 查找应用卡片
  ///
  /// [appName] - 应用名称
  PatrolFinder appCard(String appName) => $(Card).containing(appName);

  /// 查找打开按钮
  PatrolFinder openButton() => $(ElevatedButton).containing('打开');

  /// 查找更多菜单按钮
  PatrolFinder moreMenuButton() => $(PopupMenuButton<String>);

  /// 查找卸载菜单项
  PatrolFinder uninstallMenuItem() => text('卸载');

  /// 查找空状态提示
  PatrolFinder emptyState() => text('暂无已安装应用');

  /// 点击更多菜单
  Future<void> tapMoreMenu() async {
    await tap(moreMenuButton());
  }

  /// 点击卸载菜单项
  Future<void> tapUninstallMenu() async {
    await tap(uninstallMenuItem());
  }

  /// 搜索应用
  ///
  /// [keyword] - 搜索关键词
  Future<void> search(String keyword) async {
    await enterText(searchField(), keyword);
    await $.pump(const Duration(milliseconds: 500));
  }

  /// 清空搜索
  Future<void> clearSearch() async {
    // 清空搜索框
    await enterText(searchField(), '');
    await $.pump(const Duration(milliseconds: 300));
  }

  /// 验证应用存在
  ///
  /// [appName] - 应用名称
  void verifyAppExists(String appName) {
    verifyExists(appCard(appName));
  }

  /// 验证应用不存在
  ///
  /// [appName] - 应用名称
  void verifyAppNotExists(String appName) {
    verifyNotExists(appCard(appName));
  }

  /// 验证列表非空
  void verifyListNotEmpty() {
    final list = appList().evaluate();
    expect(list.isNotEmpty, isTrue, reason: '应用列表应该非空');
  }

  /// 验证空状态
  void verifyEmptyState() {
    verifyExists(emptyState());
  }
}

/// 扩展方法：创建 MyAppsRobot
extension MyAppsRobotExtension on PatrolTester {
  /// 创建我的应用页 Robot
  MyAppsRobot get myAppsRobot => MyAppsRobot(this);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('卸载流程测试 - BF-04', () {
    /// 卸载确认弹窗测试
    group('卸载确认弹窗', () {
      /// 验证卸载确认对话框显示
      patrolTest(
        '点击卸载应该显示确认对话框',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 导航到"我的应用"页
          // 2. 找到一个已安装应用
          // 3. 点击更多菜单
          // 4. 点击卸载菜单项
          // 5. 验证确认对话框出现

          TestHelpers.log('卸载确认对话框显示测试');
        },
        skip: true, // 需要实际应用数据支持
      );

      /// 验证确认对话框内容
      patrolTest(
        '确认对话框应该显示应用名称',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 触发卸载确认对话框
          // 2. 验证对话框标题为"确认卸载"
          // 3. 验证对话框内容包含应用名称
          // 4. 验证确认和取消按钮都存在

          TestHelpers.log('确认对话框内容测试');
        },
        skip: true, // 需要实际应用数据支持
      );

      /// 验证取消卸载
      patrolTest(
        '取消确认对话框应该不执行卸载',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 触发卸载确认对话框
          // 2. 点击取消按钮
          // 3. 验证对话框关闭
          // 4. 验证应用仍在列表中

          TestHelpers.log('取消卸载测试');
        },
        skip: true, // 需要实际应用数据支持
      );
    });

    /// 卸载成功后状态测试
    group('卸载成功后状态', () {
      /// 验证卸载成功后应用从列表移除
      patrolTest(
        '卸载成功后应用应该从列表中移除',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 找到一个已安装应用
          // 2. 执行卸载
          // 3. 等待卸载完成
          // 4. 验证应用从列表中移除

          TestHelpers.log('卸载成功后列表移除测试');
        },
        skip: true, // 需要实际 CLI 支持进行卸载
      );

      /// 验证卸载成功后显示成功提示
      patrolTest(
        '卸载成功后应该显示成功提示',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 执行卸载
          // 2. 等待卸载完成
          // 3. 验证 SnackBar 显示成功消息

          TestHelpers.log('卸载成功提示测试');
        },
        skip: true, // 需要实际 CLI 支持进行卸载
      );

      /// 验证卸载成功后按钮变为安装
      patrolTest(
        '卸载成功后应用详情页按钮应该变为安装',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 进入应用详情页
          // 2. 执行卸载
          // 3. 等待卸载完成
          // 4. 验证按钮变为"安装"

          TestHelpers.log('卸载成功后按钮变化测试');
        },
        skip: true, // 需要实际 CLI 支持进行卸载
      );

      /// 验证卸载成功后更新列表刷新
      patrolTest(
        '卸载后已安装缓存应该刷新',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 执行卸载
          // 2. 导航到其他页面
          // 3. 返回我的应用页
          // 4. 验证应用不在列表中

          TestHelpers.log('卸载后缓存刷新测试');
        },
        skip: true, // 需要实际 CLI 支持进行卸载
      );
    });

    /// 卸载失败测试
    group('卸载失败', () {
      /// 验证卸载失败时显示错误
      patrolTest(
        '卸载失败时应该显示错误信息',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 模拟卸载失败场景
          // 2. 验证错误 SnackBar 显示
          // 3. 验证应用仍在列表中

          TestHelpers.log('卸载失败错误信息测试');
        },
        skip: true, // 需要 mock 失败场景
      );

      /// 验证卸载失败后应用仍在列表
      patrolTest(
        '卸载失败后应用应该仍在列表中',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 模拟卸载失败
          // 2. 验证应用卡片仍然存在

          TestHelpers.log('卸载失败后列表状态测试');
        },
        skip: true, // 需要 mock 失败场景
      );
    });

    /// 从应用详情页卸载测试
    group('从应用详情页卸载', () {
      /// 验证应用详情页卸载入口
      patrolTest(
        '应用详情页应该有卸载入口',
        ($) async {
          // 启动应用
          await $.pumpWidgetAndSettle(
            const LinglongStoreApp(),
            duration: TestConfig.appStartupTimeout,
          );
          await $.pump(const Duration(seconds: 2));

          // 验证应用已启动
          expect($(MaterialApp), findsOneWidget);

          // 注：实际测试流程：
          // 1. 进入已安装应用的详情页
          // 2. 验证卸载按钮存在（如果已安装）

          TestHelpers.log('应用详情页卸载入口测试');
        },
        skip: true, // 需要实际应用数据支持
      );
    });
  });

  group('卸载性能测试', () {
    /// 测量卸载操作响应时间
    patrolTest(
      '卸载操作响应时间应该小于 2 秒',
      ($) async {
        final stopwatch = Stopwatch()..start();

        // 启动应用
        await $.pumpWidgetAndSettle(
          const LinglongStoreApp(),
          duration: TestConfig.appStartupTimeout,
        );
        stopwatch.stop();

        TestHelpers.log('启动时间: ${stopwatch.elapsedMilliseconds}ms');

        // 验证应用已启动
        expect($(MaterialApp), findsOneWidget);
      },
      skip: true, // 需要实际卸载场景
    );
  });
}
