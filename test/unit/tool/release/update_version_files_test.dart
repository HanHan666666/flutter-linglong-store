import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/update_version_files.dart';

void main() {
  group('update version file helpers', () {
    test('updates both pubspec files with the release version suffix', () {
      final pubspec = File('test/fixtures/release/sample_pubspec.yaml').readAsStringSync();
      final linuxPubspec = File('test/fixtures/release/sample_linux_pubspec.yaml').readAsStringSync();

      final updatedPubspec = updatePubspecVersion(pubspec, '3.0.7');
      final updatedLinuxPubspec = updateLinuxPubspecVersion(linuxPubspec, '3.0.7');

      expect(updatedPubspec, contains('version: 3.0.7+1'));
      expect(updatedLinuxPubspec, contains('version: 3.0.7+1'));
    });

    test('updates app version constants in both Dart sources', () {
      final appConfig = File('test/fixtures/release/sample_app_config.dart').readAsStringSync();
      final appConstants = File('test/fixtures/release/sample_app_constants.dart').readAsStringSync();

      final updatedAppConfig = updateAppConfigVersion(appConfig, '3.0.7');
      final updatedAppConstants = updateAppConstantsVersion(appConstants, '3.0.7');

      expect(updatedAppConfig, contains("static const String appVersion = '3.0.7';"));
      expect(updatedAppConstants, contains("static const String appVersion = '3.0.7';"));
    });
  });
}
