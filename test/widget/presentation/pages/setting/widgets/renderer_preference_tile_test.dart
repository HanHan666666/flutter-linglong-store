import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/platform/linux_renderer_service.dart';
import 'package:linglong_store/presentation/pages/setting/widgets/renderer_preference_tile.dart';
import 'package:linglong_store/presentation/widgets/copyable_command_block.dart';

void main() {
  Future<void> pumpRendererPreferenceTile(
    WidgetTester tester, {
    required AsyncValue<LinuxRendererRuntimeState> rendererRuntime,
    required LinuxRendererPreference rendererPreference,
    required LinuxRendererService rendererService,
    required Future<void> Function(LinuxRendererPreference preference)
    onPreferenceSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: RendererPreferenceTile(
            rendererRuntime: rendererRuntime,
            rendererPreference: rendererPreference,
            rendererService: rendererService,
            onPreferenceSelected: onPreferenceSelected,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('environment-controlled renderer state locks the switch', (
    tester,
  ) async {
    final rendererService = LinuxRendererService(
      configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
      dataDirectoryPathOverride: '/tmp/unused',
    );

    await pumpRendererPreferenceTile(
      tester,
      rendererRuntime: const AsyncValue.data(
        LinuxRendererRuntimeState(
          currentMode: LinuxRendererMode.software,
          decisionSource: LinuxRendererDecisionSource.environment,
          isCpuWhitelisted: false,
          cpuVendor: 'Loongson',
          cpuModel: '3A6000',
          environmentValue: 'software',
        ),
      ),
      rendererPreference: LinuxRendererPreference.hardware,
      rendererService: rendererService,
      onPreferenceSelected: (_) async {},
    );

    expect(find.text('软件渲染'), findsOneWidget);
    expect(find.textContaining('检测到环境变量 software'), findsOneWidget);

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
    expect(tile.onChanged, isNull);
  });

  testWidgets('unsupported CPU warns before disabling software rendering', (
    tester,
  ) async {
    LinuxRendererPreference? savedPreference;
    final rendererService = LinuxRendererService(
      configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
      dataDirectoryPathOverride: '/tmp/Linyaps Store',
    );

    await pumpRendererPreferenceTile(
      tester,
      rendererRuntime: const AsyncValue.data(
        LinuxRendererRuntimeState(
          currentMode: LinuxRendererMode.software,
          decisionSource: LinuxRendererDecisionSource.cpuFallback,
          isCpuWhitelisted: false,
          cpuVendor: 'Loongson',
          cpuModel: '3A6000',
          environmentValue: null,
        ),
      ),
      rendererPreference: LinuxRendererPreference.auto,
      rendererService: rendererService,
      onPreferenceSelected: (preference) async {
        savedPreference = preference;
      },
    );

    expect(find.text('当前设备建议保留软件渲染，以获得更稳定的显示效果。'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('确认关闭软件渲染'), findsOneWidget);
    expect(find.text('删除命令'), findsOneWidget);
    expect(find.byType(CopyableCommandBlock), findsOneWidget);
    expect(find.text("rm -rf -- '/tmp/Linyaps Store'"), findsOneWidget);
    expect(savedPreference, isNull);

    await tester.tap(find.widgetWithText(FilledButton, '继续关闭'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(savedPreference, LinuxRendererPreference.hardware);
    expect(find.text('已切换为硬件渲染，将在下次启动时生效。'), findsOneWidget);
  });
}
