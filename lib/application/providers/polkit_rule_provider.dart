/// 设置页免密安装开关的唯一控制器（docs/50 §4、§5.2）。
///
/// 本 Provider 是本地缓存、单飞约束、UI 状态与结果保存的唯一所有者：
/// - Presentation 只发送目标值并观察状态，不执行文件、进程或偏好写入；
/// - 页面不可见时操作仍正确收尾并更新缓存（keepAlive）；
/// - 普通进入页面只读取内存偏好，不访问受限目录、不调用 pkexec、不做同步 IO。
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/polkit_rule_state.dart';
import '../services/polkit_rule_service.dart';
import 'application_dependency_providers.dart';
import 'install_queue_provider.dart';

part 'polkit_rule_provider.freezed.dart';
part 'polkit_rule_provider.g.dart';

/// 免密安装规则同步服务。
///
/// 与其它 Application 服务一致，装配声明与使用它的控制器放在同一文件；
/// 外部依赖端口仍集中在 `application_dependency_providers.dart`。
final polkitRuleServiceProvider = Provider<PolkitRuleService>((ref) {
  return PolkitRuleService(gateway: ref.watch(polkitRuleGatewayProvider));
});

/// 免密开关事务阶段。
enum PasswordFreeInstallPhase {
  /// 空闲：开关可交互。
  ready,

  /// 等待用户确认开启风险（仅开启方向经过此阶段）。
  confirming,

  /// 授权、同步与修改进行中：开关禁用并显示 loading。
  applying,
}

/// 一次用户操作的结果反馈，Presentation 据此选择本地化文案。
enum PasswordFreeInstallFeedback {
  /// 没有产生任何反馈（重复请求被单飞拦截）。
  none,

  /// 已开启安装免密。
  enabled,

  /// 已关闭本功能的免密设置。
  disabled,

  /// 用户取消了系统授权，未修改设置。
  authorizationCancelled,

  /// 授权组件或系统授权不可用。
  authorizationUnavailable,

  /// 固定路径与本功能模板冲突，未做修改。
  ruleConflict,

  /// 当前环境不支持修改规则。
  unsupported,

  /// 系统状态已确认，但本地记录保存失败。
  cacheSaveFailed,

  /// 操作失败，附可复制诊断摘要。
  failed,
}

/// 免密安装开关的界面状态。
@freezed
sealed class PasswordFreeInstallState with _$PasswordFreeInstallState {
  const PasswordFreeInstallState._();

  /// 创建状态。
  const factory PasswordFreeInstallState({
    /// 事务阶段。
    @Default(PasswordFreeInstallPhase.ready) PasswordFreeInstallPhase phase,

    /// 最近一次由特权操作确认的配置；没有缓存时为关闭。
    @Default(false) bool enabled,

    /// 上一次修改尚未获得可靠结果，或结果未能完整写回缓存。
    @Default(false) bool needsSync,

    /// 最近一次失败类型；用于错误详情展示。
    PolkitRuleFailureKind? lastFailureKind,

    /// 最近一次失败的诊断摘要；用于可复制错误详情。
    String? lastDiagnostic,
  }) = _PasswordFreeInstallState;

  /// 是否允许安装任务走普通 CLI（已确认开启且没有待同步标记）。
  bool get usesPasswordFreeCli => enabled && !needsSync;

  /// 开关当前是否可交互。
  bool get isInteractive => phase == PasswordFreeInstallPhase.ready;
}

/// 免密安装开关控制器。
@Riverpod(keepAlive: true)
class PolkitRule extends _$PolkitRule {
  /// 单飞锁：覆盖确认、授权、修改、回读和缓存保存（§5.2）。
  bool _inFlight = false;

  @override
  PasswordFreeInstallState build() {
    final cache = _loadCache();
    return PasswordFreeInstallState(
      enabled: cache.enabled,
      needsSync: cache.needsSync,
    );
  }

  /// 进入开启确认阶段。
  ///
  /// 返回 true 表示调用方可以展示风险确认框；返回 false 表示已有事务在飞行中
  /// 或状态不可交互，调用方必须直接放弃，避免重复确认框和重复提权。
  bool beginEnableRequest() {
    if (_inFlight || state.phase != PasswordFreeInstallPhase.ready) {
      AppLogger.info('[PolkitRule] 忽略重复的开启请求: phase=${state.phase.name}');
      return false;
    }
    state = state.copyWith(
      phase: PasswordFreeInstallPhase.confirming,
      lastFailureKind: null,
      lastDiagnostic: null,
    );
    return true;
  }

  /// 用户在风险确认框选择“保持原设置”或关闭确认框。
  void cancelEnableRequest() {
    if (state.phase != PasswordFreeInstallPhase.confirming) {
      return;
    }
    state = state.copyWith(phase: PasswordFreeInstallPhase.ready);
  }

  /// 按用户点击时固定的目标值执行一次提权同步与修改。
  ///
  /// 开启方向必须先经过 [beginEnableRequest]；关闭方向无需再次风险确认。
  Future<PasswordFreeInstallFeedback> applyTarget({
    required bool enabled,
  }) async {
    if (_inFlight) {
      AppLogger.info('[PolkitRule] 忽略重复的设置请求');
      return PasswordFreeInstallFeedback.none;
    }
    if (enabled && state.phase != PasswordFreeInstallPhase.confirming) {
      AppLogger.warning('[PolkitRule] 未经过风险确认，拒绝开启请求');
      return PasswordFreeInstallFeedback.none;
    }

    _inFlight = true;
    // 操作前缓存快照：授权取消或组件不可用时原样恢复，包括原有的待同步标记。
    final snapshot = PasswordFreeInstallCache(
      enabled: state.enabled,
      needsSync: state.needsSync,
    );
    state = state.copyWith(
      phase: PasswordFreeInstallPhase.applying,
      lastFailureKind: null,
      lastDiagnostic: null,
    );

    // 设置事务期间暂缓新安装任务出队：避免一边同步系统规则一边启动另一轮
    // 安装授权；进行中的任务不受影响（§7.1）。
    final queue = ref.read(installQueueProvider.notifier);
    queue.pauseDequeueForSettings();
    try {
      // §4.3 第 2 步：先落盘待同步标记，写入失败则不启动修改。
      final marked = await _writeCache(
        PasswordFreeInstallCache(enabled: snapshot.enabled, needsSync: true),
      );
      if (!marked) {
        state = state.copyWith(
          phase: PasswordFreeInstallPhase.ready,
          lastFailureKind: PolkitRuleFailureKind.unexpected,
          lastDiagnostic: '本地待同步标记写入失败，未启动系统修改',
        );
        return PasswordFreeInstallFeedback.failed;
      }

      final fact = await ref
          .read(polkitRuleServiceProvider)
          .synchronize(enabled: enabled);
      return await _applyFact(fact, requested: enabled, snapshot: snapshot);
    } catch (error, stackTrace) {
      // 兜底：服务层已归约所有同步异常，这里只可能是装配缺失等意外错误。
      // 必须把阶段恢复为 ready 并标记待同步，避免开关永久卡在不可交互状态。
      AppLogger.error('[PolkitRule] 设置事务异常', error, stackTrace);
      state = state.copyWith(
        phase: PasswordFreeInstallPhase.ready,
        enabled: snapshot.enabled,
        // 提权前已把待同步标记落盘，这里让内存状态与缓存保持一致。
        needsSync: true,
        lastFailureKind: PolkitRuleFailureKind.unexpected,
        lastDiagnostic: error.toString(),
      );
      return PasswordFreeInstallFeedback.failed;
    } finally {
      _inFlight = false;
      queue.resumeDequeueForSettings();
    }
  }

  /// 把同步事实归约为界面状态与缓存写入。
  Future<PasswordFreeInstallFeedback> _applyFact(
    PolkitRuleSyncFact fact, {
    required bool requested,
    required PasswordFreeInstallCache snapshot,
  }) async {
    switch (fact) {
      case PolkitRuleSyncCompleted(:final result):
        return _applyCompletedResult(
          result,
          requested: requested,
          snapshot: snapshot,
        );
      case PolkitRuleSyncFailed(:final kind, :final diagnostic):
        return _applyFailure(
          kind: kind,
          diagnostic: diagnostic,
          snapshot: snapshot,
        );
    }
  }

  Future<PasswordFreeInstallFeedback> _applyCompletedResult(
    PolkitRuleTransactionResult result, {
    required bool requested,
    required PasswordFreeInstallCache snapshot,
  }) async {
    // 正常成功：结论为 applied/unchanged 且回读状态等于用户目标。
    if (result.matchesRequestedTarget) {
      return _commit(
        enabled: requested,
        needsSync: false,
        feedback: requested
            ? PasswordFreeInstallFeedback.enabled
            : PasswordFreeInstallFeedback.disabled,
      );
    }

    // 冲突：不覆盖管理员文件，保留最近可靠值并标记待同步。
    if (result.outcome == PolkitRuleOutcome.conflict) {
      return _commit(
        enabled: snapshot.enabled,
        needsSync: true,
        feedback: PasswordFreeInstallFeedback.ruleConflict,
        failureKind: PolkitRuleFailureKind.ruleConflict,
        diagnostic: '固定路径与本功能模板冲突（before=${result.before.name}）',
      );
    }

    // 写入/删除失败但回读成功：保存实际状态，同时说明目标未完成。
    //
    // 回读到确定状态说明缓存已经与系统一致（§4.1 对 needsSync 的定义是“尚未
    // 获得可靠结果或结果未能写回缓存”），因此此时清除待同步标记；只有回读失败
    // （after=unknown）才保留标记（§4.3 第 7 步、§6.3 表格）。
    final determined =
        result.after == PolkitRuleSystemState.enabled ||
        result.after == PolkitRuleSystemState.disabled;
    return _commit(
      enabled: determined
          ? result.after == PolkitRuleSystemState.enabled
          : snapshot.enabled,
      needsSync: !determined,
      feedback: PasswordFreeInstallFeedback.failed,
      failureKind: PolkitRuleFailureKind.applyFailed,
      diagnostic:
          '系统规则未按目标完成（outcome=${result.outcome.name}, '
          'after=${result.after.name}, reason=${result.reason.name}）',
    );
  }

  Future<PasswordFreeInstallFeedback> _applyFailure({
    required PolkitRuleFailureKind kind,
    required String diagnostic,
    required PasswordFreeInstallCache snapshot,
  }) async {
    switch (kind) {
      case PolkitRuleFailureKind.authorizationCancelled:
        // 用户取消授权：系统尚未被修改，恢复操作前的缓存与待同步标记。
        return _restoreSnapshot(
          snapshot,
          feedback: PasswordFreeInstallFeedback.authorizationCancelled,
          failureKind: kind,
          diagnostic: diagnostic,
        );
      case PolkitRuleFailureKind.authorizationUnavailable:
        // 授权组件不可用：root 操作未启动，保留最近状态。
        return _restoreSnapshot(
          snapshot,
          feedback: PasswordFreeInstallFeedback.authorizationUnavailable,
          failureKind: kind,
          diagnostic: diagnostic,
        );
      case PolkitRuleFailureKind.unsupportedEnvironment:
        return _commit(
          enabled: snapshot.enabled,
          needsSync: true,
          feedback: PasswordFreeInstallFeedback.unsupported,
          failureKind: kind,
          diagnostic: diagnostic,
        );
      default:
        // 超时、格式错误、回读失败：保留最近可靠值并标记待同步，
        // 不显示操作成功。
        return _commit(
          enabled: snapshot.enabled,
          needsSync: true,
          feedback: PasswordFreeInstallFeedback.failed,
          failureKind: kind,
          diagnostic: diagnostic,
        );
    }
  }

  Future<PasswordFreeInstallFeedback> _restoreSnapshot(
    PasswordFreeInstallCache snapshot, {
    required PasswordFreeInstallFeedback feedback,
    required PolkitRuleFailureKind failureKind,
    required String diagnostic,
  }) {
    return _commit(
      enabled: snapshot.enabled,
      needsSync: snapshot.needsSync,
      feedback: feedback,
      failureKind: failureKind,
      diagnostic: diagnostic,
    );
  }

  /// 落定界面状态并持久化缓存。
  ///
  /// 系统状态已确认但本地保存失败时，界面显示真实值并提示未保存，不回滚系统，
  /// 也不为修复缓存再弹授权框（§4.4）。
  Future<PasswordFreeInstallFeedback> _commit({
    required bool enabled,
    required bool needsSync,
    required PasswordFreeInstallFeedback feedback,
    PolkitRuleFailureKind? failureKind,
    String? diagnostic,
  }) async {
    state = state.copyWith(
      phase: PasswordFreeInstallPhase.ready,
      enabled: enabled,
      needsSync: needsSync,
      lastFailureKind: failureKind,
      lastDiagnostic: diagnostic,
    );
    final saved = await _writeCache(
      PasswordFreeInstallCache(enabled: enabled, needsSync: needsSync),
    );
    if (!saved &&
        (feedback == PasswordFreeInstallFeedback.enabled ||
            feedback == PasswordFreeInstallFeedback.disabled)) {
      AppLogger.warning('[PolkitRule] 系统状态已确认，但本地缓存保存失败');
      return PasswordFreeInstallFeedback.cacheSaveFailed;
    }
    return feedback;
  }

  /// 读取本地缓存。
  ///
  /// 只访问已初始化的内存偏好：不遍历受限目录、不调用 pkexec、不做同步文件 IO。
  PasswordFreeInstallCache _loadCache() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final raw = prefs.getString(PasswordFreeInstallCache.preferencesKey);
      final parsed = PasswordFreeInstallCache.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
      // 键不存在：默认关闭；解析失败或版本不支持：关闭显示并标记待同步，
      // 且不据此创建、删除任何系统文件。
      return raw == null
          ? PasswordFreeInstallCache.defaults
          : const PasswordFreeInstallCache(enabled: false, needsSync: true);
    } catch (error, stackTrace) {
      AppLogger.error('[PolkitRule] 读取免密安装本地缓存失败', error, stackTrace);
      return const PasswordFreeInstallCache(enabled: false, needsSync: true);
    }
  }

  /// 写入本地缓存；必须检查 SharedPreferences 的写入结果。
  Future<bool> _writeCache(PasswordFreeInstallCache cache) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = await prefs.setString(
        PasswordFreeInstallCache.preferencesKey,
        jsonEncode(cache.toJson()),
      );
      if (!saved) {
        AppLogger.warning('[PolkitRule] 本地缓存写入返回失败: $cache');
      }
      return saved;
    } catch (error, stackTrace) {
      AppLogger.error('[PolkitRule] 本地缓存写入异常', error, stackTrace);
      return false;
    }
  }
}
