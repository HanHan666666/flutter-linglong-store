import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/linglong_cli_repository.dart';

/// 已安装列表差量检测上报服务（对齐旧版 Electron 的统计模型）。
///
/// 旧版客户端不在安装回调里上报统计，而是周期性执行 `ll-cli list` 并与
/// 内存快照做差量对比：任何途径（含商店外命令行）的安装/卸载都会被捕获，
/// 应用更新天然表现为「旧版本移除 + 新版本新增」。本服务复刻该模型：
///
/// - 启动首轮快照为空，全量已安装列表作为基线 `addedItems` 上报一次；
/// - 之后每轮按 `appId + version` 对比，差量非空才上报；
/// - 窗口隐藏/最小化时暂停轮询（本地命令也不执行），恢复可见立即补检；
/// - 商店内安装/卸载完成后由同步服务触发立即检测，不必等待下一轮轮询。
///
/// 轮询间隔从旧版的 3 秒放宽到 30 秒：商店内操作走立即检测路径，外部
/// 安装最多延迟一个轮询周期被发现，统计不丢事件，本地开销可控。
class InstalledAppDiffReportService with WidgetsBindingObserver {
  /// 创建差量检测服务；调用方随后必须调用 [start]。
  InstalledAppDiffReportService({
    required LinglongCliRepository cliRepository,
    required AnalyticsRepository analyticsRepository,
    Duration pollInterval = const Duration(seconds: 30),
    Duration debounceDelay = const Duration(milliseconds: 500),
  }) : _cliRepository = cliRepository,
       _analyticsRepository = analyticsRepository,
       _pollInterval = pollInterval,
       _debounceDelay = debounceDelay;

  final LinglongCliRepository _cliRepository;
  final AnalyticsRepository _analyticsRepository;
  final Duration _pollInterval;

  /// 立即检测的防抖间隔，用于合并操作完成后的连续触发并避开同步链路
  /// 正在执行的 ll-cli 调用。
  final Duration _debounceDelay;

  /// 上一次检测的系统快照；启动首轮为空列表，全量结果即基线上报。
  List<InstalledApp> _snapshot = const [];

  Timer? _pollTimer;
  Timer? _debounceTimer;
  bool _started = false;
  bool _isChecking = false;

  /// Linux 桌面最小化进入 inactive/hidden，resumed 即窗口恢复可见。
  bool _isLifecycleVisible = true;

  /// 启动差量检测：注册生命周期监听、执行首轮基线检测并开始自续期轮询。
  ///
  /// 重复调用是安全的（幂等），供启动流程多次读取同一 Provider 时兜底。
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    scheduleImmediateCheck();
    _scheduleNextPoll();
  }

  /// 停止检测并释放资源；服务与进程同生命周期，正常情况下无需调用。
  @mustCallSuper
  void dispose() {
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (visible == _isLifecycleVisible) {
      return;
    }
    _isLifecycleVisible = visible;
    if (visible) {
      // 恢复可见时立即补检一次，捕获最小化期间通过外部途径发生的变化，
      // 随后恢复正常轮询节奏。
      scheduleImmediateCheck();
      _scheduleNextPoll();
    } else {
      // 窗口隐藏期间暂停一切检测，本地 ll-cli 调用也不执行。
      _cancelTimers();
    }
  }

  /// 请求立即检测（500ms 防抖合并连续触发）。
  ///
  /// 供安装/卸载完成后的同步链路调用，对齐旧版的 reflushInstalledItemsImmediate。
  void scheduleImmediateCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _check);
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    if (!_started || !_isLifecycleVisible) {
      return;
    }
    // 自续期单发 Timer：上一轮检测彻底结束后才排定下一轮，天然避免重叠。
    _pollTimer = Timer(_pollInterval, () async {
      await _check();
      if (_started) {
        _scheduleNextPoll();
      }
    });
  }

  void _cancelTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _check() async {
    // 上一轮未结束时跳过本轮，下一轮轮询或下次立即触发会重新对比。
    if (!_started || _isChecking) {
      return;
    }
    _isChecking = true;
    try {
      // 必须取全量列表（含 runtime 组件）：差量口径对齐旧版 --type=all，
      // 不能复用会按设置过滤基础服务的列表 Provider。
      final current = await _cliRepository.getInstalledApps(
        includeBaseService: true,
      );
      final previousKeys = _snapshot.map(_identityKey).toSet();
      final currentKeys = current.map(_identityKey).toSet();
      final added = current
          .where((app) => !previousKeys.contains(_identityKey(app)))
          .toList();
      final removed = _snapshot
          .where((app) => !currentKeys.contains(_identityKey(app)))
          .toList();
      // 快照先落位：即使上报失败也不回滚，避免下轮重复上报同一差量。
      _snapshot = current;
      if (added.isEmpty && removed.isEmpty) {
        return;
      }
      await _analyticsRepository.reportInstalledAppsDiff(
        addedItems: added,
        removedItems: removed,
      );
    } catch (error, stackTrace) {
      // ll-cli 执行异常时保留旧快照，本轮差量顺延到下一次检测。
      AppLogger.warning('[installed-diff] 已安装列表差量检测失败', error, stackTrace);
    } finally {
      _isChecking = false;
    }
  }

  /// 差量身份键：appId + version，对齐旧版 Electron 的对比口径，
  /// 因此更新（同 appId 新版本）会表现为旧版本移除、新版本新增。
  String _identityKey(InstalledApp app) => '${app.appId}@${app.version}';
}
