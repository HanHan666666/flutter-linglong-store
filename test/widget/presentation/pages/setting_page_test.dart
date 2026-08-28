import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/linux_renderer_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/app_locale.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/linux_renderer_service.dart';
import 'package:linglong_store/presentation/pages/setting/setting_page.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  testWidgets(
    'setting page no longer renders repository configuration section',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('仓库配置'), findsNothing);
      expect(find.text('当前仓库源'), findsNothing);
      expect(find.text('可选仓库'), findsNothing);
      expect(find.text('玲珑环境管理'), findsOneWidget);
    },
  );

  testWidgets(
    'setting page collapses languages and updates the selected locale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({'linglong-store-language': 'zh'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RadioListTile<Locale>), findsNothing);
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('English'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('language-selector-trigger')));
      await tester.pump();

      for (final locale in selectableAppLocales) {
        expect(
          find.byKey(ValueKey('language-option-${locale.toLanguageTag()}')),
          findsOneWidget,
        );
      }

      // 首尾项与高度上限都从 selectableAppLocales 推导，新增语言时本测试
      // 无需跟着改语言字面量；高度断言与选择器的“条目数×48px+内边距”
      // 计算契约保持一致，验证整份语言列表在常规窗口内一次性完整展示。
      final locales = selectableAppLocales;
      final firstOption = find.byKey(
        ValueKey('language-option-${locales.first.toLanguageTag()}'),
      );
      final lastOption = find.byKey(
        ValueKey('language-option-${locales.last.toLanguageTag()}'),
      );
      final trigger = find.byKey(const ValueKey('language-selector-trigger'));
      expect(tester.getSize(firstOption).width, 320);
      expect(tester.getSize(trigger).width, greaterThan(320));
      expect(
        tester.getBottomRight(lastOption).dy -
            tester.getTopLeft(firstOption).dy,
        lessThanOrEqualTo(locales.length * 48 + 8),
      );

      await tester.tap(find.byKey(const ValueKey('language-option-en')));
      await tester.pump();
      await tester.pump();

      expect(container.read(globalAppProvider).locale.languageCode, 'en');
      expect(find.text('English'), findsOneWidget);
      expect(find.byType(MenuItemButton), findsNothing);
    },
  );

  testWidgets('setting page does not render container auto-update option', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('容器内自动更新商店本体'), findsNothing);
  });

  testWidgets('setting page about section renders community exchange link', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('社区交流'), findsOneWidget);
  });

  testWidgets(
    'setting page about section shows operating system from PRETTY_NAME',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // 启动期环境检测把 /etc/os-release 的 PRETTY_NAME 写入 GlobalAppState.osName，
          // 这里直接注入以验证关于卡片只消费该字段（不再读文件、不解析诊断拼接串）。
          globalAppProvider.overrideWith(
            () => _FakeGlobalApp(
              const GlobalAppState(osName: 'Fedora Linux 42 (Evernight Edition)'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('操作系统'), findsOneWidget);
      expect(find.text('Fedora Linux 42 (Evernight Edition)'), findsOneWidget);
    },
  );

  testWidgets(
    'setting page about section falls back to unknown without osName',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // 未采集到系统名称时与系统架构/玲珑版本一致，回落「未知」占位。
          globalAppProvider.overrideWith(
            () => _FakeGlobalApp(const GlobalAppState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('操作系统'), findsOneWidget);
      // 操作系统/系统架构/玲珑版本三行均无值，各自回落同一个「未知」文案。
      expect(find.text('未知'), findsNWidgets(3));
    },
  );

  testWidgets('setting page restores renderer entry and developer links', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final rendererService = LinuxRendererService(
      configFilePathOverride: '/tmp/unused/renderer_preferences.ini',
      dataDirectoryPathOverride: '/tmp/unused',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          linuxRendererServiceProvider.overrideWithValue(rendererService),
          linuxRendererRuntimeProvider.overrideWith(
            (ref) async => const LinuxRendererRuntimeState(
              currentMode: LinuxRendererMode.software,
              decisionSource: LinuxRendererDecisionSource.cpuFallback,
              isCpuWhitelisted: false,
              cpuVendor: 'Loongson',
              cpuModel: '3A6000',
              environmentValue: null,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('软件渲染'), findsOneWidget);
    expect(find.text('Gitee'), findsOneWidget);
    expect(find.text('关于开发者'), findsOneWidget);
  });

  testWidgets('setting page renders typography controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('字体设置'), findsOneWidget);
    expect(find.text('字体大小'), findsOneWidget);
    expect(find.text('字体粗细'), findsOneWidget);
    expect(find.text('更细'), findsOneWidget);
    expect(find.text('标准'), findsOneWidget);
    expect(find.text('更粗'), findsOneWidget);
  });

  testWidgets('setting page uses unified filled button for clear cache', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.binding.setSurfaceSize(const Size(1280, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const Scaffold(body: SettingPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '清除缓存'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '清除缓存'), findsNothing);
  });

  // 入口图标颜色应与其他列表项一致使用中性灰（onSurfaceVariant），不再使用主题蓝
  testWidgets(
    'setting page linglong environment entry icon uses neutral grey color',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      // 定位「玲珑环境管理」所在 ListTile 的 leading 图标
      final tile = find.ancestor(
        of: find.text('玲珑环境管理'),
        matching: find.byType(ListTile),
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: tile,
          matching: find.byIcon(Icons.settings_suggest_outlined),
        ),
      );

      expect(icon.color, AppTheme.lightTheme.colorScheme.onSurfaceVariant);
    },
  );

  testWidgets(
    'user experience program switch toggles the preference',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      // 默认开启：该行为普通 ListTile（说明按钮在 trailing 与开关并排），
      // 开关处于选中状态。
      final tileFinder = find.widgetWithText(ListTile, '用户体验计划');
      final switchFinder = find.descendant(
        of: tileFinder,
        matching: find.byType(Switch),
      );
      expect(tileFinder, findsOneWidget);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // 直接点击开关本体，偏好必须落到 UserPreferences。
      // 开关位于页面下方，先滚动到可见区域再点击。
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      // 偏好写入含异步持久化，等待状态与重建都完成。
      await tester.pumpAndSettle();

      expect(
        container.read(globalAppProvider).userPreferences.joinUserExperienceProgram,
        isFalse,
      );
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    },
  );

  // 该行说明按钮固定 48x48，必须放在 trailing 而非 title 行，
  // 否则会把整行撑高、与相邻设置行高度不一致（回归守卫）。
  testWidgets(
    'user experience program row height matches sibling switch rows',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      // 与同区的「系统通知」两行开关行（SwitchListTile 内部同为 ListTile）
      // 高度必须一致：两行 tile 的高度由标题/副标题决定，48px 尾件不应撑高。
      final uepTile = find.widgetWithText(ListTile, '用户体验计划');
      final notifyTile = find.widgetWithText(ListTile, '系统通知');
      expect(uepTile, findsOneWidget);
      expect(notifyTile, findsOneWidget);
      expect(
        tester.getSize(uepTile).height,
        tester.getSize(notifyTile).height,
      );
    },
  );

  testWidgets(
    'user experience program info button opens the collection dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingPage()),
          ),
        ),
      );
      await tester.pump();

      // 感叹号按钮带无障碍语义，点开后展示采集项说明弹窗。
      // 语义标签验证无障碍可用；点击用图标本体定位更稳定。
      final infoIcon = find.byIcon(Icons.info_outline_rounded);
      expect(
        find.bySemanticsLabel('查看用户体验计划采集的信息说明'),
        findsOneWidget,
      );

      // 按钮位于页面下方，先滚动到可见区域再点击。
      await tester.ensureVisible(infoIcon);
      await tester.pumpAndSettle();
      await tester.tap(infoIcon);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('只收集少量匿名信息'), findsOneWidget);
      expect(find.text('系统架构、系统版本与内核信息、主机名、玲珑环境版本'), findsOneWidget);
      expect(find.textContaining('随时关闭开关'), findsOneWidget);

      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}

/// 固定初始状态的 GlobalApp 替身。
///
/// 关于卡片的环境信息行（osName/arch/llVersion）来自启动期一次性写入的全局状态，
/// widget 测试通过注入初始值验证展示，避免触发真实的 SharedPreferences 初始化。
class _FakeGlobalApp extends GlobalApp {
  _FakeGlobalApp(this._initialState);

  final GlobalAppState _initialState;

  @override
  GlobalAppState build() => _initialState;
}
