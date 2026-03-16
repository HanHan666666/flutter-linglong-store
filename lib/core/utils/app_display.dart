/// 应用名称/描述展示规则
class AppDisplay {
  AppDisplay._();

  /// 获取显示名称
  /// 优先使用本地化名称，否则使用默认名称
  static String getDisplayName({
    required String? localizedName,
    required String? defaultName,
  }) {
    return localizedName ?? defaultName ?? '未知应用';
  }

  /// 获取显示描述
  /// 截断过长的描述
  static String getDisplayDescription({
    required String? description,
    int maxLength = 100,
  }) {
    if (description == null || description.isEmpty) {
      return '暂无描述';
    }

    if (description.length <= maxLength) {
      return description;
    }

    return '${description.substring(0, maxLength)}...';
  }

  /// 获取图标 URL
  /// 处理空图标情况
  static String getIconUrl(String? icon) {
    if (icon == null || icon.isEmpty) {
      return 'assets/icons/linyaps.svg';
    }
    return icon;
  }
}