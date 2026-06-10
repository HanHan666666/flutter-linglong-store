# Download Manager Progress Message Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the duplicate active-task progress message in the download manager and align the slow-install hint icon with its text.

**Architecture:** This is a presentation-layer-only change inside the existing download manager task card. The install queue state, command output, progress parsing, copy-log behavior, and ll-cli integration remain untouched.

**Tech Stack:** Flutter, Riverpod, Flutter widget tests, existing `AppTextStyles` and `AppColorPalette` theme extensions.

---

## File Structure

- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
  - Add a regression test proving an active task message appears only once in the current-task card.
  - Extend the slow-install hint test to assert the hint row contains both the warning icon and the localized hint text.
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
  - Keep current-task phase text only in `_buildProgressBar()`.
  - Keep compact queue/history subtitles unchanged.
  - Align the slow-install hint icon using a dedicated helper that documents the baseline/line-height reason.

## Task 1: Add Regression Coverage

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Write the failing duplicate-message test**

Add this widget test inside the `DownloadManagerDialog` group, near the other active-task progress tests:

```dart
    testWidgets('shows active task progress message only once', (
      tester,
    ) async {
      const progressMessage =
          'Updating main:com.tencent.wechat/4.1.1.7/x86_64/binary';
      final installQueue = TestInstallQueue(
        initialState: InstallQueueState(
          currentTask: InstallTask(
            id: 'task-duplicate-message',
            appId: 'com.tencent.wechat',
            appName: '微信',
            kind: InstallTaskKind.update,
            status: InstallStatus.installing,
            progress: 0.99,
            message: progressMessage,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
          isProcessing: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            installQueueProvider.overrideWith(() => installQueue),
            networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
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

      expect(find.text(progressMessage), findsOneWidget);
      expect(find.byTooltip(progressMessage), findsOneWidget);
    });
```

- [ ] **Step 2: Extend the slow-install hint structure test**

Inside the existing `shows slow install hint when progress stalls near completion` test, after the existing text assertion, add:

```dart
        final hintRow = find.ancestor(
          of: find.text('如果进度看起来较慢，可能正在安装软件必备依赖，请再等等……'),
          matching: find.byType(Row),
        );
        expect(hintRow, findsOneWidget);
        expect(
          find.descendant(
            of: hintRow,
            matching: find.byIcon(Icons.info_outline),
          ),
          findsOneWidget,
        );
```

- [ ] **Step 3: Run the focused test and verify RED**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart --plain-name "shows active task progress message only once"
```

Expected: FAIL because the same progress message is currently rendered once under the app name and once above the progress bar.

## Task 2: Implement Minimal UI Fix

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: Change the current-task title area to avoid phase text duplication**

Update `_buildTaskText()` so the subtitle is still rendered, but uses a featured-safe subtitle:

```dart
        Text(
          _buildSubtitle(context, includeProgressMessage: !featured),
          style: context.appTextStyles.caption.copyWith(
            color: appColors.textSecondary,
          ),
          maxLines: featured ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
```

- [ ] **Step 2: Add a parameterized subtitle helper**

Replace the existing `_buildSubtitle(BuildContext context)` signature and body with:

```dart
  /// 构建任务副标题；当前任务的阶段文案由进度区承载，避免同一卡片内重复展示。
  String _buildSubtitle(
    BuildContext context, {
    bool includeProgressMessage = true,
  }) {
    if (widget.task.isFailed &&
        widget.task.errorMessage != null &&
        widget.task.errorMessage!.isNotEmpty) {
      return widget.task.errorMessage!;
    }
    final displayMessage = widget.task.displayMessage?.trim();
    final parts = <String>[
      if (widget.task.version != null && widget.task.version!.isNotEmpty)
        widget.task.version!,
      if (includeProgressMessage &&
          displayMessage != null &&
          displayMessage.isNotEmpty)
        displayMessage,
      if (includeProgressMessage &&
          (displayMessage == null || displayMessage.isEmpty))
        switch (widget.task.status) {
          InstallStatus.pending => widget.task.waitingMessage,
          InstallStatus.downloading => '正在下载资源',
          InstallStatus.installing => '正在安装',
          InstallStatus.success => widget.task.successMessage,
          InstallStatus.failed => '安装失败',
          InstallStatus.cancelled => widget.task.cancelledMessage,
        },
    ];
    return parts.join(' · ');
  }
```

- [ ] **Step 3: Align the slow-install hint icon**

Replace the inline `Icon(Icons.info_outline, size: 14, color: appColors.warning)` in the slow-install hint row with a helper call:

```dart
                _buildSlowInstallHintIcon(context, appColors),
```

Add this helper near `_buildErrorText()`:

```dart
  /// 构建慢安装提示图标；中文 caption 行高高于 14px 图标，需要轻微下移保证首行视觉对齐。
  Widget _buildSlowInstallHintIcon(
    BuildContext context,
    AppColorPalette appColors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Icon(Icons.info_outline, size: 14, color: appColors.warning),
    );
  }
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart --plain-name "shows active task progress message only once"
```

Expected: PASS.

## Task 3: Verify, Document Outcome, and Commit

**Files:**
- Verify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
- Verify: `lib/presentation/widgets/download_manager_dialog.dart`

- [ ] **Step 1: Run the full download manager widget test file**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run static analysis**

Run:

```bash
flutter analyze
```

Expected: exit code 0 with no new error or warning.

- [ ] **Step 3: Review the diff**

Run:

```bash
git diff -- lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart
```

Expected: diff only changes current-task subtitle handling, slow-install hint icon alignment, and related widget tests.

- [ ] **Step 4: Commit the implementation**

Run:

```bash
git add lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart docs/superpowers/plans/2026-06-10-download-manager-progress-message-alignment.md
git commit -m "fix: 修复下载管理进度文案重复"
```

Expected: commit succeeds with a Conventional Commit message.

## Self-Review

- Spec coverage: duplicate progress message, slow-install hint alignment, unchanged install queue behavior, and verification are all covered.
- Placeholder scan: no unfinished markers or vague future work remains.
- Type consistency: helper names and existing types match the current download manager widget file.
- Constraint check: no git worktree is used because repository instructions forbid it without permission.
