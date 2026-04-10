import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/update_version_files.dart';

void main() {
  group('update version file helpers', () {
    test('rewrites pubspec files as exact release-version snapshots', () {
      final pubspec = File(
        'test/fixtures/release/sample_pubspec.yaml',
      ).readAsStringSync();
      final linuxPubspec = File(
        'test/fixtures/release/sample_linux_pubspec.yaml',
      ).readAsStringSync();

      final updatedPubspec = updatePubspecVersion(pubspec, '3.0.7');
      final updatedLinuxPubspec = updateLinuxPubspecVersion(
        linuxPubspec,
        '3.0.7',
      );

      expect(
        updatedPubspec,
        equals('''name: linglong_store
description: 玲珑应用商店社区版
publish_to: none
version: 3.0.7+1

environment:
  sdk: '>=3.8.0 <4.0.0'
'''),
      );
      expect(
        updatedLinuxPubspec,
        equals('''name: linglong_store
description: 玲珑应用商店社区版 - Flutter 版
publish_to: none
version: 3.0.7+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

flutter:
  uses-material-design: true
'''),
      );
    });

    test('rewrites app config version constant as exact source snapshot', () {
      final appConfig = File(
        'test/fixtures/release/sample_app_config.dart',
      ).readAsStringSync();

      final updatedAppConfig = updateAppConfigVersion(appConfig, '3.0.7');

      expect(
        updatedAppConfig,
        equals('''/// 应用配置
class AppConfig {
  AppConfig._();

  /// 应用名称
  static const String appName = '玲珑应用商店社区版';

  /// 应用版本
  static const String appVersion = '3.0.7';
}
'''),
      );
    });

    test('rewrites current release version files without legacy app constants', () {
      final tempDir = Directory.systemTemp.createTempSync(
        'update_version_files_test.',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      Directory('${tempDir.path}/linux').createSync(recursive: true);
      Directory('${tempDir.path}/lib/core/config').createSync(recursive: true);

      File('${tempDir.path}/pubspec.yaml').writeAsStringSync(
        File('test/fixtures/release/sample_pubspec.yaml').readAsStringSync(),
      );
      File('${tempDir.path}/linux/pubspec.yaml').writeAsStringSync(
        File('test/fixtures/release/sample_linux_pubspec.yaml')
            .readAsStringSync(),
      );
      File('${tempDir.path}/lib/core/config/app_config.dart').writeAsStringSync(
        File('test/fixtures/release/sample_app_config.dart').readAsStringSync(),
      );

      rewriteVersionFiles('3.0.7', rootPath: tempDir.path);

      expect(
        File('${tempDir.path}/pubspec.yaml').readAsStringSync(),
        contains('version: 3.0.7+1'),
      );
      expect(
        File('${tempDir.path}/linux/pubspec.yaml').readAsStringSync(),
        contains('version: 3.0.7+1'),
      );
      expect(
        File('${tempDir.path}/lib/core/config/app_config.dart').readAsStringSync(),
        contains("static const String appVersion = '3.0.7';"),
      );
      expect(
        File('${tempDir.path}/lib/core/constants/app_constants.dart').existsSync(),
        isFalse,
      );
    });
  });
}
