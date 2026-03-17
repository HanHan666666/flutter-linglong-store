import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../core/platform/cli_executor.dart';
import '../../core/logging/app_logger.dart';
import '../mappers/cli_output_parser.dart';

/// ll-cli Repository 实现
class LinglongCliRepositoryImpl implements LinglongCliRepository {
  LinglongCliRepositoryImpl();

  /// 活跃的安装任务进程 PID（用于取消）
  final Map<String, int> _activeProcessPids = {};

  /// 取消标志
  final Map<String, bool> _cancelFlags = {};

  @override
  Future<List<InstalledApp>> getInstalledApps({
    bool includeBaseService = false,
  }) async {
    try {
      final output = await CliExecutor.execute(
        includeBaseService
            ? ['list', '--json', '--type=all']
            : ['list', '--json'],
        timeout: kQueryTimeout,
      );

      if (!output.success) {
        AppLogger.warning('[LinglongCli] 获取已安装应用列表失败: ${output.stderr}');
        return [];
      }

      final apps = CliOutputParser.parseInstalledApps(output.stdout);

      // 过滤基础服务
      if (!includeBaseService) {
        // 与旧版 Rust 商店保持一致：默认仅展示 kind=app 的项目；
        // 若旧版/测试数据未携带 kind，则按普通应用兜底保留。
        return apps.where((app) => (app.kind ?? 'app') == 'app').toList();
      }

      return apps;
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 获取已安装应用列表异常', e, stack);
      return [];
    }
  }

  @override
  Future<List<RunningApp>> getRunningApps() async {
    try {
      final output = await CliExecutor.execute(['ps'], timeout: kQueryTimeout);

      if (!output.success) {
        AppLogger.warning('[LinglongCli] 获取运行中进程失败: ${output.stderr}');
        return [];
      }

      return CliOutputParser.parseRunningApps(output.stdout);
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 获取运行中进程异常', e, stack);
      return [];
    }
  }

  @override
  Stream<InstallProgress> installApp(
    String appId, {
    String? version,
    bool force = false,
  }) async* {
    final processId = 'install_$appId';

    // 重置取消标志
    _cancelFlags[processId] = false;

    // 发送开始事件
    yield InstallProgress(
      appId: appId,
      status: InstallStatus.pending,
      message: '准备安装 $appId...',
    );

    try {
      // 构建安装参数
      // ll-cli install 指定版本格式：appId/version（不支持 --version 参数）
      final installTarget = version != null ? '$appId/$version' : appId;
      final args = ['install', '--json', installTarget];
      if (force) {
        args.add('--force');
      }

      AppLogger.info('[LinglongCli] 开始安装: ll-cli ${args.join(' ')}');

      // 执行安装命令（流式），并记录进程 PID
      await for (final event in CliExecutor.executeWithProgressAndProcess(
        args,
        processId: processId,
        onProcessCreated: (process) {
          // 记录 PID 用于后续取消
          _activeProcessPids[processId] = process.pid;
          AppLogger.debug('[LinglongCli] 记录安装进程 PID: ${process.pid}');
        },
      )) {
        // 检查是否已取消
        if (_cancelFlags[processId] == true) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.cancelled,
            message: '安装已取消',
          );
          return;
        }

        // 使用增强版解析器（支持 JSON 和纯文本）
        final progressInfo = CliOutputParser.parseInstallProgressEx(event.line);

        // 根据解析结果发送进度事件
        if (progressInfo.phase == InstallPhase.downloading) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.downloading,
            progress: progressInfo.progress,
            message: InstallErrorCode.getStatusFromMessage(event.line),
          );
        } else if (progressInfo.phase == InstallPhase.installing) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.installing,
            progress: progressInfo.progress,
            message: InstallErrorCode.getStatusFromMessage(event.line),
          );
        } else if (progressInfo.phase == InstallPhase.completed) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.success,
            progress: 100,
            message: '安装完成',
          );
          return;
        } else if (progressInfo.phase == InstallPhase.failed) {
          // 尝试从 JSON 或文本中提取错误码
          final jsonEvent = CliOutputParser.parseJsonLine(event.line);
          final errorCode =
              jsonEvent?.code ?? CliOutputParser.extractErrorCode(event.line);
          final errorMessage = progressInfo.errorMessage ?? event.line;

          yield InstallProgress(
            appId: appId,
            status: InstallStatus.failed,
            message: errorMessage,
            error: errorCode != null
                ? InstallErrorCode.getStatusFromCode(errorCode)
                : errorMessage,
            errorCode: errorCode,
          );
          return;
        }
      }

      // 流结束但未检测到完成状态，用 info 命令验证安装结果
      // ll-cli info 返回 exit 0 表示应用已安装，非 0 表示未安装
      final output = await CliExecutor.execute([
        'info',
        appId,
      ], timeout: kQueryTimeout);

      if (output.success) {
        yield InstallProgress(
          appId: appId,
          status: InstallStatus.success,
          progress: 100,
          message: '安装完成',
        );
      } else {
        yield InstallProgress(
          appId: appId,
          status: InstallStatus.failed,
          message: '安装状态未知',
          error: '无法确认安装结果',
        );
      }
    } on CliTimeoutException catch (e) {
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.failed,
        message: '安装超时',
        error: e.message,
        errorCode: -2,
      );
    } on CliCancelledException {
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.cancelled,
        message: '安装已取消',
      );
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 安装异常: $appId', e, stack);
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.failed,
        message: '安装失败',
        error: e.toString(),
      );
    } finally {
      _cancelFlags.remove(processId);
      _activeProcessPids.remove(processId);
    }
  }

  @override
  Future<void> cancelInstall(String appId) async {
    final processId = 'install_$appId';

    AppLogger.info('[LinglongCli] 开始取消安装: $appId');

    // 1. 设置取消标志
    _cancelFlags[processId] = true;

    // 2. 使用增强版取消方法（参考 Rust 版本实现）
    // 通过 pkexec killall 终止 ll-cli 和 ll-package-manager
    await CliExecutor.cancelWithSystemKill(
      processId,
      force: true,
      killPackageMananger: true,
    );

    // 3. 清理本地 PID 记录
    _activeProcessPids.remove(processId);

    AppLogger.info('[LinglongCli] 取消安装完成: $appId');
  }

  @override
  Stream<InstallProgress> updateApp(String appId, {String? version}) async* {
    final processId = 'update_$appId';

    // 重置取消标志
    _cancelFlags[processId] = false;

    // 发送开始事件
    yield InstallProgress(
      appId: appId,
      status: InstallStatus.pending,
      message: '准备更新 $appId...',
    );

    try {
      // 构建更新参数
      // ll-cli install 指定版本格式：appId/version（不支持 --version 参数）
      final installTarget = version != null ? '$appId/$version' : appId;
      final args = ['install', '--json', installTarget];

      AppLogger.info('[LinglongCli] 开始更新: ll-cli ${args.join(' ')}');

      // 执行安装命令（流式），并记录进程 PID
      await for (final event in CliExecutor.executeWithProgressAndProcess(
        args,
        processId: processId,
        onProcessCreated: (process) {
          // 记录 PID 用于后续取消
          _activeProcessPids[processId] = process.pid;
          AppLogger.debug('[LinglongCli] 记录更新进程 PID: ${process.pid}');
        },
      )) {
        // 检查是否已取消
        if (_cancelFlags[processId] == true) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.cancelled,
            message: '更新已取消',
          );
          return;
        }

        // 使用增强版解析器（支持 JSON 和纯文本）
        final progressInfo = CliOutputParser.parseInstallProgressEx(event.line);

        // 根据解析结果发送进度事件
        if (progressInfo.phase == InstallPhase.downloading) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.downloading,
            progress: progressInfo.progress,
            message: InstallErrorCode.getStatusFromMessage(event.line),
          );
        } else if (progressInfo.phase == InstallPhase.installing) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.installing,
            progress: progressInfo.progress,
            message: InstallErrorCode.getStatusFromMessage(event.line),
          );
        } else if (progressInfo.phase == InstallPhase.completed) {
          yield InstallProgress(
            appId: appId,
            status: InstallStatus.success,
            progress: 100,
            message: '更新完成',
          );
          return;
        } else if (progressInfo.phase == InstallPhase.failed) {
          // 尝试从 JSON 或文本中提取错误码
          final jsonEvent = CliOutputParser.parseJsonLine(event.line);
          final errorCode =
              jsonEvent?.code ?? CliOutputParser.extractErrorCode(event.line);
          final errorMessage = progressInfo.errorMessage ?? event.line;

          yield InstallProgress(
            appId: appId,
            status: InstallStatus.failed,
            message: errorMessage,
            error: errorCode != null
                ? InstallErrorCode.getStatusFromCode(errorCode)
                : errorMessage,
            errorCode: errorCode,
          );
          return;
        }
      }

      // 流结束但未检测到完成状态，用 info 命令验证更新结果
      final output = await CliExecutor.execute([
        'info',
        appId,
      ], timeout: kQueryTimeout);

      if (output.success) {
        yield InstallProgress(
          appId: appId,
          status: InstallStatus.success,
          progress: 100,
          message: '更新完成',
        );
      } else {
        yield InstallProgress(
          appId: appId,
          status: InstallStatus.failed,
          message: '更新状态未知',
          error: '无法确认更新结果',
        );
      }
    } on CliTimeoutException catch (e) {
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.failed,
        message: '更新超时',
        error: e.message,
        errorCode: -2,
      );
    } on CliCancelledException {
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.cancelled,
        message: '更新已取消',
      );
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 更新异常: $appId', e, stack);
      yield InstallProgress(
        appId: appId,
        status: InstallStatus.failed,
        message: '更新失败',
        error: e.toString(),
      );
    } finally {
      _cancelFlags.remove(processId);
      _activeProcessPids.remove(processId);
    }
  }

  @override
  Future<String> uninstallApp(String appId, String version) async {
    try {
      AppLogger.info('[LinglongCli] 卸载应用: $appId@$version');

      // ll-cli uninstall 只接受 APP 参数，不接受 version 参数
      final output = await CliExecutor.execute([
        'uninstall',
        appId,
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        AppLogger.info('[LinglongCli] 卸载成功: $appId');
        return output.stdout;
      } else {
        AppLogger.warning('[LinglongCli] 卸载失败: ${output.stderr}');
        return '卸载失败: ${output.stderr}';
      }
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 卸载异常: $appId', e, stack);
      return '卸载异常: $e';
    }
  }

  @override
  Future<void> runApp(String appId) async {
    try {
      AppLogger.info('[LinglongCli] 运行应用: $appId');

      // run 命令不等待完成，后台运行
      final process = await Process.start(
        'll-cli',
        ['run', appId],
        environment: {'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8'},
        mode: ProcessStartMode.detached,
      );

      // 不等待结果，直接返回
      AppLogger.info('[LinglongCli] 应用已启动: $appId (pid: ${process.pid})');
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 启动应用失败: $appId', e, stack);
      rethrow;
    }
  }

  @override
  Future<String> killApp(String appName) async {
    try {
      AppLogger.info('[LinglongCli] 终止应用: $appName');

      final output = await CliExecutor.execute([
        'kill',
        appName,
      ], timeout: const Duration(seconds: 10));

      if (output.success) {
        return output.stdout;
      } else {
        return '终止失败: ${output.stderr}';
      }
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 终止应用异常: $appName', e, stack);
      return '终止异常: $e';
    }
  }

  @override
  Future<String> createDesktopShortcut(String appId) async {
    try {
      AppLogger.info('[LinglongCli] 创建桌面快捷方式: $appId');

      // ll-cli 可能没有直接的快捷方式命令
      // 这里需要检查实际的命令支持
      final output = await CliExecutor.execute([
        'desktop',
        appId,
      ], timeout: const Duration(seconds: 10));

      if (output.success) {
        return '快捷方式已创建';
      } else {
        return '创建失败: ${output.stderr}';
      }
    } catch (e) {
      // 如果 desktop 命令不存在，尝试手动创建
      return await _createDesktopShortcutManually(appId);
    }
  }

  @override
  Future<List<InstalledApp>> searchVersions(String appId) async {
    try {
      final output = await CliExecutor.execute([
        'search',
        appId,
      ], timeout: kQueryTimeout);

      if (!output.success) {
        return [];
      }

      return CliOutputParser.parseSearchResults(output.stdout);
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 搜索版本异常: $appId', e, stack);
      return [];
    }
  }

  @override
  Future<String> pruneApps() async {
    try {
      AppLogger.info('[LinglongCli] 开始清理废弃服务');

      final output = await CliExecutor.execute([
        'prune',
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        return output.stdout;
      } else {
        return '清理失败: ${output.stderr}';
      }
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 清理异常', e, stack);
      return '清理异常: $e';
    }
  }

  @override
  Future<String> getLlCliVersion() async {
    try {
      final output = await CliExecutor.execute([
        '--version',
      ], timeout: const Duration(seconds: 5));

      if (output.success) {
        return output.stdout.trim();
      } else {
        return '获取版本失败';
      }
    } catch (e) {
      return 'll-cli 未安装';
    }
  }

  /// 手动创建桌面快捷方式
  Future<String> _createDesktopShortcutManually(String appId) async {
    try {
      // 用 ll-cli info 获取应用信息（输出 JSON 格式）
      final queryOutput = await CliExecutor.execute([
        'info',
        appId,
      ], timeout: kQueryTimeout);

      if (!queryOutput.success) {
        return '无法获取应用信息';
      }

      // ll-cli info 输出 JSON，直接解析
      String appName = appId;
      String appDescription = '';
      try {
        final json = jsonDecode(queryOutput.stdout) as Map<String, dynamic>;
        appName = (json['name'] as String?) ?? appId;
        appDescription = (json['description'] as String?) ?? '';
      } catch (_) {
        // 解析失败时使用默认值
      }

      // 创建 .desktop 文件
      final desktopContent =
          '''
[Desktop Entry]
Version=1.0
Type=Application
Name=$appName
Comment=$appDescription
Exec=ll-cli run $appId
Icon=$appId
Terminal=false
Categories=Application;
''';

      // 写入用户桌面目录
      final home = Platform.environment['HOME'] ?? '';
      final desktopPath = '$home/.local/share/applications/$appId.desktop';

      final file = File(desktopPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(desktopContent);

      return '快捷方式已创建: $desktopPath';
    } catch (e) {
      return '创建快捷方式失败: $e';
    }
  }
}
