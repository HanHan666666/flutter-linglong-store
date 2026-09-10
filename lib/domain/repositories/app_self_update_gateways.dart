/// 应用自更新访问网络、文件系统与系统包管理器的稳定边界。
///
/// Application 只依赖这些接口；Dio、XDG 路径、Shell 命令和文件替换均由
/// Data/Platform 实现，生产对象统一在 bootstrap 组合根创建。
library;

import '../models/app_self_update.dart';

/// 当前进程安装身份探测端口。
abstract interface class AppInstallationProbe {
  /// 判断当前进程实际来自 DEB、RPM、AppImage 或其它手动安装。
  Future<AppInstallation> detect();

  /// 判断当前运行 bundle 是否由系统包管理器（dpkg/rpm/pacman）安装。
  ///
  /// docs/51：这是特权 helper 的唯一信任条件——只有包管理器安装树（root
  /// 属主）内的 helper 才能证明"同 UID 进程不可替换"。任一包管理器证明当前
  /// 可执行文件归属即返回 true；无法证明（含命令缺失、超时等探测失败）一律
  /// 返回 false，调用方必须回退普通用户直连路径，不得失败开放。
  Future<bool> isManagedBySystemPackageManager();
}

/// 单次更新的 XDG 下载工作区。
abstract interface class AppUpdateWorkspace {
  /// 下载资产并返回工作区内的完整文件路径。
  Future<String> download({
    required String url,
    required String fileName,
    required void Function(int received, int total) onProgress,
    Future<void>? cancellationSignal,
  });

  /// 流式计算工作区文件 SHA-256。
  Future<String> computeSha256(String filePath);

  /// 读取工作区内的小型 UTF-8 文本；仅用于 `hashes.sha256`。
  Future<String> readText(String filePath);

  /// 删除本次更新的全部临时文件。
  Future<void> dispose();
}

/// XDG 更新工作区工厂。
abstract interface class AppUpdateWorkspaceFactory {
  /// 为一次更新创建隔离工作区。
  Future<AppUpdateWorkspace> create();
}

/// 单一安装方式适配器。
abstract interface class AppUpdateInstaller {
  /// 该适配器处理的当前安装身份。
  AppInstallationKind get installationKind;

  /// 安装已经完成 SHA256 校验的本地资产。
  Future<void> install({
    required AppInstallation installation,
    required String packagePath,
  });
}
