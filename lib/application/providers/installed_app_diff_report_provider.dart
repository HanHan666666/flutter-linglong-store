import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/installed_app_diff_report_service.dart';
import 'application_dependency_providers.dart';
import 'global_provider.dart';

/// 已安装列表差量检测上报服务 Provider。
///
/// 普通 Provider 不自动释放；启动流程在 `_complete()` 阶段读取并调用
/// `start()` 后即常驻（与 appOperationLifecycleCoordinatorProvider 同模式）。
/// 差量基线持久化到本地存储，重启后只与上次状态对比差值；首次运行
/// （无历史基线）仍做一次全量基线上报。
///
/// 监听「用户体验计划」开关：关闭时暂停全部检测（含本地轮询命令），
/// 重新开启时立即补检并恢复轮询（基于持久化基线，不重复计数）。
final installedAppDiffReportServiceProvider =
    Provider<InstalledAppDiffReportService>((ref) {
      final service = InstalledAppDiffReportService(
        cliRepository: ref.watch(linglongCliRepositoryProvider),
        analyticsRepository: ref.watch(analyticsRepositoryProvider),
      );
      ref.listen<bool>(
        globalAppProvider.select(
          (state) => state.userPreferences.joinUserExperienceProgram,
        ),
        (previous, next) {
          service.setReportingEnabled(next);
        },
      );
      ref.onDispose(service.dispose);
      return service;
    });
