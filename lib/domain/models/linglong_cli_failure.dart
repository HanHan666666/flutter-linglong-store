/// 描述普通 ll-cli 查询与命令的稳定失败事实。
///
/// 领域层只保存可供业务决策、日志和诊断使用的信息，不携带任何语言的用户文案。
/// Data 层负责把进程、退出码和解析异常转换到这里，Presentation 再按当前语言展示。
library;

/// ll-cli 失败的稳定类别。
enum LinglongCliFailureKind {
  /// 系统中找不到 ll-cli 或其依赖命令。
  commandNotFound,

  /// 命令在约定时间内没有结束。
  timeout,

  /// 命令因权限或授权问题无法执行。
  permissionDenied,

  /// 命令已执行，但以非零退出码或未确认结果结束。
  commandFailed,

  /// 命令成功退出，但结构化输出不符合约定。
  invalidOutput,

  /// XDG 路径、desktop 文件或其他文件系统操作失败。
  filesystem,

  /// 尚未归类的运行时异常。
  unexpected,
}

/// 一次 ll-cli 失败的不可变诊断事实。
class LinglongCliFailure {
  const LinglongCliFailure({
    required this.kind,
    required this.command,
    this.diagnostic,
    this.exitCode,
  });

  /// 稳定失败类别，供 Application 决定是否重试或展示特定入口。
  final LinglongCliFailureKind kind;

  /// 不含用户输入和 Shell 转义的命令标签，用于定位失败的业务操作。
  final String command;

  /// 原始诊断内容；不得在 Data 层翻译或拼接用户文案。
  final String? diagnostic;

  /// 子进程退出码；未成功启动或非进程错误时为空。
  final int? exitCode;
}

/// 普通 ll-cli 端口向上层传播的统一异常。
class LinglongCliException implements Exception {
  const LinglongCliException(this.failure);

  /// 保留完整分类和诊断的领域失败对象。
  final LinglongCliFailure failure;

  @override
  String toString() {
    final diagnostic = failure.diagnostic?.trim();
    if (diagnostic != null && diagnostic.isNotEmpty) {
      return diagnostic;
    }
    return 'll-cli ${failure.command} failed (${failure.kind.name})';
  }
}

/// 创建桌面快捷方式的稳定结果状态。
enum DesktopShortcutDisposition {
  /// 本次调用新建了 desktop 文件。
  created,

  /// 目标 desktop 文件原本已经存在，调用没有覆盖用户文件。
  alreadyExists,
}

/// XDG 桌面快捷方式操作的明确成功结果。
class DesktopShortcutResult {
  const DesktopShortcutResult({required this.path, required this.disposition});

  /// 最终 desktop 文件的绝对路径。
  final String path;

  /// 本次调用是创建文件还是保持已有文件。
  final DesktopShortcutDisposition disposition;
}
