import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_provider.dart';
import '../services/linglong_environment_service.dart';
import '../services/linglong_install_log_service.dart';
import '../services/linglong_install_script_service.dart';
import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/linglong_env_check_result.dart';

part 'linglong_env_provider.g.dart';

/// 玲珑环境检测状态
enum LinglongEnvCheckState {
  /// 初始状态
  initial,

  /// 正在检测
  checking,

  /// 检测成功
  success,

  /// 检测失败
  failed,
}

/// 玲珑环境检测状态
class LinglongEnvState {
  const LinglongEnvState({
    this.checkState = LinglongEnvCheckState.initial,
    this.result,
    this.isInstalling = false,
    this.installProgress = 0.0,
    this.installMessage,
    this.installLogFilePath,
    this.wasSkipped = false,
  });

  /// 检测状态
  final LinglongEnvCheckState checkState;

  /// 检测结果
  final LinglongEnvCheckResult? result;

  /// 是否正在安装
  final bool isInstalling;

  /// 安装进度 (0.0 - 1.0)
  final double installProgress;

  /// 安装消息
  final String? installMessage;

  /// 安装日志文件路径
  final String? installLogFilePath;

  /// 是否被用户跳过
  final bool wasSkipped;

  /// 是否需要显示对话框
  bool get shouldShowDialog =>
      checkState == LinglongEnvCheckState.failed ||
      (checkState == LinglongEnvCheckState.success &&
          result != null &&
          !result!.isOk);

  /// 是否正在检测
  bool get isChecking => checkState == LinglongEnvCheckState.checking;

  /// 是否检测完成
  bool get isCompleted =>
      checkState == LinglongEnvCheckState.success ||
      checkState == LinglongEnvCheckState.failed;

  /// 是否允许继续启动（环境正常或用户跳过）
  bool get canContinue => (result?.isOk ?? false) || wasSkipped;

  LinglongEnvState copyWith({
    LinglongEnvCheckState? checkState,
    LinglongEnvCheckResult? result,
    bool? isInstalling,
    double? installProgress,
    String? installMessage,
    String? installLogFilePath,
    bool? wasSkipped,
    bool clearResult = false,
    bool clearInstallMessage = false,
    bool clearInstallLogFilePath = false,
  }) {
    return LinglongEnvState(
      checkState: checkState ?? this.checkState,
      result: clearResult ? null : (result ?? this.result),
      isInstalling: isInstalling ?? this.isInstalling,
      installProgress: installProgress ?? this.installProgress,
      installMessage: clearInstallMessage
          ? null
          : (installMessage ?? this.installMessage),
      installLogFilePath: clearInstallLogFilePath
          ? null
          : (installLogFilePath ?? this.installLogFilePath),
      wasSkipped: wasSkipped ?? this.wasSkipped,
    );
  }
}

final shellCommandExecutorProvider = Provider<ShellCommandExecutor>((ref) {
  return ShellCommandExecutor();
});

final linglongEnvironmentServiceProvider = Provider<LinglongEnvironmentService>(
  (ref) {
    return LinglongEnvironmentService(
      executor: ref.watch(shellCommandExecutorProvider),
    );
  },
);

final linglongInstallScriptServiceProvider =
    Provider<LinglongInstallScriptService>((ref) {
      final apiService = ref.watch(appApiServiceProvider);
      return LinglongInstallScriptService(
        loadScript: () async {
          final response = await apiService.findShellString();
          return response.data.data;
        },
      );
    });

final linglongInstallLogServiceProvider = Provider<LinglongInstallLogService>((
  ref,
) {
  return LinglongInstallLogService();
});

/// 玲珑环境检测 Provider
///
/// 负责检测和管理玲珑运行环境状态
@Riverpod(keepAlive: true)
class LinglongEnv extends _$LinglongEnv {
  @override
  LinglongEnvState build() {
    return const LinglongEnvState();
  }

  /// 检测玲珑环境
  Future<LinglongEnvCheckResult> checkEnvironment() async {
    AppLogger.info('开始检测玲珑环境...');

    state = state.copyWith(
      checkState: LinglongEnvCheckState.checking,
      clearResult: true,
    );

    try {
      final result = await ref
          .read(linglongEnvironmentServiceProvider)
          .checkEnvironment();

      state = state.copyWith(
        checkState: LinglongEnvCheckState.success,
        result: result,
      );

      AppLogger.info(
        '玲珑环境检测完成: '
        'isOk=${result.isOk}, '
        'llCliVersion=${result.llCliVersion}, '
        'repoStatus=${result.repoStatus}',
      );
      return result;
    } catch (e, s) {
      AppLogger.error('玲珑环境检测失败', e, s);

      final result = LinglongEnvCheckResult(
        isOk: false,
        errorMessage: '环境检测失败',
        errorDetail: e.toString(),
        checkedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        checkState: LinglongEnvCheckState.failed,
        result: result,
      );

      return result;
    }
  }

  /// 重新检测
  Future<LinglongEnvCheckResult> recheck() async {
    return checkEnvironment();
  }

  /// 跳过环境检测
  ///
  /// 用户选择跳过环境检测，允许继续启动应用
  /// 注意：跳过后部分功能可能不可用
  void skipCheck() {
    state = state.copyWith(wasSkipped: true);
    AppLogger.info('用户跳过环境检测');
  }

  /// 获取安装文档 URL
  /// URL 从 AppConfig 读取，支持编译时环境变量覆盖
  String getInstallDocUrl() {
    return AppConfig.installDocUrl;
  }

  /// 执行自动安装
  ///
  /// 通过执行安装脚本安装玲珑环境
  /// 返回是否成功
  Future<bool> performAutoInstall() async {
    AppLogger.info('开始自动安装玲珑环境...');

    state = state.copyWith(
      isInstalling: true,
      installProgress: 0.0,
      installMessage: '正在准备安装...',
      clearInstallLogFilePath: true,
    );

    File? scriptFile;
    File? installLogFile;
    try {
      state = state.copyWith(
        installProgress: 0.1,
        installMessage: '正在获取安装脚本...',
      );

      final script = await ref
          .read(linglongInstallScriptServiceProvider)
          .fetchInstallScript();

      state = state.copyWith(
        installProgress: 0.25,
        installMessage: '正在写入安装脚本...',
      );

      scriptFile = await _writeInstallScript(script);

      installLogFile = await ref
          .read(linglongInstallLogServiceProvider)
          .createInstallLogFile();

      state = state.copyWith(
        installProgress: 0.35,
        installMessage: '正在准备执行安装...',
        installLogFilePath: installLogFile.path,
      );

      await _setExecutablePermission(scriptFile.path);

      state = state.copyWith(
        installProgress: 0.5,
        installMessage: '正在执行安装脚本（需要管理员权限）...',
      );

      final installResult = await ref
          .read(shellCommandExecutorProvider)
          .run(
            ['pkexec', 'bash', scriptFile.path],
            timeout: const Duration(minutes: 30),
            logOptions: installLogFile == null
                ? null
                : ShellCommandLogOptions(
                    filePath: installLogFile.path,
                    overwrite: true,
                  ),
          );

      if (!installResult.success) {
        final errorMessage = installResult.primaryMessage.isNotEmpty
            ? installResult.primaryMessage
            : '安装脚本执行失败';
        state = state.copyWith(
          isInstalling: false,
          installMessage: errorMessage,
        );
        return false;
      }

      state = state.copyWith(installProgress: 0.9, installMessage: '正在验证安装...');

      final result = await ref
          .read(linglongEnvironmentServiceProvider)
          .checkEnvironment();
      state = state.copyWith(
        checkState: LinglongEnvCheckState.success,
        result: result,
      );

      state = state.copyWith(
        isInstalling: false,
        installProgress: result.isOk ? 1.0 : 0.95,
        installMessage: result.isOk
            ? '安装完成'
            : (result.errorMessage ?? '安装完成，但环境仍异常'),
      );

      AppLogger.info('自动安装完成, 结果: ${result.isOk ? "成功" : "失败"}');
      return result.isOk;
    } catch (e, s) {
      AppLogger.error('自动安装失败', e, s);

      state = state.copyWith(
        isInstalling: false,
        installMessage: _buildInstallErrorMessage(e),
      );

      return false;
    } finally {
      if (scriptFile != null) {
        await _deleteTempScript(scriptFile);
      }
    }
  }

  Future<File> _writeInstallScript(String script) async {
    final file = File(
      '${Directory.systemTemp.path}/install-linglong-${DateTime.now().millisecondsSinceEpoch}.sh',
    );
    await file.writeAsString(script, flush: true);
    return file;
  }

  Future<void> _setExecutablePermission(String scriptPath) async {
    final result = await Process.run('chmod', ['+x', scriptPath]);
    if (result.exitCode != 0) {
      throw Exception('设置执行权限失败: ${result.stderr}');
    }
  }

  Future<void> _deleteTempScript(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.warning('清理临时安装脚本失败: $e');
    }
  }

  String _buildInstallErrorMessage(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  /// 取消安装
  void cancelInstall() {
    if (state.isInstalling) {
      state = state.copyWith(isInstalling: false, installMessage: '安装已取消');
      AppLogger.info('用户取消安装');
    }
  }
}

/// 便捷访问 Provider

/// 环境检测结果
@riverpod
LinglongEnvCheckResult? linglongEnvResult(Ref ref) {
  return ref.watch(linglongEnvProvider).result;
}

/// 环境是否正常
@riverpod
bool isLinglongEnvOk(Ref ref) {
  final result = ref.watch(linglongEnvProvider).result;
  return result?.isOk ?? false;
}

/// 是否需要显示环境对话框
@riverpod
bool shouldShowEnvDialog(Ref ref) {
  return ref.watch(linglongEnvProvider).shouldShowDialog;
}
