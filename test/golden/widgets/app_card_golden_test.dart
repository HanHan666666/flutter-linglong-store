import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/domain/models/installed_app.dart';

// 导入测试用的 AppCard（从 app_card_test.dart）
// 在实际项目中，应该从 lib/presentation/widgets/ 导入
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    this.onTap,
    this.onInstall,
    this.inkKey,
  });

  final Key? inkKey;

  final InstalledApp app;
  final VoidCallback? onTap;
  final VoidCallback? onInstall;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps, size: 32),
              ),
              const SizedBox(width: 12),
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
  group('AppCard Widget Tests', () {
    late InstalledApp testApp;

    setUp(() {
      testApp = const InstalledApp(
        appId: 'com.example.test',
        name: 'Test App',
        version: '1.0.0',
        description: 'A test application for testing',
        icon: 'https://example.com/icon.png',
        size: '10.5 MB',
      );
    });

    testWidgets('AppCard should render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF016FFD)),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: AppCard(app: testApp),
              ),
            ),
          ),
        ),
      );

      // Verify the app name is displayed
      expect(find.text('Test App'), findsOneWidget);
      // Verify the install button is displayed
      expect(find.text('Install'), findsOneWidget);
      // Verify the description is displayed
      expect(find.text('A test application for testing'), findsOneWidget);
    });

    testWidgets('AppCard should render correctly with long text', (tester) async {
      const longTextApp = InstalledApp(
        appId: 'com.example.longname',
        name: 'Very Long Application Name That Should Be Truncated',
        version: '1.0.0',
        description: 'This is a very long description that should be truncated with ellipsis when displayed in the card widget',
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF016FFD)),
          ),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: AppCard(app: longTextApp),
              ),
            ),
          ),
        ),
      );

      // Verify the app name is displayed (even if truncated)
      expect(find.textContaining('Very Long'), findsOneWidget);
    });

    testWidgets('AppCard should render in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF016FFD),
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: AppCard(app: testApp),
              ),
            ),
          ),
        ),
      );

      // Verify the app name is displayed
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('AppCard list should render correctly', (tester) async {
      final apps = [
        const InstalledApp(appId: '1', name: 'App One', version: '1.0.0', description: 'First app'),
        const InstalledApp(appId: '2', name: 'App Two', version: '2.0.0', description: 'Second app'),
        const InstalledApp(appId: '3', name: 'App Three', version: '3.0.0', description: 'Third app'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF016FFD)),
          ),
          home: Scaffold(
            body: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) => AppCard(app: apps[index]),
            ),
          ),
        ),
      );

      // Verify all apps are displayed
      expect(find.text('App One'), findsOneWidget);
      expect(find.text('App Two'), findsOneWidget);
      expect(find.text('App Three'), findsOneWidget);
    });

    testWidgets('AppCard should handle onTap callback', (tester) async {
      bool tapped = false;

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
      expect(tapped, isTrue);
    });

    testWidgets('AppCard should handle onInstall callback', (tester) async {
      bool installed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onInstall: () => installed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Install'));
      expect(installed, isTrue);
    });
  });
}