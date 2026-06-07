# App Detail Header Actions UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重做应用详情页头部操作区，让安装、更新、打开、桌面快捷方式、卸载和分享操作形成清晰、专业、稳定的视觉层级。

**Architecture:** 页面层继续聚合 Riverpod 状态和业务回调；新增 `AppDetailHeroHeader` 只负责渲染。`InstallButton` 增加 `ButtonSize.hero`，`AppDetailSecondaryActions` 保留可见性和回调语义，仅升级视觉和无障碍。

**Tech Stack:** Flutter, Riverpod, Material 3, Flutter widget tests.

---

## Files

- Create: `lib/presentation/widgets/app_detail_hero_header.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/presentation/widgets/install_button.dart`
- Modify: `lib/presentation/widgets/app_detail_secondary_actions.dart`
- Modify: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
- Modify: `test/widget/presentation/widgets/app_detail_secondary_actions_test.dart`
- Modify: `test/widget/widgets/install_button_test.dart`
- Modify: `docs/03d-ui-pages.md`

## Task 1: Failing Tests For Detail Header Behavior

- [ ] Add widget tests in `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`:

```dart
testWidgets('uninstalled header shows install and hides installed-only actions', (tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _buildTestApp(
      appId: 'org.example.demo',
      uninstallService: _RecordingUninstallService(),
      detailState: _detailState(versions: const []),
      installedApps: const [],
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('app-detail-hero-header')), findsOneWidget);
  expect(find.byKey(const Key('app-detail-hero-primary-action')), findsOneWidget);
  expect(find.text('安 装'), findsOneWidget);
  expect(find.text('创建桌面快捷方式'), findsNothing);
  expect(find.text('卸载'), findsNothing);
  expect(find.byTooltip('分享'), findsOneWidget);
});
```

- [ ] Add installed/update header test:

```dart
testWidgets('installed header groups primary and secondary actions', (tester) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    _buildTestApp(
      appId: 'org.example.demo',
      uninstallService: _RecordingUninstallService(),
      detailState: _detailState(versions: const []),
      installedApps: const [
        InstalledApp(
          appId: 'org.example.demo',
          name: 'Demo',
          version: '2.0.0',
          arch: 'x86_64',
          channel: 'main',
          module: 'main',
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();

  final actionPanel = find.byKey(const Key('app-detail-hero-action-panel'));
  expect(actionPanel, findsOneWidget);
  expect(find.descendant(of: actionPanel, matching: find.text('打开')), findsOneWidget);
  expect(find.descendant(of: actionPanel, matching: find.text('创建桌面快捷方式')), findsOneWidget);
  expect(find.descendant(of: actionPanel, matching: find.text('卸载')), findsOneWidget);
  expect(find.descendant(of: actionPanel, matching: find.byTooltip('分享')), findsOneWidget);
});
```

- [ ] Add installing status bar test:

```dart
testWidgets('header renders installing status as independent copyable bar', (tester) async {
  await tester.binding.setSurfaceSize(const Size(760, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  const displayedMessage = '准备安装...';
  const rawMessage = '完整安装状态：正在解析依赖并准备安装';
  MethodCall? clipboardCall;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    clipboardCall = call;
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  await tester.pumpWidget(
    _buildTestApp(
      appId: 'org.example.demo',
      uninstallService: _RecordingUninstallService(),
      detailState: _detailState(versions: const []),
      installedApps: const [],
      installQueueState: InstallQueueState(
        currentTask: InstallTask(
          id: 'active-task',
          appId: 'org.example.demo',
          appName: 'Demo',
          version: '2.0.0',
          status: InstallStatus.installing,
          message: displayedMessage,
          rawMessage: rawMessage,
          createdAt: 0,
        ),
        isProcessing: true,
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();

  final statusBar = find.byKey(const Key('app-detail-hero-status-bar'));
  expect(statusBar, findsOneWidget);
  expect(find.descendant(of: statusBar, matching: find.text(displayedMessage)), findsOneWidget);
  await tester.tap(find.descendant(of: statusBar, matching: find.widgetWithText(TextButton, '复制')));
  await tester.pump();

  expect(clipboardCall?.arguments, equals(<String, dynamic>{'text': rawMessage}));
});
```

- [ ] Run:

```bash
flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart --plain-name "header"
```

Expected: fails because the new keys and independent hero header do not exist yet.

## Task 2: Failing Tests For Button And Secondary Actions

- [ ] Add `InstallButton` hero size test in `test/widget/widgets/install_button_test.dart`:

```dart
testWidgets('hero size uses 48px visual height and stable width constraints', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: InstallButton(
            state: InstallButtonState.notInstalled,
            size: ButtonSize.hero,
          ),
        ),
      ),
    ),
  );

  final buttonSize = tester.getSize(find.byType(FilledButton));
  expect(buttonSize.height, 48);
  expect(buttonSize.width, greaterThanOrEqualTo(144));
  expect(buttonSize.width, lessThanOrEqualTo(184));
});
```

- [ ] Add secondary actions test in `test/widget/presentation/widgets/app_detail_secondary_actions_test.dart`:

```dart
testWidgets('次级操作保持 48px 热区并提供工具提示', (tester) async {
  await pumpSecondaryActions(tester, isVisible: true);
  final l10n = l10nFor(tester);

  final shortcutButton = find.widgetWithText(OutlinedButton, l10n.createDesktopShortcut);
  final uninstallButton = find.widgetWithText(OutlinedButton, l10n.uninstall);

  expect(tester.getSize(shortcutButton).height, greaterThanOrEqualTo(48));
  expect(tester.getSize(uninstallButton).height, greaterThanOrEqualTo(48));
  expect(find.byTooltip(l10n.createDesktopShortcut), findsOneWidget);
  expect(find.byTooltip(l10n.uninstall), findsOneWidget);
});
```

- [ ] Run:

```bash
flutter test test/widget/widgets/install_button_test.dart --plain-name "hero size"
flutter test test/widget/presentation/widgets/app_detail_secondary_actions_test.dart --plain-name "48px"
```

Expected: fails because `ButtonSize.hero` does not exist and secondary actions are still 40px without tooltips.

## Task 3: Implement Button And Secondary Action Visuals

- [ ] In `lib/presentation/widgets/install_button.dart`, add `hero` to `ButtonSize`:

```dart
/// 按钮大小枚举
enum ButtonSize { small, medium, large, hero }
```

- [ ] Update `_getButtonHeight()`, `_getIconSize()`, `_getHorizontalPadding()`:

```dart
case ButtonSize.hero:
  return 48;
```

```dart
case ButtonSize.hero:
  return 20;
```

```dart
case ButtonSize.hero:
  return 24;
```

- [ ] Wrap button contents with stable constraints for `hero`:

```dart
BoxConstraints _getButtonConstraints() {
  return switch (widget.size) {
    ButtonSize.hero => const BoxConstraints(minWidth: 144, maxWidth: 184),
    _ => const BoxConstraints(),
  };
}
```

- [ ] Apply the constraints to primary, outlined, destructive, progress and pending button roots.
- [ ] In `lib/presentation/widgets/app_detail_secondary_actions.dart`, increase action height to `48`, add `Tooltip`, add `Semantics`, and keep existing callbacks unchanged.
- [ ] Run the two focused tests from Task 2 and confirm they pass.

## Task 4: Create And Integrate AppDetailHeroHeader

- [ ] Create `lib/presentation/widgets/app_detail_hero_header.dart`.
- [ ] Add file-level Chinese doc comment explaining that the widget owns only presentation and receives computed props from the page.
- [ ] Define `AppDetailHeroHeader` with required props for app data, tags, install button state, progress, download speed, status message, callbacks, source icon key, and visibility of installed-only actions.
- [ ] Implement responsive layout using `LayoutBuilder`:
  - `maxWidth >= 920`: icon + info + action panel in one row.
  - `maxWidth < 920`: icon + info first, action panel below.
  - Status bar always spans full header width.
- [ ] Move status bar rendering out of `AppDetailPage` into `AppDetailHeroHeader`; keep the copy text resolver in `AppDetailPage` and pass both display text and copy text into the header.
- [ ] In `lib/presentation/pages/app_detail/app_detail_page.dart`, replace the current header body with `AppDetailHeroHeader`.
- [ ] Keep `_installSourceKey` attached to the app icon in the new header.
- [ ] Keep `_handleInstallAction`, `_handleCancelInstall`, `_createShortcut`, `_showUninstallDialog`, and `_shareApp` unchanged except for callback wiring.
- [ ] Run the header tests from Task 1 and confirm they pass.

## Task 5: Documentation, Verification, Commit

- [ ] Update `docs/03d-ui-pages.md` detail page section with the new head action layout convention:
  - Head action is rendered by `AppDetailHeroHeader`.
  - `ButtonSize.hero` is the detail page primary action size.
  - Status message is an independent header status bar.
- [ ] Run focused tests:

```bash
flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart
flutter test test/widget/presentation/widgets/app_detail_secondary_actions_test.dart
flutter test test/widget/widgets/install_button_test.dart
```

- [ ] Run static analysis:

```bash
flutter analyze
```

- [ ] Commit implementation:

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/widgets/app_detail_hero_header.dart lib/presentation/widgets/install_button.dart lib/presentation/widgets/app_detail_secondary_actions.dart test/widget/presentation/pages/app_detail/app_detail_page_test.dart test/widget/presentation/widgets/app_detail_secondary_actions_test.dart test/widget/widgets/install_button_test.dart docs/03d-ui-pages.md
git commit -m "feat: 优化应用详情页头部操作区"
```
