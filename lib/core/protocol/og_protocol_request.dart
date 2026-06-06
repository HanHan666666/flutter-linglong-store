/// 旧版网页版商店 og 协议安装请求。
///
/// 该文件只承载 `og://appId` 的解析规则，避免把网页入口的兼容逻辑
/// 扩散到安装队列、路由或平台单实例模块中。当前项目仅继续兼容旧协议，
/// 不在这里引入新的 scheme 或额外查询参数语义。
class OgProtocolRequest {
  const OgProtocolRequest._({
    required this.rawUrl,
    required this.appId,
  });

  /// 浏览器或桌面环境传入的原始 og 链接。
  ///
  /// 保留原文便于日志诊断；实际安装只使用解析出的 [appId]，避免旧网页
  /// 未来附带的 query 参数意外改变客户端行为。
  final String rawUrl;

  /// 旧协议中唯一可信的应用身份。
  ///
  /// 该值会传给应用详情接口，再复用现有安装队列入队流程，不直接拼接
  /// `ll-cli` 命令，保证安装逻辑仍由应用商店统一入口控制。
  final String appId;

  /// 尝试从原始字符串解析旧 `og://appId` 请求。
  ///
  /// Linux 各桌面环境可能把自定义 scheme 传为 `og://appId`，少数启动器
  /// 会保留为 `og:///appId`。两种形式都归一成同一个 [appId]；非 `og`
  /// scheme、空应用 ID 或 URI 解析失败时返回 `null`，由上层展示兜底提示。
  static OgProtocolRequest? tryParse(String rawUrl) {
    final normalizedRawUrl = rawUrl.trim();
    if (normalizedRawUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(normalizedRawUrl);
    if (uri == null || uri.scheme.toLowerCase() != 'og') {
      return null;
    }

    final appId = _appIdFromRawUrl(normalizedRawUrl, uri);

    if (appId.isEmpty) {
      return null;
    }

    return OgProtocolRequest._(
      rawUrl: normalizedRawUrl,
      appId: appId,
    );
  }

  /// 从原始 URL 中提取应用 ID。
  ///
  /// Dart 的 [Uri.host] 会按 URI 规范把 host 归一为小写，但玲珑旧协议把
  /// `og://appId` 的 authority 当作业务 ID 承载。这里使用 [Uri] 做 scheme
  /// 校验，再从原文中取 authority，避免客户端擅自改写旧网页传来的 appId。
  static String _appIdFromRawUrl(String rawUrl, Uri uri) {
    final schemeSeparatorIndex = rawUrl.indexOf('://');
    if (schemeSeparatorIndex < 0) {
      return _pathAppId(uri);
    }

    final afterScheme = rawUrl.substring(schemeSeparatorIndex + 3);
    if (!afterScheme.startsWith('/')) {
      final authorityEndIndex = _firstDelimiterIndex(afterScheme);
      final authority = authorityEndIndex < 0
          ? afterScheme
          : afterScheme.substring(0, authorityEndIndex);

      if (authority.trim().isNotEmpty) {
        return Uri.decodeComponent(authority).trim();
      }
    }

    return _pathAppId(uri);
  }

  /// 查找 authority 结束位置。
  ///
  /// 旧协议只有 appId，没有 query 业务语义；遇到路径、查询或片段时都应停止
  /// 读取 authority，保证 `og://appId?x=1` 仍只解析出 `appId`。
  static int _firstDelimiterIndex(String value) {
    final delimiterIndexes = <int>[
      value.indexOf('/'),
      value.indexOf('?'),
      value.indexOf('#'),
    ].where((index) => index >= 0).toList();

    if (delimiterIndexes.isEmpty) {
      return -1;
    }

    delimiterIndexes.sort();
    return delimiterIndexes.first;
  }

  /// 从 `og:///appId` 这类路径形式中提取应用 ID。
  ///
  /// 使用 pathSegments 可以避免手动处理多个斜杠与百分号转义，减少不同
  /// 桌面启动器传参差异带来的解析歧义。
  static String _pathAppId(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return '';
    }

    return uri.pathSegments.join('/').trim();
  }
}
