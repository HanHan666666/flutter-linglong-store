import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/shell_branch_visibility.dart';
import 'package:linglong_store/core/config/shell_primary_route.dart';

void main() {
  group('ShellBranchVisibilityScope', () {
    testWidgets(
      'isActive is true when activeRoute equals currentRoute',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final isActiveState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(isActiveState.lastIsActive, isTrue);
      },
    );

    testWidgets(
      'isActive is false when activeRoute differs from currentRoute',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.allApps,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final isActiveState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(isActiveState.lastIsActive, isFalse);
      },
    );

    testWidgets(
      'isActive is false when activeRoute is null (secondary route)',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: null,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final isActiveState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(isActiveState.lastIsActive, isFalse);
      },
    );

    testWidgets(
      'updateShouldNotify triggers rebuild when activeRoute changes',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final isActiveState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(isActiveState.lastIsActive, isTrue);
        expect(isActiveState.rebuildCount, 1);

        // 切换到另一个主路由（当前页面变为隐藏）
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.allApps,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        expect(isActiveState.lastIsActive, isFalse);
        expect(isActiveState.rebuildCount, 2);
      },
    );

    testWidgets(
      'updateShouldNotify does not trigger rebuild when nothing changes',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final isActiveState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(isActiveState.rebuildCount, 1);

        // 相同的状态，不应触发重建
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        expect(isActiveState.rebuildCount, 1);
      },
    );
  });

  group('ShellBranchVisibilityMixin', () {
    testWidgets(
      'receives initial callback with isActive=true and isInitial=true',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        // Mixin 在 didChangeDependencies 中使用 addPostFrameCallback
        // 需要等待一帧后才能收到回调
        await tester.pump();

        expect(callbackLog.length, 1);
        expect(callbackLog[0].isActive, isTrue);
        expect(callbackLog[0].isInitial, isTrue);
      },
    );

    testWidgets(
      'receives initial callback with isActive=false when not active',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.allApps,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();

        expect(callbackLog.length, 1);
        expect(callbackLog[0].isActive, isFalse);
        expect(callbackLog[0].isInitial, isTrue);
      },
    );

    testWidgets(
      'receives callback when switching from active to hidden',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 1);
        expect(callbackLog[0].isActive, isTrue);
        expect(callbackLog[0].isInitial, isTrue);

        // 切换到另一个路由，当前页面变为隐藏
        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.allApps,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 2);
        expect(callbackLog[1].isActive, isFalse);
        expect(callbackLog[1].isInitial, isFalse);
      },
    );

    testWidgets(
      'receives callback when switching from hidden to active',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.allApps,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 1);
        expect(callbackLog[0].isActive, isFalse);
        expect(callbackLog[0].isInitial, isTrue);

        // 切换回当前路由，页面变为激活
        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 2);
        expect(callbackLog[1].isActive, isTrue);
        expect(callbackLog[1].isInitial, isFalse);
      },
    );

    testWidgets(
      'receives isActive=false when secondary route overlay shows (activeRoute=null)',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 1);
        expect(callbackLog[0].isActive, isTrue);

        // 二级路由覆盖，activeRoute 变为 null
        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: null,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 2);
        expect(callbackLog[1].isActive, isFalse);
        expect(callbackLog[1].isInitial, isFalse);
      },
    );

    testWidgets(
      'does not receive duplicate callbacks when state stays the same',
      (tester) async {
        final callbackLog = <VisibilityCallbackRecord>[];

        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 1);

        // 状态不变，不应有新回调
        await tester.pumpWidget(
          _MixinTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            watchedRoute: ShellPrimaryRoute.recommend,
            callbackLog: callbackLog,
          ),
        );

        await tester.pump();
        expect(callbackLog.length, 1);
      },
    );
  });

  group('ShellBranchVisibilityExtension', () {
    testWidgets(
      'isShellBranchActive returns correct value',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.recommend,
          ),
        );

        final consumerState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(consumerState.context.isShellBranchActive, isTrue);
      },
    );

    testWidgets(
      'currentShellBranch returns correct route',
      (tester) async {
        await tester.pumpWidget(
          _VisibilityTestHarness(
            activeRoute: ShellPrimaryRoute.recommend,
            currentRoute: ShellPrimaryRoute.allApps,
          ),
        );

        final consumerState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(consumerState.context.currentShellBranch, ShellPrimaryRoute.allApps);
      },
    );

    testWidgets(
      'isShellBranchActive returns false when not in scope',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: _VisibilityConsumer()));

        final consumerState = tester.state<_VisibilityConsumerState>(
          find.byType(_VisibilityConsumer),
        );
        expect(consumerState.context.isShellBranchActive, isFalse);
        expect(consumerState.context.currentShellBranch, isNull);
      },
    );
  });
}

/// 可见性回调记录
class VisibilityCallbackRecord {
  VisibilityCallbackRecord({required this.isActive, required this.isInitial});

  final bool isActive;
  final bool isInitial;
}

/// 可见性测试 Harness
///
/// 用于测试 ShellBranchVisibilityScope 的 isActive 判断逻辑
class _VisibilityTestHarness extends StatelessWidget {
  const _VisibilityTestHarness({
    required this.activeRoute,
    required this.currentRoute,
  });

  final ShellPrimaryRoute? activeRoute;
  final ShellPrimaryRoute currentRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShellBranchVisibilityScope(
        activeRoute: activeRoute,
        currentRoute: currentRoute,
        child: const _VisibilityConsumer(),
      ),
    );
  }
}

/// 可见性消费者组件
///
/// 用于验证 ShellBranchVisibilityScope 提供的 isActive 状态
class _VisibilityConsumer extends StatefulWidget {
  const _VisibilityConsumer({super.key});

  @override
  State<_VisibilityConsumer> createState() => _VisibilityConsumerState();
}

class _VisibilityConsumerState extends State<_VisibilityConsumer> {
  bool? lastIsActive;
  int rebuildCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ShellBranchVisibilityScope.maybeOf(context);
    lastIsActive = scope?.isActive;
    rebuildCount++;
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

/// Mixin 测试 Harness
///
/// 用于测试 ShellBranchVisibilityMixin 的回调逻辑
class _MixinTestHarness extends StatelessWidget {
  const _MixinTestHarness({
    required this.activeRoute,
    required this.watchedRoute,
    required this.callbackLog,
  });

  final ShellPrimaryRoute? activeRoute;
  final ShellPrimaryRoute watchedRoute;
  final List<VisibilityCallbackRecord> callbackLog;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ShellBranchVisibilityScope(
        activeRoute: activeRoute,
        currentRoute: watchedRoute,
        child: _MixinTestWidget(
          watchedRoute: watchedRoute,
          callbackLog: callbackLog,
        ),
      ),
    );
  }
}

/// 使用 ShellBranchVisibilityMixin 的测试组件
class _MixinTestWidget extends StatefulWidget {
  const _MixinTestWidget({
    required this.watchedRoute,
    required this.callbackLog,
  });

  final ShellPrimaryRoute watchedRoute;
  final List<VisibilityCallbackRecord> callbackLog;

  @override
  State<_MixinTestWidget> createState() => _MixinTestWidgetState();
}

class _MixinTestWidgetState extends State<_MixinTestWidget>
    with ShellBranchVisibilityMixin {
  @override
  ShellPrimaryRoute get watchedPrimaryRoute => widget.watchedRoute;

  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    widget.callbackLog.add(
      VisibilityCallbackRecord(isActive: isActive, isInitial: isInitial),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}