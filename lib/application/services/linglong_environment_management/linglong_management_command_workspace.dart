/// 玲珑环境管理命令的临时资源工作区。
///
/// 该文件只管理特权脚本、XDG 日志和命令输出边界，供不同环境修复用例复用。
/// 业务判断保留在各自服务中，避免共享工具重新演变为环境管理 God Class。
library;

import 'dart:io';

import 'package:path/path.dart' as path;

import '../../../core/platform/shell_command_executor.dart';
import '../../../core/storage/app_xdg_paths.dart';

/// 为环境管理命令提供统一的临时文件和日志生命周期。
class LinglongManagementCommandWorkspace {
  /// 创建命令工作区。
  ///
  /// [clock] 用于生成可预测的日志和临时脚本名称，[logDirectoryPath] 仅供测试或
  /// 显式诊断目录覆盖；默认始终遵循应用的 XDG 日志路径。
  LinglongManagementCommandWorkspace({
    required DateTime Function() clock,
    String? logDirectoryPath,
  }) : _clock = clock,
       _logDirectoryPath = logDirectoryPath;

  final DateTime Function() _clock;
  final String? _logDirectoryPath;

  /// 为依赖英文输出做兼容判断的系统命令提供稳定 locale。
  static const Map<String, String> englishLocaleEnvironment = {
    'LC_ALL': 'C.UTF-8',
    'LANG': 'C.UTF-8',
    'LANGUAGE': 'C.UTF-8',
    'LC_MESSAGES': 'C.UTF-8',
  };

  /// 创建符合 XDG 目录约定的完整日志文件路径。
  Future<String> createLogFilePath(String prefix) async {
    final directoryPath =
        _logDirectoryPath ??
        AppXdgPaths.resolveLogsDirectoryPath() ??
        path.join(Directory.systemTemp.path, 'linglong-store', 'logs');
    final directory = Directory(directoryPath);
    await directory.create(recursive: true);
    final now = _clock();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return path.join(directory.path, '$prefix-$timestamp.log');
  }

  /// 把受控脚本写入系统临时目录并立即刷盘。
  ///
  /// 调用方必须在 `finally` 中调用 [deleteTemporaryScript]，避免特权脚本残留。
  Future<File> writeTemporaryScript(
    String script, {
    String prefix = 'linglong-storage-move',
  }) async {
    final file = File(
      path.join(
        Directory.systemTemp.path,
        '$prefix-${_clock().millisecondsSinceEpoch}.sh',
      ),
    );
    await file.writeAsString(script, flush: true);
    return file;
  }

  /// 尽力删除临时脚本，不让清理失败覆盖主操作结果。
  Future<void> deleteTemporaryScript(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 临时脚本删除失败不影响主修复结果，完整执行过程已经写入日志。
    }
  }

  /// 返回命令最适合在简短结果中展示的输出。
  String primaryOutput(ShellCommandResult result) {
    final primary = result.primaryMessage;
    if (primary.isNotEmpty) {
      return primary;
    }
    return result.stdout.trim();
  }

  /// 合并一次命令的 stdout/stderr，供跨发行版兼容判断使用。
  ///
  /// 底层工具的进度、partial 计数和错误原因可能分散在两个流里，因此不能只读
  /// `primaryMessage`。
  String combinedCommandOutput(ShellCommandResult result) {
    return [
      result.stdout.trim(),
      result.stderr.trim(),
    ].where((item) => item.isNotEmpty).join('\n');
  }

  /// 合并多次修复尝试的输出，保留参数降级和复验的完整上下文。
  String combinedCommandOutputs(List<ShellCommandResult> results) {
    return results
        .map(combinedCommandOutput)
        .where((item) => item.isNotEmpty)
        .join('\n');
  }

  /// 截断 UI 结果中的命令输出，完整内容继续由日志文件承载。
  String truncateOutput(String output, {int maxLength = 4000}) {
    if (output.length <= maxLength) {
      return output;
    }
    return '${output.substring(0, maxLength)}\n... 输出已截断，请查看完整日志。';
  }

  /// 使用 POSIX 单引号规则转义脚本常量，避免路径改变 Shell 语义。
  String shellSingleQuote(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }
}
