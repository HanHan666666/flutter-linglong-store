import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'installed_app_diff_report_provider.dart';
import 'installed_apps_provider.dart';
import 'update_apps_provider.dart';

/// 应用集合变更后的统一同步服务。
///
/// 安装、更新、卸载等会改变“已安装列表”和“可更新列表”的场景，
/// 都应该复用这里，避免页面或 Widget 自己拼 refresh 链路。
class AppCollectionSyncService {
  const AppCollectionSyncService(this._ref);

  final Ref _ref;

  /// 后台刷新 installed apps 和 updates。
  Future<void> syncAfterSuccessfulOperation() async {
    // 先刷新 installed apps，再基于新版本重新计算 updates，
    // 避免更新列表继续读取到成功前的旧版本。
    await _ref.read(installedAppsProvider.notifier).refresh();
    await _ref.read(updateAppsProvider.notifier).checkUpdates();
    // 同步完成后触发差量检测上报（对齐旧版 reflushInstalledItemsImmediate），
    // 防抖合并且不阻塞操作链路：安装/卸载统计由差量结果统一产生。
    _ref
        .read(installedAppDiffReportServiceProvider)
        .scheduleImmediateCheck();
  }
}

final appCollectionSyncServiceProvider = Provider<AppCollectionSyncService>((
  ref,
) {
  return AppCollectionSyncService(ref);
});
