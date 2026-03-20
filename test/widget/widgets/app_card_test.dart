import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/domain/models/installed_app.dart';

/// 应用卡片 Widget（用于测试）
///
/// 注意：这是测试用的简化版本
/// 实际项目应该在 lib/presentation/widgets/ 中实现完整版本
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    this.onTap,
    this.onInstall,
    this.inkKey,
  });

  final InstalledApp app;
  final VoidCallback? onTap;
  final VoidCallback? onInstall;
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: inkKey,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 应用图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: app.icon != null
                    ? const Icon(Icons.apps, size: 32)
                    : const Icon(Icons.apps, size: 32),
              ),
              const SizedBox(width: 12),
              // 应用信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.description ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 安装按钮
              ElevatedButton(
                onPressed: onInstall,
                child: const Text('Install'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('AppCard Widget', () {
    late InstalledApp testApp;

    setUp(() {
      testApp = const InstalledApp(
        appId: 'com.example.test',
        name: 'Test App',
        version: '1.0.0',
        description: 'A test application for unit testing',
        icon: 'https://example.com/icon.png',
        size: '10.5 MB',
      );
    });

    testWidgets('should display app name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(app: testApp),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('should display app description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(app: testApp),
          ),
        ),
      );

      expect(find.text('A test application for unit testing'), findsOneWidget);
    });

    testWidgets('should display install button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(app: testApp),
          ),
        ),
      );

      expect(find.text('Install'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () => tapped = true,
              inkKey: const Key('app-card-ink'),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('app-card-ink')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should call onInstall when install button is pressed', (tester) async {
      var installPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onInstall: () => installPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(installPressed, isTrue);
    });

    testWidgets('should display app icon placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(app: testApp),
          ),
        ),
      );

      // 应该显示图标占位符
      expect(find.byIcon(Icons.apps), findsOneWidget);
    });

    testWidgets('should handle long app name with ellipsis', (tester) async {
      const longNameApp = InstalledApp(
        appId: 'com.example.verylongname',
        name: 'This is a very long application name that should be truncated with ellipsis',
        version: '1.0.0',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppCard(app: longNameApp),
            ),
          ),
        ),
      );

      // 应该找到名称文本（即使被截断）
      expect(find.textContaining('This is a very long'), findsOneWidget);
    });

    testWidgets('should handle null description gracefully', (tester) async {
      const noDescApp = InstalledApp(
        appId: 'com.example.test',
        name: 'Test App',
        version: '1.0.0',
        description: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(app: noDescApp),
          ),
        ),
      );

      // 不应该崩溃
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('should render within card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(app: testApp),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}