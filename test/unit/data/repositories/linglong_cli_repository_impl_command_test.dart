import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/install_messages.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_exceptions.dart';
import 'package:linglong_store/core/platform/cli_executor.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';

class _RecordingCliExecutor {
  final List<List<String>> executeCalls = [];
  final List<List<String>> progressCalls = [];
  CliOutput nextExecuteOutput = const CliOutput(
    stdout: 'ok',
    stderr: '',
    exitCode: 0,
  );

  Future<CliOutput> execute(
    List<String> args, {
    Duration timeout = kDefaultTimeout,
    String? processId,
    String? locale,
  }) async {
    executeCalls.add(List<String>.from(args));
    return nextExecuteOutput;
  }

  Stream<ProgressEvent> executeWithProgressAndProcess(
    List<String> args, {
    String? processId,
    String? locale,
    void Function(Process process)? onProcessCreated,
  }) async* {
    progressCalls.add(List<String>.from(args));
    yield const ProgressEvent(
      line: '{"message":"Install success"}',
      type: ProgressEventType.stdout,
    );
  }

  Future<bool> cancelWithSystemKill(
    String processId, {
    bool force = true,
    bool killPackageMananger = true,
  }) async {
    return true;
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
    });
  });
}
