import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/og_install_controller.dart';
import 'package:linglong_store/application/providers/app_operation_queue_provider.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  group('OgInstallController', () {
    test('keeps request pending until launch sequence completes', () async {
      final harness = _OgInstallHarness(launchCompleted: false);

      harness.controller.acceptRawUrl('og://org.example.App');
      await harness.controller.processPending();

      expect(harness.detailRequests, isEmpty);
      expect(harness.enqueuedParams, isEmpty);

      harness.launchCompleted = true;
      await harness.controller.processPending();

      expect(harness.detailRequests, ['org.example.App']);
      expect(harness.enqueuedParams, hasLength(1));
      expect(harness.enqueuedParams.single.kind, InstallTaskKind.install);
      expect(harness.enqueuedParams.single.appId, 'org.example.App');
      expect(harness.enqueuedParams.single.appName, 'Example App');
    });

    test(
      'rejects invalid og url without touching repository or queue',
      () async {
        final harness = _OgInstallHarness();

        harness.controller.acceptRawUrl('https://example.com/app');
        await harness.controller.processPending();

        expect(harness.detailRequests, isEmpty);
        expect(harness.enqueuedParams, isEmpty);
        expect(harness.events.single.type, OgInstallEventType.invalid);
      },
    );

    test('blocks install when linglong environment is unavailable', () async {
      final harness = _OgInstallHarness(linglongEnvOk: false);

      harness.controller.acceptRawUrl('og://org.example.App');
      await harness.controller.processPending();

      expect(harness.detailRequests, isEmpty);
      expect(harness.enqueuedParams, isEmpty);
      expect(
        harness.events.map((event) => event.type),
        contains(OgInstallEventType.environmentUnavailable),
      );
    });

    test('emits duplicate event when queue refuses same app', () async {
      final harness = _OgInstallHarness(enqueueTaskId: '');

      harness.controller.acceptRawUrl('og://org.example.App');
      await harness.controller.processPending();

      expect(harness.detailRequests, ['org.example.App']);
      expect(harness.enqueuedParams, hasLength(1));
      expect(harness.events.last.type, OgInstallEventType.duplicate);
    });

    test('emits failure event when app detail cannot be loaded', () async {
      final harness = _OgInstallHarness(
        loadDetail: (_) async => throw Exception('network failed'),
      );

      harness.controller.acceptRawUrl('og://org.example.App');
      await harness.controller.processPending();

      expect(harness.enqueuedParams, isEmpty);
      expect(harness.events.last.type, OgInstallEventType.detailFailed);
      expect(harness.events.last.error, contains('network failed'));
    });
  });
}

class _OgInstallHarness {
  _OgInstallHarness({
    this.launchCompleted = true,
    this.linglongEnvOk = true,
    this.enqueueTaskId = 'task-1',
    Future<AppDetail> Function(String appId)? loadDetail,
  }) : _loadDetail = loadDetail {
    controller = OgInstallController(
      isLaunchCompleted: () => launchCompleted,
      isLinglongEnvOk: () => linglongEnvOk,
      loadAppDetail: (appId) async {
        detailRequests.add(appId);
        final loadDetail = _loadDetail;
        if (loadDetail != null) {
          return loadDetail(appId);
        }
        return AppDetail(
          appId: appId,
          name: 'Example App',
          version: '1.0.0',
          icon: 'https://example.com/icon.png',
        );
      },
      enqueueInstall: (params) {
        enqueuedParams.add(params);
        return enqueueTaskId;
      },
      emitEvent: events.add,
    );
  }

  bool launchCompleted;
  bool linglongEnvOk;
  String enqueueTaskId;

  final Future<AppDetail> Function(String appId)? _loadDetail;
  final List<String> detailRequests = [];
  final List<EnqueueAppOperationParams> enqueuedParams = [];
  final List<OgInstallEvent> events = [];

  late final OgInstallController controller;
}
