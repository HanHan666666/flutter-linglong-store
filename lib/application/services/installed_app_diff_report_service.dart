import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/preferences_service.dart';
import '../../domain/models/installed_app.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/linglong_cli_repository.dart';

/// 已安装列表差量检测上报服务。
///
/// 通过周期性执行 `ll-cli list` 并与持久化基线做差量对比，捕获任何途径
/// （商店内、命令行等）的安装/卸载变化。应用更新天然表现为「旧版本
/// 移除 + 新版本新增」。
///
/// - 基线持久化：上一次检测的完整应用列表（含 arch/module/channel 等
///   服务端匹配字段）序列化写入本地存储，重启后只上报与上轮的差值，
///   避免每次启动都全量基线上报导致服务端 `installCount` 重复计数；
/// - 持久化完整对象而非仅 `appId@version`：重启后捕获的卸载记录
///   `removedItems` 字段完整，服务端主表按非空字段匹配不会失败；
/// - 首次运行（无历史基线）仍做一次全量基线上报，用于初始化统计；
/// - 之后每轮按 `appId + version` 对比，差量非空才上报；
/// - 窗口隐藏/最小化时暂停轮询（本地命令也不执行），恢复可见立即补检；
/// - 商店内安装/卸载完成后由同步服务触发立即检测，不必等待下一轮轮询。
///
/// 轮询间隔 30 秒：商店内操作走立即检测路径，外部安装最多延迟一个轮询
/// 周期被发现，统计不丢事件，本地开销可控。
class InstalledAppDiffReportService with WidgetsBindingObserver {
  /// 本地存储中基线对象列表的存储键名。
  static const _kBaselineStorageKey = 'installed_diff_baseline_objects';

  /// 创建差量检测服务；调用方随后必须调用 [start]。
  ///
  /// [baselineLoader] / [baselineSaver] 可选注入，用于测试替换存储实现；
  /// 缺省时使用 [PreferencesService] 持久化差量基线。
  InstalledAppDiffReportService({
    required LinglongCliRepository cliRepository,
    required AnalyticsRepository analyticsRepository,
    Duration pollInterval = const Duration(seconds: 30),
    Duration debounceDelay = const Duration(milliseconds: 500),
    Future<List<InstalledApp>?> Function()? baselineLoader,
    Future<void> Function(List<InstalledApp>)? baselineSaver,
  }) : _cliRepository = cliRepository,
       _analyticsRepository = analyticsRepository,
       _pollInterval = pollInterval,
       _debounceDelay = debounceDelay,
       _baselineLoader = baselineLoader ?? defaultBaselineLoader,
       _baselineSaver = baselineSaver ?? defaultBaselineSaver;

  final LinglongCliRepository _cliRepository;
  final AnalyticsRepository _analyticsRepository;
  final Duration _pollInterval;

  /// 立即检测的防抖间隔，用于合并操作完成后的连续触发并避开同步链路
  /// 正在执行的 ll-cli 调用。
  final Duration _debounceDelay;

  /// 持久化基线加载器：返回上次存储的完整应用列表，无历史时返回 null。
  final Future<List<InstalledApp>?> Function() _baselineLoader;

  /// 持久化基线写入器：将本轮完整应用列表写入本地存储。
  final Future<void> Function(List<InstalledApp>) _baselineSaver;

  /// 上一次检测的系统快照（完整 InstalledApp，用于 diff 和上报字段填充）。
  List<InstalledApp> _snapshot = const [];

  /// 基线加载 Future，懒加载且只加载一次。
  ///
  /// 首次检测开始时触发加载，所有并发/后续检测都 await 同一个 Future，
  /// 确保基线就绪前不会产生不准确的差量。
  Future<void>? _baselineLoadFuture;

  /// 基线是否已加载完成（用于快速判断，不必每次 await）。
  bool _baselineLoaded = false;

  Timer? _pollTimer;
  Timer? _debounceTimer;
  bool _started = false;
  bool _isChecking = false;

  /// 默认基线加载实现：从 SharedPreferences 读取 JSON 对象列表并还原。
  ///
  /// 逐条容错：单个条目反序列化失败只跳过该条，不整批丢弃基线，
  /// 避免一条脏数据导致重启后丢失全部历史基线。
  @visibleForTesting
  static Future<List<InstalledApp>?> defaultBaselineLoader() async {
    final rawList = PreferencesService.getStringList(_kBaselineStorageKey);
    if (rawList == null || rawList.isEmpty) {
      return null;
    }
    final restored = <InstalledApp>[];
    for (final raw in rawList) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          restored.add(InstalledApp.fromJson(json));
        }
      } catch (_) {
        // 忽略单条损坏数据，其余条目继续还原。
      }
    }
    return restored.isEmpty ? null : restored;
  }

  /// 默认基线写入实现：将完整应用列表序列化为 JSON 字符串列表写入存储。
  @visibleForTesting
  static Future<void> defaultBaselineSaver(List<InstalledApp> apps) async {
    final rawList = apps.map((app) => jsonEncode(app.toJson())).toList();
    await PreferencesService.setStringList(_kBaselineStorageKey, rawList);
  }

  /// 用户体验计划开关：关闭时暂停一切检测（本地 ll-cli 调用也不执行）；
  /// 重新开启后立即补检并恢复轮询。基线在关闭期间保持不变，重开后按差值
  /// 上报（不会因开关切换而产生全量基线）。
  bool _reportingAllowed = true;

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
    if (_reportingAllowed) {
      scheduleImmediateCheck();
      _scheduleNextPoll();
    }
  }

  /// 停止检测并释放资源；服务与进程同生命周期，正常情况下无需调用。
  @mustCallSuper
  void dispose() {
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
  }

  /// 响应「用户体验计划」开关变化。
  ///
  /// 关闭：取消全部待执行检测，本地轮询命令也不执行；
  /// 重新开启：立即补检并恢复正常轮询节奏。
  void setReportingEnabled(bool enabled) {
    if (_reportingAllowed == enabled) {
      return;
    }
    _reportingAllowed = enabled;
    if (!enabled) {
      _cancelTimers();
    } else if (_started && _isLifecycleVisible) {
      scheduleImmediateCheck();
      _scheduleNextPoll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (visible == _isLifecycleVisible) {
      return;
    }
    _isLifecycleVisible = visible;
    if (visible && _reportingAllowed) {
      // 恢复可见时立即补检一次，捕获最小化期间通过外部途径发生的变化，
      // 随后恢复正常轮询节奏。
      scheduleImmediateCheck();
      _scheduleNextPoll();
    } else if (!visible) {
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
    if (!_started || !_isLifecycleVisible || !_reportingAllowed) {
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

  /// 确保持久化基线已加载；只加载一次，并发调用共享同一个 Future。
  Future<void> _ensureBaselineLoaded() async {
    if (_baselineLoaded) {
      return;
    }
    final future = _baselineLoadFuture ??= _loadBaseline();
    await future;
  }

  /// 从持久化存储加载历史基线作为内存快照。
  ///
  /// 基线保存完整 InstalledApp（含 arch/module/channel 等字段），
  /// 保证重启后捕获的卸载记录上报字段完整。无历史基线时快照保持空列表，
  /// 首轮检测产生全量基线上报（新设备首次运行）。
  Future<void> _loadBaseline() async {
    try {
      final baseline = await _baselineLoader();
      if (baseline != null && baseline.isNotEmpty) {
        _snapshot = baseline;
      }
      _baselineLoaded = true;
    } catch (error, stackTrace) {
      // 加载失败不清空已有快照（可能是默认空），本轮按现状对比，
      // 下一轮加载若成功会自动校正。失败不阻断检测，最多首轮差量偏多。
      AppLogger.warning(
        '[installed-diff] 持久化基线加载失败，使用空基线兜底',
        error,
        stackTrace,
      );
      _baselineLoaded = true;
    }
  }

  Future<void> _check() async {
    // 上一轮未结束时跳过本轮，下一轮轮询或下次立即触发会重新对比；
    // 用户体验计划已关闭时同样跳过（正在排队的防抖检测作废）。
    if (!_started || _isChecking || !_reportingAllowed) {
      return;
    }
    _isChecking = true;
    try {
      // 首轮检测前先加载持久化基线，避免重启后全量重新计数。
      // 基线加载极快（SharedPreferences 内存读），放在检测开头可保证
      // 所有入口（start / setReportingEnabled / 生命周期恢复）都一致等待。
      await _ensureBaselineLoaded();

      // 必须取全量列表（含 runtime 组件）：差量口径按 --type=all，
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

      // 异步持久化完整基线（含 arch/module/channel 等字段），重启后可继续
      // 正确对比。写入失败不影响本轮结果，下轮会重写。
      unawaited(
        _baselineSaver(current).catchError(
          (Object error, StackTrace stackTrace) {
            AppLogger.warning(
              '[installed-diff] 持久化基线写入失败',
              error,
              stackTrace,
            );
          },
        ),
      );

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

  /// 差量身份键：appId + version，
  /// 因此更新（同 appId 新版本）会表现为旧版本移除、新版本新增。
  String _identityKey(InstalledApp app) => '${app.appId}@${app.version}';
}
