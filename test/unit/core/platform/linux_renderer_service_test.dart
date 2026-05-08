import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/platform/linux_renderer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LinuxRendererService', () {
    test(
      'savePreferredMode persists and loadPersistedPreferenceSync restores it',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'linux-renderer-service-',
        );
        addTearDown(() => tempDirectory.delete(recursive: true));

        final service = LinuxRendererService(
          configFilePathOverride:
              '${tempDirectory.path}/renderer_preferences.ini',
          dataDirectoryPathOverride: tempDirectory.path,
        );

        await service.savePreferredMode(LinuxRendererPreference.software);

        expect(
          service.loadPersistedPreferenceSync(),
          LinuxRendererPreference.software,
        );
      },
    );

    test('buildRecoveryInfo returns a safely quoted delete command', () {
      final service = LinuxRendererService(
        configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
        dataDirectoryPathOverride: "/tmp/Linyaps Store/it's-safe",
      );

      final recoveryInfo = service.buildRecoveryInfo();

      expect(recoveryInfo.dataDirectoryPath, "/tmp/Linyaps Store/it's-safe");
      expect(
        recoveryInfo.deleteDataDirectoryCommand,
        "rm -rf -- '/tmp/Linyaps Store/it'\"'\"'s-safe'",
      );
    });

    test(
      'environment-controlled runtime state stays authoritative for next launch',
      () async {
        const channel = MethodChannel('test/linux_renderer');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method != 'getRendererRuntimeState') {
                return null;
              }

              return <String, Object?>{
                'currentMode': 'software',
                'decisionSource': 'environment',
                'isCpuWhitelisted': false,
                'cpuVendor': 'Loongson',
                'cpuModel': '3A6000',
                'environmentValue': 'software',
              };
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        final service = LinuxRendererService(
          channel: channel,
          configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
          dataDirectoryPathOverride: '/tmp/unused',
        );

        final runtimeState = await service.getRuntimeState();

        expect(runtimeState.isEnvironmentLocked, isTrue);
        expect(
          service.resolveNextLaunchUsesSoftwareRendering(
            runtimeState: runtimeState,
            preference: LinuxRendererPreference.hardware,
          ),
          isTrue,
        );
      },
    );
  });
}
