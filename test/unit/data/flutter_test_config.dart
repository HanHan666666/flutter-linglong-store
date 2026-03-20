import 'dart:async';

/// 数据层测试配置
///
/// 覆盖 test/ 根目录的 flutter_test_config.dart，
/// 不初始化 TestWidgetsFlutterBinding，原因：
///   1. 数据层单元测试（DTO、Repository、API 集成）不需要 Widget 绑定
///   2. TestWidgetsFlutterBinding 会拦截所有 HTTP 请求并返回 400，
///      导致真实 API 集成测试无法运行
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 不调用 TestWidgetsFlutterBinding.ensureInitialized()
  // 数据层测试只需要 Dart VM 运行时，不需要 Flutter 渲染引擎
  await testMain();
}
