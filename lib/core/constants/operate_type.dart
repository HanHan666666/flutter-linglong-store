/// 操作类型枚举
enum OperateType {
  /// 安装
  install('install'),

  /// 卸载
  uninstall('uninstall'),

  /// 更新
  update('update'),

  /// 运行
  run('run'),

  /// 停止
  stop('stop');

  const OperateType(this.value);

  final String value;

  /// 从字符串解析
  static OperateType? fromString(String value) {
    return switch (value.toLowerCase()) {
      'install' => OperateType.install,
      'uninstall' => OperateType.uninstall,
      'update' => OperateType.update,
      'run' => OperateType.run,
      'stop' => OperateType.stop,
      _ => null,
    };
  }
}