import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/update_version_files.dart';

void main() {
  group('update version file helpers', () {
    test('rewrites pubspec files as exact release-version snapshots', () {
      final pubspec = File('test/fixtures/release/sample_pubspec.yaml').readAsStringSync();
      final linuxPubspec = File('test/fixtures/release/sample_linux_pubspec.yaml').readAsStringSync();

      final updatedPubspec = updatePubspecVersion(pubspec, '3.0.7');
      final updatedLinuxPubspec = updateLinuxPubspecVersion(linuxPubspec, '3.0.7');

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

    test('rewrites app version constants as exact source snapshots', () {
      final appConfig = File('test/fixtures/release/sample_app_config.dart').readAsStringSync();
      final appConstants = File('test/fixtures/release/sample_app_constants.dart').readAsStringSync();

      final updatedAppConfig = updateAppConfigVersion(appConfig, '3.0.7');
      final updatedAppConstants = updateAppConstantsVersion(appConstants, '3.0.7');

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
      expect(
        updatedAppConstants,
        equals('''/// 应用常量
class AppConstants {
  AppConstants._();

  /// 应用版本
  static const String appVersion = '3.0.7';
}
'''),
      );
    });
  });
}
