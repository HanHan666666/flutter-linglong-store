import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_detail.freezed.dart';

/// 应用详情领域模型
///
/// 从 [AppDetailDTO] 提取关键字段，解耦 Domain 层与 Data 层 DTO。
@freezed
sealed class AppDetail with _$AppDetail {
  const factory AppDetail({
    /// 应用 ID
    required String appId,

    /// 应用名称
    required String name,

    /// 应用版本
    required String version,

    /// 应用图标 URL
    String? icon,

    /// 简短描述
    String? description,

    /// 详细描述
    String? detailDescription,

    /// 应用类型
    String? kind,

    /// 运行时
    String? runtime,

    /// 模块
    String? module,

    /// 基础镜像
    String? base,

    /// 架构
    String? arch,

    /// 发布渠道
    String? channel,

    /// 开发者名称
    String? developerName,

    /// 分类名称
    String? categoryName,

    /// 分类 ID
    String? categoryId,

    /// 下载次数
    int? downloadTimes,

    /// 包大小
    String? packageSize,

    /// 截图列表
    @Default([]) List<AppScreenshot> screenshots,

    /// 标签列表
    @Default([]) List<AppTag> tags,

    /// 仓库名称
    String? repoName,

    /// 仓库 URL
    String? repoUrl,

    /// 主页 URL
    String? homePage,

    /// 许可证
    String? license,

    /// 更新日志
    String? releaseNote,
  }) = _AppDetail;
}

/// 应用截图领域模型
@freezed
sealed class AppScreenshot with _$AppScreenshot {
  const factory AppScreenshot({
    /// 截图 URL
    required String url,

    /// 截图描述
    String? description,
  }) = _AppScreenshot;
}

/// 应用标签领域模型
@freezed
sealed class AppTag with _$AppTag {
  const factory AppTag({
    /// 标签名称
    required String name,
  }) = _AppTag;
}
