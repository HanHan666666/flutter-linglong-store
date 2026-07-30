/// 提供 Application 层领域模型之间的纯映射。
///
/// 应用详情页面需要把后端详情领域模型转为可复用的 InstalledApp 展示模型；
/// 映射不应通过向下转型调用 Data Repository 的实现细节。
library;

import '../../domain/models/app_detail.dart';
import '../../domain/models/installed_app.dart';

/// 把应用详情转换为页面和操作流程共用的应用模型。
///
/// 详情没有返回架构时使用 [fallbackArch]；调用方应优先传入列表入口或全局环境
/// 已知的真实架构，最终默认值只用于缺少任何上下文的兼容场景。
InstalledApp mapAppDetailToInstalledApp(
  AppDetail detail, {
  String fallbackArch = 'x86_64',
}) {
  return InstalledApp(
    appId: detail.appId,
    name: detail.name,
    version: detail.version,
    arch: detail.arch ?? fallbackArch,
    channel: detail.channel ?? 'stable',
    description: detail.description,
    icon: detail.icon,
    kind: detail.kind,
    module: detail.module,
    runtime: detail.runtime,
    size: detail.packageSize,
    repoName: detail.repoName,
  );
}
