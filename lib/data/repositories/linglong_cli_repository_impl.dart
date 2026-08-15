import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/network/api_exceptions.dart';
import '../../domain/models/app_operation_failure.dart';
import '../../domain/models/linglong_env_check_result.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/models/linglong_cli_failure.dart';
import '../../domain/models/running_app.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/linux_distribution.dart';
import '../../domain/models/linglong_repository_config.dart';
import '../../domain/repositories/linglong_cli_repository.dart';
import '../../domain/repositories/linglong_repository_management_repository.dart';
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
    Future<bool> Function(String processId, {required int pid, bool force});

/// ll-cli Repository 实现
class LinglongCliRepositoryImpl
    implements LinglongCliRepository, LinglongRepositoryManagementRepository {
  LinglongCliRepositoryImpl()
    : _execute = CliExecutor.execute,
      _executeWithProgressAndProcess =
          CliExecutor.executeWithProgressAndProcess,
      _cancelWithSystemKill = CliExecutor.cancelWithSystemKill;

  LinglongCliRepositoryImpl.withExecutor({
    required CliExecuteFn execute,
    required CliExecuteWithProgressAndProcessFn executeWithProgressAndProcess,
    required CliCancelWithSystemKillFn cancelWithSystemKill,
  }) : _execute = execute,
       _executeWithProgressAndProcess = executeWithProgressAndProcess,
       _cancelWithSystemKill = cancelWithSystemKill;

  final CliExecuteFn _execute;
  final CliExecuteWithProgressAndProcessFn _executeWithProgressAndProcess;
  final CliCancelWithSystemKillFn _cancelWithSystemKill;

  /// 取消标志
  final Map<String, bool> _cancelFlags = {};

  /// 运行进程面板专用的已装列表快照（含基础服务），配合 [_runningPanelSnapshotAt] 做 TTL 复用。
  ///
  /// 运行进程页每 3 秒轮询一次 `getRunningApps`，而它内部为了补齐进程元数据
  /// 每次都全量执行 `ll-cli list --json --type=all`（数百条大 JSON + 子进程），
  /// 是稳态下最大的周期性开销。已装列表在轮询窗口内几乎不变，这里按短 TTL
  /// 复用快照；卸载成功后主动失效，安装/更新场景的元数据最迟在 TTL 后自然收敛。
  /// 仅进程面板读取该缓存，installedAppsProvider 的刷新路径始终全量拉取。
  List<InstalledApp>? _runningPanelInstalledSnapshot;

  /// 快照生成时间；远超 TTL 视为无缓存。
  DateTime? _runningPanelSnapshotAt;

  /// 进程面板已装列表快照的复用时长。
  static const Duration _runningPanelSnapshotTtl = Duration(seconds: 15);

  /// 失效进程面板已装列表快照（卸载等确定改变已装集合的操作后调用）。
  void _invalidateRunningPanelSnapshot() {
    _runningPanelInstalledSnapshot = null;
    _runningPanelSnapshotAt = null;
  }

  /// 读取（或按 TTL 复用）进程面板所需的已装列表快照。
  Future<List<InstalledApp>> _installedAppsForRunningPanel() async {
    final snapshot = _runningPanelInstalledSnapshot;
    final snapshotAt = _runningPanelSnapshotAt;
    if (snapshot != null &&
        snapshotAt != null &&
        DateTime.now().difference(snapshotAt) < _runningPanelSnapshotTtl) {
      return snapshot;
    }

    final apps = await getInstalledApps(includeBaseService: true);
    _runningPanelInstalledSnapshot = apps;
    _runningPanelSnapshotAt = DateTime.now();
    return apps;
  }

  /// 把非零退出结果转换为稳定领域失败。
  LinglongCliException _commandOutputException(
    String command,
    CliOutput output,
  ) {
    final diagnostic = output.primaryMessage;
    final lowerDiagnostic = diagnostic.toLowerCase();
    final kind =
        output.exitCode == 127 ||
            lowerDiagnostic.contains('command not found') ||
            lowerDiagnostic.contains('no such file or directory')
        ? LinglongCliFailureKind.commandNotFound
        : output.exitCode == 126 ||
              output.exitCode == 13 ||
              lowerDiagnostic.contains('permission denied') ||
              lowerDiagnostic.contains('not authorized') ||
              lowerDiagnostic.contains('request dismissed')
        ? LinglongCliFailureKind.permissionDenied
        : LinglongCliFailureKind.commandFailed;
    return LinglongCliException(
      LinglongCliFailure(
        kind: kind,
        command: command,
        diagnostic: diagnostic.isEmpty ? null : diagnostic,
        exitCode: output.exitCode,
      ),
    );
  }

  /// 把 Platform/Core 异常翻译为 Domain 失败，防止上层依赖进程实现细节。
  LinglongCliException _domainException(String command, Object error) {
    if (error is LinglongCliException) {
      return error;
    }
    if (error is CliTimeoutException) {
      return LinglongCliException(
        LinglongCliFailure(
          kind: LinglongCliFailureKind.timeout,
          command: command,
          diagnostic: error.message,
        ),
      );
    }
    if (error is CliExecutionException) {
      return LinglongCliException(
        LinglongCliFailure(
          kind: LinglongCliFailureKind.commandFailed,
          command: command,
          diagnostic: error.message,
          exitCode: error.exitCode,
        ),
      );
    }
    if (error is ProcessException) {
      final kind = switch (error.errorCode) {
        2 => LinglongCliFailureKind.commandNotFound,
        13 => LinglongCliFailureKind.permissionDenied,
        _ => LinglongCliFailureKind.unexpected,
      };
      return LinglongCliException(
        LinglongCliFailure(
          kind: kind,
          command: command,
          diagnostic: error.message,
          exitCode: error.errorCode,
        ),
      );
    }
    if (error is FileSystemException) {
      return LinglongCliException(
        LinglongCliFailure(
          kind: LinglongCliFailureKind.filesystem,
          command: command,
          diagnostic: error.message,
        ),
      );
    }
    if (error is FormatException) {
      return LinglongCliException(
        LinglongCliFailure(
          kind: LinglongCliFailureKind.invalidOutput,
          command: command,
          diagnostic: error.message,
        ),
      );
    }
    return LinglongCliException(
      LinglongCliFailure(
        kind: LinglongCliFailureKind.unexpected,
        command: command,
        diagnostic: error.toString(),
      ),
    );
  }

  /// 在 Data 边界统一记录并转换普通命令异常。
  Future<T> _guardCommand<T>(
    String command,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } catch (error, stack) {
      final exception = _domainException(command, error);
      AppLogger.error('[LinglongCli] $command 失败', exception, stack);
      throw exception;
    }
  }

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
    return kind == InstallTaskKind.update ? 'update' : 'install';
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
    return (jsonEvent?.message ?? line).trim();
  }

  Stream<InstallProgress> _runInstallLikeOperation(
    String appId, {
    required InstallTaskKind kind,
    String? version,
    bool force = false,
  }) async* {
    final processId = _operationProcessId(appId, kind);
    final operationLabel = _operationLabel(kind);
    // 所有安装/更新都记录执行前版本集合，避免默认安装已存在应用时被误判成功。
    final installedVersionsBefore = await _getInstalledVersionsForApp(appId);

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
    final commandLine = 'll-cli ${args.join(' ')}';

    // 每次开始新任务前重置该任务的取消标志。
    _cancelFlags[processId] = false;

    yield InstallProgress(
      appId: appId,
      eventType: InstallProgressEventType.message,
      status: InstallStatus.pending,
      messageCode: AppOperationMessageCode.preparing,
      outputLine: commandLine,
    );

    try {
      AppLogger.info('[LinglongCli] 开始$operationLabel: $commandLine');

      await for (final event in _executeWithProgressAndProcess(
        args,
        processId: processId,
        onProcessCreated: (process) {
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
            outputLine: 'Operation cancelled by user',
          );
          return;
        }

        final jsonEvent = CliOutputParser.parseJsonLine(event.line);
        // 复用上面已解析的 JSON 事件，安装输出行高频到达，避免逐行二次 jsonDecode
        final progressInfo = CliOutputParser.parseInstallProgressFromEvent(
          jsonEvent,
          event.line,
        );
        final rawMessage = _extractRawMessage(event.line, jsonEvent: jsonEvent);

        if (progressInfo.phase == InstallPhase.downloading) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.downloading,
            progress: progressInfo.progress,
            messageCode: progressInfo.messageCode,
            rawMessage: rawMessage,
            outputLine: event.line,
          );
        } else if (progressInfo.phase == InstallPhase.installing) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.installing,
            progress: progressInfo.progress,
            messageCode: progressInfo.messageCode,
            rawMessage: rawMessage,
            outputLine: event.line,
          );
        } else if (progressInfo.phase == InstallPhase.completed) {
          yield InstallProgress(
            appId: appId,
            eventType: _mapEventType(jsonEvent),
            status: InstallStatus.success,
            progress: 100,
            messageCode: AppOperationMessageCode.completed,
            rawMessage: rawMessage.isNotEmpty ? rawMessage : null,
            outputLine: event.line,
          );
          return;
        } else if (progressInfo.phase == InstallPhase.failed) {
          final errorCode = jsonEvent?.code;
          // 诊断匹配必须优先保留 JSON message 的逐字内容；rawMessage 还承担
          // 进度展示职责，会经过历史 trim 兼容，不能作为新诊断协议的首选值。
          final exactErrorMessage = jsonEvent?.message;
          final errorDetail =
              exactErrorMessage ??
              (rawMessage.isNotEmpty ? rawMessage : event.line.trim());

          yield InstallProgress(
            appId: appId,
            eventType: InstallProgressEventType.error,
            status: InstallStatus.failed,
            rawMessage: errorDetail,
            failure: AppOperationFailure(
              kind: AppOperationFailureKind.cli,
              cliCode: errorCode,
              diagnostic: errorDetail,
              guidanceScenario: kind == InstallTaskKind.update
                  ? LinuxDistributionGuidanceScenario.appUpdateFailure
                  : LinuxDistributionGuidanceScenario.appInstallFailure,
            ),
            outputLine: event.line,
          );
          return;
        }
      }

      final confirmed = await _confirmInstalledTarget(
        appId,
        kind: kind,
        version: kind == InstallTaskKind.install ? version : null,
        force: force,
        installedVersionsBefore: installedVersionsBefore,
      );

      if (confirmed) {
        yield InstallProgress(
          appId: appId,
          eventType: InstallProgressEventType.progress,
          status: InstallStatus.success,
          progress: 100,
          messageCode: AppOperationMessageCode.completed,
          outputLine: 'Operation result confirmed',
        );
      } else {
        final targetRef = version != null && version.isNotEmpty
            ? '$appId/$version'
            : appId;
        final diagnostic =
            'Installed target not found after $operationLabel: $targetRef';

        yield InstallProgress(
          appId: appId,
          eventType: InstallProgressEventType.error,
          status: InstallStatus.failed,
          rawMessage: diagnostic,
          outputLine: diagnostic,
          failure: AppOperationFailure(
            kind: AppOperationFailureKind.resultUnconfirmed,
            diagnostic: diagnostic,
            guidanceScenario: kind == InstallTaskKind.update
                ? LinuxDistributionGuidanceScenario.appUpdateFailure
                : LinuxDistributionGuidanceScenario.appInstallFailure,
          ),
        );
      }
    } on CliTimeoutException catch (e) {
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.error,
        status: InstallStatus.failed,
        outputLine: e.message,
        rawMessage: e.message,
        failure: AppOperationFailure(
          kind: AppOperationFailureKind.timeout,
          diagnostic: e.message,
          guidanceScenario: kind == InstallTaskKind.update
              ? LinuxDistributionGuidanceScenario.appUpdateFailure
              : LinuxDistributionGuidanceScenario.appInstallFailure,
        ),
      );
    } on CliCancelledException {
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.cancelled,
        status: InstallStatus.cancelled,
        outputLine: 'Operation cancelled',
      );
    } catch (e, stack) {
      AppLogger.error('[LinglongCli] $operationLabel异常: $appId', e, stack);
      yield InstallProgress(
        appId: appId,
        eventType: InstallProgressEventType.error,
        status: InstallStatus.failed,
        outputLine: e.toString(),
        rawMessage: e.toString(),
        failure: AppOperationFailure(
          kind: AppOperationFailureKind.execution,
          diagnostic: e.toString(),
          guidanceScenario: kind == InstallTaskKind.update
              ? LinuxDistributionGuidanceScenario.appUpdateFailure
              : LinuxDistributionGuidanceScenario.appInstallFailure,
        ),
      );
    } finally {
      _cancelFlags.remove(processId);
    }
  }

  Future<bool> _confirmInstalledTarget(
    String appId, {
    required InstallTaskKind kind,
    String? version,
    bool force = false,
    Set<String>? installedVersionsBefore,
  }) async {
    final installedVersionsAfter = await _getInstalledVersionsForApp(appId);

    if (kind == InstallTaskKind.update) {
      if (installedVersionsBefore == null) {
        return false;
      }
      return !_sameVersionSet(installedVersionsBefore, installedVersionsAfter);
    }

    if (version != null && version.isNotEmpty) {
      if (!installedVersionsAfter.contains(version)) {
        return false;
      }

      if (force &&
          installedVersionsBefore != null &&
          installedVersionsBefore.contains(version) &&
          _sameVersionSet(installedVersionsBefore, installedVersionsAfter)) {
        return false;
      }

      return true;
    }

    if (installedVersionsAfter.isEmpty) {
      return false;
    }

    if (installedVersionsBefore == null || installedVersionsBefore.isEmpty) {
      return true;
    }

    return !_sameVersionSet(installedVersionsBefore, installedVersionsAfter);
  }

  Future<Set<String>> _getInstalledVersionsForApp(String appId) async {
    final installedApps = await getInstalledApps();
    return installedApps
        .where((app) => app.appId == appId && app.version.isNotEmpty)
        .map((app) => app.version)
        .toSet();
  }

  bool _sameVersionSet(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  String _stripAnsi(String input) {
    return input.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  String? _stringValue(Object? value) {
    final stringValue = value?.toString().trim();
    return stringValue == null || stringValue.isEmpty ? null : stringValue;
  }

  int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  LinglongRepoInfo? _mapRepoInfo(Map<String, dynamic> json) {
    final name = _stringValue(json['name'] ?? json['alias']);
    final url = _stringValue(json['url']);
    if (name == null || url == null) {
      return null;
    }

    return LinglongRepoInfo(
      name: name,
      url: url,
      alias: _stringValue(json['alias']),
      priority: _stringValue(json['priority']),
    );
  }

  LinglongRepositoryConfig? _parseRepositoryConfigJson(String output) {
    try {
      final decoded = jsonDecode(output.trim());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rawRepos = decoded['repos'];
      final repos = rawRepos is List<dynamic>
          ? rawRepos
                .whereType<Map<String, dynamic>>()
                .map(_mapRepoInfo)
                .whereType<LinglongRepoInfo>()
                .toList()
          : const <LinglongRepoInfo>[];

      return LinglongRepositoryConfig(
        defaultRepo: _stringValue(
          decoded['defaultRepo'] ??
              decoded['default_repo'] ??
              decoded['default'],
        ),
        version: _intValue(decoded['version']),
        repos: repos,
      );
    } catch (_) {
      return null;
    }
  }

  LinglongRepositoryConfig _parseRepositoryConfigText(String output) {
    final sanitizedOutput = _stripAnsi(output);
    final repos = <LinglongRepoInfo>[];
    String? defaultRepo;

    for (final rawLine in sanitizedOutput.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      final defaultMatch = RegExp(
        r'^Default:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (defaultMatch != null) {
        defaultRepo = defaultMatch.group(1)?.trim();
        continue;
      }

      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('name') && lowerLine.contains('url')) {
        continue;
      }

      final columns = line
          .split(RegExp(r'\s{2,}'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (columns.length < 2) {
        continue;
      }

      repos.add(
        LinglongRepoInfo(
          name: columns[0],
          url: columns[1],
          alias: columns.length > 2 ? columns[2] : null,
          priority: columns.length > 3 ? columns[3] : null,
        ),
      );
    }

    return LinglongRepositoryConfig(defaultRepo: defaultRepo, repos: repos);
  }

  Future<String> _runRepositoryCommand(List<String> args) async {
    return _guardCommand('repo', () async {
      final output = await _execute(args, timeout: kQueryTimeout);
      if (!output.success) {
        throw _commandOutputException('repo', output);
      }
      return output.stdout.trim();
    });
  }

  @override
  Future<LinglongRepositoryConfig> getRepositoryConfig() {
    return _guardCommand('repo show', () async {
      final jsonOutput = await _execute([
        '--json',
        'repo',
        'show',
      ], timeout: kQueryTimeout);
      if (jsonOutput.success) {
        final config = _parseRepositoryConfigJson(jsonOutput.stdout);
        if (config != null) {
          return config;
        }
      }

      final textOutput = await _execute([
        'repo',
        'show',
      ], timeout: kQueryTimeout);
      if (!textOutput.success) {
        throw _commandOutputException('repo show', textOutput);
      }

      final config = _parseRepositoryConfigText(textOutput.stdout);
      if (config.repos.isEmpty && config.defaultRepo == null) {
        throw const FormatException(
          'll-cli repo show output does not contain a repository',
        );
      }
      return config;
    });
  }

  @override
  Future<String> addRepository({
    required String name,
    required String url,
    String? alias,
  }) {
    return _runRepositoryCommand([
      'repo',
      'add',
      if (alias != null && alias.trim().isNotEmpty) ...['--alias', alias],
      name,
      url,
    ]);
  }

  @override
  Future<String> updateRepository({
    required String aliasOrName,
    required String url,
  }) {
    return _runRepositoryCommand(['repo', 'update', aliasOrName, url]);
  }

  @override
  Future<String> removeRepository(String aliasOrName) {
    return _runRepositoryCommand(['repo', 'remove', aliasOrName]);
  }

  @override
  Future<String> setDefaultRepository(String aliasOrName) {
    return _runRepositoryCommand(['repo', 'set-default', aliasOrName]);
  }

  @override
  Future<String> setRepositoryPriority(String aliasOrName, int priority) {
    return _runRepositoryCommand([
      'repo',
      'set-priority',
      aliasOrName,
      priority.toString(),
    ]);
  }

  @override
  Future<String> setRepositoryMirror(
    String aliasOrName, {
    required bool enabled,
  }) {
    return _runRepositoryCommand([
      'repo',
      enabled ? 'enable-mirror' : 'disable-mirror',
      aliasOrName,
    ]);
  }

  @override
  Future<List<InstalledApp>> getInstalledApps({
    bool includeBaseService = false,
  }) {
    return _guardCommand('list', () async {
      final output = await _execute(
        includeBaseService
            ? ['list', '--json', '--type=all']
            : ['list', '--json'],
        timeout: kQueryTimeout,
      );

      if (!output.success) {
        throw _commandOutputException('list', output);
      }

      // list 全量输出是 CLI 最大的单体 JSON，且被运行进程页高频轮询；
      // 解析移入后台 isolate，避免主 isolate 周期性卡顿。
      final apps = await CliOutputParser.parseInstalledAppsInBackground(
        output.stdout,
      );

      // 过滤基础服务
      if (!includeBaseService) {
        // 与旧版 Rust 商店保持一致：默认仅展示 kind=app 的项目；
        // 若旧版/测试数据未携带 kind，则按普通应用兜底保留。
        return apps.where((app) => (app.kind ?? 'app') == 'app').toList();
      }

      return apps;
    });
  }

  @override
  Future<List<RunningApp>> getRunningApps() {
    return _guardCommand('ps', () async {
      final psOutput = await _execute(['--json', 'ps'], timeout: kQueryTimeout);

      if (!psOutput.success) {
        throw _commandOutputException('ps', psOutput);
      }

      final runningApps = CliOutputParser.parseRunningApps(psOutput.stdout);
      if (runningApps.isEmpty) {
        return const [];
      }

      // 与 Rust 版本保持一致：使用 list --json --type=all 的批量详情补齐
      // 版本、架构、渠道和来源，避免为每个进程额外执行一次外部命令。
      // 快照按短 TTL 复用，避免 3 秒轮询反复全量执行 list。
      final installedApps = await _installedAppsForRunningPanel();
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
    });
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

    // 从 CliExecutor 的静态进程表读取该任务的 root ll-cli 进程 PID。
    //
    // 关键：必须用 CliExecutor 静态表，而非本实例的 _activeProcessPids。
    // 因为本 repository 所在的 provider 是 autoDispose，安装期间实例可能被
    // 销毁重建，导致实例字段丢失 PID。CliExecutor 的 _activeProcesses 是静态
    // 字段，且其清理绑定在进程真实退出（exitCode 回调）而非 stream 生命周期，
    // 只要 root ll-cli 进程还在跑，PID 就可查（详见 cli_executor.dart 注释）。
    final pid = CliExecutor.getProcessPid(processId);
    if (pid == null) {
      // PID 缺失：进程已真实退出（exitCode 回调已清理）或从未注册。
      // 视为取消失败，由上层 cancelTask 保持任务为 Installing（见 2026-05-31 约定）。
      AppLogger.warning(
        '[LinglongCli] 取消$operationLabel失败：未找到进程 PID（进程可能已结束）: $appId',
      );
      return false;
    }

    final success = await _cancelWithSystemKill(
      processId,
      pid: pid,
      force: true,
    );

    if (success) {
      // 只有系统级 kill 确认成功后，安装流才允许切换为 cancelled。
      _setOperationCancelled(appId);
      AppLogger.info('[LinglongCli] 取消$operationLabel成功: $appId');
    } else {
      AppLogger.warning(
        '[LinglongCli] 取消$operationLabel返回 false（系统级进程终止未成功）: $appId',
      );
    }

    return success;
  }

  @override
  Stream<InstallProgress> updateApp(String appId) async* {
    yield* _runInstallLikeOperation(appId, kind: InstallTaskKind.update);
  }

  @override
  Future<void> uninstallApp(String appId, String? version) {
    // version 为空时只传 appId，交由 ll-cli 自行解析目标（应用详情页头部
    // “整体卸载”场景）；version 非空时按 appId/version 精确卸载指定版本
    // （应用详情页历史版本列表场景）。ll-cli uninstall 会把 APP 解析为
    // FuzzyReference，两种形式均受支持。
    final hasVersion = version != null && version.isNotEmpty;
    final target = hasVersion ? '$appId/$version' : appId;

    return _guardCommand('uninstall', () async {
      AppLogger.info('[LinglongCli] 卸载应用: $target');

      final output = await _execute([
        'uninstall',
        target,
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        AppLogger.info('[LinglongCli] 卸载成功: $appId');
        // 卸载确定改变已装集合，立即失效进程面板快照
        _invalidateRunningPanelSnapshot();
        return;
      }

      throw _commandOutputException('uninstall', output);
    });
  }

  @override
  Future<void> runApp(String appId) {
    return _guardCommand('run', () async {
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
    });
  }

  @override
  Future<void> killApp(String appName) {
    return _guardCommand('kill', () async {
      AppLogger.info('[LinglongCli] 终止应用: $appName');

      CliOutput? lastOutput;
      for (var attempt = 1; attempt <= 5; attempt++) {
        final runningApps = await getRunningApps();
        final isStillRunning = runningApps.any((app) => app.appId == appName);
        if (!isStillRunning) {
          return;
        }

        lastOutput = await _execute([
          'kill',
          '-s',
          '9',
          appName,
        ], timeout: const Duration(seconds: 10));

        if (!lastOutput.success && attempt == 5) {
          throw _commandOutputException('kill', lastOutput);
        }

        if (attempt < 5) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }

      final runningApps = await getRunningApps();
      if (runningApps.any((app) => app.appId == appName)) {
        throw LinglongCliException(
          LinglongCliFailure(
            kind: LinglongCliFailureKind.commandFailed,
            command: 'kill',
            diagnostic: lastOutput?.primaryMessage.isNotEmpty == true
                ? lastOutput!.primaryMessage
                : 'Target process is still running after kill attempts',
            exitCode: lastOutput?.exitCode,
          ),
        );
      }
    });
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
  /// 3. $XDG_CONFIG_HOME/user-dirs.dirs 配置文件
  /// 4. 默认 ~/Desktop
  Future<String> _getDesktopDirectory() async {
    final home = Platform.environment['HOME'];

    // 优先级1: XDG_DESKTOP_DIR 环境变量
    final xdgDesktop = Platform.environment['XDG_DESKTOP_DIR'];
    if (xdgDesktop != null && xdgDesktop.isNotEmpty) {
      final resolvedPath = _expandHome(xdgDesktop, home);
      if (_isUsableDesktopPath(resolvedPath)) {
        AppLogger.debug('[LinglongCli] 使用 XDG_DESKTOP_DIR: $resolvedPath');
        return resolvedPath;
      }
    }

    // 优先级2: 通过 xdg-user-dir 命令获取
    try {
      final result = await Process.run('xdg-user-dir', ['DESKTOP']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (_isUsableDesktopPath(path)) {
          AppLogger.debug('[LinglongCli] 使用 xdg-user-dir: $path');
          return path;
        }
      }
    } catch (e) {
      AppLogger.debug('[LinglongCli] xdg-user-dir 命令不可用: $e');
    }

    // 优先级3: 按 XDG Base Directory 规范解析 user-dirs.dirs。
    try {
      if (home != null && home.isNotEmpty) {
        final configuredRoot = Platform.environment['XDG_CONFIG_HOME'];
        final configRoot =
            configuredRoot != null && configuredRoot.startsWith('/')
            ? _expandHome(configuredRoot, home)
            : '$home/.config';
        final userDirsFile = File('$configRoot/user-dirs.dirs');
        if (await userDirsFile.exists()) {
          final content = await userDirsFile.readAsString();
          final match = RegExp(
            r'XDG_DESKTOP_DIR="([^"]+)"',
          ).firstMatch(content);
          if (match != null) {
            final rawPath = match.group(1)!;
            final path = _expandHome(rawPath, home);
            if (_isUsableDesktopPath(path)) {
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
    if (home == null || home.isEmpty) {
      throw const FileSystemException(
        'HOME is unavailable while resolving the XDG desktop directory',
      );
    }
    final fallbackPath = '$home/Desktop';
    AppLogger.debug('[LinglongCli] 使用 fallback 路径: $fallbackPath');
    return fallbackPath;
  }

  /// XDG 用户目录必须是绝对路径，并拒绝把文件直接写入根目录。
  bool _isUsableDesktopPath(String path) {
    return path.startsWith('/') && path != '/';
  }

  /// 展开 user-dirs.dirs 允许使用的 HOME 表达式。
  String _expandHome(String path, String? home) {
    if (home == null || home.isEmpty) {
      return path;
    }
    return path
        .replaceAll(r'\$HOME', home)
        .replaceAll(r'$HOME', home)
        .replaceFirst(RegExp(r'^~(?=/|$)'), home);
  }

  @override
  Future<DesktopShortcutResult> createDesktopShortcut(String appId) {
    return _guardCommand('create-desktop-shortcut', () async {
      AppLogger.info('[LinglongCli] 创建桌面快捷方式: $appId');

      // 1. 检查应用是否已安装
      final installedApps = await getInstalledApps();
      final isInstalled = installedApps.any((app) => app.appId == appId);
      if (!isInstalled) {
        throw LinglongCliException(
          LinglongCliFailure(
            kind: LinglongCliFailureKind.commandFailed,
            command: 'create-desktop-shortcut',
            diagnostic: 'Application is not installed: $appId',
          ),
        );
      }

      // 2. 使用 ll-cli content 获取应用导出的文件列表
      final output = await _execute([
        'content',
        appId,
      ], timeout: const Duration(seconds: 10));

      if (!output.success) {
        throw _commandOutputException('content', output);
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
        throw LinglongCliException(
          LinglongCliFailure(
            kind: LinglongCliFailureKind.invalidOutput,
            command: 'content',
            diagnostic: 'No exported desktop file found for $appId',
          ),
        );
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
        return DesktopShortcutResult(
          path: targetPath,
          disposition: DesktopShortcutDisposition.alreadyExists,
        );
      }

      // 8. 复制 .desktop 文件到桌面
      final sourceFile = File(desktopSource);
      if (!await sourceFile.exists()) {
        throw FileSystemException(
          'Exported desktop file does not exist',
          desktopSource,
        );
      }
      await sourceFile.copy(targetPath);

      // 9. 设置可执行权限 (0o755)
      final chmodResult = await Process.run('chmod', ['755', targetPath]);
      if (chmodResult.exitCode != 0) {
        final diagnostic = chmodResult.stderr.toString().trim();
        throw FileSystemException(
          diagnostic.isEmpty
              ? 'Failed to mark desktop file as executable'
              : diagnostic,
          targetPath,
        );
      }

      AppLogger.info('[LinglongCli] 桌面快捷方式创建成功: $appId -> $targetPath');

      return DesktopShortcutResult(
        path: targetPath,
        disposition: DesktopShortcutDisposition.created,
      );
    });
  }

  @override
  Future<List<InstalledApp>> searchVersions(String appId) {
    return _guardCommand('search', () async {
      final output = await _execute([
        'search',
        appId,
        '--json',
      ], timeout: kQueryTimeout);

      if (!output.success) {
        throw _commandOutputException('search', output);
      }

      return CliOutputParser.parseSearchResults(output.stdout);
    });
  }

  @override
  Future<void> pruneApps() {
    return _guardCommand('prune', () async {
      AppLogger.info('[LinglongCli] 开始清理废弃服务');

      final output = await _execute([
        'prune',
      ], timeout: const Duration(minutes: 5));

      if (output.success) {
        // 清理废弃服务同样改变已装集合，失效进程面板快照
        _invalidateRunningPanelSnapshot();
        return;
      }

      throw _commandOutputException('prune', output);
    });
  }

  @override
  Future<String> getLlCliVersion() {
    return _guardCommand('version', () async {
      final output = await _execute([
        '--version',
      ], timeout: const Duration(seconds: 5));

      if (!output.success) {
        throw _commandOutputException('version', output);
      }

      final version = output.stdout.trim();
      if (version.isEmpty) {
        throw const FormatException('ll-cli version output is empty');
      }
      return version;
    });
  }
}
