/// 安装按钮状态枚举
///
/// 描述应用在卡片或详情页上安装/更新/打开按钮的展示态。
enum InstallButtonState {
  /// 未安装
  notInstalled,

  /// 安装中
  installing,

  /// 等待安装（排队中）
  pending,

  /// 已安装
  installed,

  /// 需要更新
  update,

  /// 打开应用
  open,

  /// 卸载
  uninstall,
}
