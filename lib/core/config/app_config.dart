/// 应用配置
class AppConfig {
  AppConfig._();

  /// API 基础地址
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://storeapi.linyaps.org.cn',
  );

  /// 应用名称
  static const String appName = '玲珑应用商店社区版';

  /// 应用版本
  static const String appVersion = '3.2.0';

  /// 默认语言
  static const String defaultLocale = 'zh';

  /// 商店 API 默认仓库
  ///
  /// 当前后端列表类接口在未显式传递仓库时会落到 `repo`，
  /// 但线上/现有数据实际集中在 `stable`。
  static const String defaultStoreRepoName = 'stable';

  /// 缓存过期时间（分钟）
  static const int cacheExpirationMinutes = 5;

  /// 最大保活页面数
  static const int maxKeepAlivePages = 10;

  /// 默认超时时间（秒）
  static const int defaultTimeoutSeconds = 30;

  /// 图片缓存大小（字节）
  static const int imageCacheSizeBytes = 64 * 1024 * 1024; // 64MB

  /// 安装文档 URL
  /// 可通过编译时环境变量覆盖：-DINSTALL_DOC_URL=https://...
  static const String installDocUrl = String.fromEnvironment(
    'INSTALL_DOC_URL',
    defaultValue: 'https://linyaps.org.cn/guide/start/install.html',
  );
}
