import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../core/logging/app_logger.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../core/security/trusted_content_signature.dart';
import '../../core/storage/app_xdg_paths.dart';

/// 引导修复执行状态。
enum GuidedRepairStatus {
  /// 脚本退出码为 0。
  success,

  /// 脚本正常结束但退出码非 0。
  failed,

  /// 脚本超过客户端固定的 30 分钟上限。
  timedOut,
}

/// 引导修复执行结果。
class GuidedRepairResult {
  /// 创建不可变的执行结果。
  const GuidedRepairResult({
    required this.status,
    required this.logFilePath,
    required this.stdout,
    required this.stderr,
    this.exitCode,
  });

  /// 按退出码或超时归类的状态。
  final GuidedRepairStatus status;

  /// 完整执行日志路径。
  final String logFilePath;

  /// 执行期间累计的标准输出。
  final String stdout;

  /// 执行期间累计的标准错误。
  final String stderr;

  /// 进程退出码；超时时没有可靠退出码。
  final int? exitCode;

  /// 是否按脚本退出码 0 判定修复完成。
  bool get success => status == GuidedRepairStatus.success;
}

/// 受信内容签名无效异常。
class InvalidTrustedContentSignatureException implements Exception {
  /// 创建签名无效异常。
  const InvalidTrustedContentSignatureException();

  @override
  String toString() => '修复脚本签名无效';
}

/// 安装错误的一键修复执行服务。
///
/// 服务集中负责执行前复验、精确写入临时脚本、pkexec 调用、30 分钟超时、
/// XDG 日志和 finally 清理。UI 只负责脚本审计确认与实时输出展示。
class GuidedRepairService {
  /// 用户脚本的固定执行上限。
  static const Duration repairTimeout = Duration(minutes: 30);

  /// 为 GNU timeout 退出和日志收尾预留的执行器看门狗时间。
  static const Duration _executorWatchdogTimeout = Duration(
    minutes: 30,
    seconds: 30,
  );

  /// GNU timeout 表示达到时限的退出码。
  static const int _timeoutExitCode = 124;

  /// 创建修复服务。
  GuidedRepairService({
    required ShellCommandExecutor executor,
    required TrustedContentSignatureVerifier signatureVerifier,
    String? temporaryDirectoryPath,
    String? logDirectoryPath,
    DateTime Function()? clock,
  }) : _executor = executor,
       _signatureVerifier = signatureVerifier,
       _temporaryDirectoryPath =
           temporaryDirectoryPath ?? Directory.systemTemp.path,
       _logDirectoryPath = logDirectoryPath,
       _clock = clock ?? DateTime.now;

  /// Shell 命令统一执行器。
  final ShellCommandExecutor _executor;

  /// 通用受信内容验签器。
  final TrustedContentSignatureVerifier _signatureVerifier;

  /// 临时脚本父目录。
  final String _temporaryDirectoryPath;

  /// 测试或定制日志目录。
  final String? _logDirectoryPath;

  /// 可测试时钟。
  final DateTime Function() _clock;

  /// 执行已经过用户全文审计确认的修复脚本。
  ///
  /// 即使进入该方法前已经验签，也会在落盘和 pkexec 之前重新验证完全相同的
  /// [script]，防止展示内容与最终执行内容之间出现漂移。
  Future<GuidedRepairResult> execute({
    required String script,
    required String signature,
    required void Function(ShellOutputLine output) onOutput,
  }) async {
    final signatureValid = await _signatureVerifier.verify(
      purpose: TrustedContentPurpose.privilegedShellScript,
      content: script,
      signature: signature,
    );
    if (!signatureValid) {
      throw const InvalidTrustedContentSignatureException();
    }

    final logFilePath = await _createLogFilePath();
    final temporaryDirectory = await Directory(
      _temporaryDirectoryPath,
    ).createTemp('linglong-guided-repair-');
    final scriptFile = File(path.join(temporaryDirectory.path, 'repair.sh'));
    await scriptFile.writeAsString(script, flush: true);

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    void captureOutput(ShellOutputLine output) {
      if (output.channel == ShellOutputChannel.stdout) {
        stdoutBuffer.writeln(output.line);
      } else {
        stderrBuffer.writeln(output.line);
      }
      onOutput(output);
    }

    try {
      final result = await _executor.runStreaming(
        [
          'pkexec',
          'timeout',
          '--signal=TERM',
          '--kill-after=10s',
          '${repairTimeout.inSeconds}s',
          'bash',
          scriptFile.path,
        ],
        timeout: _executorWatchdogTimeout,
        environment: const <String, String>{
          'LANG': 'C.UTF-8',
          'LC_ALL': 'C.UTF-8',
        },
        logOptions: ShellCommandLogOptions(
          filePath: logFilePath,
          overwrite: true,
        ),
        onOutput: captureOutput,
      );
      return GuidedRepairResult(
        status: result.exitCode == _timeoutExitCode
            ? GuidedRepairStatus.timedOut
            : result.success
            ? GuidedRepairStatus.success
            : GuidedRepairStatus.failed,
        logFilePath: logFilePath,
        stdout: result.stdout,
        stderr: result.stderr,
        exitCode: result.exitCode,
      );
    } on TimeoutException {
      return GuidedRepairResult(
        status: GuidedRepairStatus.timedOut,
        logFilePath: logFilePath,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } finally {
      await _deleteTemporaryDirectory(temporaryDirectory);
    }
  }

  /// 创建本次执行的完整日志路径。
  Future<String> _createLogFilePath() async {
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
        '${now.second.toString().padLeft(2, '0')}-'
        '${now.microsecond.toString().padLeft(6, '0')}';
    return path.join(directory.path, 'guided-repair-$timestamp.log');
  }

  /// 尽力删除包含受信脚本的临时目录。
  Future<void> _deleteTemporaryDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      AppLogger.warning('清理一键修复临时脚本失败', error, stackTrace);
    }
  }
}
