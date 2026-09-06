/// 可拖拽调宽侧边栏（ResizableSidebar）组件测试。
///
/// 覆盖 issue #27 的核心交互：
/// 1. 默认展开宽度渲染与拖拽手柄存在性；
/// 2. 拖拽加宽/收窄及 [SidebarWidthPolicy] 边界钳制；
/// 3. 拖拽结束时持久化、双击重置（恢复默认并清除持久化键）；
/// 4. RTL（阿拉伯语）下拖拽方向镜像；
/// 5. 键盘左右方向键微调（等效无障碍 increase/decrease）；
/// 6. ≤768px 自动折叠态隐藏手柄；
/// 7. 下次启动从持久化恢复宽度。
library;

import 'package:flutter/gestures.dart'
    show kDoubleTapMinTime, kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart'
    show sharedPreferencesProvider;
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/sidebar_width_provider.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/presentation/widgets/resizable_sidebar.dart';
import 'package:linglong_store/presentation/widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 手柄的本地化语义标签（zh 模板），测试用其定位交互面。
  const handleLabel = '调整侧边栏宽度';

  Future<SharedPreferences> mockPrefs({double? sidebarWidth}) async {
    final initialValues = <String, Object>{};
    // sidebarWidth 为 null 时不写入持久化键，走默认宽度分支
    if (sidebarWidth != null) {
      initialValues[SidebarWidthPolicy.prefsKey] = sidebarWidth;
    }
    SharedPreferences.setMockInitialValues(initialValues);
    return SharedPreferences.getInstance();
  }

  /// 构建被测组件。
  ///
  /// 挂载真实的 [Sidebar] 以同时验证「外层紧约束覆盖其内部默认宽度」
  /// 这一集成点；installQueueProvider 覆盖为空队列，隔离安装队列副作用。
  Future<void> pumpResizableSidebar(
    WidgetTester tester, {
    required SharedPreferences prefs,
    Size windowSize = const Size(1280, 800),
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          installQueueProvider.overrideWith(() => TestInstallQueue()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            // 测试窗口尺寸与真实桌面窗口解耦，覆盖折叠断点分支
            data: MediaQueryData(size: windowSize),
            child: const Scaffold(
              body: ResizableSidebar(
                sidebar: Sidebar(currentPath: '/recommend'),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('默认渲染展开态：宽度 176 且拖拽手柄存在', (tester) async {
    await pumpResizableSidebar(tester, prefs: await mockPrefs());

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.defaultWidth,
    );
    expect(find.bySemanticsLabel(handleLabel), findsOneWidget);
  });

  testWidgets('拖拽手柄向右加宽 80px', (tester) async {
    await pumpResizableSidebar(tester, prefs: await mockPrefs());

    await tester.drag(find.bySemanticsLabel(handleLabel), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.defaultWidth + 80,
    );
  });

  testWidgets('拖拽宽度被钳制在上限 400px', (tester) async {
    await pumpResizableSidebar(tester, prefs: await mockPrefs());

    await tester.drag(find.bySemanticsLabel(handleLabel), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.maxWidth,
    );
  });

  testWidgets('拖拽宽度被钳制在下限 120px', (tester) async {
    await pumpResizableSidebar(tester, prefs: await mockPrefs());

    await tester.drag(
      find.bySemanticsLabel(handleLabel),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.minWidth,
    );
  });

  testWidgets('拖拽结束后宽度持久化', (tester) async {
    final prefs = await mockPrefs();
    await pumpResizableSidebar(tester, prefs: prefs);

    await tester.drag(find.bySemanticsLabel(handleLabel), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(
      prefs.getDouble(SidebarWidthPolicy.prefsKey),
      SidebarWidthPolicy.defaultWidth + 80,
    );
  });

  testWidgets('双击手柄恢复默认宽度并清除持久化', (tester) async {
    final prefs = await mockPrefs();
    await pumpResizableSidebar(tester, prefs: prefs);

    // 先拖宽再双击，验证重置回到默认并移除持久化键
    await tester.drag(find.bySemanticsLabel(handleLabel), const Offset(80, 0));
    await tester.pumpAndSettle();
    final handleFinder = find.bySemanticsLabel(handleLabel);
    await tester.tap(handleFinder);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(handleFinder);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.defaultWidth,
    );
    expect(prefs.getDouble(SidebarWidthPolicy.prefsKey), isNull);
  });

  testWidgets('RTL（阿拉伯语）下拖拽方向镜像：向左拖为加宽', (tester) async {
    await pumpResizableSidebar(
      tester,
      prefs: await mockPrefs(),
      locale: const Locale('ar'),
    );

    await tester.drag(
      find.bySemanticsLabel('تغيير عرض الشريط الجانبي'),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.defaultWidth + 80,
    );
  });

  testWidgets('键盘方向键微调宽度并持久化', (tester) async {
    final prefs = await mockPrefs();
    await pumpResizableSidebar(tester, prefs: prefs);

    // 点按手柄获得焦点（注册了双击识别后，单击 onTap 需等双击窗口超时
    // 才会触发），再按右方向键加宽一步
    await tester.tap(find.bySemanticsLabel(handleLabel));
    await tester.pump(kDoubleTapTimeout);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(Sidebar)).width,
      SidebarWidthPolicy.defaultWidth + SidebarWidthPolicy.keyboardStep,
    );
    expect(
      prefs.getDouble(SidebarWidthPolicy.prefsKey),
      SidebarWidthPolicy.defaultWidth + SidebarWidthPolicy.keyboardStep,
    );
  });

  testWidgets('≤768px 自动折叠态隐藏手柄并保持 56px', (tester) async {
    await pumpResizableSidebar(
      tester,
      prefs: await mockPrefs(),
      windowSize: const Size(600, 800),
    );

    expect(tester.getSize(find.byType(Sidebar)).width, Sidebar.collapsedWidth);
    expect(find.bySemanticsLabel(handleLabel), findsNothing);
  });

  testWidgets('下次启动从持久化恢复宽度', (tester) async {
    await pumpResizableSidebar(
      tester,
      prefs: await mockPrefs(sidebarWidth: 300),
    );

    expect(tester.getSize(find.byType(Sidebar)).width, 300);
  });
}

/// 空队列安装队列桩：隔离 Sidebar 红点徽章对真实队列副作用的依赖。
class TestInstallQueue extends InstallQueue {
  @override
  InstallQueueState build() => const InstallQueueState();
}
