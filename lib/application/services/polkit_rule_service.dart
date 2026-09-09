/// 免密安装规则同步服务（docs/50 §8）。
///
/// 只负责“调用 Gateway + 归约为 Application 事实 + 记录日志”：不写本地缓存、
/// 不碰界面状态，也不解释自由文本。这样同一次提权的结果只会被解释一次，
/// 控制器可以专注于缓存、单飞与结果保存。
library;

import '../../core/logging/app_logger.dart';
import '../../domain/models/polkit_rule_state.dart';
import '../../domain/repositories/polkit_rule_gateway.dart';

/// 一次同步归约出的事实。
sealed class PolkitRuleSyncFact {
  /// 创建同步事实。
  const PolkitRuleSyncFact();
}

/// 取得了可靠的系统回读状态。
final class PolkitRuleSyncCompleted extends PolkitRuleSyncFact {
  /// 创建“有可靠结果”的事实。
  const PolkitRuleSyncCompleted(this.result);

  /// root 侧结构化结果。
  final PolkitRuleTransactionResult result;

  /// 是否按用户目标完成（结论为 applied/unchanged 且 after 等于目标）。
  bool get matchesRequestedTarget => result.matchesRequestedTarget;
}

/// 未取得可靠结果，系统状态未知或操作未启动。
final class PolkitRuleSyncFailed extends PolkitRuleSyncFact {
  /// 创建“无可靠结果”的事实。
  const PolkitRuleSyncFailed({required this.kind, required this.diagnostic});

  /// 稳定失败类型。
  final PolkitRuleFailureKind kind;

  /// 未经本地化的底层诊断。
  final String diagnostic;
}

/// 免密安装规则的提权同步服务。
class PolkitRuleService {
  /// 创建服务。
  const PolkitRuleService({required PolkitRuleGateway gateway})
    : _gateway = gateway;

  final PolkitRuleGateway _gateway;

  /// 按目标值执行一次提权同步。
  ///
  /// [enabled] 是用户点击时固定的目标值；实现不得对系统真实状态取反。
  Future<PolkitRuleSyncFact> synchronize({required bool enabled}) async {
    try {
      final result = await _gateway.apply(enabled: enabled);
      AppLogger.info('[PolkitRule] 提权同步完成: $result');
      return PolkitRuleSyncCompleted(result);
    } on PolkitRuleException catch (error) {
      AppLogger.warning('[PolkitRule] 提权同步失败: $error');
      return PolkitRuleSyncFailed(
        kind: error.kind,
        diagnostic: error.diagnostic,
      );
    } catch (error, stackTrace) {
      AppLogger.error('[PolkitRule] 提权同步异常', error, stackTrace);
      return PolkitRuleSyncFailed(
        kind: PolkitRuleFailureKind.unexpected,
        diagnostic: error.toString(),
      );
    }
  }
}
