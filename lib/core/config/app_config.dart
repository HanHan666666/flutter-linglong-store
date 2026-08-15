/// 应用配置
class AppConfig {
  AppConfig._();

  /// 商店 API 基础地址。
  ///
  /// 正式域名作为可分发构建和真实 API 测试的安全默认值；本地联调必须通过
  /// `--dart-define=API_BASE_URL=...` 显式覆盖，禁止提交私有网络地址。
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://storeapi.linyaps.org.cn',
  );

  /// 应用版本
  static const String appVersion = '3.5.0';

  /// 默认语言
  static const String defaultLocale = 'zh';

  /// 商店 API 默认仓库
  ///
  /// 当前后端列表类接口在未显式传递仓库时会落到 `repo`，
  /// 但线上/现有数据实际集中在 `stable`。
  static const String defaultStoreRepoName = 'stable';

  /// 缓存过期时间（分钟）
  static const int cacheExpirationMinutes = 5;

  /// 缓存 box 逻辑条目数上限
  ///
  /// 应用详情缓存按 应用×版本×语言 组合膨胀，长期运行若无上限会单调增长。
  /// 超限后优先淘汰已过期与带 TTL 的可再生条目，永久条目（推荐页快照）不受影响。
  static const int cacheMaxLogicalEntries = 300;

  /// 列表页内存条目数上限
  ///
  /// 推荐页/全部应用/搜索/分类页都是 IndexedStack 常驻页面，loadMore 若无上限，
  /// 深度翻页后多份全量列表会同时驻留内存。触顶后置 hasMore=false 终止自动补页；
  /// 更深的应用检索应走搜索/分类过滤，而不是无限滚动。
  static const int maxListItems = 300;

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

  /// 玲珑社区发帖入口。
  ///
  /// 无匹配解决方案时与设置页共用该地址，避免多个页面维护不同的社区入口。
  static const String communityForumUrl =
      'https://bbs.deepin.org.cn/module/detail/230';
}
