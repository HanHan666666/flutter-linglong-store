import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/platform/native_menu_theme_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('org.linglong_store/native_theme');

  group('NativeMenuThemeSync', () {
    final calls = <MethodCall>[];

    Future<void> pumpSyncWidget(
      WidgetTester tester, {
      required ThemeMode themeMode,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          builder: (context, child) => NativeMenuThemeSync(
            isDark: switch (themeMode) {
              ThemeMode.dark => true,
              ThemeMode.light || ThemeMode.system => false,
            },
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('同步深色亮度到原生菜单', (tester) async {
      await pumpSyncWidget(tester, themeMode: ThemeMode.dark);

      expect(calls, hasLength(1));
      expect(calls.single.method, 'setContextMenuDarkTheme');
      expect(calls.single.arguments, {'isDark': true});
    });

    testWidgets('亮度未变化时不重复同步', (tester) async {
      await pumpSyncWidget(tester, themeMode: ThemeMode.dark);
      await pumpSyncWidget(tester, themeMode: ThemeMode.dark);

      expect(calls, hasLength(1));
    });

    testWidgets('主题切换后重新同步', (tester) async {
      await pumpSyncWidget(tester, themeMode: ThemeMode.dark);
      await pumpSyncWidget(tester, themeMode: ThemeMode.light);

      expect(calls, hasLength(2));
      expect(calls.last.method, 'setContextMenuDarkTheme');
      expect(calls.last.arguments, {'isDark': false});
    });
  });
}
