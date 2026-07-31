import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/app_self_update_provider.dart';
import 'package:linglong_store/application/services/app_self_update_service.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/domain/repositories/app_self_update_gateways.dart';

/// 只用于构造阻塞服务的未调用外部端口集合。
class _UnusedGateways
    implements AppInstallationProbe, AppUpdateWorkspaceFactory {
  @override
  Future<AppInstallation> detect() => throw UnimplementedError();

  @override
  Future<AppUpdateWorkspace> create() => throw UnimplementedError();
}

/// 用 Completer 控制任务结束时间，验证 Controller 的单飞约束。
class _BlockingSelfUpdateService extends AppSelfUpdateService {
  _BlockingSelfUpdateService()
    : super(
        probe: _UnusedGateways(),
        workspaceFactory: _UnusedGateways(),
        installers: const <AppUpdateInstaller>[],
        currentArch: () => 'amd64',
      );

  final Completer<void> finish = Completer<void>();
  int callCount = 0;

  @override
  Future<void> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required AppSelfUpdateCancellation cancellation,
    required void Function(AppSelfUpdateProgress progress) onProgress,
  }) async {
    callCount++;
    onProgress(
      const AppSelfUpdateProgress(
        AppSelfUpdatePhase.downloading,
        progress: 0.2,
      ),
    );
    await finish.future;
    onProgress(
      const AppSelfUpdateProgress(AppSelfUpdatePhase.done, progress: 1),
    );
  }
}

void main() {
  test('任务运行期间重复开始不会创建第二个下载或安装任务', () async {
    const update = VersionCheckResultUpdateAvailable(
      currentVersion: '3.5.0',
      latestVersion: 'v3.5.1',
      releasePageUrl: 'https://example.com/releases/v3.5.1',
    );
    final service = _BlockingSelfUpdateService();
    final container = ProviderContainer(
      overrides: [appSelfUpdateServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appSelfUpdateControllerProvider.notifier);

    final firstTask = controller.start(update);
    await Future<void>.delayed(Duration.zero);
    await controller.start(update);

    expect(service.callCount, 1);
    expect(container.read(appSelfUpdateControllerProvider).isRunning, isTrue);

    service.finish.complete();
    await firstTask;
    expect(
      container.read(appSelfUpdateControllerProvider).phase,
      AppSelfUpdatePhase.done,
    );
  });
}
