/// 免密安装 polkit 规则的提权同步端口（docs/50 §6.1）。
///
/// Application 只通过本端口发起“按目标值同步一次系统规则”，不接触脚本路径、
/// 命令参数或输出格式。实现必须是唯一可以为本功能构造和执行特权脚本的入口：
/// 禁止在其他位置新增第二条 pkexec 调用路径，也不复用安装传输用的特权 helper
/// 静默修改系统策略（docs/50 §6.1）。
library;

import '../models/polkit_rule_state.dart';

/// 一次提权同步（读取 → 修改 → 回读）的端口。
abstract interface class PolkitRuleGateway {
  /// 按 [enabled] 目标执行一次提权同步。
  ///
  /// 读取、修改与回读共用同一次授权，不拆成两次 pkexec；目标值在调用时固定，
  /// 实现不得对系统真实状态取反。
  ///
  /// 返回结构化事务结果。无法产生可靠结果时抛 [PolkitRuleException]，
  /// 由上层映射为“待同步”而不是“已关闭”。
  Future<PolkitRuleTransactionResult> apply({required bool enabled});
}
