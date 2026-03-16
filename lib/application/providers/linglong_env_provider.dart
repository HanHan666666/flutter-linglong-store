import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/cli_executor.dart';
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

  /// 是否被用户跳过
  final bool wasSkipped;

  /// 是否需要显示对话框
  bool get shouldShowDialog =>
      checkState == LinglongEnvCheckState.failed ||
      (checkState == LinglongEnvCheckState.success && result != null && !result!.isOk);

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
    bool? wasSkipped,
    bool clearResult = false,
    bool clearInstallMessage = false,
  }) {
    return LinglongEnvState(
      checkState: checkState ?? this.checkState,
      result: clearResult ? null : (result ?? this.result),
      isInstalling: isInstalling ?? this.isInstalling,
      installProgress: installProgress ?? this.installProgress,
      installMessage: clearInstallMessage ? null : (installMessage ?? this.installMessage),
      wasSkipped: wasSkipped ?? this.wasSkipped,
    );
  }
}

/// 安装脚本配置
class InstallScriptConfig {
  const InstallScriptConfig({
    required this.url,
    required this.name,
    this.description,
  });

  final String url;
  final String name;
  final String? description;
}

/// 玲珑环境检测 Provider
///
/// 负责检测和管理玲珑运行环境状态
@Riverpod(keepAlive: true)
class LinglongEnv extends _$LinglongEnv {
  /// 安装进程 ID
  static const String _installProcessId = 'linglong_env_install';

  /// 安装脚本配置
  /// URL 从 AppConfig 读取，支持编译时环境变量覆盖
  static const InstallScriptConfig _installScript = InstallScriptConfig(
    url: AppConfig.installScriptUrl,
    name: '玲珑环境安装脚本',
    description: '自动安装玲珑运行环境',
  );

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
      // 检测 ll-cli 是否可用
      final llCliVersion = await _checkLlCliVersion();

      if (llCliVersion == null) {
        final result = LinglongEnvCheckResult(
          isOk: false,
          errorMessage: 'll-cli 未安装或不可用',
          errorDetail: '请先安装玲珑环境，或确保 ll-cli 在系统 PATH 中',
          checkedAt: DateTime.now().millisecondsSinceEpoch,
        );
        state = state.copyWith(
          checkState: LinglongEnvCheckState.success,
          result: result,
        );
        return result;
      }

      // 检测 ll-cli 基本功能
      final isFunctional = await _checkLlCliFunctional();

      if (!isFunctional) {
        final result = LinglongEnvCheckResult(
          isOk: false,
          errorMessage: 'll-cli 功能异常',
          errorDetail: 'll-cli 已安装但功能异常，请检查玲珑环境配置',
          llCliVersion: llCliVersion,
          checkedAt: DateTime.now().millisecondsSinceEpoch,
        );
        state = state.copyWith(
          checkState: LinglongEnvCheckState.success,
          result: result,
        );
        return result;
      }

      // ll-cli 可用且功能正常
      final result = LinglongEnvCheckResult(
        isOk: true,
        llCliVersion: llCliVersion,
        checkedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        checkState: LinglongEnvCheckState.success,
        result: result,
      );

      AppLogger.info('玲珑环境检测完成: llCliVersion=$llCliVersion');
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

  /// 检测 ll-cli 版本
  Future<String?> _checkLlCliVersion() async {
    try {
      final result = await Process.run(
        kLlCliPath,
        ['--version'],
        environment: {
          'LC_ALL': 'C.UTF-8',
          'LANG': 'C.UTF-8',
        },
      );

      if (result.exitCode != 0) {
        AppLogger.warning('ll-cli --version 返回非零退出码: ${result.exitCode}');
        return null;
      }

      final output = result.stdout.toString();
      return _parseVersion(output);
    } catch (e) {
      AppLogger.warning('执行 ll-cli --version 失败: $e');
      return null;
    }
  }

  /// 检测 ll-cli 基本功能是否正常
  Future<bool> _checkLlCliFunctional() async {
    try {
      // 尝试执行 ps 命令检查 ll-cli 是否能正常响应
      final result = await Process.run(
        kLlCliPath,
        ['ps'],
        environment: {
          'LC_ALL': 'C.UTF-8',
          'LANG': 'C.UTF-8',
        },
      );

      // 退出码为 0 表示正常
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.warning('ll-cli 功能检测失败: $e');
      return false;
    }
  }

  /// 解析版本号
  String? _parseVersion(String output) {
    final lines = output.split('\n');
    for (final line in lines) {
      // 尝试匹配语义版本号 (如 1.2.3)
      final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }
    // 如果没有找到版本号，返回第一行非空内容
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
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

  /// 获取安装脚本 URL
  String getInstallScriptUrl() {
    return _installScript.url;
  }

  /// 获取安装脚本名称
  String getInstallScriptName() {
    return _installScript.name;
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
    );

    try {
      // 步骤 1: 下载安装脚本
      state = state.copyWith(
        installProgress: 0.05,
        installMessage: '正在下载安装脚本...',
      );

      final scriptPath = await _downloadInstallScript();
      if (scriptPath == null) {
        throw Exception('下载安装脚本失败');
      }

      // 步骤 2: 设置脚本执行权限
      state = state.copyWith(
        installProgress: 0.1,
        installMessage: '正在准备执行安装...',
      );

      await _setExecutablePermission(scriptPath);

      // 步骤 3: 执行安装脚本（需要 sudo 权限）
      state = state.copyWith(
        installProgress: 0.15,
        installMessage: '正在执行安装脚本（需要管理员权限）...',
      );

      final installSuccess = await _executeInstallScript(scriptPath);

      // 清理临时文件
      try {
        final file = File(scriptPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.warning('清理临时脚本文件失败: $e');
      }

      if (!installSuccess) {
        throw Exception('安装脚本执行失败');
      }

      // 步骤 4: 验证安装
      state = state.copyWith(
        installProgress: 0.95,
        installMessage: '正在验证安装...',
      );

      await Future.delayed(const Duration(milliseconds: 500));
      await checkEnvironment();

      // 检查安装结果
      final isOk = state.result?.isOk ?? false;

      state = state.copyWith(
        installProgress: 1.0,
        installMessage: isOk ? '安装完成' : '安装验证失败',
      );

      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isInstalling: false,
        clearInstallMessage: true,
      );

      AppLogger.info('自动安装完成, 结果: ${isOk ? "成功" : "失败"}');
      return isOk;
    } catch (e, s) {
      AppLogger.error('自动安装失败', e, s);

      state = state.copyWith(
        isInstalling: false,
        installMessage: '安装失败: ${e.toString()}',
      );

      return false;
    }
  }

  /// 下载安装脚本
  ///
  /// 返回脚本临时路径，失败返回 null
  Future<String?> _downloadInstallScript() async {
    try {
      final scriptUrl = _installScript.url;
      AppLogger.info('下载安装脚本: $scriptUrl');

      // 使用 curl 或 wget 下载脚本
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/linglong_install_${DateTime.now().millisecondsSinceEpoch}.sh');

      // 优先使用 curl
      final curlResult = await Process.run(
        'curl',
        ['-fsSL', '-o', scriptFile.path, scriptUrl],
      ).timeout(const Duration(minutes: 2));

      if (curlResult.exitCode == 0 && await scriptFile.exists()) {
        AppLogger.info('安装脚本下载成功: ${scriptFile.path}');
        return scriptFile.path;
      }

      // curl 失败，尝试 wget
      AppLogger.warning('curl 下载失败，尝试 wget');
      final wgetResult = await Process.run(
        'wget',
        ['-q', '-O', scriptFile.path, scriptUrl],
      ).timeout(const Duration(minutes: 2));

      if (wgetResult.exitCode == 0 && await scriptFile.exists()) {
        AppLogger.info('安装脚本下载成功: ${scriptFile.path}');
        return scriptFile.path;
      }

      AppLogger.error('下载安装脚本失败');
      return null;
    } catch (e, s) {
      AppLogger.error('下载安装脚本异常', e, s);
      return null;
    }
  }

  /// 设置脚本执行权限
  Future<void> _setExecutablePermission(String scriptPath) async {
    final result = await Process.run('chmod', ['+x', scriptPath]);
    if (result.exitCode != 0) {
      throw Exception('设置执行权限失败: ${result.stderr}');
    }
  }

  /// 执行安装脚本
  ///
  /// 使用 pkexec 或 sudo 执行安装脚本，监听输出进度
  Future<bool> _executeInstallScript(String scriptPath) async {
    try {
      // 使用流式执行以获取实时进度
      final progressStream = CliExecutor.executeWithProgress(
        ['sh', '-c', 'pkexec sh "$scriptPath" || sudo sh "$scriptPath"'],
        processId: _installProcessId,
      );

      // 监听进度事件
      await for (final event in progressStream) {
        // 更新进度消息
        final line = event.line.trim();
        if (line.isNotEmpty) {
          state = state.copyWith(
            installMessage: _parseInstallProgress(line),
          );
        }

        // 解析进度百分比
        final progress = event.progress;
        if (progress != null) {
          // 映射进度到 0.15 - 0.90 范围
          final mappedProgress = 0.15 + (progress / 100) * 0.75;
          state = state.copyWith(installProgress: mappedProgress);
        }
      }

      // 检查是否被取消
      if (!CliExecutor.isRunning(_installProcessId)) {
        // 进程已结束，检查是否被取消
        // 这里假设如果到达这里说明执行成功
        return true;
      }

      return true;
    } on CliCancelledException {
      AppLogger.info('安装被用户取消');
      state = state.copyWith(installMessage: '安装已取消');
      return false;
    } catch (e, s) {
      AppLogger.error('执行安装脚本失败', e, s);
      return false;
    }
  }

  /// 解析安装进度消息
  String _parseInstallProgress(String line) {
    // 常见的安装阶段消息
    if (line.contains('download') || line.contains('下载')) {
      return '正在下载组件...';
    }
    if (line.contains('install') || line.contains('安装')) {
      return '正在安装组件...';
    }
    if (line.contains('configure') || line.contains('配置')) {
      return '正在配置环境...';
    }
    if (line.contains('error') || line.contains('错误') || line.contains('fail')) {
      return '安装遇到问题: $line';
    }

    // 默认返回原始行（截断）
    return line.length > 50 ? '${line.substring(0, 50)}...' : line;
  }

  /// 取消安装
  void cancelInstall() {
    if (state.isInstalling) {
      CliExecutor.cancel(_installProcessId, force: true);
      state = state.copyWith(
        isInstalling: false,
        installMessage: '安装已取消',
      );
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