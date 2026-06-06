import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/install_messages.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_exceptions.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';

class _RecordingCliExecutor {
  final List<List<String>> executeCalls = [];
  final List<List<String>> progressCalls = [];
  final List<String> cancelProcessIds = [];
  final List<bool> cancelForceValues = [];
  final List<bool> cancelKillPackageManagerValues = [];
  final Map<String, CliOutput> executeOutputsByCommand = {};
  final Map<String, List<CliOutput>> executeOutputSequencesByCommand = {};
  CliOutput nextExecuteOutput = const CliOutput(
    stdout: 'ok',
    stderr: '',
    exitCode: 0,
  );
  bool cancelWithSystemKillResult = true;
  List<ProgressEvent> progressEvents = const [
    ProgressEvent(
      line: '{"message":"Install success"}',
      type: ProgressEventType.stdout,
    ),
  ];

  String _commandKey(List<String> args) => args.join(' ');

  Future<CliOutput> execute(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
    String? locale,
  }) async {
    executeCalls.add(List<String>.from(args));
    final commandKey = _commandKey(args);
    final queuedOutputs = executeOutputSequencesByCommand[commandKey];
    if (queuedOutputs != null && queuedOutputs.isNotEmpty) {
      return queuedOutputs.removeAt(0);
    }
    return executeOutputsByCommand[commandKey] ?? nextExecuteOutput;
  }

  Stream<ProgressEvent> executeWithProgressAndProcess(
    List<String> args, {
    String? processId,
    String? locale,
    void Function(Process process)? onProcessCreated,
  }) async* {
    progressCalls.add(List<String>.from(args));
    for (final event in progressEvents) {
      yield event;
    }
  }

  Future<bool> cancelWithSystemKill(
    String processId, {
    bool force = true,
    bool killPackageMananger = true,
  }) async {
    cancelProcessIds.add(processId);
    cancelForceValues.add(force);
    cancelKillPackageManagerValues.add(killPackageMananger);
    return cancelWithSystemKillResult;
  }
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('LinglongCliRepositoryImpl command building', () {
    test(
      'installApp without version uses install command without version suffix',
      () async {
        final executor = _RecordingCliExecutor();
        final repository = LinglongCliRepositoryImpl.withExecutor(
          InstallMessages.fromLocale(const Locale('zh')),
          execute: executor.execute,
          executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
          cancelWithSystemKill: executor.cancelWithSystemKill,
        );

        await repository.installApp('org.example.demo').drain<void>();

        expect(executor.progressCalls, hasLength(1));
        expect(executor.progressCalls.single, [
          'install',
          '--json',
          'org.example.demo',
        ]);
      },
    );

    test(
      'installApp with version uses install command with version suffix',
      () async {
        final executor = _RecordingCliExecutor();
        final repository = LinglongCliRepositoryImpl.withExecutor(
          InstallMessages.fromLocale(const Locale('zh')),
          execute: executor.execute,
          executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
          cancelWithSystemKill: executor.cancelWithSystemKill,
        );

        await repository
            .installApp('org.example.demo', version: '1.2.3')
            .drain<void>();

        expect(executor.progressCalls, hasLength(1));
        expect(executor.progressCalls.single, [
          'install',
          '--json',
          'org.example.demo/1.2.3',
        ]);
      },
    );

    test('installApp with force appends force flag', () async {
      final executor = _RecordingCliExecutor();
      final repository = LinglongCliRepositoryImpl.withExecutor(
        InstallMessages.fromLocale(const Locale('zh')),
        execute: executor.execute,
        executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
        cancelWithSystemKill: executor.cancelWithSystemKill,
      );

      await repository
          .installApp('org.example.demo', version: '1.2.3', force: true)
          .drain<void>();

      expect(executor.progressCalls, hasLength(1));
      expect(executor.progressCalls.single, [
        'install',
        '--json',
        'org.example.demo/1.2.3',
        '--force',
      ]);
    });

    test(
      'versioned install fallback requires the target version to be installed',
      () async {
        final executor = _RecordingCliExecutor()
          ..progressEvents = const [
            ProgressEvent(
              line: '{"message":"Preparing install"}',
              type: ProgressEventType.stdout,
            ),
          ]
          ..executeOutputsByCommand['list --json'] = const CliOutput(
            stdout:
                '[{"appId":"org.example.demo","name":"Demo","version":"9.9.9"}]',
            stderr: '',
            exitCode: 0,
          );
        final repository = LinglongCliRepositoryImpl.withExecutor(
          InstallMessages.fromLocale(const Locale('zh')),
          execute: executor.execute,
          executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
          cancelWithSystemKill: executor.cancelWithSystemKill,
        );

        final events = await repository
            .installApp('org.example.demo', version: '1.2.3')
            .toList();

        expect(events.last.status, InstallStatus.failed);
        expect(events.last.error, contains('无法确认安装结果'));
        expect(
          executor.executeCalls.any(
            (args) =>
                args.length == 2 && args[0] == 'list' && args[1] == '--json',
          ),
          isTrue,
        );
      },
    );

    test(
      'silent update fallback requires installed versions to actually change',
      () async {
        final executor = _RecordingCliExecutor()
          ..progressEvents = const [
            ProgressEvent(
              line: '{"message":"Preparing update"}',
              type: ProgressEventType.stdout,
            ),
          ]
          ..executeOutputSequencesByCommand['list --json'] = [
            const CliOutput(
              stdout:
                  '[{"appId":"org.example.demo","name":"Demo","version":"1.0.0"}]',
              stderr: '',
              exitCode: 0,
            ),
            const CliOutput(
              stdout:
                  '[{"appId":"org.example.demo","name":"Demo","version":"1.0.0"}]',
              stderr: '',
              exitCode: 0,
            ),
          ];
        final repository = LinglongCliRepositoryImpl.withExecutor(
          InstallMessages.fromLocale(const Locale('zh')),
          execute: executor.execute,
          executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
          cancelWithSystemKill: executor.cancelWithSystemKill,
        );

        final events = await repository.updateApp('org.example.demo').toList();

        expect(events.last.status, InstallStatus.failed);
        expect(events.last.error, contains('无法确认更新结果'));
      },
    );

    test('updateApp uses upgrade command without version suffix', () async {
      final executor = _RecordingCliExecutor();
      final repository = LinglongCliRepositoryImpl.withExecutor(
        InstallMessages.fromLocale(const Locale('zh')),
        execute: executor.execute,
        executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
        cancelWithSystemKill: executor.cancelWithSystemKill,
      );

      await repository.updateApp('org.example.demo').drain<void>();

      expect(executor.progressCalls, hasLength(1));
      expect(executor.progressCalls.single, [
        'upgrade',
        '--json',
        'org.example.demo',
      ]);
    });

    test(
      'includes ll-cli json message for generic error code without generic wording',
      () async {
        const detail =
            'ostree_repo_pull_with_options [code 24]: Could not resolve hostname';
        final executor = _RecordingCliExecutor()
          ..progressEvents = const [
            ProgressEvent(
              line: '{"code":-1,"message":"$detail"}',
              type: ProgressEventType.stdout,
            ),
          ];
        final repository = LinglongCliRepositoryImpl.withExecutor(
          InstallMessages.fromLocale(const Locale('zh')),
          execute: executor.execute,
          executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
          cancelWithSystemKill: executor.cancelWithSystemKill,
        );

        final events = await repository.installApp('org.example.demo').toList();

        expect(events.last.status, InstallStatus.failed);
        expect(events.last.error, contains('安装失败'));
        expect(events.last.error, contains('Could not resolve hostname'));
        expect(events.last.error, isNot(contains('通用错误')));
        expect(events.last.errorDetail, equals(detail));
      },
    );

    test('includes ll-cli json message for specific error code', () async {
      const detail = 'mirror unavailable while fetching object';
      final executor = _RecordingCliExecutor()
        ..progressEvents = const [
          ProgressEvent(
            line: '{"code":3001,"message":"$detail"}',
            type: ProgressEventType.stdout,
          ),
        ];
      final repository = LinglongCliRepositoryImpl.withExecutor(
        InstallMessages.fromLocale(const Locale('zh')),
        execute: executor.execute,
        executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
        cancelWithSystemKill: executor.cancelWithSystemKill,
      );

      final events = await repository.installApp('org.example.demo').toList();

      expect(events.last.status, InstallStatus.failed);
      expect(events.last.error, contains('网络错误'));
      expect(events.last.error, contains('mirror unavailable'));
      expect(events.last.errorDetail, equals(detail));
    });

    test('cancelOperation returns false when system kill fails', () async {
      final executor = _RecordingCliExecutor()
        ..cancelWithSystemKillResult = false;
      final repository = LinglongCliRepositoryImpl.withExecutor(
        InstallMessages.fromLocale(const Locale('zh')),
        execute: executor.execute,
        executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
        cancelWithSystemKill: executor.cancelWithSystemKill,
      );

      final result = await repository.cancelOperation(
        'org.example.demo',
        kind: InstallTaskKind.install,
      );

      expect(result, isFalse);
      expect(executor.cancelProcessIds, ['install_org.example.demo']);
      expect(executor.cancelForceValues, [true]);
      expect(executor.cancelKillPackageManagerValues, [true]);
    });

    test('uninstallApp falls back to stdout when stderr is empty', () async {
      final executor = _RecordingCliExecutor()
        ..nextExecuteOutput = const CliOutput(
          stdout: 'main:com.browser.softedge.stable/138.0.3351.95/x86_64',
          stderr: '',
          exitCode: 255,
        );
      final repository = LinglongCliRepositoryImpl.withExecutor(
        InstallMessages.fromLocale(const Locale('zh')),
        execute: executor.execute,
        executeWithProgressAndProcess: executor.executeWithProgressAndProcess,
        cancelWithSystemKill: executor.cancelWithSystemKill,
      );

      expect(
        () => repository.uninstallApp(
          'com.browser.softedge.stable',
          '138.0.3351.95',
        ),
        throwsA(
          isA<UninstallException>().having(
            (UninstallException error) => error.message,
            'message',
            'main:com.browser.softedge.stable/138.0.3351.95/x86_64',
          ),
        ),
      );

      expect(executor.executeCalls, [
        ['uninstall', 'com.browser.softedge.stable/138.0.3351.95'],
      ]);
    });
  });
}
