import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repository_provider.dart';
import '../../core/logging/app_logger.dart';
import '../../core/protocol/og_protocol_request.dart';
import '../../domain/models/app_detail.dart';
import '../../domain/models/install_task.dart';
import 'app_operation_queue_provider.dart';
import 'launch_provider.dart';
import 'linglong_env_provider.dart';

/// og 协议安装事件类型。
///
/// 控制器只产出业务事件，不直接依赖 Flutter UI；根组件订阅后决定如何展示
/// 通知，从而避免 Application 层持有 BuildContext 或页面组件。
enum OgInstallEventType {
  /// 收到可识别的旧 og 协议请求。
  received,

  /// 请求已成功写入安装队列。
  enqueued,

  /// 请求格式不是当前客户端支持的 `og://appId`。
  invalid,

  /// 玲珑运行环境不可用，暂不允许自动安装。
  environmentUnavailable,

  /// 应用已在安装队列中，队列拒绝重复入队。
  duplicate,

  /// 应用详情加载失败，无法构造安装任务。
  detailFailed,
}

/// og 协议安装事件。
///
/// [appId] 与 [appName] 用于 UI 展示；[rawUrl] 和 [error] 保留诊断信息，
/// 便于日志、测试和后续通知中心呈现完整上下文。
class OgInstallEvent {
  const OgInstallEvent({
    required this.type,
    this.rawUrl,
    this.appId,
    this.appName,
    this.error,
  });

  /// 事件类型。
  final OgInstallEventType type;

  /// 浏览器传入的原始链接。
  final String? rawUrl;

  /// 从旧协议解析出的应用 ID。
  final String? appId;

  /// 详情接口返回的应用名称。
  final String? appName;

  /// 失败时的完整错误信息。
  final String? error;
}

/// 应用启动时注入的 og 协议链接列表。
///
/// 冷启动场景中 Linux runner 会把 `%u` 传给 Dart 入口，main 在初始化
/// ProviderScope 时覆盖该 Provider；已运行实例的链接则走 [SingleInstance]
/// 的 socket 流，不使用这里。
final initialOgProtocolUrlsProvider = Provider<List<String>>((ref) {
  return const [];
});

/// og 协议安装控制器 Provider。
///
/// 该 Provider 把协议入口接入现有仓储和安装队列：先等待启动流程完成，
/// 再加载应用详情，最后通过 [AppOperationQueueController] 入队安装。
final ogInstallControllerProvider = Provider<OgInstallController>((ref) {
  final controller = OgInstallController(
    isLaunchCompleted: () => ref.read(launchSequenceProvider).isCompleted,
    isLinglongEnvOk: () => ref.read(linglongEnvProvider).result?.isOk ?? false,
    loadAppDetail: (appId) {
      return ref.read(appRepositoryProvider).getAppDetail(appId);
    },
    enqueueInstall: (params) {
      return ref
          .read(appOperationQueueControllerProvider)
          .enqueueAppOperation(params);
    },
    logInfo: (message, error, stackTrace) {
      AppLogger.info(message, error, stackTrace);
    },
    logWarning: (message, error, stackTrace) {
      AppLogger.warning(message, error, stackTrace);
    },
    logError: (message, error, stackTrace) {
      AppLogger.error(message, error, stackTrace);
    },
  );

  ref.listen(launchSequenceProvider, (previous, next) {
    if (next.isCompleted && previous?.isCompleted != true) {
      unawaited(controller.processPending());
    }
  });

  ref.onDispose(controller.dispose);
  return controller;
});

/// og 协议安装控制器。
///
/// 该类是可测试的业务编排单元，不直接访问 Riverpod、UI 或 ll-cli。外层
/// Provider 注入启动状态、环境状态、详情仓储和安装队列入口，保证网页拉起
/// 安装与页面按钮安装最终落到同一个队列状态机。
class OgInstallController {
  OgInstallController({
    required bool Function() isLaunchCompleted,
    required bool Function() isLinglongEnvOk,
    required Future<AppDetail> Function(String appId) loadAppDetail,
    required String Function(EnqueueAppOperationParams params) enqueueInstall,
    void Function(OgInstallEvent event)? emitEvent,
    void Function(String message, Object? error, StackTrace? stackTrace)?
    logInfo,
    void Function(String message, Object? error, StackTrace? stackTrace)?
    logWarning,
    void Function(String message, Object? error, StackTrace? stackTrace)?
    logError,
  }) : _isLaunchCompleted = isLaunchCompleted,
       _isLinglongEnvOk = isLinglongEnvOk,
       _loadAppDetail = loadAppDetail,
       _enqueueInstall = enqueueInstall,
       _externalEmitEvent = emitEvent,
       _logInfo = logInfo ?? _noopLog,
       _logWarning = logWarning ?? _noopLog,
       _logError = logError ?? _noopLog;

  final bool Function() _isLaunchCompleted;
  final bool Function() _isLinglongEnvOk;
  final Future<AppDetail> Function(String appId) _loadAppDetail;
  final String Function(EnqueueAppOperationParams params) _enqueueInstall;
  final void Function(OgInstallEvent event)? _externalEmitEvent;
  final void Function(String message, Object? error, StackTrace? stackTrace)
  _logInfo;
  final void Function(String message, Object? error, StackTrace? stackTrace)
  _logWarning;
  final void Function(String message, Object? error, StackTrace? stackTrace)
  _logError;

  /// 等待启动流程或环境恢复后再处理的 og 请求队列。
  ///
  /// 使用 FIFO 是为了让用户连续点击网页安装时按触发顺序进入队列；真正的
  /// 单任务执行约束仍由现有安装队列负责。
  final Queue<OgProtocolRequest> _pendingRequests = Queue<OgProtocolRequest>();

  /// 当前待处理队列中的 appId 集合。
  ///
  /// 这里只去重尚未进入安装队列的请求，已经入队的重复判断继续交给
  /// `InstallQueue`，避免两套状态判定发生漂移。
  final Set<String> _pendingAppIds = <String>{};

  /// 事件流控制器。
  final StreamController<OgInstallEvent> _eventController =
      StreamController<OgInstallEvent>.broadcast();

  /// 是否正在顺序处理 pending 请求。
  bool _isProcessing = false;

  /// UI 层订阅的 og 安装事件流。
  Stream<OgInstallEvent> get events => _eventController.stream;

  /// 接收浏览器或单实例转发来的原始 URL。
  ///
  /// 非法链接会立即发出 [OgInstallEventType.invalid]，合法链接先进入本地
  /// pending 队列，再根据启动状态决定是否立即处理。
  void acceptRawUrl(String rawUrl) {
    final request = OgProtocolRequest.tryParse(rawUrl);
    if (request == null) {
      _logWarning('[OgInstall] Unsupported protocol url: $rawUrl', null, null);
      _emit(
        OgInstallEvent(
          type: OgInstallEventType.invalid,
          rawUrl: rawUrl,
          error: '仅支持 og://appId 形式的旧协议链接',
        ),
      );
      return;
    }

    if (!_pendingAppIds.add(request.appId)) {
      _emit(
        OgInstallEvent(
          type: OgInstallEventType.duplicate,
          rawUrl: request.rawUrl,
          appId: request.appId,
        ),
      );
      return;
    }

    _pendingRequests.add(request);
    _logInfo(
      '[OgInstall] Accepted og install request: ${request.appId}',
      null,
      null,
    );
    _emit(
      OgInstallEvent(
        type: OgInstallEventType.received,
        rawUrl: request.rawUrl,
        appId: request.appId,
      ),
    );

    unawaited(processPending());
  }

  /// 处理已缓存的 og 安装请求。
  ///
  /// 启动流程未完成时只保留请求，不提前触发网络或队列副作用；环境不可用时
  /// 也不入队，避免浏览器点击后产生一个注定失败的 ll-cli 安装任务。
  Future<void> processPending() async {
    if (_isProcessing || _pendingRequests.isEmpty) {
      return;
    }

    if (!_isLaunchCompleted()) {
      _logInfo(
        '[OgInstall] Launch sequence not completed, pending request kept',
        null,
        null,
      );
      return;
    }

    if (!_isLinglongEnvOk()) {
      final blockedRequest = _pendingRequests.first;
      _logWarning(
        '[OgInstall] Linglong environment unavailable, install blocked: '
        '${blockedRequest.appId}',
        null,
        null,
      );
      _emit(
        OgInstallEvent(
          type: OgInstallEventType.environmentUnavailable,
          rawUrl: blockedRequest.rawUrl,
          appId: blockedRequest.appId,
          error: '玲珑运行环境不可用，暂不能从网页自动安装',
        ),
      );
      return;
    }

    _isProcessing = true;
    try {
      while (_pendingRequests.isNotEmpty &&
          _isLaunchCompleted() &&
          _isLinglongEnvOk()) {
        final request = _pendingRequests.removeFirst();
        _pendingAppIds.remove(request.appId);
        await _enqueueRequest(request);
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 释放事件流资源。
  void dispose() {
    _eventController.close();
  }

  Future<void> _enqueueRequest(OgProtocolRequest request) async {
    try {
      final detail = await _loadAppDetail(request.appId);
      final appName = detail.name.trim().isEmpty ? detail.appId : detail.name;
      final taskId = _enqueueInstall(
        EnqueueAppOperationParams(
          kind: InstallTaskKind.install,
          appId: detail.appId,
          appName: appName,
          icon: detail.icon,
          version: null,
        ),
      );

      if (taskId.isEmpty) {
        _emit(
          OgInstallEvent(
            type: OgInstallEventType.duplicate,
            rawUrl: request.rawUrl,
            appId: detail.appId,
            appName: appName,
          ),
        );
        return;
      }

      _logInfo(
        '[OgInstall] Enqueued install task: $taskId ${detail.appId}',
        null,
        null,
      );
      _emit(
        OgInstallEvent(
          type: OgInstallEventType.enqueued,
          rawUrl: request.rawUrl,
          appId: detail.appId,
          appName: appName,
        ),
      );
    } catch (e, s) {
      _logError('[OgInstall] Failed to enqueue og install request', e, s);
      _emit(
        OgInstallEvent(
          type: OgInstallEventType.detailFailed,
          rawUrl: request.rawUrl,
          appId: request.appId,
          error: e.toString(),
        ),
      );
    }
  }

  void _emit(OgInstallEvent event) {
    _externalEmitEvent?.call(event);
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  static void _noopLog(String message, Object? error, StackTrace? stackTrace) {}
}
