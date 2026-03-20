/// 应用常量
class AppConstants {
  AppConstants._();

  /// 应用 ID
  static const String appId = 'org.linglongstore.linglong_store';

  /// 应用名称
  static const String appName = '玲珑应用商店社区版';

  /// 应用版本
  static const String appVersion = '3.0.2';

  /// 默认仓库
  static const String defaultRepo = 'repo';

  /// 支持的架构列表
  static const List<String> supportedArchs = ['x86_64', 'aarch64'];

  /// 最小窗口宽度
  static const double minWindowWidth = 600.0;

  /// 最小窗口高度
  static const double minWindowHeight = 400.0;

  /// 默认窗口宽度
  static const double defaultWindowWidth = 1200.0;

  /// 默认窗口高度
  static const double defaultWindowHeight = 800.0;

  /// 卡片最小宽度
  static const double minCardWidth = 288.0;

  /// 卡片高度
  static const double cardHeight = 120.0;

  /// 分页大小
  static const int pageSize = 20;

  /// 安装重试次数
  static const int installRetryCount = 3;
}