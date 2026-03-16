import 'dart:io';

import '../logging/app_logger.dart';

/// NVIDIA 驱动兼容性处理器
///
/// 检测 NVIDIA 驱动并提供兼容性解决方案：
/// - DMABUF 导出问题
/// - WebKit/Wayland 兼容性
/// - 环境变量设置
class NvidiaWorkaround {
  NvidiaWorkaround._();

  /// 是否已初始化
  static bool _initialized = false;

  /// 是否检测到 NVIDIA 显卡
  static bool _isNvidia = false;

  /// NVIDIA 驱动版本
  static String? _driverVersion;

  /// 是否需要应用 workaround
  static bool _needsWorkaround = false;

  /// 已应用的 workaround 列表
  static final Set<String> _appliedWorkarounds = {};

  /// 是否检测到 NVIDIA 显卡
  static bool get isNvidia => _isNvidia;

  /// NVIDIA 驱动版本
  static String? get driverVersion => _driverVersion;

  /// 是否需要应用 workaround
  static bool get needsWorkaround => _needsWorkaround;

  /// 已应用的 workaround 列表
  static Set<String> get appliedWorkarounds => Set.unmodifiable(_appliedWorkarounds);

  /// 初始化 NVIDIA 检测
  ///
  /// 应在应用启动时调用
  static Future<void> init() async {
    if (_initialized) return;

    AppLogger.info('[NVIDIA] 开始检测 NVIDIA 显卡...');

    // 检测 NVIDIA 显卡
    _isNvidia = await _detectNvidiaGpu();

    if (_isNvidia) {
      AppLogger.info('[NVIDIA] 检测到 NVIDIA 显卡');

      // 获取驱动版本
      _driverVersion = await _getDriverVersion();
      AppLogger.info('[NVIDIA] 驱动版本: ${_driverVersion ?? "未知"}');

      // 检查是否需要 workaround
      _needsWorkaround = await _checkNeedsWorkaround();

      if (_needsWorkaround) {
        AppLogger.warning('[NVIDIA] 需要应用兼容性 workaround');
      }
    } else {
      AppLogger.info('[NVIDIA] 未检测到 NVIDIA 显卡');
    }

    _initialized = true;
  }

  /// 应用所有必要的 workaround
  ///
  /// [workarounds] 指定要应用的 workaround，默认应用所有
  static Future<void> apply([Set<NvidiaWorkaroundType>? workarounds]) async {
    if (!_initialized) {
      await init();
    }

    if (!_needsWorkaround) {
      AppLogger.info('[NVIDIA] 不需要应用 workaround');
      return;
    }

    final toApply = workarounds ?? NvidiaWorkaroundType.values.toSet();

    for (final type in toApply) {
      await _applyWorkaround(type);
    }

    AppLogger.info('[NVIDIA] 已应用 workaround: $_appliedWorkarounds');
  }

  /// 获取需要设置的环境变量
  ///
  /// 返回用于进程启动的环境变量映射
  static Map<String, String> getEnvVars() {
    if (!_initialized || !_needsWorkaround) {
      return {};
    }

    final env = <String, String>{};

    // WebKit/WebKitGTK DMABUF workaround
    if (_appliedWorkarounds.contains('webkit_dmabuf')) {
      env['WEBKIT_DISABLE_COMPOSITING_MODE'] = '1';
      env['WEBKIT_DISABLE_DMABUF_RENDERER'] = '1';
    }

    // NVIDIA 特定环境变量
    if (_appliedWorkarounds.contains('nvidia_env')) {
      env['__GLX_VENDOR_LIBRARY_NAME'] = 'nvidia';
      env['GBM_BACKEND'] = 'nvidia-drm';
    }

    // Wayland 兼容性
    if (_appliedWorkarounds.contains('wayland_compat')) {
      env['QT_QPA_PLATFORM'] = 'wayland;xcb';
      env['GDK_BACKEND'] = 'wayland,x11';
      env['CLUTTER_BACKEND'] = 'wayland';
    }

    return env;
  }

  /// 检测是否是 NVIDIA 显卡
  static Future<bool> _detectNvidiaGpu() async {
    // 方法1: 检查 /proc/driver/nvidia/version
    final nvidiaVersionFile = File('/proc/driver/nvidia/version');
    if (await nvidiaVersionFile.exists()) {
      AppLogger.debug('[NVIDIA] 通过 /proc/driver/nvidia/version 检测到');
      return true;
    }

    // 方法2: 检查 nvidia-smi 命令
    try {
      final result = await Process.run('nvidia-smi', ['-L']);
      if (result.exitCode == 0) {
        AppLogger.debug('[NVIDIA] 通过 nvidia-smi 检测到');
        return true;
      }
    } catch (_) {
      // nvidia-smi 不存在或执行失败
    }

    // 方法3: 检查 /sys/bus/pci/drivers/nvidia
    final nvidiaDriverPath = Directory('/sys/bus/pci/drivers/nvidia');
    if (await nvidiaDriverPath.exists()) {
      AppLogger.debug('[NVIDIA] 通过 /sys/bus/pci/drivers/nvidia 检测到');
      return true;
    }

    // 方法4: 检查 lspci 输出
    try {
      final result = await Process.run('lspci', []);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        if (output.toLowerCase().contains('nvidia')) {
          AppLogger.debug('[NVIDIA] 通过 lspci 检测到');
          return true;
        }
      }
    } catch (_) {
      // lspci 不存在
    }

    // 方法5: 检查已加载的内核模块
    try {
      final result = await Process.run('lsmod', []);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        if (output.contains('nvidia')) {
          AppLogger.debug('[NVIDIA] 通过 lsmod 检测到 nvidia 模块');
          return true;
        }
      }
    } catch (_) {
      // lsmod 执行失败
    }

    return false;
  }

  /// 获取 NVIDIA 驱动版本
  static Future<String?> _getDriverVersion() async {
    // 方法1: 从 nvidia-smi 获取
    try {
      final result = await Process.run(
        'nvidia-smi',
        ['--query-gpu=driver_version', '--format=csv,noheader'],
      );
      if (result.exitCode == 0) {
        final version = (result.stdout as String).trim();
        if (version.isNotEmpty && !version.startsWith('N/A')) {
          return version;
        }
      }
    } catch (_) {}

    // 方法2: 从 /proc 文件获取
    try {
      final file = File('/proc/driver/nvidia/version');
      if (await file.exists()) {
        final content = await file.readAsString();
        // 解析版本号，格式: NVRM version: NVIDIA UNIX x86_64 Kernel Module 535.154.05
        final match = RegExp(r'Kernel Module\s+([\d.]+)').firstMatch(content);
        if (match != null) {
          return match.group(1);
        }
      }
    } catch (_) {}

    // 方法3: 从 modinfo 获取
    try {
      final result = await Process.run('modinfo', ['-F', 'version', 'nvidia']);
      if (result.exitCode == 0) {
        final version = (result.stdout as String).trim();
        if (version.isNotEmpty) {
          return version;
        }
      }
    } catch (_) {}

    return null;
  }

  /// 检查是否需要应用 workaround
  static Future<bool> _checkNeedsWorkaround() async {
    if (!_isNvidia) return false;

    // 检查驱动版本
    // 535.x 及以下版本有已知的 DMABUF 问题
    if (_driverVersion != null) {
      final versionParts = _driverVersion!.split('.');
      if (versionParts.isNotEmpty) {
        final majorVersion = int.tryParse(versionParts[0]) ?? 0;
        // 驱动版本 <= 535 通常需要 workaround
        if (majorVersion <= 535) {
          return true;
        }
      }
    }

    // 检查是否在 Wayland 环境下
    final waylandDisplay = Platform.environment['WAYLAND_DISPLAY'];
    final xdgSessionType = Platform.environment['XDG_SESSION_TYPE'];

    if (waylandDisplay != null || xdgSessionType == 'wayland') {
      // Wayland + NVIDIA 通常需要 workaround
      return true;
    }

    // 默认情况下，如果检测到 NVIDIA，建议应用 workaround
    return true;
  }

  /// 应用特定类型的 workaround
  static Future<void> _applyWorkaround(NvidiaWorkaroundType type) async {
    switch (type) {
      case NvidiaWorkaroundType.webkitDmabuf:
        // WebKit/WebKitGTK DMABUF 渲染器 workaround
        _appliedWorkarounds.add('webkit_dmabuf');
        AppLogger.info('[NVIDIA] 应用 WebKit DMABUF workaround');
        break;

      case NvidiaWorkaroundType.nvidiaEnv:
        // NVIDIA 特定环境变量
        _appliedWorkarounds.add('nvidia_env');
        AppLogger.info('[NVIDIA] 应用 NVIDIA 环境变量 workaround');
        break;

      case NvidiaWorkaroundType.waylandCompat:
        // Wayland 兼容性
        _appliedWorkarounds.add('wayland_compat');
        AppLogger.info('[NVIDIA] 应用 Wayland 兼容性 workaround');
        break;

      case NvidiaWorkaroundType.gbmBackend:
        // GBM 后端设置
        _appliedWorkarounds.add('gbm_backend');
        // 这会与 nvidia_env 一起设置
        break;
    }
  }

  /// 重置状态（用于测试）
  static void reset() {
    _initialized = false;
    _isNvidia = false;
    _driverVersion = null;
    _needsWorkaround = false;
    _appliedWorkarounds.clear();
  }
}

/// NVIDIA Workaround 类型
enum NvidiaWorkaroundType {
  /// WebKit DMABUF 禁用
  webkitDmabuf,

  /// NVIDIA 环境变量
  nvidiaEnv,

  /// Wayland 兼容性
  waylandCompat,

  /// GBM 后端
  gbmBackend,
}

/// NVIDIA 驱动信息
class NvidiaDriverInfo {
  const NvidiaDriverInfo({
    required this.isPresent,
    this.version,
    this.gpuName,
    this.vramTotal,
    this.driverDate,
  });

  /// 是否存在 NVIDIA 显卡
  final bool isPresent;

  /// 驱动版本
  final String? version;

  /// GPU 名称
  final String? gpuName;

  /// 显存总量（MB）
  final int? vramTotal;

  /// 驱动日期
  final DateTime? driverDate;

  /// 从 nvidia-smi 输出解析
  static Future<NvidiaDriverInfo> fromSmi() async {
    try {
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=name,driver_version,memory.total',
        '--format=csv,noheader',
      ]);

      if (result.exitCode != 0) {
        return const NvidiaDriverInfo(isPresent: false);
      }

      final output = (result.stdout as String).trim();
      if (output.isEmpty || output.contains('N/A')) {
        return const NvidiaDriverInfo(isPresent: false);
      }

      // 解析输出: GPU Name, Driver Version, Memory Total
      final parts = output.split(',').map((s) => s.trim()).toList();

      String? gpuName;
      String? version;
      int? vramTotal;

      if (parts.isNotEmpty) {
        gpuName = parts[0];
      }
      if (parts.length > 1) {
        version = parts[1];
      }
      if (parts.length > 2) {
        // 解析显存，如 "8192 MiB"
        final vramMatch = RegExp(r'(\d+)').firstMatch(parts[2]);
        if (vramMatch != null) {
          vramTotal = int.tryParse(vramMatch.group(1)!);
        }
      }

      return NvidiaDriverInfo(
        isPresent: true,
        version: version,
        gpuName: gpuName,
        vramTotal: vramTotal,
      );
    } catch (_) {
      return const NvidiaDriverInfo(isPresent: false);
    }
  }

  @override
  String toString() => 'NvidiaDriverInfo(present: $isPresent, version: $version, gpu: $gpuName)';
}

/// NVIDIA 常见问题诊断
class NvidiaDiagnostics {
  NvidiaDiagnostics._();

  /// 检查常见问题
  static Future<List<NvidiaIssue>> diagnose() async {
    final issues = <NvidiaIssue>[];

    // 检查驱动是否安装
    if (!NvidiaWorkaround.isNvidia) {
      return issues;
    }

    // 检查 Wayland 兼容性
    if (Platform.environment['WAYLAND_DISPLAY'] != null ||
        Platform.environment['XDG_SESSION_TYPE'] == 'wayland') {
      issues.add(NvidiaIssue(
        type: NvidiaIssueType.waylandCompat,
        severity: NvidiaIssueSeverity.warning,
        message: 'NVIDIA + Wayland 可能存在兼容性问题',
        suggestion: '建议设置 WEBKIT_DISABLE_DMABUF_RENDERER=1',
      ));
    }

    // 检查驱动版本
    final version = NvidiaWorkaround.driverVersion;
    if (version != null) {
      final majorVersion = int.tryParse(version.split('.').first) ?? 0;
      if (majorVersion < 535) {
        issues.add(NvidiaIssue(
          type: NvidiaIssueType.oldDriver,
          severity: NvidiaIssueSeverity.warning,
          message: 'NVIDIA 驱动版本较旧 ($version)',
          suggestion: '建议升级到 535 或更高版本',
        ));
      }
    }

    // 检查 32 位库
    final has32Bit = await _check32BitLibs();
    if (!has32Bit) {
      issues.add(NvidiaIssue(
        type: NvidiaIssueType.missing32Bit,
        severity: NvidiaIssueSeverity.info,
        message: '未检测到 32 位 NVIDIA 库',
        suggestion: '运行 32 位应用需要安装 lib32-nvidia-utils',
      ));
    }

    return issues;
  }

  /// 检查 32 位库
  static Future<bool> _check32BitLibs() async {
    try {
      final result = await Process.run('ldconfig', ['-p']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        return output.contains('libGL.so.1') &&
               (output.contains('lib32') || output.contains('emul'));
      }
    } catch (_) {}
    return false;
  }
}

/// NVIDIA 问题类型
enum NvidiaIssueType {
  waylandCompat,
  oldDriver,
  missing32Bit,
  dmabufIssue,
}

/// NVIDIA 问题严重程度
enum NvidiaIssueSeverity {
  info,
  warning,
  error,
}

/// NVIDIA 问题
class NvidiaIssue {
  const NvidiaIssue({
    required this.type,
    required this.severity,
    required this.message,
    this.suggestion,
  });

  final NvidiaIssueType type;
  final NvidiaIssueSeverity severity;
  final String message;
  final String? suggestion;

  @override
  String toString() => 'NvidiaIssue($severity: $message)';
}