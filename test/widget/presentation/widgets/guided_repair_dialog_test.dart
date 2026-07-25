import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/guided_repair_service.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/core/security/trusted_content_signature.dart';
import 'package:linglong_store/presentation/widgets/guided_repair_execution_dialog.dart';
import 'package:linglong_store/presentation/widgets/script_review_dialog.dart';

/// 脚本审计与实时输出 Widget 测试。
void main() {
  testWidgets('脚本审计展示精确全文并在确认后返回 true', (tester) async {
    const script = '#!/usr/bin/env bash\necho 审计\n';
    bool? confirmed;
    await tester.pumpWidget(
      _LocalizedTestApp(
        child: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              confirmed = await showScriptReviewDialog(context, script: script);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(script), findsOneWidget);
    expect(find.text('审计一键修复脚本'), findsOneWidget);
    await tester.tap(find.byKey(const Key('executeRepairScriptButton')));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('执行对话框实时区分 STDOUT 与 STDERR 并反馈成功', (tester) async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'guided-repair-widget-test-',
    );
    addTearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });
    final service = GuidedRepairService(
      executor: ShellCommandExecutor(runner: _WidgetStreamingRunner()),
      signatureVerifier: const _AlwaysValidVerifier(),
      temporaryDirectoryPath: tempRoot.path,
      logDirectoryPath: tempRoot.path,
    );

    await tester.pumpWidget(
      _LocalizedTestApp(
        child: GuidedRepairExecutionDialog(
          service: service,
          script: 'echo ok\n',
          signature: 'valid',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('stdout visible'), findsOneWidget);
    expect(find.text('stderr visible'), findsOneWidget);
    expect(find.text('修复完成，请重新尝试安装。'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.widgetWithText(SelectableText, 'stderr visible'),
          )
          .style
          ?.color,
      isNotNull,
    );
  });
}

/// 提供项目本地化和主题环境的测试应用。
class _LocalizedTestApp extends StatelessWidget {
  /// 创建测试应用。
  const _LocalizedTestApp({required this.child});

  /// 测试内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }
}

/// Widget 测试使用的固定验签器。
class _AlwaysValidVerifier implements TrustedContentSignatureVerifier {
  /// 创建固定验签器。
  const _AlwaysValidVerifier();

  @override
  Future<bool> verify({
    required TrustedContentPurpose purpose,
    required String content,
    required String signature,
  }) async {
    return true;
  }
}

/// 同步发出两路输出的 Widget 测试执行器。
class _WidgetStreamingRunner
    implements ShellCommandRunner, StreamingShellCommandRunner {
  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) {
    throw UnsupportedError('该测试只允许流式执行');
  }

  @override
  Future<ShellCommandResult> runStreaming(
    List<String> command, {
    required void Function(ShellOutputLine output) onOutput,
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    onOutput(
      const ShellOutputLine(
        channel: ShellOutputChannel.stdout,
        line: 'stdout visible',
      ),
    );
    onOutput(
      const ShellOutputLine(
        channel: ShellOutputChannel.stderr,
        line: 'stderr visible',
      ),
    );
    return const ShellCommandResult(
      stdout: 'stdout visible\n',
      stderr: 'stderr visible\n',
      exitCode: 0,
    );
  }
}
