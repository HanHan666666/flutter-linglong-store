/// 当有正在进行的安装/更新任务时，点击卸载按钮所展示的拦截弹窗结果枚举
enum UninstallBlockedAction {
  /// 用户点击「我知道了」，关闭弹窗，不做额外操作
  acknowledge,

  /// 用户点击「查看下载管理」，关闭弹窗后跳转到下载管理
  openDownloadManager,
}
