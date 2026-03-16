/// Patrol 集成测试基础 Robot 类
///
/// 使用 patrol 提供 UI 元素查找和交互的通用方法。
/// Robot Pattern 将测试逻辑与 UI 操作分离，提高测试代码的可维护性。
///
/// 参考：
/// - https://patrol.leancode.co/basics/robot-pattern-testing
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' show PatrolTester;

/// 基础 Robot 类
///
/// 提供通用的 Finder 方法和交互操作，所有页面 Robot 都应继承此类。
/// 适用于 Linux 桌面端应用测试。
abstract class BaseRobot {
  /// 构造函数
  BaseRobot(this.$);

  /// Patrol Finder 上下文
  ///
  /// 用于查找和交互 UI 元素
  final PatrolTester $;

  /// 查找文本 widget
  ///
  /// [text] - 要查找的文本内容
  /// [skipOffstage] - 是否跳过舞台外的 widget，默认为 true
  PatrolFinder text(String text, {bool skipOffstage = true}) {
    return $(find.text(text, skipOffstage: skipOffstage, findRichText: true));
  }

  /// 查找包含文本的 widget
  ///
  /// [text] - 要包含的文本内容
  PatrolFinder textContaining(String text) {
    return $(find.textContaining(text, findRichText: true));
  }

  /// 查找 RichText 中包含指定文本的 widget
  ///
  /// [text] - 要包含的文本内容
  PatrolFinder richTextContaining(String text) {
    return $(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      ),
    );
  }

  /// 查找图标 widget
  ///
  /// [icon] - 要查找的 IconData
  PatrolFinder iconWidget(IconData icon) {
    return $(icon);
  }

  /// 查找指定类型的 widget
  ///
  /// [type] - Widget 类型
  PatrolFinder widget(Type type) {
    return $(type);
  }

  /// 查找指定 Key 的 widget
  ///
  /// [key] - ValueKey 或 GlobalKey
  PatrolFinder byKey(Key key) {
    return $(key);
  }

  /// 查找 TextField widget
  ///
  /// [hintText] - 可选的提示文本
  PatrolFinder textFieldWidget({String? hintText}) {
    if (hintText != null) {
      return $(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText == hintText,
        ),
      );
    }
    return $(TextField);
  }

  /// 查找 ElevatedButton widget
  ///
  /// [text] - 可选的按钮文本
  PatrolFinder elevatedButtonWidget({String? text}) {
    if (text != null) {
      return $(find.widgetWithText(ElevatedButton, text));
    }
    return $(ElevatedButton);
  }

  /// 查找 FilledButton widget
  ///
  /// [text] - 可选的按钮文本
  PatrolFinder filledButtonWidget({String? text}) {
    if (text != null) {
      return $(find.widgetWithText(FilledButton, text));
    }
    return $(FilledButton);
  }

  /// 查找 OutlinedButton widget
  ///
  /// [text] - 可选的按钮文本
  PatrolFinder outlinedButtonWidget({String? text}) {
    if (text != null) {
      return $(find.widgetWithText(OutlinedButton, text));
    }
    return $(OutlinedButton);
  }

  /// 查找 TextButton widget
  ///
  /// [text] - 可选的按钮文本
  PatrolFinder textButtonWidget({String? text}) {
    if (text != null) {
      return $(find.widgetWithText(TextButton, text));
    }
    return $(TextButton);
  }

  /// 查找 IconButton widget
  ///
  /// [icon] - 可选的图标
  /// [tooltip] - 可选的提示文本
  PatrolFinder iconButtonWidget({IconData? icon, String? tooltip}) {
    if (icon != null) {
      return $(find.widgetWithIcon(IconButton, icon));
    }
    if (tooltip != null) {
      return $(find.byTooltip(tooltip));
    }
    return $(IconButton);
  }

  /// 查找 ListView widget
  PatrolFinder listViewWidget() {
    return $(ListView);
  }

  /// 查找 GridView widget
  PatrolFinder gridViewWidget() {
    return $(GridView);
  }

  /// 查找 Card widget
  PatrolFinder cardWidget() {
    return $(Card);
  }

  /// 查找 Checkbox widget
  PatrolFinder checkboxWidget() {
    return $(Checkbox);
  }

  /// 查找 Switch widget
  PatrolFinder switchWidget() {
    return $(Switch);
  }

  /// 查找 CircularProgressIndicator widget
  PatrolFinder circularProgressIndicatorWidget() {
    return $(CircularProgressIndicator);
  }

  /// 查找 LinearProgressIndicator widget
  PatrolFinder linearProgressIndicatorWidget() {
    return $(LinearProgressIndicator);
  }

  /// 查找 Scaffold widget
  PatrolFinder scaffoldWidget() {
    return $(Scaffold);
  }

  /// 查找 AppBar widget
  PatrolFinder appBarWidget() {
    return $(AppBar);
  }

  /// 查找 BottomNavigationBar widget
  PatrolFinder bottomNavigationBarWidget() {
    return $(BottomNavigationBar);
  }

  /// 查找 NavigationRail widget（适用于桌面端侧边导航）
  PatrolFinder navigationRailWidget() {
    return $(NavigationRail);
  }

  /// 查找 NavigationBar widget
  PatrolFinder navigationBarWidget() {
    return $(NavigationBar);
  }

  /// 等待 widget 出现
  ///
  /// [finder] - 要等待的 finder
  /// [timeout] - 超时时间，默认 10 秒
  Future<void> waitFor(
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await finder.waitUntilVisible(timeout: timeout);
  }

  /// 等待 widget 消失
  ///
  /// [finder] - 要等待消失的 finder
  /// [timeout] - 超时时间，默认 10 秒
  Future<void> waitUntilGone(
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (finder.evaluate().isEmpty) {
        return;
      }
      await $.pump(const Duration(milliseconds: 100));
    }

    throw FlutterError('Finder did not disappear within $timeout: $finder');
  }

  /// 等待加载指示器消失
  ///
  /// [timeout] - 超时时间，默认 30 秒
  Future<void> waitForLoadingToFinish({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    await waitUntilGone(circularProgressIndicatorWidget(), timeout: timeout);
  }

  /// 点击 widget
  ///
  /// [finder] - 要点击的 finder
  Future<void> tap(PatrolFinder finder) async {
    await finder.tap();
  }

  /// 点击文本
  ///
  /// [text] - 要点击的文本
  Future<void> tapText(String text) async {
    await $(text).tap();
  }

  /// 点击按钮
  ///
  /// [text] - 按钮文本
  Future<void> tapButton(String text) async {
    await $(text).tap();
  }

  /// 在文本框中输入文本
  ///
  /// [finder] - TextField finder
  /// [text] - 要输入的文本
  /// [clearFirst] - 是否先清空，默认为 true
  Future<void> enterText(
    PatrolFinder finder,
    String text, {
    bool clearFirst = true,
  }) async {
    await finder.enterText(text);
  }

  /// 滚动直到可见
  ///
  /// [finder] - 目标 finder
  /// [scrollable] - 可滚动的容器 finder，默认为 ListView
  Future<void> scrollUntilVisible(
    PatrolFinder finder, {
    PatrolFinder? scrollable,
  }) async {
    await $.scrollUntilVisible(
      finder: finder,
      view: scrollable ?? listViewWidget(),
    );
  }

  /// 向下滚动
  ///
  /// [scrollable] - 可滚动的容器 finder
  /// [distance] - 滚动距离
  Future<void> scrollDown({
    PatrolFinder? scrollable,
    double distance = 500,
  }) async {
    await $.tester.drag(scrollable ?? listViewWidget(), Offset(0, -distance));
    await $.pumpAndSettle();
  }

  /// 向上滚动
  ///
  /// [scrollable] - 可滚动的容器 finder
  /// [distance] - 滚动距离
  Future<void> scrollUp({
    PatrolFinder? scrollable,
    double distance = 500,
  }) async {
    await $.tester.drag(scrollable ?? listViewWidget(), Offset(0, distance));
    await $.pumpAndSettle();
  }

  /// 验证 widget 存在
  ///
  /// [finder] - 要验证的 finder
  void verifyExists(PatrolFinder finder) {
    expect(finder, findsOneWidget);
  }

  /// 验证 widget 不存在
  ///
  /// [finder] - 要验证的 finder
  void verifyNotExists(PatrolFinder finder) {
    expect(finder, findsNothing);
  }

  /// 验证文本存在
  ///
  /// [text] - 要验证的文本
  void verifyTextExists(String text) {
    expect(this.text(text), findsOneWidget);
  }

  /// 验证文本不存在
  ///
  /// [text] - 要验证的文本
  void verifyTextNotExists(String text) {
    expect(this.text(text), findsNothing);
  }

  /// 验证 widget 数量
  ///
  /// [finder] - 要验证的 finder
  /// [count] - 期望的数量
  void verifyCount(PatrolFinder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// 截图
  ///
  /// [name] - 截图名称
  /// [subfolder] - 可选的子文件夹
  Future<void> takeScreenshot(String name, {String? subfolder}) async {
    // Patrol 原生截图功能通过 patrol CLI 提供
    // 这里预留接口，后续可通过 native 自动化扩展
    await $.pump(const Duration(milliseconds: 100));
  }

  /// 等待指定时间
  ///
  /// [duration] - 等待时间
  Future<void> wait(Duration duration) async {
    await $.pump(duration);
  }

  /// 等待动画完成
  ///
  /// [timeout] - 超时时间
  Future<void> waitForAnimations({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await $.pumpAndSettle(timeout: timeout);
  }
}
