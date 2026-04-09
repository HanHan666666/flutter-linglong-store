import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';

/// 应用版本领域模型
///
/// 从 [AppVersionDTO] 提取关键字段，解耦 Domain 层与 Data 层 DTO。
@freezed
sealed class AppVersion with _$AppVersion {
  const factory AppVersion({
    /// 版本 ID
    String? versionId,
    /// 版本号
    required String versionNo,
    /// 版本名称
    String? versionName,
    /// 描述
    String? description,
    /// 发布时间
    String? releaseTime,
    /// 包大小
    String? packageSize,
    /// 应用 ID
    String? appId,
    /// 图标
    String? icon,
    /// 类型
    String? kind,
    /// 模块
    String? module,
    /// 渠道
    String? channel,
    /// 架构
    String? arch,
    /// 仓库名称
    String? repoName,
    /// 安装次数
    int? installCount,
  }) = _AppVersion;
}
