/// 应用自更新用例编排。
///
/// 本服务只维护稳定业务顺序：识别当前运行身份、选择 Release 资产、在 XDG
/// 工作区下载并按 `hashes.sha256` 校验后安装。UI 状态由上层 Controller 独占；
/// 安装成功后不自动关闭或拉起应用。
library;

import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../domain/models/app_self_update.dart';
import '../../domain/repositories/app_self_update_gateways.dart';
import 'version_check_service.dart';

/// 自更新阶段。
enum AppSelfUpdatePhase {
  /// 检测当前运行身份。
  detectingInstallation,

  /// 选择安装资产与 SHA256 清单。
  resolvingAsset,

  /// 下载更新资产。
  downloading,

  /// 校验 Release 声明的 SHA-256。
  verifying,

  /// 执行系统安装。
  installing,

  /// 安装完成，等待用户手动重新打开应用。
  done,

  /// 更新失败。
  failed,

  /// 用户在安装前取消。
  cancelled,
}

/// 自更新进度事实。
class AppSelfUpdateProgress {
  /// 创建阶段进度。
  const AppSelfUpdateProgress(this.phase, {this.progress = 0});

  /// 当前阶段。
  final AppSelfUpdatePhase phase;

  /// 0..1 的整体进度。
  final double progress;
}

/// 单次自更新的协作取消信号。
///
/// 只允许在进入安装器前取消；安装器开始后由 Controller 隐藏取消入口，避免
/// 中断系统包管理器事务造成半安装状态。
class AppSelfUpdateCancellation {
  final Completer<void> _cancelled = Completer<void>();

  /// 下载适配器监听的取消 Future。
  Future<void> get signal => _cancelled.future;

  /// 是否已经请求取消。
  bool get isCancelled => _cancelled.isCompleted;

  /// 请求取消；重复调用保持幂等。
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }

  /// 在不可分割阶段之间检查取消请求。
  void throwIfCancelled() {
    if (isCancelled) {
      throw const AppSelfUpdateCancelledException();
    }
  }
}

/// 自更新应用用例。
class AppSelfUpdateService {
  /// 创建只依赖稳定端口的自更新用例。
  AppSelfUpdateService({
    required AppInstallationProbe probe,
    required AppUpdateWorkspaceFactory workspaceFactory,
    required List<AppUpdateInstaller> installers,
    required String Function() currentArch,
  }) : _probe = probe,
       _workspaceFactory = workspaceFactory,
       _installers = List<AppUpdateInstaller>.unmodifiable(installers),
       _currentArch = currentArch;

  final AppInstallationProbe _probe;
  final AppUpdateWorkspaceFactory _workspaceFactory;
  final List<AppUpdateInstaller> _installers;
  final String Function() _currentArch;

  /// 完成一次自动安装。
  ///
  /// 成功只代表新版已经安装到原位置；当前进程继续运行，由 UI 提示用户关闭后
  /// 手动重新打开。任何退出路径都会释放本次 XDG 工作区。
  Future<void> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required AppSelfUpdateCancellation cancellation,
    required void Function(AppSelfUpdateProgress progress) onProgress,
  }) async {
    AppUpdateWorkspace? workspace;
    try {
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.detectingInstallation,
          progress: 0.05,
        ),
      );
      final installation = await _probe.detect();
      cancellation.throwIfCancelled();
      if (installation.kind == AppInstallationKind.manual) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.manualInstall,
        );
      }

      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.resolvingAsset,
          progress: 0.1,
        ),
      );
      final asset = resolveAppUpdatePackageAsset(
        assets: update.assets,
        installationKind: installation.kind,
        arch: _currentArch(),
      );
      if (asset == null) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.unsupportedArch,
        );
      }
      final hashesAsset = resolveAppUpdateHashesAsset(update.assets);
      if (hashesAsset == null) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.missingChecksumFile,
        );
      }
      final installer = _installerFor(installation.kind);
      cancellation.throwIfCancelled();

      workspace = await _workspaceFactory.create();
      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.downloading,
          progress: 0.15,
        ),
      );
      var lastReportedProgress = 0.15;
      final packagePath = await workspace.download(
        url: asset.browserDownloadUrl,
        fileName: asset.name,
        cancellationSignal: cancellation.signal,
        onProgress: (received, total) {
          final fraction = total > 0 ? received / total : null;
          final progress = fraction == null ? 0.5 : 0.15 + 0.65 * fraction;
          // 网络分块可能非常密集；按 1% 节流，避免下载回调持续触发 UI 重建。
          if (progress - lastReportedProgress < 0.01 && received != total) {
            return;
          }
          lastReportedProgress = progress;
          onProgress(
            AppSelfUpdateProgress(
              AppSelfUpdatePhase.downloading,
              progress: progress,
            ),
          );
        },
      );
      cancellation.throwIfCancelled();

      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.verifying,
          progress: 0.82,
        ),
      );
      final hashesPath = await workspace.download(
        url: hashesAsset.browserDownloadUrl,
        fileName: hashesAsset.name,
        cancellationSignal: cancellation.signal,
        onProgress: (_, _) {},
      );
      cancellation.throwIfCancelled();
      final hashesContent = await workspace.readText(hashesPath);
      final expectedHash = parseAppUpdateSha256(hashesContent, asset.name);
      if (expectedHash == null) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.missingChecksumFile,
        );
      }
      final actualHash = await workspace.computeSha256(packagePath);
      if (actualHash.toLowerCase() != expectedHash) {
        throw const AppSelfUpdateUnsupportedException(
          AppSelfUpdateUnsupportedReason.checksumMismatch,
        );
      }
      cancellation.throwIfCancelled();

      onProgress(
        const AppSelfUpdateProgress(
          AppSelfUpdatePhase.installing,
          progress: 0.9,
        ),
      );
      await installer.install(
        installation: installation,
        packagePath: packagePath,
      );
      onProgress(
        const AppSelfUpdateProgress(AppSelfUpdatePhase.done, progress: 1),
      );
    } catch (error, stackTrace) {
      AppLogger.error('[AppSelfUpdate] 自更新失败', error, stackTrace);
      rethrow;
    } finally {
      try {
        await workspace?.dispose();
      } catch (error, stackTrace) {
        // 临时文件清理失败不能覆盖真实安装结果，但必须留下诊断。
        AppLogger.warning('[AppSelfUpdate] 清理 XDG 更新工作区失败', error, stackTrace);
      }
    }
  }

  AppUpdateInstaller _installerFor(AppInstallationKind installationKind) {
    AppUpdateInstaller? match;
    for (final installer in _installers) {
      if (installer.installationKind != installationKind) {
        continue;
      }
      if (match != null) {
        throw StateError('自更新安装适配器重复注册: $installationKind');
      }
      match = installer;
    }
    if (match == null) {
      throw StateError('缺少自更新安装适配器: $installationKind');
    }
    return match;
  }
}
