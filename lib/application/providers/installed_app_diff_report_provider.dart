import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/installed_app_diff_report_service.dart';
import 'application_dependency_providers.dart';

/// 已安装列表差量检测上报服务 Provider。
///
/// 普通 Provider 不自动释放；启动流程在 `_complete()` 阶段读取并调用
/// `start()` 后即常驻（与 appOperationLifecycleCoordinatorProvider 同模式），
/// 首轮检测即为旧版对齐的启动全量基线上报。
final installedAppDiffReportServiceProvider =
    Provider<InstalledAppDiffReportService>((ref) {
      final service = InstalledAppDiffReportService(
        cliRepository: ref.watch(linglongCliRepositoryProvider),
        analyticsRepository: ref.watch(analyticsRepositoryProvider),
      );
      ref.onDispose(service.dispose);
      return service;
    });
