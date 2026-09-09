/// 免密安装 polkit 规则的领域模型（docs/50）。
///
/// 本文件只描述稳定事实：系统状态快照、一次提权事务的结论、稳定失败类型，
/// 以及本地缓存的版本化格式。固定路径、命令构造、脚本正文与输出解析属于
/// Platform 层；状态归约与缓存写入属于 Application 层；本地化文案属于
/// Presentation。任何一层都不得把另一层的细节写进这里的模型。
library;

import 'dart:convert';

/// 固定规则文件在本机上的系统状态（由特权侧回读得出，docs/50 §4.2）。
///
/// 只有 [enabled] 才代表“本功能规则已配置”：它要求固定路径是普通文件、
/// 属主与权限符合预期、正文与受支持模板逐字节一致。[disabled] 只表示本功能
/// 文件不存在，其他管理员规则仍可能让同类操作免密。
enum PolkitRuleSystemState {
  /// 固定路径存在且通过完整校验。
  enabled,

  /// 固定路径不存在，且不是悬空符号链接。
  disabled,

  /// 同名文件内容不同、符号链接、目录、属主或权限异常：不覆盖、不删除。
  conflict,

  /// 无法可靠读取或输出不完整：保留最近显示值并标记待同步。
  unknown,
}

/// 一次提权事务的业务结论（docs/50 §6.3）。
///
/// 与进程退出码解耦：脚本正常完成协议时退出码为 0，业务结论由本枚举承载，
/// 因此“冲突”和“写入失败”也能带回可用的回读状态。
enum PolkitRuleOutcome {
  /// 已按目标完成写入或删除。
  applied,

  /// 系统状态已经等于目标，未重复写入或删除。
  unchanged,

  /// 固定路径被非本功能内容占用，未做任何修改。
  conflict,

  /// 事务未能按目标完成（写入、删除或回读失败）。
  failed,
}

/// 脚本结构化结果中的失败原因。
///
/// 使用固定枚举而不是自由文本，使 GUI 能在不解析诊断文字的前提下区分
/// “目录缺失”“冲突”“写入失败”等原因（docs/50 §6.3）。
enum PolkitRuleFailureReason {
  /// 事务正常结束，无额外失败原因。
  none,

  /// 规则目录缺失或不是目录：环境不支持，不自动创建。
  rulesDirMissing,

  /// 固定路径所在位置不是预期的目录。
  rulesDirNotDirectory,

  /// 等待跨实例排他锁超时。
  lockTimeout,

  /// 固定路径被非本功能内容占用。
  conflict,

  /// 写入或发布规则文件失败。
  writeFailed,

  /// 删除规则文件失败。
  deleteFailed,

  /// 写入后的回读校验失败。
  verifyFailed,

  /// 动作参数不是受支持的白名单值。
  unknownAction,

  /// 非 root 且未处于隔离测试模式。
  notRoot,

  /// 脚本内部错误。
  internalError,
}

/// 无法产生可靠事务结果时的稳定失败类型（docs/50 §6.3）。
///
/// 这些情况表示“系统状态未知或操作未启动”，Application 必须据此标记待同步，
/// 而不是把失败当作关闭。
enum PolkitRuleFailureKind {
  /// pkexec 126 或用户关闭授权对话框：root 操作未启动，系统未被修改。
  authorizationCancelled,

  /// pkexec 不存在、127 或启动失败：授权组件或系统授权不可用。
  authorizationUnavailable,

  /// 规则目录缺失或环境不支持 JS rules：不修改目录权限、不自动部署 polkit。
  unsupportedEnvironment,

  /// 固定路径被占用或内容不符：不覆盖管理员文件。
  ruleConflict,

  /// 写入或删除失败。
  applyFailed,

  /// 输出结构不符合版本化契约。
  invalidResult,

  /// 超时或通道断开。
  timeout,

  /// 其他未预期执行异常。
  unexpected,
}

/// 一次 root 事务的结构化结果（stdout 契约版本 1）。
///
/// [after] 是脚本在释放锁之前回读到的真实状态；当脚本无法回读时保持
/// [PolkitRuleSystemState.unknown]，调用方必须按“待同步”处理。
class PolkitRuleTransactionResult {
  /// 创建事务结果。
  const PolkitRuleTransactionResult({
    required this.requestedEnabled,
    required this.before,
    required this.after,
    required this.outcome,
    this.reason = PolkitRuleFailureReason.none,
  });

  /// 当前支持的 stdout 契约版本。
  static const int contractVersion = 1;

  /// 用户点击时固定的目标值，不会被 root 侧取反。
  final bool requestedEnabled;

  /// 进入事务时读到的系统状态。
  final PolkitRuleSystemState before;

  /// 事务结束（或失败）时回读到的系统状态。
  final PolkitRuleSystemState after;

  /// 业务结论。
  final PolkitRuleOutcome outcome;

  /// 失败原因；正常结束时为 [PolkitRuleFailureReason.none]。
  final PolkitRuleFailureReason reason;

  /// 是否按用户目标完成：结论为 applied/unchanged 且回读状态等于目标。
  ///
  /// 单凭“文件存在”或单凭退出码都不能判定成功，必须由本方法统一表达
  /// （docs/50 §6.3）。
  bool get matchesRequestedTarget {
    if (outcome != PolkitRuleOutcome.applied &&
        outcome != PolkitRuleOutcome.unchanged) {
      return false;
    }
    return after ==
        (requestedEnabled
            ? PolkitRuleSystemState.enabled
            : PolkitRuleSystemState.disabled);
  }

  @override
  String toString() =>
      'PolkitRuleTransactionResult(requested=$requestedEnabled, '
      'before=${before.name}, after=${after.name}, '
      'outcome=${outcome.name}, reason=${reason.name})';
}

/// 提权同步无法产生可靠结果时抛出的稳定异常。
///
/// 诊断文字只用于日志和“可复制错误详情”，不参与成功判定。
class PolkitRuleException implements Exception {
  /// 创建异常。
  const PolkitRuleException(this.kind, this.diagnostic, {this.exitCode});

  /// 稳定失败类型。
  final PolkitRuleFailureKind kind;

  /// 未经本地化和改写的底层诊断。
  final String diagnostic;

  /// pkexec 或脚本的退出码；无退出码（如启动失败）时为空。
  final int? exitCode;

  @override
  String toString() =>
      'PolkitRuleException(${kind.name}'
      '${exitCode == null ? '' : ', exitCode=$exitCode'}): $diagnostic';
}

/// 本地缓存中的免密安装开关状态（docs/50 §4.1）。
///
/// 单个版本化 JSON 键同时保存 [enabled] 与 [needsSync]，避免两次写入造成
/// 逻辑上的半更新。缓存只用于界面展示和下一次安装的执行路径选择，不授予
/// 任何系统权限。
class PasswordFreeInstallCache {
  /// 创建缓存快照。
  const PasswordFreeInstallCache({
    required this.enabled,
    required this.needsSync,
  });

  /// 缓存格式版本。
  static const int formatVersion = 1;

  /// SharedPreferences 中唯一的缓存键。
  static const String preferencesKey = 'setting_password_free_install_state';

  /// 缓存缺失时的默认值：显示关闭且不标记待同步。
  static const PasswordFreeInstallCache defaults = PasswordFreeInstallCache(
    enabled: false,
    needsSync: false,
  );

  /// 最近一次由特权操作确认的本功能配置。
  final bool enabled;

  /// 上一次修改尚未获得可靠结果，或结果未能完整写回缓存。
  final bool needsSync;

  /// 是否允许安装任务走普通 CLI：已确认开启且没有待同步标记。
  ///
  /// 缓存异常或待同步一律回落到 docs/47 的特权 helper，避免在系统状态
  /// 不确定时假设规则已生效（docs/50 §7.1）。
  bool get usesPasswordFreeCli => enabled && !needsSync;

  /// 序列化为缓存 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': formatVersion,
    'enabled': enabled,
    'needsSync': needsSync,
  };

  /// 解析缓存 JSON；版本不支持或结构损坏时返回 null。
  ///
  /// 调用方必须区分“键不存在”和“解析失败”：前者使用 [defaults]，后者
  /// 使用关闭显示并标记待同步，且不据此创建或删除任何系统文件。
  static PasswordFreeInstallCache? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    if (decoded['version'] != formatVersion) {
      return null;
    }
    final enabled = decoded['enabled'];
    final needsSync = decoded['needsSync'];
    if (enabled is! bool || needsSync is! bool) {
      return null;
    }
    return PasswordFreeInstallCache(enabled: enabled, needsSync: needsSync);
  }

  @override
  String toString() =>
      'PasswordFreeInstallCache(enabled: $enabled, needsSync: $needsSync)';
}

/// 免密安装模式的只读快照读取器（docs/50 §7.1）。
///
/// 由生产组合根注入，Data 层在任务启动时同步取一次值并绑定到该任务。
/// 实现只能读取内存状态：不得执行文件、进程、提权或网络操作，也不得触发
/// 系统状态查询，否则每次安装都会额外付出授权或 IO 成本。
typedef PasswordFreeInstallModeReader = bool Function();
