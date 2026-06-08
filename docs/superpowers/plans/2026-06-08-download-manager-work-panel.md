# 下载中心任务工作面板 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将下载管理弹窗重构为参考图片预览灯箱的精致任务工作面板，同时保持安装队列业务行为不变。

**Architecture:** 继续以 `DownloadManagerDialog` 作为唯一入口，使用 `installQueueProvider` 与 `networkSpeedProvider` 派生展示状态。UI 拆成稳定 shell、顶栏、概览条、滚动任务区、底部状态栏和任务行组件，业务动作仍由现有 provider 回调承接。

**Tech Stack:** Flutter desktop, Riverpod, Material widgets, existing `AppColors` / `AppSpacing` / `AppTextStyles`, widget tests.

---

## File Structure

- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
  - 增加工作面板结构测试，验证新 shell 的关键可观察结构和当前任务标签。
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
  - 重构弹窗 shell、顶栏、概览条、任务列表和底部状态栏。
  - 保留取消、重试、打开、移除、复制日志等现有业务回调。
- Create: `docs/superpowers/specs/2026-06-08-download-manager-work-panel-design.md`
  - 记录用户确认的 UI 方案、约束和验收标准。
- Create: `docs/superpowers/plans/2026-06-08-download-manager-work-panel.md`
  - 记录实施步骤和验证命令。

## Task 1: Write Failing Layout Test

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Add a widget test for the work-panel shell**

Add a test under `group('DownloadManagerDialog', ...)`:

```dart
testWidgets('renders refined work panel structure for active tasks', (
  tester,
) async {
  final installQueue = TestInstallQueue(
    initialState: InstallQueueState(
      currentTask: InstallTask(
        id: 'task-1',
        appId: 'org.example.demo',
        appName: 'Demo',
        kind: InstallTaskKind.install,
        status: InstallStatus.downloading,
        progress: 0.42,
        message: 'Downloading files',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      queue: [
        InstallTask(
          id: 'task-2',
          appId: 'org.example.next',
          appName: 'Next',
          kind: InstallTaskKind.install,
          status: InstallStatus.pending,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
      isProcessing: true,
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        installQueueProvider.overrideWith(() => installQueue),
        networkSpeedProvider.overrideWithValue(
          const NetworkSpeed(downloadBytesPerSec: 1024 * 1024),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showDownloadManagerDialog(context),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('downloadManagerTitleBar')), findsOneWidget);
  expect(find.byKey(const Key('downloadManagerOverviewBar')), findsOneWidget);
  expect(find.byKey(const Key('downloadManagerTaskList')), findsOneWidget);
  expect(find.byKey(const Key('downloadManagerStatusBar')), findsOneWidget);
  expect(find.text('当前任务'), findsOneWidget);

  final dialogSize = tester.getSize(find.byType(Dialog));
  expect(dialogSize.width, greaterThanOrEqualTo(560));
  expect(dialogSize.height, greaterThanOrEqualTo(460));
});
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: FAIL because the current dialog has no `downloadManagerTitleBar` / `downloadManagerOverviewBar` / `downloadManagerTaskList` / `downloadManagerStatusBar` keys, does not render the `当前任务` label, and still uses the old narrow shell width.

## Task 2: Implement The Work-Panel Shell

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: Replace the fixed narrow shell**

Change `DownloadManagerDialog` constants and root build:

```dart
static const double _dialogWidth = 640;
static const double _dialogMinHeight = 480;
static const double _dialogMaxHeight = 620;
static const double _dialogRadius = 12;
```

Use `LayoutBuilder` to clamp height to available desktop space and keep the list bounded:

```dart
return Dialog(
  insetPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.x2l,
    vertical: AppSpacing.xl,
  ),
  backgroundColor: Colors.transparent,
  child: LayoutBuilder(
    builder: (context, constraints) {
      final availableHeight = MediaQuery.sizeOf(context).height - AppSpacing.x5l;
      final dialogHeight = availableHeight.clamp(
        _dialogMinHeight,
        _dialogMaxHeight,
      );
      return SizedBox(
        width: _dialogWidth,
        height: dialogHeight,
        child: DecoratedBox(...),
      );
    },
  ),
);
```

- [ ] **Step 2: Add top title bar and overview bar keys**

Add keys:

```dart
key: const Key('downloadManagerTitleBar')
key: const Key('downloadManagerOverviewBar')
key: const Key('downloadManagerTaskList')
key: const Key('downloadManagerStatusBar')
```

These keys are test-facing layout anchors, not business state.

- [ ] **Step 3: Keep only list content scrollable**

Use `Expanded(child: _buildContent(...))`; inside `_buildContent`, keep `Scrollbar` + `SingleChildScrollView`, and make the outer shell fixed height.

## Task 3: Refine Task Cards And Actions

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: Update current task card**

The featured card should render:

- app icon `48px`
- app name
- subtitle with version/message
- status pill label `当前任务`
- cancel action
- progress row with message, percentage, speed, version
- linear progress bar

- [ ] **Step 2: Update waiting/history rows**

Compact rows should render:

- app icon `40px`
- app name and one-line subtitle
- status pill
- copy log button when `commandOutput` is non-empty
- row actions with stable 36px icon hit areas

- [ ] **Step 3: Preserve existing behavior**

Keep the existing callbacks:

```dart
cancelTask(task.appId)
removeQueuedTask(task.id)
retryFailedTask(task.id)
removeHistoryTask(task.id)
runApp(task.appId)
```

Do not add any shell calls or new repository methods.

## Task 4: Verify And Commit

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Create: `docs/superpowers/specs/2026-06-08-download-manager-work-panel-design.md`
- Create: `docs/superpowers/plans/2026-06-08-download-manager-work-panel.md`

- [ ] **Step 1: Format changed Dart files**

Run:

```bash
dart format lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
```

- [ ] **Step 2: Run targeted widget tests**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: all tests in the file pass.

- [ ] **Step 3: Run focused analysis**

Run:

```bash
/home/han/flutter/bin/flutter analyze lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: no new analyzer errors or warnings for the touched files.

- [ ] **Step 4: Commit**

Run:

```bash
git add docs/superpowers/specs/2026-06-08-download-manager-work-panel-design.md docs/superpowers/plans/2026-06-08-download-manager-work-panel.md test/widget/presentation/widgets/download_manager_dialog_test.dart lib/presentation/widgets/download_manager_dialog.dart
git commit -m "feat: 优化下载中心任务面板"
```

## Self-Review

- Spec coverage: shell、顶栏、概览条、当前任务、队列/历史、底部状态栏、行为保持、测试策略均有对应任务。
- Placeholder scan: plan does not contain `TBD`, `TODO`, `implement later`, or undefined future steps.
- Type consistency: all referenced files and providers already exist in the repository; new test keys are introduced in Task 2.
