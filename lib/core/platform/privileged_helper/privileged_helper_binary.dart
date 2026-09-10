/// 特权 helper 的统一定位入口：bundle 内固定路径解析（docs/51）。
///
/// docs/51 起 helper 只服务"当前 bundle 由系统包管理器安装"的形态，路径必然
/// 位于 root 属主的安装树内；原 FUSE 检测与一次性暂存副本机制已随信任边界
/// 收敛删除——暂存会把 helper 复制到当前用户可写目录后再让 pkexec 以 root
/// 执行，属于要消除的提权路径，保留会造成"探测漏判时漏洞路径静默复活"。
///
/// 所有运行形态都必须经由本类取得 pkexec 要执行的 helper 路径；路径以
/// `Platform.resolvedExecutable` 所在 bundle 为唯一基准，不接受环境变量或
/// 调用方指定其他路径（docs/47 §5.2 第 1 步的定位基准不变）。
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'privileged_helper_exception.dart';

/// bundle 内 helper 的固定相对位置（相对 `Platform.resolvedExecutable`）。
const String _helperRelativePath = 'libexec/linglong_store_helper';

/// 所有运行形态唯一的 helper 定位入口。
class PrivilegedHelperBinary {
  /// 创建定位器。
  ///
  /// [bundleHelperPathOverride] 为测试注入点：默认以
  /// `Platform.resolvedExecutable` 所在 bundle 为唯一基准；生产代码不需要
  /// 显式传参。
  PrivilegedHelperBinary({String? bundleHelperPathOverride})
    : _bundleHelperPathOverride = bundleHelperPathOverride;

  final String? _bundleHelperPathOverride;

  /// 解析本次启动要执行的 helper 绝对路径。
  ///
  /// 抛出 [PrivilegedHelperUnavailableException]：bundle 内 helper 缺失。
  /// 统一按 docs/47 §10.3"授权组件不可用"处理。
  String prepare() {
    final bundlePath = _bundleHelperPathOverride ?? _defaultBundleHelperPath();
    if (!File(bundlePath).existsSync()) {
      throw PrivilegedHelperUnavailableException(
        'privileged helper binary not found: $bundlePath',
      );
    }
    return bundlePath;
  }

  /// bundle 内 helper 的默认绝对路径：以 `Platform.resolvedExecutable` 所在
  /// bundle 为唯一基准，不接受环境变量或调用方指定其他路径（docs/47 §5.2）。
  String _defaultBundleHelperPath() {
    return p.join(
      p.dirname(Platform.resolvedExecutable),
      _helperRelativePath,
    );
  }
}
