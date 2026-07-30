import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/error_solution.dart';
import 'package:linglong_store/domain/repositories/error_solution_repository.dart';
import 'package:linglong_store/presentation/widgets/error_solution_help_button.dart';

/// 错误解决方案入口 Widget 测试。
///
/// 重点验证按需请求、锚定失败反馈和 Markdown 弹窗三条用户可见路径。
void main() {
  testWidgets('未命中时显示暂无方案与社区发帖的小浮窗', (tester) async {
    final repository = _FakeErrorSolutionRepository(result: null);
    await tester.pumpWidget(_TestApp(repository: repository));

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pumpAndSettle();

    expect(repository.queryCount, 1);
    expect(repository.lastMessage, 'RequestInteraction');
    expect(find.text('暂无解决方案'), findsOneWidget);
    expect(
      find.byKey(const Key('errorSolutionCommunityPostButton')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('命中时渲染完整 Markdown 并且每次点击都重新请求', (tester) async {
    final repository = _FakeErrorSolutionRepository(
      result: const ErrorSolution(title: '软件源交互失败', markdown: '# 原因\n\n请重试。'),
    );
    await tester.pumpWidget(_TestApp(repository: repository));

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('软件源交互失败'), findsOneWidget);
    expect(find.byKey(const Key('errorSolutionMarkdown')), findsOneWidget);
    expect(repository.queryCount, 1);

    await tester.tap(find.text('关闭'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.queryCount, 2);
  });

  testWidgets('查询异常时显示可重试浮窗', (tester) async {
    final repository = _FakeErrorSolutionRepository(
      error: StateError('命中多条规则'),
    );
    await tester.pumpWidget(_TestApp(repository: repository));

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pumpAndSettle();

    expect(find.text('查询失败，请重试'), findsOneWidget);
    expect(find.text('重新查询'), findsOneWidget);
  });

  testWidgets('浮窗打开后接收焦点，Escape 关闭并恢复帮助按钮焦点', (tester) async {
    final repository = _FakeErrorSolutionRepository(result: null);
    await tester.pumpWidget(_TestApp(repository: repository));

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pumpAndSettle();

    expect(
      tester.binding.focusManager.primaryFocus?.debugLabel,
      'ErrorSolutionPopoverClose',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.binding.focusManager.primaryFocus?.debugLabel,
      'ErrorSolutionPopoverCommunity',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byKey(const Key('errorSolutionHelpPopover')), findsNothing);
    expect(
      tester.binding.focusManager.primaryFocus?.debugLabel,
      'ErrorSolutionHelpTrigger',
    );
  });

  testWidgets('message 更新后丢弃旧查询结果', (tester) async {
    final repository = _DeferredErrorSolutionRepository();
    final message = ValueNotifier<String>('first-error');
    addTearDown(message.dispose);
    await tester.pumpWidget(
      _MutableMessageTestApp(repository: repository, message: message),
    );

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pump();
    message.value = 'second-error';
    await tester.pump();
    repository.complete(
      'first-error',
      const ErrorSolution(title: '旧任务方案', markdown: '# 不应展示'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('旧任务方案'), findsNothing);
    expect(find.byKey(const Key('errorSolutionHelpPopover')), findsNothing);

    await tester.tap(find.byKey(const Key('errorSolutionHelpButton')));
    await tester.pump();
    expect(repository.messages, ['first-error', 'second-error']);
    repository.complete('second-error', null);
    await tester.pumpAndSettle();
  });
}

/// 为 Widget 测试提供本地化和仓储覆盖。
class _TestApp extends StatelessWidget {
  /// 创建测试应用。
  const _TestApp({required this.repository});

  /// 测试仓储。
  final ErrorSolutionRepository repository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        errorSolutionRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ErrorSolutionHelpButton(message: 'RequestInteraction'),
          ),
        ),
      ),
    );
  }
}

/// 在同一个 Widget State 上切换 message，覆盖列表复用时的异步竞态。
class _MutableMessageTestApp extends StatelessWidget {
  /// 创建可更新 message 的测试应用。
  const _MutableMessageTestApp({
    required this.repository,
    required this.message,
  });

  /// 延迟返回结果的仓储。
  final ErrorSolutionRepository repository;

  /// 当前错误 message。
  final ValueNotifier<String> message;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        errorSolutionRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<String>(
              valueListenable: message,
              builder: (_, value, _) => ErrorSolutionHelpButton(message: value),
            ),
          ),
        ),
      ),
    );
  }
}

/// 可记录请求次数的错误解决方案假仓储。
class _FakeErrorSolutionRepository implements ErrorSolutionRepository {
  /// 创建固定结果或固定异常的假仓储。
  _FakeErrorSolutionRepository({this.result, this.error});

  /// 固定查询结果。
  final ErrorSolution? result;

  /// 固定查询异常。
  final Object? error;

  /// 实际查询次数。
  int queryCount = 0;

  /// 最近一次收到的原始 message。
  String? lastMessage;

  @override
  Future<ErrorSolution?> find({
    required String message,
    required String language,
  }) async {
    queryCount += 1;
    lastMessage = message;
    if (error != null) {
      throw error!;
    }
    return result;
  }
}

/// 由测试精确控制每个 message 完成时机的仓储。
class _DeferredErrorSolutionRepository implements ErrorSolutionRepository {
  /// 各 message 对应的延迟结果。
  final Map<String, Completer<ErrorSolution?>> _completers =
      <String, Completer<ErrorSolution?>>{};

  /// 已收到的 message 顺序。
  final List<String> messages = <String>[];

  @override
  Future<ErrorSolution?> find({
    required String message,
    required String language,
  }) {
    messages.add(message);
    return (_completers[message] ??= Completer<ErrorSolution?>()).future;
  }

  /// 完成指定 message 的查询。
  void complete(String message, ErrorSolution? solution) {
    (_completers[message] ??= Completer<ErrorSolution?>()).complete(solution);
  }
}
