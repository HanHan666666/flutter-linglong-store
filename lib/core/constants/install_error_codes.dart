/// 安装错误码定义
class InstallErrorCodes {
  InstallErrorCodes._();

  /// 成功
  static const int success = 0;

  /// 网络错误
  static const int networkError = 1;

  /// 依赖错误
  static const int dependencyError = 2;

  /// 权限错误
  static const int permissionError = 3;

  /// 磁盘空间不足
  static const int diskSpaceError = 4;

  /// 包损坏
  static const int packageCorrupted = 5;

  /// 版本冲突
  static const int versionConflict = 6;

  /// 未知错误
  static const int unknownError = 999;

  /// 获取错误消息
  static String getMessage(int code) {
    return switch (code) {
      success => '成功',
      networkError => '网络连接失败',
      dependencyError => '依赖关系错误',
      permissionError => '权限不足',
      diskSpaceError => '磁盘空间不足',
      packageCorrupted => '安装包损坏',
      versionConflict => '版本冲突',
      unknownError => '未知错误',
      _ => '错误码：$code',
    };
  }
}