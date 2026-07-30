/// 定义应用操作入队时的不可变目标快照。
///
/// 该快照用于崩溃恢复、批次汇总和通知文案，避免运行期间的列表刷新、
/// 应用改名或多实例选择变化污染已经开始执行的操作。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_operation_target_snapshot.freezed.dart';
part 'app_operation_target_snapshot.g.dart';

/// 应用操作目标快照。
@freezed
sealed class AppOperationTargetSnapshot with _$AppOperationTargetSnapshot {
  /// 创建一次安装或更新操作所针对的完整应用身份。
  const factory AppOperationTargetSnapshot({
    /// 应用主身份。
    required String appId,

    /// 入队时的用户可见名称。
    required String displayName,

    /// 入队时的图标地址，仅供历史界面展示。
    String? icon,

    /// 本机实例架构，用于多实例精确恢复。
    String? arch,

    /// 本机实例渠道，用于多实例精确恢复。
    String? channel,

    /// 本机实例模块，用于多实例精确恢复。
    String? module,

    /// 本机实例仓库，用于多实例精确恢复。
    String? repoName,

    /// 更新开始前已安装的版本。
    String? installedVersion,

    /// 更新成功后应当出现的版本。
    String? expectedVersion,

    /// 显式版本安装传给 ll-cli 的版本参数。
    String? requestedInstallVersion,
  }) = _AppOperationTargetSnapshot;

  /// 从持久化 JSON 恢复目标快照。
  factory AppOperationTargetSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AppOperationTargetSnapshotFromJson(json);
}
