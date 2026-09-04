import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/app.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/launch_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/system_accent_color.dart';
import 'package:linglong_store/domain/repositories/system_accent_color_gateway.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 根应用系统强调色热更新测试（docs/48 §7.6/§8/§12.3）。
///
/// 通过 Fake Gateway 驱动 EventChannel 等价的 Stream 事件，验证：
/// - loading/null 解析为品牌蓝且不阻塞首帧；
/// - 收到系统色事件后无需重启，下一帧浅/深主题同时换色；
/// - 真实页面里的 Material 组件（ElevatedButton）从组件上下文取到派生色
///   （即 §12.3 要求的代表性非蓝强调色核心组件组合验证）；
/// - 强制浅色、强制深色、跟随系统三种 ThemeMode 下都生效；
/// - 仅强调色变化不重复触发原生菜单明暗同步（既有行为不回归）。
void main() {
  // 根应用内 WindowService/AppLogger 等组件在平台通道缺失时会记日志。
  setUpAll(() async {
    await AppLogger.init();
  });

  testWidgets('强制浅色：loading 先画品牌蓝，事件后下一帧切系统色', (tester) async {
    final harness = await _AccentTestHarness.pump(tester, ThemeMode.light);

    // 初始 loading → null → 品牌蓝（docs/48 §8：冷启动不阻塞首帧）。
    expect(harness.innerPrimary, AppColors.brandPrimary);

    // 在真实页面里渲染一个真实 ElevatedButton（§12.3 的核心组件组合验证）：
    // 初始取色为品牌回退。
    await harness.pushProbePage();
    expect(harness.probeButtonBackground, AppColors.brandPrimary);

    await harness.emit(const SystemAccentColor(red: 232, green: 89, blue: 12));
    final expected = _expectedPrimary(
      const SystemAccentColor(red: 232, green: 89, blue: 12),
      Brightness.light,
    );

    // 内层 resolvedTheme 与 MaterialApp.theme 参数同时换色。
    expect(harness.innerPrimary, expected);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.colorScheme.primary, expected);
    expect(materialApp.darkTheme!.colorScheme.primary, _expectedPrimary(
      const SystemAccentColor(red: 232, green: 89, blue: 12),
      Brightness.dark,
    ));

    // 真实页面中的 ElevatedButton 无需重建路由即取到系统派生背景色：
    // 验证的是 Provider → 根主题 → Theme InheritedWidget → 组件取色的
    // 完整接线（ElevatedButtonTheme.of 正是组件渲染时的取色入口）。
    expect(harness.probeButtonBackground, expected);
    expect(harness.probeButtonBackground, isNot(AppColors.brandPrimary));

    // 不可用事件（portal 无该键）回退品牌蓝。
    await harness.emit(null);
    expect(harness.innerPrimary, AppColors.brandPrimary);
    expect(harness.probeButtonBackground, AppColors.brandPrimary);
  });

  testWidgets('强制深色：强调色事件在深色主题下生效', (tester) async {
    final harness = await _AccentTestHarness.pump(tester, ThemeMode.dark);

    expect(harness.innerPrimary, AppColors.brandPrimary);

    const seed = SystemAccentColor(red: 0, green: 200, blue: 83);
    await harness.emit(seed);

    expect(harness.innerPrimary, _expectedPrimary(seed, Brightness.dark));
    expect(
      harness.innerBrightness,
      Brightness.dark,
      reason: '强调色跟随不得改变用户选择的明暗模式',
    );
  });

  testWidgets('跟随系统：系统深色下强调色事件在深色主题下生效', (tester) async {
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final harness = await _AccentTestHarness.pump(tester, ThemeMode.system);

    expect(harness.innerBrightness, Brightness.dark);
    expect(harness.innerPrimary, AppColors.brandPrimary);

    const seed = SystemAccentColor(red: 255, green: 235, blue: 0);
    await harness.emit(seed);

    expect(harness.innerPrimary, _expectedPrimary(seed, Brightness.dark));
  });

  testWidgets('NativeMenuThemeSync 明暗同步不因强调色事件重复触发', (tester) async {
    final harness = await _AccentTestHarness.pump(tester, ThemeMode.dark);

    // 首帧同步一次 isDark: true。
    expect(harness.nativeThemeCalls, hasLength(1));
    expect(harness.nativeThemeCalls.single.arguments, {'isDark': true});

    // 仅强调色变化：明暗未变，不得再次调用原生通道。
    await harness.emit(const SystemAccentColor(red: 1, green: 160, blue: 30));
    expect(harness.nativeThemeCalls, hasLength(1));
  });
}

/// 计算与 AppTheme._fromSystemSeed 相同的期望 primary。
///
/// 测试独立复算而不是读取被测产物，避免实现自证。
Color _expectedPrimary(SystemAccentColor accent, Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: Color.fromARGB(0xFF, accent.red, accent.green, accent.blue),
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    brightness: brightness,
  ).primary;
}

/// 根应用测试夹具：注入 Fake Gateway 与受控 ThemeMode。
class _AccentTestHarness {
  _AccentTestHarness._(this._tester, this.nativeThemeCalls);

  final WidgetTester _tester;
  final StreamController<SystemAccentColor?> controller =
      StreamController<SystemAccentColor?>();
  final List<MethodCall> nativeThemeCalls;

  /// 启动真实 LinglongStoreApp。
  ///
  /// 覆盖项收敛为根渲染必需依赖：偏好存储、强调色 Gateway、主题模式与
  /// 启动序列（停在启动页，避免牵动 ll-cli 与安装队列）。
  static Future<_AccentTestHarness> pump(
    WidgetTester tester,
    ThemeMode themeMode,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final harness = _AccentTestHarness._(tester, []);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    PackageInfo.setMockInitialValues(
      appName: 'linglong_store',
      packageName: 'linglong_store',
      version: '3.1.2',
      buildNumber: '1',
      buildSignature: '',
    );

    // 记录原生菜单明暗同步调用，验证既有行为不回归。
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('org.linglong_store/native_theme'),
          (call) async {
            harness.nativeThemeCalls.add(call);
            return null;
          },
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          systemAccentColorGatewayProvider.overrideWithValue(
            _FakeAccentColorGateway(harness.controller.stream),
          ),
          currentThemeModeProvider.overrideWith((ref) => themeMode),
          launchSequenceProvider.overrideWith(() => _IdleLaunchSequence()),
        ],
        child: const LinglongStoreApp(),
      ),
    );
    // 驱动首帧后的 post-frame 回调（og 协议桥、原生菜单同步等）。
    await tester.pump();

    return harness;
  }

  /// 推送强调色事件并推进到事件生效的下一帧。
  Future<void> emit(SystemAccentColor? accent) async {
    controller.add(accent);
    await _tester.pump();
    await _tester.pump();
  }

  /// 在根应用路由栈内压入一个含真实 ElevatedButton 的探测页。
  ///
  /// 目的是验证「页面上真实 Material 组件取到新主题色」而不仅是根主题
  /// 参数变化；项目全局禁用转场动画，瞬切无需等待。
  Future<void> pushProbePage() async {
    final navigator = _tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('probe'),
            ),
          ),
        ),
      ),
    );
    await _tester.pump();
    await _tester.pump();
  }

  /// 探测页内真实 ElevatedButton 在其组件上下文中解析出的背景色。
  ///
  /// `ElevatedButtonTheme.of` 就是组件渲染时的取色入口，用它断言等价于
  /// 验证真实按钮画出来的颜色，但不耦合 SDK 内部渲染结构。
  Color get probeButtonBackground {
    final context = _tester.element(find.byType(ElevatedButton));
    final style = ElevatedButtonTheme.of(context).style;
    return style?.backgroundColor?.resolve(const {}) ??
        const Color.fromARGB(0, 0, 0, 0);
  }

  /// 根 builder 内层 Theme（实际作用于页面内容）的 primary。
  Color get innerPrimary {
    final context = _tester.element(find.byType(Navigator).first);
    return Theme.of(context).colorScheme.primary;
  }

  /// 根 builder 内层 Theme 的实际亮度。
  Brightness get innerBrightness {
    final context = _tester.element(find.byType(Navigator).first);
    return Theme.of(context).brightness;
  }
}

/// 私有 Fake Gateway：直接转发注入流，不触达平台通道。
class _FakeAccentColorGateway implements SystemAccentColorGateway {
  _FakeAccentColorGateway(this._stream);

  final Stream<SystemAccentColor?> _stream;

  @override
  Stream<SystemAccentColor?> watchAccentColor() => _stream;
}

/// 停在启动页的空闲启动序列：只提供路由 redirect 需要的状态。
class _IdleLaunchSequence extends LaunchSequence {
  @override
  LaunchState build() => const LaunchState();

  @override
  Future<void> runSequence() async {}
}
