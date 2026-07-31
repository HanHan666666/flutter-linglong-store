import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_installation_probe.dart';
import 'package:linglong_store/application/services/app_self_update_service.dart';
import 'package:linglong_store/application/services/version_check_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/file_downloader.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';

/// 可控安装方式探测替身。
class _FakeProbe extends AppInstallationProbe {
  _FakeProbe(this.result) : super();

  final AppInstallation result;

  @override
  Future<AppInstallation> detect() async => result;
}

/// 可控下载器：按 URL 区分返回安装包内容或 hashes.sha256 内容。
class _FakeDownloader extends FileDownloader {
  _FakeDownloader({
    required this.packageBytes,
    required this.packageFileName,
    required this.hashesContent,
    this.failOnPackage = false,
  }) : super();

  final List<int> packageBytes;
  final String packageFileName;
  final String hashesContent;
  final bool failOnPackage;
  final List<String> requestedUrls = [];

  @override
  Future<File> downloadToFile({
    required String url,
    required String destinationPath,
    void Function(int received, int total)? onProgress,
  }) async {
    requestedUrls.add(url);
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    if (url.contains('hashes.sha256')) {
      await file.writeAsString(hashesContent);
    } else {
      if (failOnPackage) {
        throw const FileDownloadException('模拟下载失败');
      }
      await file.writeAsBytes(packageBytes);
    }
    onProgress?.call(file.lengthSync(), file.lengthSync());
    return file;
  }
}

/// 可控 shell runner。
class _FakeShellRunner implements ShellCommandRunner {
  _FakeShellRunner(this.onRun);

  final Future<ShellCommandResult> Function(List<String> command) onRun;

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    return onRun(command);
  }
}

ShellCommandResult _ok() => const ShellCommandResult(
  stdout: '',
  stderr: '',
  exitCode: 0,
);

ShellCommandResult _fail() => const ShellCommandResult(
  stdout: '',
  stderr: 'pkexec: authentication cancelled',
  exitCode: 1,
);

void main() {
  const packageFileName = 'linglong-store_3.5.1_amd64.deb';
  final packageBytes = utf8.encode('fake package payload');
  late Directory tempDir;

  setUpAll(() async {
    await AppLogger.init();
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('self_update_test_');
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // 忽略清理失败。
    }
  });

  Future<String> hashOfPackageBytes() async {
    final file = File('${tempDir.path}/probe.bin');
    await file.writeAsBytes(packageBytes);
    return computeSha256(file);
  }

  VersionCheckResultUpdateAvailable buildUpdate({bool withHashes = true}) {
    return VersionCheckResultUpdateAvailable(
      currentVersion: '3.5.0',
      latestVersion: 'v3.5.1',
      releasePageUrl: 'https://example.com/releases/v3.5.1',
      assets: <ReleaseAsset>[
        const ReleaseAsset(
          name: packageFileName,
          browserDownloadUrl: 'https://example.com/$packageFileName',
        ),
        if (withHashes)
          const ReleaseAsset(
            name: 'hashes.sha256',
            browserDownloadUrl: 'https://example.com/hashes.sha256',
          ),
      ],
    );
  }

  group('AppSelfUpdateService', () {
    test('dpkg full flow installs via pkexec and restarts', () async {
      final expectedHash = await hashOfPackageBytes();
      final commands = <List<String>>[];
      final restarts = <String>[];
      var closed = false;

      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerDpkg),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '$expectedHash  $packageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _ok();
          }),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async => restarts.add(exe),
        closeApp: () async => closed = true,
        tempDirectory: tempDir.path,
      );

      final phases = <AppSelfUpdatePhase>[];
      final ok = await service.performUpdate(
        update: buildUpdate(),
        onProgress: (p) => phases.add(p.phase),
      );

      expect(ok, isTrue);
      expect(commands, hasLength(1));
      expect(commands.first[0], 'pkexec');
      expect(commands.first[1], 'dpkg');
      expect(commands.first[2], '-i');
      expect(commands.first[3], endsWith(packageFileName));
      expect(restarts, <String>['/opt/linglong-store/linglong_store']);
      expect(closed, isTrue);
      expect(phases.first, AppSelfUpdatePhase.detectingInstallation);
      expect(phases.last, AppSelfUpdatePhase.done);
      expect(phases, contains(AppSelfUpdatePhase.downloading));
      expect(phases, contains(AppSelfUpdatePhase.verifying));
      // 安装成功后下载文件与校验文件应被清理。
      expect(File('${tempDir.path}/$packageFileName').existsSync(), isFalse);
      expect(File('${tempDir.path}/hashes.sha256').existsSync(), isFalse);
    });

    test('rpm full flow installs via pkexec rpm -Uvh', () async {
      final expectedHash = await hashOfPackageBytes();
      const rpmFileName = 'linglong-store-3.5.1-1.x86_64.rpm';
      final commands = <List<String>>[];
      var closed = false;

      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerRpm),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: rpmFileName,
          hashesContent: '$expectedHash  $rpmFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _ok();
          }),
        ),
        currentArch: () => 'amd64',
        restartApp: (exe) async {},
        closeApp: () async => closed = true,
        tempDirectory: tempDir.path,
      );

      const update = VersionCheckResultUpdateAvailable(
        currentVersion: '3.5.0',
        latestVersion: 'v3.5.1',
        releasePageUrl: 'https://example.com/releases/v3.5.1',
        assets: <ReleaseAsset>[
          ReleaseAsset(
            name: rpmFileName,
            browserDownloadUrl: 'https://example.com/$rpmFileName',
          ),
          ReleaseAsset(
            name: 'hashes.sha256',
            browserDownloadUrl: 'https://example.com/hashes.sha256',
          ),
        ],
      );

      final ok = await service.performUpdate(
        update: update,
        onProgress: (_) {},
      );

      expect(ok, isTrue);
      expect(commands.first[1], 'rpm');
      expect(commands.first[2], '-Uvh');
      expect(closed, isTrue);
    });

    test('appImage flow replaces the running AppImage file in place', () async {
      const appImageFileName = 'linglong-store-3.5.1-amd64.AppImage';
      final expectedHash = await hashOfPackageBytes();
      final oldPath = '${tempDir.path}/linglong-store.AppImage';
      await File(oldPath).writeAsBytes(utf8.encode('old appimage'));
      final restarts = <String>[];

      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          AppInstallation(
            kind: AppInstallationKind.appImage,
            appImagePath: oldPath,
          ),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: appImageFileName,
          hashesContent: '$expectedHash  $appImageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async => restarts.add(exe),
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      const update = VersionCheckResultUpdateAvailable(
        currentVersion: '3.5.0',
        latestVersion: 'v3.5.1',
        releasePageUrl: 'https://example.com/releases/v3.5.1',
        assets: <ReleaseAsset>[
          ReleaseAsset(
            name: appImageFileName,
            browserDownloadUrl: 'https://example.com/$appImageFileName',
          ),
          ReleaseAsset(
            name: 'hashes.sha256',
            browserDownloadUrl: 'https://example.com/hashes.sha256',
          ),
        ],
      );

      final ok = await service.performUpdate(
        update: update,
        onProgress: (_) {},
      );

      expect(ok, isTrue);
      // 旧文件已被新包内容替换。
      final replaced = await File(oldPath).readAsBytes();
      expect(replaced, packageBytes);
      // 重启使用 AppImage 真实路径，而不是 /proc/self/exe。
      expect(restarts, <String>[oldPath]);
    });

    test('appImage falls back to pkexec when in-place replace fails', () async {
      const appImageFileName = 'linglong-store-3.5.1-amd64.AppImage';
      final expectedHash = await hashOfPackageBytes();
      // 父目录不存在，copy 到 "$oldPath.new" 必然失败，触发 pkexec 回退。
      final oldPath = '${tempDir.path}/missing-dir/linglong-store.AppImage';
      final commands = <List<String>>[];

      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          AppInstallation(
            kind: AppInstallationKind.appImage,
            appImagePath: oldPath,
          ),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: appImageFileName,
          hashesContent: '$expectedHash  $appImageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async {
            commands.add(command);
            return _ok();
          }),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      const update = VersionCheckResultUpdateAvailable(
        currentVersion: '3.5.0',
        latestVersion: 'v3.5.1',
        releasePageUrl: 'https://example.com/releases/v3.5.1',
        assets: <ReleaseAsset>[
          ReleaseAsset(
            name: appImageFileName,
            browserDownloadUrl: 'https://example.com/$appImageFileName',
          ),
          ReleaseAsset(
            name: 'hashes.sha256',
            browserDownloadUrl: 'https://example.com/hashes.sha256',
          ),
        ],
      );

      final ok = await service.performUpdate(
        update: update,
        onProgress: (_) {},
      );

      expect(ok, isTrue);
      expect(commands, hasLength(1));
      expect(commands.first[0], 'pkexec');
      expect(commands.first[1], 'install');
      expect(commands.first[2], '-m');
      expect(commands.first[3], '755');
      expect(commands.first[5], oldPath);
    });

    test('throws manualInstall for manual installation', () async {
      final expectedHash = await hashOfPackageBytes();
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.manual),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '$expectedHash  $packageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      await expectLater(
        service.performUpdate(update: buildUpdate(), onProgress: (_) {}),
        throwsA(
          isA<AppSelfUpdateUnsupportedException>().having(
            (e) => e.reason,
            'reason',
            AppSelfUpdateUnsupportedReason.manualInstall,
          ),
        ),
      );
    });

    test('throws unsupportedArch when no package exists for architecture', () async {
      final expectedHash = await hashOfPackageBytes();
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerRpm),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '$expectedHash  $packageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'loong64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      await expectLater(
        service.performUpdate(update: buildUpdate(), onProgress: (_) {}),
        throwsA(
          isA<AppSelfUpdateUnsupportedException>().having(
            (e) => e.reason,
            'reason',
            AppSelfUpdateUnsupportedReason.unsupportedArch,
          ),
        ),
      );
    });

    test('throws missingChecksumFile when hashes asset is absent', () async {
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerDpkg),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      await expectLater(
        service.performUpdate(update: buildUpdate(withHashes: false), onProgress: (_) {}),
        throwsA(
          isA<AppSelfUpdateUnsupportedException>().having(
            (e) => e.reason,
            'reason',
            AppSelfUpdateUnsupportedReason.missingChecksumFile,
          ),
        ),
      );
    });

    test('throws checksumMismatch when hash does not match', () async {
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerDpkg),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '${'0' * 64}  $packageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      await expectLater(
        service.performUpdate(update: buildUpdate(), onProgress: (_) {}),
        throwsA(
          isA<AppSelfUpdateUnsupportedException>().having(
            (e) => e.reason,
            'reason',
            AppSelfUpdateUnsupportedReason.checksumMismatch,
          ),
        ),
      );
    });

    test('reports failed progress and rethrows on download failure', () async {
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerDpkg),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '',
          failOnPackage: true,
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _ok()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      final phases = <AppSelfUpdatePhase>[];
      await expectLater(
        service.performUpdate(update: buildUpdate(), onProgress: (p) => phases.add(p.phase)),
        throwsA(isA<FileDownloadException>()),
      );
      expect(phases.last, AppSelfUpdatePhase.failed);
    });

    test('rethrows when pkexec install command fails', () async {
      final expectedHash = await hashOfPackageBytes();
      final service = AppSelfUpdateService(
        probe: _FakeProbe(
          const AppInstallation(kind: AppInstallationKind.packageManagerDpkg),
        ),
        downloader: _FakeDownloader(
          packageBytes: packageBytes,
          packageFileName: packageFileName,
          hashesContent: '$expectedHash  $packageFileName\n',
        ),
        shellExecutor: ShellCommandExecutor(
          runner: _FakeShellRunner((command) async => _fail()),
        ),
        currentArch: () => 'x86_64',
        restartApp: (exe) async {},
        closeApp: () async {},
        tempDirectory: tempDir.path,
      );

      await expectLater(
        service.performUpdate(update: buildUpdate(), onProgress: (_) {}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('parseHashesFile', () {
    test('parses sha256sum text format', () {
      final parsed = parseHashesFile(
        '${'a' * 64}  linglong-store_3.5.0_amd64.deb\n'
        '${'b' * 64} *hashes.sha256\n'
        'invalid line without hash\n'
        '\n',
      );
      expect(parsed['linglong-store_3.5.0_amd64.deb'], 'a' * 64);
      expect(parsed['hashes.sha256'], 'b' * 64);
      expect(parsed, hasLength(2));
    });
  });
}
