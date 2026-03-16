import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/page_visibility.dart';
import 'package:linglong_store/core/config/visibility_aware_mixin.dart';

void main() {
  group('VisibilityAwareMixin', () {
    setUp(() {
      // 清除 PageVisibilityManager 的状态
      PageVisibilityManager.instance.clearAll();
    });

    testWidgets('should trigger onVisibilityChanged with first visible on init',
        (tester) async {
      final events = <PageVisibilityEvent>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (event) {
                events.add(event);
              },
            ),
          ),
        ),
      );

      // 等待 postFrameCallback 完成
      await tester.pump();

      // 初始状态应该触发首次可见事件
      expect(events.length, equals(1));
      expect(events[0].isFirstVisible, isTrue);
      expect(events[0].becameVisible, isTrue);
    });

    testWidgets('notifyBecameVisible should trigger callback with correct event',
        (tester) async {
      final events = <PageVisibilityEvent>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (event) {
                events.add(event);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));

      // 先隐藏，再可见
      state.notifyBecameHidden();
      expect(events.length, equals(2));
      expect(events[1].becameHidden, isTrue);

      // 现在调用可见
      state.notifyBecameVisible();
      expect(events.length, equals(3));
      expect(events[2].becameVisible, isTrue);
      expect(events[2].isFirstVisible, isFalse);
    });

    testWidgets('notifyBecameHidden should trigger callback with correct event',
        (tester) async {
      final events = <PageVisibilityEvent>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (event) {
                events.add(event);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // 获取 state 并调用 notifyBecameHidden
      final state = tester.state<_TestPageState>(find.byType(_TestPage));
      state.notifyBecameHidden();

      // 应该收到隐藏事件
      expect(events.length, equals(2));
      expect(events[1].becameHidden, isTrue);
    });

    testWidgets('should handle visible -> hidden -> visible sequence correctly',
        (tester) async {
      final events = <PageVisibilityEvent>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (event) {
                events.add(event);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final state = tester.state<_TestPageState>(find.byType(_TestPage));

      // 隐藏
      state.notifyBecameHidden();
      expect(events.length, equals(2));
      expect(events[1].becameHidden, isTrue);

      // 可见
      state.notifyBecameVisible();
      expect(events.length, equals(3));
      expect(events[2].becameVisible, isTrue);
    });

    testWidgets('should clean up on dispose', (tester) async {
      PageVisibilityManager.instance.notifyPageMounted('/test');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // 页面存在
      expect(PageVisibilityManager.instance.isVisible('/test'), isTrue);

      // 销毁页面
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Text('Empty')),
          ),
        ),
      );
      await tester.pump();

      // 页面应该被标记为 evicted
      expect(
        PageVisibilityManager.instance.getVisibilityStatus('/test'),
        equals(PageVisibilityStatus.evicted),
      );
    });

    testWidgets('build should render content correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _TestPage(
              routePath: '/test',
              onVisibilityChanged: (_) {},
              contentText: 'Test Content',
            ),
          ),
        ),
      );

      // 验证内容被正确渲染
      expect(find.text('Test Content'), findsOneWidget);
    });
  });
}

/// 测试用的 ConsumerStatefulWidget，实现 VisibilityAwareMixin
class _TestPage extends ConsumerStatefulWidget {
  const _TestPage({
    required this.routePath,
    required this.onVisibilityChanged,
    this.contentText,
  });

  final String routePath;
  final void Function(PageVisibilityEvent event) onVisibilityChanged;
  final String? contentText;

  @override
  ConsumerState<_TestPage> createState() => _TestPageState();
}

class _TestPageState extends ConsumerState<_TestPage>
    with VisibilityAwareMixin<_TestPage> {
  @override
  String get routePath => widget.routePath;

  @override
  void onVisibilityChanged(PageVisibilityEvent event) {
    widget.onVisibilityChanged(event);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(widget.contentText ?? 'Default Content'),
    );
  }
}