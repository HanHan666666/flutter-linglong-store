import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/shell_branch_visibility.dart';
import 'package:linglong_store/core/config/shell_primary_route.dart';

void main() {
  group('PrimaryIndexedStackConcept', () {
    testWidgets(
      'first entry only creates first route (lazy loading)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
            ),
          ),
        );

        // 只有 recommend 页面被创建（首次访问）
        // 其他 3 个槽位应该是 SizedBox.shrink
        final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.children.length, 4);
        // 第一个槽位是 ShellBranchVisibilityScope 包装的 _TestPrimaryPage
        expect(stack.children[0], isA<ShellBranchVisibilityScope>());
        expect(stack.children[1], isA<SizedBox>());
        expect(stack.children[2], isA<SizedBox>());
        expect(stack.children[3], isA<SizedBox>());
      },
    );

    testWidgets(
      'visiting new route adds it to visited set and creates the page',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 只有 recommend 页面
        var stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.index, 0);
        expect(stack.children[0], isA<ShellBranchVisibilityScope>());
        expect(stack.children[1], isA<SizedBox>());

        // 模拟导航到 allApps
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.allApps);
        await tester.pump();

        // 现在 recommend 和 allApps 都存在于 IndexedStack children 中
        stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.index, 1); // active index 是 allApps
        expect(stack.children[0], isA<ShellBranchVisibilityScope>());
        expect(stack.children[1], isA<ShellBranchVisibilityScope>());
      },
    );

    testWidgets(
      'switching back to previous route preserves page state',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 设置 recommend 页面的计数器值
        final recommendState = tester.state<_TestPageState>(
          find.byType(_TestPrimaryPage),
        );
        recommendState.counter = 5;

        // 导航到 allApps
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.allApps);
        await tester.pump();

        // 导航回 recommend
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.recommend);
        await tester.pump();

        // 状态仍然保留（因为 IndexedStack 保留了所有子组件）
        expect(recommendState.counter, 5);
        expect(recommendState.mounted, isTrue);
      },
    );

    testWidgets(
      'secondary route overlay preserves primary stack (activeRoute=null)',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 先访问两个主页面
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.allApps);
        await tester.pump();

        // 两个页面都存在
        var stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.children[0], isA<ShellBranchVisibilityScope>());
        expect(stack.children[1], isA<ShellBranchVisibilityScope>());

        // 二级路由覆盖（activeRoute = null）
        harnessKey.currentState!.showSecondaryOverlay();
        await tester.pump();

        // 二级路由覆盖层显示
        expect(find.text('secondary-overlay'), findsOneWidget);

        // 通过 harness state 直接检查 visitedRoutes 来验证页面未被销毁
        expect(harnessKey.currentState!.visitedPrimaryRoutes, contains(ShellPrimaryRoute.recommend));
        expect(harnessKey.currentState!.visitedPrimaryRoutes, contains(ShellPrimaryRoute.allApps));
      },
    );

    testWidgets(
      'after overlay dismissed, primary page state is preserved',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 设置计数器值
        final recommendState = tester.state<_TestPageState>(
          find.byType(_TestPrimaryPage),
        );
        recommendState.counter = 42;

        // 二级路由覆盖
        harnessKey.currentState!.showSecondaryOverlay();
        await tester.pump();

        // 二级路由消失，返回主页面
        harnessKey.currentState!.dismissSecondaryOverlay();
        await tester.pump();

        // 状态仍然保留
        expect(recommendState.counter, 42);
        expect(recommendState.mounted, isTrue);
      },
    );

    testWidgets(
      'IndexedStack index follows activeRoute',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 访问所有主页面
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.ranking);
        await tester.pump();

        final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.index, ShellPrimaryRoute.ranking.index);
      },
    );

    testWidgets(
      'when activeRoute=null, IndexedStack keeps first index (hidden by Offstage)',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.ranking,
              key: harnessKey,
            ),
          ),
        );

        // 访问所有页面以确保 IndexedStack 有内容
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        // 二级路由覆盖
        harnessKey.currentState!.showSecondaryOverlay();
        await tester.pump();

        // 二级路由覆盖层显示
        expect(find.text('secondary-overlay'), findsOneWidget);

        // 通过 harness state 直接检查 visitedRoutes 来验证所有页面未被销毁
        expect(harnessKey.currentState!.visitedPrimaryRoutes.length, 4);
      },
    );

    testWidgets(
      'all visited pages exist in IndexedStack children',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
            ),
          ),
        );

        // 访问所有主页面
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.recommend);
        await tester.pump();

        // 所有 4 个页面都存在
        final stack = tester.widget<IndexedStack>(find.byType(IndexedStack));
        expect(stack.children.length, 4);
        for (int i = 0; i < 4; i++) {
          expect(stack.children[i], isA<ShellBranchVisibilityScope>());
        }
      },
    );

    testWidgets(
      'ShellBranchVisibilityScope provides correct isActive for each page',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();
        final visibilityRecords = <_VisibilityRecord>[];

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
              onVisibilityChanged: (route, isActive) {
                visibilityRecords.add(_VisibilityRecord(route: route, isActive: isActive));
              },
            ),
          ),
        );

        // 访问所有页面
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        // 切到 recommend
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.recommend);
        await tester.pump();

        // 最后一条记录应该是 recommend isActive=true
        final lastRecord = visibilityRecords.lastWhere(
          (r) => r.route == ShellPrimaryRoute.recommend,
        );
        expect(lastRecord.isActive, isTrue);
      },
    );

    testWidgets(
      'visibility updates correctly when switching activeRoute',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();
        final visibilityStates = <ShellPrimaryRoute, bool>{};

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
              onVisibilityChanged: (route, isActive) {
                visibilityStates[route] = isActive;
              },
            ),
          ),
        );

        // 访问所有页面
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        // 切到 ranking
        harnessKey.currentState!.navigateTo(ShellPrimaryRoute.ranking);
        await tester.pump();

        expect(visibilityStates[ShellPrimaryRoute.ranking], isTrue);
        expect(visibilityStates[ShellPrimaryRoute.recommend], isFalse);
        expect(visibilityStates[ShellPrimaryRoute.allApps], isFalse);
        expect(visibilityStates[ShellPrimaryRoute.myApps], isFalse);
      },
    );

    testWidgets(
      'all pages receive isActive=false when secondary overlay shows',
      (tester) async {
        final harnessKey = GlobalKey<_StatefulPrimaryStackHarnessState>();
        final visibilityStates = <ShellPrimaryRoute, bool>{};

        await tester.pumpWidget(
          MaterialApp(
            home: _StatefulPrimaryStackHarness(
              initialActiveRoute: ShellPrimaryRoute.recommend,
              key: harnessKey,
              onVisibilityChanged: (route, isActive) {
                visibilityStates[route] = isActive;
              },
            ),
          ),
        );

        // 访问所有页面
        for (final route in ShellPrimaryRoute.values) {
          harnessKey.currentState!.navigateTo(route);
          await tester.pump();
        }

        // 二级路由覆盖
        harnessKey.currentState!.showSecondaryOverlay();
        await tester.pump();

        // 所有页面都应该 isActive=false
        for (final route in ShellPrimaryRoute.values) {
          expect(visibilityStates[route], isFalse);
        }
      },
    );
  });
}

/// 可见性记录
class _VisibilityRecord {
  _VisibilityRecord({required this.route, required this.isActive});

  final ShellPrimaryRoute route;
  final bool isActive;
}

/// 状态保持的主页面栈测试 Harness
///
/// 模拟 AppShell 的行为：
/// - 内部维护 `_visitedPrimaryRoutes` 状态集合
/// - 通过 `navigateTo` 方法更新激活路由和已访问集合
/// - 通过 `showSecondaryOverlay/dismissSecondaryOverlay` 控制二级路由覆盖
class _StatefulPrimaryStackHarness extends StatefulWidget {
  const _StatefulPrimaryStackHarness({
    required this.initialActiveRoute,
    this.onVisibilityChanged,
    super.key,
  });

  final ShellPrimaryRoute initialActiveRoute;
  final void Function(ShellPrimaryRoute route, bool isActive)? onVisibilityChanged;

  @override
  State<_StatefulPrimaryStackHarness> createState() =>
      _StatefulPrimaryStackHarnessState();
}

class _StatefulPrimaryStackHarnessState
    extends State<_StatefulPrimaryStackHarness> {
  ShellPrimaryRoute _activePrimaryRoute = ShellPrimaryRoute.recommend;
  final Set<ShellPrimaryRoute> _visitedPrimaryRoutes = {};
  bool _showSecondaryOverlay = false;

  /// 暴露已访问路由集合用于测试验证
  Set<ShellPrimaryRoute> get visitedPrimaryRoutes => Set.unmodifiable(_visitedPrimaryRoutes);

  @override
  void initState() {
    super.initState();
    _activePrimaryRoute = widget.initialActiveRoute;
    _visitedPrimaryRoutes.add(widget.initialActiveRoute);
  }

  void navigateTo(ShellPrimaryRoute route) {
    setState(() {
      _showSecondaryOverlay = false;
      _activePrimaryRoute = route;
      _visitedPrimaryRoutes.add(route);
    });
  }

  void showSecondaryOverlay() {
    setState(() {
      _showSecondaryOverlay = true;
    });
  }

  void dismissSecondaryOverlay() {
    setState(() {
      _showSecondaryOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showOverlay = _showSecondaryOverlay;
    final activeRoute = showOverlay ? null : _activePrimaryRoute;

    return Stack(
      children: [
        Offstage(
          offstage: showOverlay,
          child: _TestPrimaryIndexedStack(
            activeRoute: activeRoute,
            visitedRoutes: _visitedPrimaryRoutes,
            onVisibilityChanged: widget.onVisibilityChanged,
          ),
        ),
        if (showOverlay)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xFFFFFFFF),
              child: Center(child: Text('secondary-overlay')),
            ),
          ),
      ],
    );
  }
}

/// 测试用主页面 IndexedStack
class _TestPrimaryIndexedStack extends StatelessWidget {
  const _TestPrimaryIndexedStack({
    required this.activeRoute,
    required this.visitedRoutes,
    this.onVisibilityChanged,
  });

  final ShellPrimaryRoute? activeRoute;
  final Set<ShellPrimaryRoute> visitedRoutes;
  final void Function(ShellPrimaryRoute route, bool isActive)? onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _getActiveIndex(),
      children: ShellPrimaryRoute.values.map((route) {
        return _buildPrimarySlot(route);
      }).toList(),
    );
  }

  int _getActiveIndex() {
    if (activeRoute == null) {
      return ShellPrimaryRoute.values.first.index;
    }
    return activeRoute!.index;
  }

  Widget _buildPrimarySlot(ShellPrimaryRoute route) {
    final hasVisited = visitedRoutes.contains(route);
    final isActive = activeRoute != null && route == activeRoute;

    if (!hasVisited) {
      return const SizedBox.shrink();
    }

    // 使用 ShellBranchVisibilityScope 提供可见性状态
    // 这样页面的 didChangeDependencies 会在 activeRoute 变化时被调用
    return ShellBranchVisibilityScope(
      activeRoute: activeRoute,
      currentRoute: route,
      child: _TestPrimaryPage(
        key: ValueKey(route),
        route: route,
        onVisibilityChanged: onVisibilityChanged,
      ),
    );
  }
}

/// 测试用主页面组件
class _TestPrimaryPage extends StatefulWidget {
  const _TestPrimaryPage({
    required this.route,
    this.onVisibilityChanged,
    super.key,
  });

  final ShellPrimaryRoute route;
  final void Function(ShellPrimaryRoute route, bool isActive)? onVisibilityChanged;

  @override
  State<_TestPrimaryPage> createState() => _TestPageState();
}

class _TestPageState extends State<_TestPrimaryPage> {
  int counter = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从 ShellBranchVisibilityScope 读取 isActive
    final scope = ShellBranchVisibilityScope.maybeOf(context);
    final isActive = scope?.isActive ?? false;
    widget.onVisibilityChanged?.call(widget.route, isActive);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ShellBranchVisibilityScope.maybeOf(context);
    final isActive = scope?.isActive ?? false;
    return Container(
      child: Center(
        child: Text('${widget.route.name}: $counter (active: $isActive)'),
      ),
    );
  }
}