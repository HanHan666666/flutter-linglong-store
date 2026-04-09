import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_comment.freezed.dart';

/// 应用评论领域模型
///
/// 从 [AppCommentDTO] 提取关键字段，解耦 Domain 层与 Data 层 DTO。
@freezed
sealed class AppComment with _$AppComment {
  const factory AppComment({
    /// 评论 ID
    required String id,
    /// 应用 ID
    required String appId,
    /// 关联版本号
    String? version,
    /// 评论内容
    required String remark,
    /// 赞同数
    @Default(0) int agreeNum,
    /// 反对数
    @Default(0) int disagreeNum,
    /// 创建时间
    String? createTime,
  }) = _AppComment;
}
