import 'dart:async';
import 'dart:io';

import '../../core/i18n/install_messages.dart';
import '../../core/network/api_exceptions.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../core/platform/cli_executor.dart';
import '../../core/logging/app_logger.dart';
import '../mappers/cli_output_parser.dart';

typedef CliExecuteFn =
    Future<CliOutput> Function(
      List<String> args, {
      Duration timeout,
      String? processId,
      String? locale,
    });

typedef CliExecuteWithProgressAndProcessFn =
    Stream<ProgressEvent> Function(
      List<String> args, {
      String? processId,
      String? locale,
      void Function(Process process)? onProcessCreated,
    });

typedef CliCancelWithSystemKillFn =
    Future<bool> Function(
      String processId, {
      bool force,
      bool killPackageMananger,
    });

/// ll-cli Repository 实现
class LinglongCliRepositoryImpl implements LinglongCliRepository {
  LinglongCliRepositoryImpl(this._messages)
    : _execute = CliExecutor.execute,
      _executeWithProgressAndProcess =
          CliExecutor.executeWithProgressAndProcess,
      _cancelWithSystemKill = CliExecutor.cancelWithSystemKill;

  LinglongCliRepositoryImpl.withExecutor(
    this._messages, {
    required CliExecuteFn execute,
    required CliExecuteWithProgressAndProcessFn executeWithProgressAndProcess,
    required CliCancelWithSystemKillFn cancelWithSystemKill,
  }) : _execute = execute,
       _executeWithProgressAndProcess = executeWithProgressAndProcess,
       _cancelWithSystemKill = cancelWithSystemKill;

  final InstallMessages _messages;
  final CliExecuteFn _execute;
  final CliExecuteWithProgressAndProcessFn _executeWithProgressAndProcess;
  final CliCancelWithSystemKillFn _cancelWithSystemKill;

  /// 活跃的安装任务进程 PID（用于取消）
  final Map<String, int> _activeProcessPids = {};

  /// 取消标志
  final Map<String, bool> _cancelFlags = {};

  String _operationProcessId(String appId, InstallTaskKind kind) {
    return '${kind.name}_$appId';
  }

  void _setOperationCancelled(String appId, {InstallTaskKind? kind}) {
    if (kind == null) {
      _cancelFlags[_operationProcessId(appId, InstallTaskKind.install)] = true;
      _cancelFlags[_operationProcessId(appId, InstallTaskKind.update)] = true;
      return;
    }
    _cancelFlags[_operationProcessId(appId, kind)] = true;
  }

  String _operationLabel(InstallTaskKind kind) {
    return kind == InstallTaskKind.update
        ? _messages.updateLabel
        : _messages.installLabel;
  }

  InstallProgressEventType _mapEventType(ParsedJsonEvent? jsonEvent) {
    switch (jsonEvent?.eventType) {
      case JsonEventType.progress:
        return InstallProgressEventType.progress;
      case JsonEventType.error:
        return InstallProgressEventType.error;
      case JsonEventType.message:
        return InstallProgressEventType.message;
      case null:
        return InstallProgressEventType.message;
    }
  }

  String _extractRawMessage(String line, {ParsedJsonEvent? jsonEvent}) {
    final raw = jsonEvent?.message ?? _messages.extractMessageText(line);
    return raw.trim();
  }

  Stream<InstallProgress> _runInstallLikeOperation(
    String appId, {
    required InstallTaskKind kind,
    String? version,
    bool force = false,
  }) async* {
    final processId = _operationProcessId(appId, kind);
    final operationLabel = _operationLabel(kind);

    // 每次开始新任务前重置该任务的取消标志。
    _cancelFlags[processId] = false;

    yield InstallProgress(
      appId: appId,
      eventType: InstallProgressEventType.message,
      status: InstallStatus.pending,
      message: _messages.preparing(operationLabel, appId),
      rawMessage: _messages.preparing(operationLabel, appId),
    );

    try {
      // 只有显式指定版本的安装才拼接 appId/version；升级统一走 ll-cli upgrade。
      final args = <String>[
        kind == InstallTaskKind.update ? 'upgrade' : 'install',
        '--json',
        if (kind == InstallTaskKind.install)
          version != null ? '$appId/$version' : appId
        else
          appId,
      ];
      if (force && kind == InstallTaskKind.install) {
        args.add('--force');
      }

      AppLogger.info(
        '[LinglongCli] 开始$operationLabel: ll-cli ${args.join(' ')}',
      );

      await for (final event in _executeWithProgressAndProcess(
        args,
        processId: processId,
        onProcessCreated: (process) {
          _activeProcessPids[processId] = process.pid;
          AppLogger.debug(
            '[LinglongCli] 记录$operationLabel进程 PID: ${process.pid}',
          );
        },
      )) {
        if (_cancelFlags[processId] == true) {
          yield InstallProgress(
            appId: appId,
            eventType: InstallProgressEventType.cancelled,
            status: InstallStatus.cancelled,
            message: _messages.cancelled(operationLabel),
            rawMessage: _messages.cancelled(operationLabel),
          );
          return;
        }

        final jsonEvent = CliOutputParser.parseJsonLine(event.line);
        final progressInfo = CliOutputParser.parseInstallProgressEx(event.line);
        final rawMessage = _extractRawMessage(event.line, jsonEvent: jsonEvent);
        final displayMessage = _messages.getStatusFromMessage(rawMessage);

        if (progressInfo.phase == InstallPhase.downloading) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.downloading,
            progress: progressInfo.progress,
            message: displayMessage,
            rawMessage: rawMessage,
          );
        } else if (progressInfo.phase == InstallPhase.installing) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.installing,
            progress: progressInfo.progress,
            message: displayMessage,
            rawMessage: rawMessage,
          );
        } else if (progressInfo.phase == InstallPhase.completed) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.success,
            progress: 100,
            message: _messages.completed(operationLabel),
            rawMessage: rawMessage.isNotEmpty
                ? rawMessage
                : _messages.completed(operationLabel),
          );
          return;
        } else if (progressInfo.phase == InstallPhase.failed) {
          final errorCode =
              jsonEvent?.code ?? CliOutputParser.extractErrorCode(event.line);
          final errorDetail = rawMessage.isNotEmpty
              ? rawMessage
              : (progressInfo.errorMessage ?? event.line).trim();
          final errorMessage = errorCode != null
              ? _messages.getErrorMessageFromCode(errorCode)
              : _messages.getStatusFromMessage(errorDetail);

          yield InstallProgress(
            appId: appId,
            eventType: InstallProgressEventType.error,
            status: InstallStatus.failed,
            message: errorMessage,
            rawMessage: errorDetail,
            error: errorMessage,
            errorCode: errorCode,
            errorDetail: errorDetail,
          );
          return;
        }
      }

      final output = await _execute(['info', appId], timeout: kQueryTimeout);

      if (output.success) {
        yield InstallProgress(
          appId: appId,
          eventType: InstallProgressEventType.progress,
          status: InstallStatus.success,
          progress: 100,
          message: _messages.completed(operationLabel),
          rawMessage: _messages.completed(operationLabel),
        );
      } else {
        yield InstallProgress(
          appId: appId,
          eventType: InstallProgressEventType.error,
          status: InstallStatus.failed,
          message: _messages.unknownStatus(operationLabel),
          error: _messages.confirmFailed(operationLabel),
          rawMessage: _messages.unknownStatus(operationLabel),
          errorDetail: _messages.confirmFailed(operationLabel),
        );
      }
    } on CliTimeoutException catch (e) {
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.error,
        status: InstallStatus.failed,
        message: _messages.timeout(operationLabel),
        error: e.message,
        errorCode: -2,
        rawMessage: e.message,
        errorDetail: e.message,
      );
    } on CliCancelledException {
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.cancelled,
        status: InstallStatus.cancelled,
        message: _messages.cancelled(operationLabel),
        rawMessage: _messages.cancelled(operationLabel),
      );
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] $operationLabel异常: $appId', e, stack);
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.error,
        status: InstallStatus.failed,
        message: _messages.failed(operationLabel),
        error: e.toString(),
        rawMessage: e.toString(),
        errorDetail: e.toString(),
      );
    } finally {
      _cancelFlags.remove(processId);
      _activeProcessPids.remove(processId);
    }
  }

  @override
  Future<List<InstalledApp>> getInstalledApps({
    bool includeBaseService = false,
  }) async {
    try {
      final output = await _execute(
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
      final psOutput = await _execute(['ps'], timeout: kQueryTimeout);

      if (!psOutput.success) {
        AppLogger.warning('[LinglongCli] 获取运行中进程失败: ${psOutput.stderr}');
        throw Exception('获取运行中进程失败: ${psOutput.stderr}');
      }

      final runningApps = CliOutputParser.parseRunningApps(psOutput.stdout);
      if (runningApps.isEmpty) {
        return const [];
      }

      // 与 Rust 版本保持一致：使用 list --json --type=all 的批量详情补齐
      // 版本、架构、渠道和来源，避免为每个进程额外执行一次外部命令。
      final installedApps = await getInstalledApps(includeBaseService: true);
      final installedByAppId = {
        for (final app in installedApps) app.appId: app,
      };

      return runningApps.map((app) {
        final installed = installedByAppId[app.appId];
        final source = _extractSource(installed?.runtime);
        return app.copyWith(
          name: installed != null && installed.name.isNotEmpty
              ? installed.name
              : app.appId,
          version: installed?.version ?? '',
          arch: installed?.arch ?? '',
          channel: installed?.channel ?? '',
          source: source,
          icon: installed?.icon,
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 获取运行中进程异常', e, stack);
      rethrow;
    }
  }

  @override
  Stream<InstallProgress> installApp(
    String appId, {
    String? version,
    bool force = false,
  }) async* {
    yield* _runInstallLikeOperation(
      appId,
      kind: InstallTaskKind.install,
      version: version,
      force: force,
    );
  }

  @override
  Future<bool> cancelOperation(
    String appId, {
    required InstallTaskKind kind,
  }) async {
    final processId = _operationProcessId(appId, kind);
    final operationLabel = _operationLabel(kind);

    AppLogger.info('[LinglongCli] 开始取消$operationLabel: $appId');

    // Rust 版本本质是杀掉当前 ll-cli / ll-package-manager，
    // 这里同时标记 install / update 两类流为已取消，避免流结束前继续上报。
    _setOperationCancelled(appId);

    final success = await _cancelWithSystemKill(
      processId,
      force: true,
      killPackageMananger: true,
    );

    _activeProcessPids.remove(processId);

    if (success) {
      AppLogger.info('[LinglongCli] 取消$operationLabel成功: $appId');
    } else {
      AppLogger.warning(
        '[LinglongCli] 取消$operationLabel返回 false（可能无活跃进程）: $appId',
      );
    }

    return success;
  }

  @override
  Stream<InstallProgress> updateApp(String appId) async* {
    yield* _runInstallLikeOperation(appId, kind: InstallTaskKind.update);
  }

  @override
  Future<String> uninstallApp(String appId, String version) async {
    try {
      AppLogger.info('[LinglongCli] 卸载应用: $appId@$version');

      // ll-cli uninstall 只接受 APP 参数，不接受 version 参数
      final output = await _execute([
        'uninstall',
        appId,
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        AppLogger.info('[LinglongCli] 卸载成功: $appId');
        return output.stdout;
      } else {
        // 失败时抛出异常，让调用方正确处理错误
        AppLogger.warning('[LinglongCli] 卸载失败: ${output.stderr}');
        throw UninstallException(
          output.stderr.isNotEmpty ? output.stderr : '卸载命令执行失败',
          appId: appId,
          exitCode: output.exitCode,
        );
      }
    } on UninstallException {
      // 已是 UninstallException，直接重新抛出
      rethrow;
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 卸载异常: $appId', e, stack);
      throw UninstallException(e.toString(), appId: appId);
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

      for (var attempt = 1; attempt <= 5; attempt++) {
        final runningApps = await getRunningApps();
        final isStillRunning = runningApps.any((app) => app.appId == appName);
        if (!isStillRunning) {
          return 'Successfully stopped $appName';
        }

        final output = await _execute([
          'kill',
          '-s',
          '9',
          appName,
        ], timeout: const Duration(seconds: 10));

        if (!output.success && attempt == 5) {
          return _messages.stopFailed(output.stderr);
        }

        if (attempt < 5) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }

      return 'Successfully stopped $appName';
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 终止应用异常: $appName', e, stack);
      return _messages.stopException(e.toString());
    }
  }

  String _extractSource(String? runtime) {
    if (runtime == null || runtime.isEmpty) {
      return '';
    }

    return runtime.split(':').first;
  }

  /// 根据 XDG Base Directory Specification 获取桌面目录路径
  ///
  /// 优先级顺序：
  /// 1. XDG_DESKTOP_DIR 环境变量
  /// 2. xdg-user-dir DESKTOP 命令
  /// 3. ~/.config/user-dirs.dirs 配置文件
  /// 4. 默认 ~/Desktop
  Future<String> _getDesktopDirectory() async {
    // 优先级1: XDG_DESKTOP_DIR 环境变量
    final xdgDesktop = Platform.environment['XDG_DESKTOP_DIR'];
    if (xdgDesktop != null && xdgDesktop.isNotEmpty) {
      final dir = Directory(xdgDesktop);
      if (await dir.exists()) {
        AppLogger.debug('[LinglongCli] 使用 XDG_DESKTOP_DIR: $xdgDesktop');
        return xdgDesktop;
      }
    }

    // 优先级2: 通过 xdg-user-dir 命令获取
    try {
      final result = await Process.run('xdg-user-dir', ['DESKTOP']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty && path != '/') {
          final dir = Directory(path);
          if (await dir.exists()) {
            AppLogger.debug('[LinglongCli] 使用 xdg-user-dir: $path');
            return path;
          }
        }
      }
    } catch (e) {
      AppLogger.debug('[LinglongCli] xdg-user-dir 命令不可用: $e');
    }

    // 优先级3: 解析 ~/.config/user-dirs.dirs
    try {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final userDirsFile = File('$home/.config/user-dirs.dirs');
        if (await userDirsFile.exists()) {
          final content = await userDirsFile.readAsString();
          final match = RegExp(
            r'XDG_DESKTOP_DIR="([^"]+)"',
          ).firstMatch(content);
          if (match != null) {
            final rawPath = match.group(1)!;
            final path = rawPath
                .replaceAll(r'\$HOME', home)
                .replaceAll(r'$HOME', home);
            final dir = Directory(path);
            if (await dir.exists()) {
              AppLogger.debug('[LinglongCli] 使用 user-dirs.dirs: $path');
              return path;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.debug('[LinglongCli] 解析 user-dirs.dirs 失败: $e');
    }

    // Fallback: 默认 ~/Desktop
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw Exception('无法获取 HOME 目录');
    }
    final fallbackPath = '$home/Desktop';
    AppLogger.debug('[LinglongCli] 使用 fallback 路径: $fallbackPath');
    return fallbackPath;
  }

  @override
  Future<String> createDesktopShortcut(String appId) async {
    try {
      AppLogger.info('[LinglongCli] 创建桌面快捷方式: $appId');

      // 1. 检查应用是否已安装
      final installedApps = await getInstalledApps();
      final isInstalled = installedApps.any((app) => app.appId == appId);
      if (!isInstalled) {
        return '应用未安装，无法创建快捷方式: $appId';
      }

      // 2. 使用 ll-cli content 获取应用导出的文件列表
      final output = await _execute([
        'content',
        appId,
      ], timeout: const Duration(seconds: 10));

      if (!output.success) {
        return _messages.shortcutCreateFailed(output.stderr);
      }

      // 3. 从输出中找到 .desktop 文件路径
      final lines = output.stdout.split('\n');
      String? desktopSource;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && trimmed.endsWith('.desktop')) {
          desktopSource = trimmed;
          break;
        }
      }

      if (desktopSource == null) {
        return '未找到应用导出的 desktop 文件: $appId';
      }

      // 4. 根据 XDG 规范获取桌面目录路径
      final desktopDir = await _getDesktopDirectory();

      // 5. 确保桌面目录存在
      final desktopDirFile = Directory(desktopDir);
      if (!await desktopDirFile.exists()) {
        await desktopDirFile.create(recursive: true);
      }

      // 6. 构建目标路径
      final desktopFileName = desktopSource.split('/').last;
      final targetPath = '$desktopDir/$desktopFileName';

      // 7. 检查是否已存在
      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        return '快捷方式已存在，不会覆盖: $targetPath';
      }

      // 8. 复制 .desktop 文件到桌面
      final sourceFile = File(desktopSource);
      if (!await sourceFile.exists()) {
        return '源 desktop 文件不存在: $desktopSource';
      }
      await sourceFile.copy(targetPath);

      // 9. 设置可执行权限 (0o755)
      await Process.run('chmod', ['755', targetPath]);

      AppLogger.info('[LinglongCli] 桌面快捷方式创建成功: $appId -> $targetPath');

      return '已创建桌面快捷方式: $targetPath';
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 创建桌面快捷方式异常: $appId', e, stack);
      return _messages.shortcutCreateException(e.toString());
    }
  }

  @override
  Future<List<InstalledApp>> searchVersions(String appId) async {
    try {
      final output = await _execute(['search', appId], timeout: kQueryTimeout);

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

      final output = await _execute([
        'prune',
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        return output.stdout;
      } else {
        return _messages.pruneFailed(output.stderr);
      }
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] 清理异常', e, stack);
      return _messages.pruneException(e.toString());
    }
  }

  @override
  Future<String> getLlCliVersion() async {
    try {
      final output = await _execute([
        '--version',
      ], timeout: const Duration(seconds: 5));

      if (output.success) {
        return output.stdout.trim();
      } else {
        return _messages.versionFailed;
      }
    } catch (e) {
      return _messages.llCliNotInstalled;
    }
  }
}
