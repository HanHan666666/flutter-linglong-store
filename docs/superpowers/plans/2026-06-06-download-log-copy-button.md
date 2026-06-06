# Download Log Copy Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move download-center install-log copying from whole-item clicks to an explicit copy button with local success text feedback.

**Architecture:** Keep `DownloadManagerDialog` as the single UI owner for download task actions. `_TaskCard` owns only local copy-button feedback state; `InstallQueue` and `InstallTask.commandOutput` storage remain unchanged.

**Tech Stack:** Flutter, Riverpod, Material widgets, Flutter Clipboard platform channel, ARB-based localizations, widget tests.

---

## File Map

- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`
  - Replace the old whole-row copy expectation with a regression test for button-only copying and local success text.
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
  - Remove whole-card copy tap behavior.
  - Add a compact copy button to `_TaskCard` when `commandOutput` exists.
  - Keep copy feedback inside `_TaskCardState` with a 1200ms timer.
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Add `copyLog` and `copySucceeded`.
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Add `copyLog` and `copySucceeded`.
- Regenerate/modify: `lib/core/i18n/l10n/app_localizations*.dart`
- Expose the new `copyLog` and `copySucceeded` getters.

## Task 1: Write The Regression Test

**Files:**
- Modify: `test/widget/presentation/widgets/download_manager_dialog_test.dart`

- [ ] **Step 1: Replace the current copy test**

Replace the existing test named `clicking a history item copies its command output` with a test named `copy button copies command output and shows local success text`.

The test must:

```dart
expect(clipboardCall, isNull);
await tester.tap(find.text('微信'));
await tester.pump();
expect(clipboardCall, isNull);

await tester.tap(find.text('复制日志'));
await tester.pump();
expect(clipboardCall?.method, equals('Clipboard.setData'));
expect(clipboardCall?.arguments, {'text': commandOutput});
expect(find.text('复制成功'), findsOneWidget);
expect(find.text('命令已复制到剪贴板'), findsNothing);

await tester.pump(const Duration(milliseconds: 1200));
expect(find.text('复制日志'), findsOneWidget);
expect(find.text('复制成功'), findsNothing);
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart --plain-name "copy button copies command output and shows local success text"
```

Expected: FAIL because the current implementation copies from the whole task item and does not render a “复制” button in the download item action area.

## Task 2: Implement Button-Only Copying

**Files:**
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Regenerate/modify: `lib/core/i18n/l10n/app_localizations*.dart`

- [ ] **Step 1: Add `copyLog` and `copySucceeded` localization**

Add these ARB entries near `copy`:

```json
"copyLog": "复制日志",
"copySucceeded": "复制成功"
```

```json
"copyLog": "Copy Log",
"copySucceeded": "Copied"
```

- [ ] **Step 2: Update generated localization API**

Run:

```bash
flutter gen-l10n
```

Expected: generated `app_localizations.dart`, `app_localizations_zh.dart`, and `app_localizations_en.dart` expose `copyLog` and `copySucceeded`.

- [ ] **Step 3: Move copy behavior into `_TaskCardState`**

In `download_manager_dialog.dart`:

- remove the `app_notification_helpers.dart` import;
- remove `_copyCommandOutput()` from `DownloadManagerDialog`;
- remove `onCopyOutput` from `_TaskCard`;
- remove `InkWell.onTap`;
- add `_isOutputCopied`, `_copyFeedbackTimer`, and `_handleCopyOutputPressed()`;
- add a `TextButton` rendered only when `widget.task.commandOutput.trim().isNotEmpty`;
- make the button label `copySucceeded` while copied, otherwise `copyLog`.

Implementation details:

```dart
static const _copyFeedbackDuration = Duration(milliseconds: 1200);

Timer? _copyFeedbackTimer;
bool _isOutputCopied = false;

Future<void> _handleCopyOutputPressed() async {
  final output = widget.task.commandOutput.trim();
  if (output.isEmpty) {
    return;
  }

  await Clipboard.setData(ClipboardData(text: output));
  if (!mounted) {
    return;
  }

  _copyFeedbackTimer?.cancel();
  setState(() => _isOutputCopied = true);
  _copyFeedbackTimer = Timer(_copyFeedbackDuration, () {
    if (!mounted) {
      return;
    }
    setState(() => _isOutputCopied = false);
  });
}
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run:

```bash
flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart --plain-name "copy button copies command output and shows local success text"
```

Expected: PASS.

## Task 3: Full Verification And Commit

**Files:**
- Verify: all modified files

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

Expected: exits 0 with no errors or warnings introduced by this change.

- [ ] **Step 3: Review diff**

Run:

```bash
git diff -- lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb lib/core/i18n/l10n/app_localizations.dart lib/core/i18n/l10n/app_localizations_zh.dart lib/core/i18n/l10n/app_localizations_en.dart docs/superpowers/specs/2026-06-06-download-log-copy-button-design.md docs/superpowers/plans/2026-06-06-download-log-copy-button.md
```

Expected: diff only contains the documented copy-button behavior, localization, tests, and docs.

- [ ] **Step 4: Commit**

Run:

```bash
git add lib/presentation/widgets/download_manager_dialog.dart test/widget/presentation/widgets/download_manager_dialog_test.dart lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb lib/core/i18n/l10n/app_localizations.dart lib/core/i18n/l10n/app_localizations_zh.dart lib/core/i18n/l10n/app_localizations_en.dart docs/superpowers/specs/2026-06-06-download-log-copy-button-design.md docs/superpowers/plans/2026-06-06-download-log-copy-button.md
git commit -m "fix: 修正下载日志复制入口"
```

Expected: commit succeeds with a Conventional Commits message.
