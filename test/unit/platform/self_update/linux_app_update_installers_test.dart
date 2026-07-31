import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/platform/self_update/linux_app_update_installers.dart';

void main() {
  setUpAll(AppLogger.init);

  test('AppImage 原地替换后保留所有用户可执行权限', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'appimage-installer-test-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final currentAppImage = File('${temporaryDirectory.path}/store.AppImage');
    final downloadedAppImage = File('${temporaryDirectory.path}/download');
    await currentAppImage.writeAsString('old');
    await downloadedAppImage.writeAsString('new');

    await AppImageAppUpdateInstaller(ShellCommandExecutor()).install(
      installation: AppInstallation(
        kind: AppInstallationKind.appImage,
        appImagePath: currentAppImage.path,
      ),
      packagePath: downloadedAppImage.path,
    );

    expect(await currentAppImage.readAsString(), 'new');
    final mode = (await currentAppImage.stat()).mode;
    // 0100、0010、0001 分别是 user/group/other 的执行位。
    expect(mode & 0x49, 0x49);
  });
}
