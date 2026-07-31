import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/file_downloader.dart';
import 'package:linglong_store/platform/self_update/xdg_app_update_workspace.dart';

/// 把固定内容写入目标路径的下载替身。
class _FakeDownloader extends FileDownloader {
  @override
  Future<File> downloadToFile({
    required String url,
    required String destinationPath,
    void Function(int received, int total)? onProgress,
    Future<void>? cancellationSignal,
  }) async {
    final file = File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('payload');
    onProgress?.call(7, 7);
    return file;
  }
}

void main() {
  test('任务目录位于 XDG_CACHE_HOME 且释放时删除全部临时文件', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'xdg-update-workspace-test-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final workspace = await XdgAppUpdateWorkspaceFactory(
      downloader: _FakeDownloader(),
      environment: <String, String>{'XDG_CACHE_HOME': temporaryDirectory.path},
    ).create();

    final packagePath = await workspace.download(
      url: 'https://example.com/store.deb',
      fileName: 'store.deb',
      onProgress: (_, _) {},
    );

    expect(packagePath, startsWith(temporaryDirectory.path));
    expect(packagePath, endsWith('/store.deb'));
    expect(await File(packagePath).exists(), isTrue);
    expect(await File('$packagePath.part').exists(), isFalse);

    await workspace.dispose();
    expect(await File(packagePath).exists(), isFalse);
  });
}
