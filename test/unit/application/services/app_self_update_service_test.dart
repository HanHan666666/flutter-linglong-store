import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_self_update_service.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/domain/repositories/app_self_update_gateways.dart';

const _sha256 =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
const _invalidSha256 =
    '0000000000000000000000000000000000000000000000000000000000000000';

/// 固定当前运行身份的探测替身。
class _FakeProbe implements AppInstallationProbe {
  _FakeProbe(this.installation);

  final AppInstallation installation;

  @override
  Future<AppInstallation> detect() async => installation;
}

/// 记录所有退出路径是否释放临时文件的工作区替身。
class _FakeWorkspace implements AppUpdateWorkspace {
  _FakeWorkspace({this.sha256 = _sha256, this.downloadError});

  final String sha256;
  final Object? downloadError;
  bool disposed = false;

  /// 模拟下载文件的固定字节数。
  int get size => 3;

  /// 模拟 Release 发布流程生成的标准 SHA256 文件。
  String get hashesContent => '$_sha256  store_amd64.deb\n';

  @override
  Future<String> download({
    required String url,
    required String fileName,
    required void Function(int received, int total) onProgress,
    Future<void>? cancellationSignal,
  }) async {
    final error = downloadError;
    if (error != null) {
      throw error;
    }
    onProgress(size, size);
    return '/xdg/cache/session/$fileName';
  }

  @override
  Future<String> computeSha256(String filePath) async => sha256;

  @override
  Future<String> readText(String filePath) async => hashesContent;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

/// 固定返回同一个任务工作区的工厂替身。
class _FakeWorkspaceFactory implements AppUpdateWorkspaceFactory {
  _FakeWorkspaceFactory(this.workspace);

  final _FakeWorkspace workspace;
  int createCount = 0;

  @override
  Future<AppUpdateWorkspace> create() async {
    createCount++;
    return workspace;
  }
}

/// 记录安装调用并可模拟授权失败的适配器替身。
class _FakeInstaller implements AppUpdateInstaller {
  _FakeInstaller({required this.installationKind, this.installError});

  @override
  final AppInstallationKind installationKind;
  final Object? installError;
  int callCount = 0;

  @override
  Future<void> install({
    required AppInstallation installation,
    required String packagePath,
  }) async {
    callCount++;
    final error = installError;
    if (error != null) {
      throw error;
    }
  }
}

/// 创建服务输入使用的 Release 快照。
const _update = VersionCheckResultUpdateAvailable(
  currentVersion: '3.5.0',
  latestVersion: 'v3.5.1',
  releasePageUrl: 'https://example.com/releases/v3.5.1',
  assets: <ReleaseAsset>[
    ReleaseAsset(
      name: 'store_amd64.deb',
      browserDownloadUrl: 'https://example.com/store.deb',
    ),
    ReleaseAsset(
      name: appUpdateHashesAssetName,
      browserDownloadUrl: 'https://example.com/hashes.sha256',
    ),
  ],
);

/// 创建使用同一批测试边界的自更新服务。
AppSelfUpdateService _service({
  required AppInstallation installation,
  required _FakeWorkspaceFactory workspaceFactory,
  required _FakeInstaller installer,
}) {
  return AppSelfUpdateService(
    probe: _FakeProbe(installation),
    workspaceFactory: workspaceFactory,
    installers: <AppUpdateInstaller>[installer],
    currentArch: () => 'x86_64',
  );
}

void main() {
  setUpAll(AppLogger.init);

  test('成功安装后进入完成态并释放 XDG 工作区，不负责重启', () async {
    final workspace = _FakeWorkspace();
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
    );
    final phases = <AppSelfUpdatePhase>[];

    await _service(
      installation: const AppInstallation(
        kind: AppInstallationKind.packageManagerDpkg,
      ),
      workspaceFactory: factory,
      installer: installer,
    ).performUpdate(
      update: _update,
      cancellation: AppSelfUpdateCancellation(),
      onProgress: (progress) => phases.add(progress.phase),
    );

    expect(installer.callCount, 1);
    expect(phases.last, AppSelfUpdatePhase.done);
    expect(workspace.disposed, isTrue);
  });

  test('下载失败后仍清理本次工作区', () async {
    final workspace = _FakeWorkspace(downloadError: StateError('network'));
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
    );

    await expectLater(
      _service(
        installation: const AppInstallation(
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        workspaceFactory: factory,
        installer: installer,
      ).performUpdate(
        update: _update,
        cancellation: AppSelfUpdateCancellation(),
        onProgress: (_) {},
      ),
      throwsStateError,
    );

    expect(workspace.disposed, isTrue);
    expect(installer.callCount, 0);
  });

  test('哈希不匹配时中止安装并清理工作区', () async {
    final workspace = _FakeWorkspace(sha256: _invalidSha256);
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
    );

    await expectLater(
      _service(
        installation: const AppInstallation(
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        workspaceFactory: factory,
        installer: installer,
      ).performUpdate(
        update: _update,
        cancellation: AppSelfUpdateCancellation(),
        onProgress: (_) {},
      ),
      throwsA(
        isA<AppSelfUpdateUnsupportedException>().having(
          (error) => error.reason,
          'reason',
          AppSelfUpdateUnsupportedReason.checksumMismatch,
        ),
      ),
    );

    expect(installer.callCount, 0);
    expect(workspace.disposed, isTrue);
  });

  test('用户取消授权导致安装失败后清理下载文件', () async {
    final workspace = _FakeWorkspace();
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
      installError: StateError('pkexec authentication cancelled'),
    );

    await expectLater(
      _service(
        installation: const AppInstallation(
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        workspaceFactory: factory,
        installer: installer,
      ).performUpdate(
        update: _update,
        cancellation: AppSelfUpdateCancellation(),
        onProgress: (_) {},
      ),
      throwsStateError,
    );

    expect(installer.callCount, 1);
    expect(workspace.disposed, isTrue);
  });

  test('用户在下载开始前取消时不进入安装阶段并清理文件', () async {
    final workspace = _FakeWorkspace();
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
    );
    final cancellation = AppSelfUpdateCancellation();

    await expectLater(
      _service(
        installation: const AppInstallation(
          kind: AppInstallationKind.packageManagerDpkg,
        ),
        workspaceFactory: factory,
        installer: installer,
      ).performUpdate(
        update: _update,
        cancellation: cancellation,
        onProgress: (progress) {
          if (progress.phase == AppSelfUpdatePhase.downloading) {
            cancellation.cancel();
          }
        },
      ),
      throwsA(isA<AppSelfUpdateCancelledException>()),
    );

    expect(installer.callCount, 0);
    expect(workspace.disposed, isTrue);
  });

  test('手动安装身份不创建下载工作区', () async {
    final workspace = _FakeWorkspace();
    final factory = _FakeWorkspaceFactory(workspace);
    final installer = _FakeInstaller(
      installationKind: AppInstallationKind.packageManagerDpkg,
    );

    await expectLater(
      _service(
        installation: const AppInstallation(kind: AppInstallationKind.manual),
        workspaceFactory: factory,
        installer: installer,
      ).performUpdate(
        update: _update,
        cancellation: AppSelfUpdateCancellation(),
        onProgress: (_) {},
      ),
      throwsA(isA<AppSelfUpdateUnsupportedException>()),
    );

    expect(factory.createCount, 0);
  });
}
