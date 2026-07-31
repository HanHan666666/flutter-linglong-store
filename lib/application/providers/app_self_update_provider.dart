import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/file_downloader.dart';
import '../../core/platform/window_service.dart';
import '../services/app_installation_probe.dart';
import '../services/app_self_update_service.dart';
import 'global_provider.dart';
import 'linglong_env_provider.dart';

/// 应用安装方式检测服务。
final appInstallationProbeProvider = Provider<AppInstallationProbe>((ref) {
  return AppInstallationProbe(
    shellExecutor: ref.watch(shellCommandExecutorProvider),
  );
});

/// 自更新编排服务。
///
/// 重启回调在 Provider 层收口：先以分离进程重新拉起新版本可执行文件，
/// 再关闭当前窗口（与 `WindowService.close` 解耦便于测试替换）。
final appSelfUpdateServiceProvider = Provider<AppSelfUpdateService>((ref) {
  return AppSelfUpdateService(
    probe: ref.watch(appInstallationProbeProvider),
    downloader: FileDownloader(),
    shellExecutor: ref.watch(shellCommandExecutorProvider),
    currentArch: () =>
        ref.read(globalAppProvider).arch ?? kDefaultRequestArch,
    restartApp: restartAppExecutable,
    closeApp: WindowService.close,
  );
});

/// 以分离进程方式重新拉起 [executable]。
Future<void> restartAppExecutable(String executable) async {
  await Process.start(
    executable,
    const [],
    mode: ProcessStartMode.detached,
  );
}
