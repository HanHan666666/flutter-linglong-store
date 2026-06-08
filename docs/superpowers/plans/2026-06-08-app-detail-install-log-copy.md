# App Detail Install Log Copy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change the app detail status-bar copy action to copy the matched download-manager install log instead of copying status or error text.

**Architecture:** `AppDetailPage` remains the only reader of `installQueueProvider` for the detail header. It extracts `InstallTask.commandOutput.trim()` from the already matched task and passes it to `AppDetailHeroHeader`; the header renders a copy button only when that log text is non-empty.

**Tech Stack:** Flutter, Riverpod, Material widgets, Flutter Clipboard platform channel, ARB localization, widget tests.

---

## File Map

- Modify: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
  - Replace existing status-copy expectations with install-log copy expectations.
  - Add a regression test for hiding the copy button when `commandOutput` is empty.
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
  - Resolve a nullable install-log copy text from the matched `InstallTask`.
  - Pass the log text to `AppDetailHeroHeader`.
- Modify: `lib/presentation/widgets/app_detail_hero_header.dart`
  - Rename the copy parameter to install-log semantics.
  - Render the copy button only when log text exists.
  - Use `l10n.copyLog` for Tooltip, Semantics, and visible text.
- Modify: `docs/superpowers/specs/2026-06-08-app-detail-install-log-copy-design.md`
  - Record the approved data source and hiding rule.
- Modify: `docs/superpowers/plans/2026-06-08-app-detail-install-log-copy.md`
  - Track implementation and verification steps.

## Task 1: Regression Tests

**Files:**
- Modify: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`

- [ ] **Step 1: Update the existing status-copy test**

Replace the test named `header installing state renders independent copyable status bar` so it provides both a display message and a command log:

```dart
const displayedMessage = '准备安装...';
const commandOutput =
    'll-cli install --json org.example.demo\n'
    '{"message":"准备安装..."}\n'
    '{"message":"正在下载","percentage":42}';
```

The task fixture must set `commandOutput: commandOutput`.

- [ ] **Step 2: Assert log-copy behavior**

In the same test, verify the status message remains visible, then tap the new log-copy button:

```dart
expect(
  find.descendant(of: statusBar, matching: find.text(displayedMessage)),
  findsOneWidget,
);
expect(
  find.descendant(of: statusBar, matching: find.text('复制日志')),
  findsOneWidget,
);
expect(
  find.descendant(of: statusBar, matching: find.text('复制')),
  findsNothing,
);

await tester.tap(
  find.descendant(
    of: statusBar,
    matching: find.widgetWithText(TextButton, '复制日志'),
  ),
);
await tester.pump();

expect(
  clipboardCall?.arguments,
  equals(<String, dynamic>{'text': commandOutput}),
);
```

- [ ] **Step 3: Add the empty-log hiding test**

Add a widget test named `header hides install log copy action when matched task has no command output`:

```dart
testWidgets(
  'header hides install log copy action when matched task has no command output',
  (tester) async {
    await tester.binding.setSurfaceSize(const Size(760, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const displayedMessage = '安装完成';

    await tester.pumpWidget(
      _buildTestApp(
        appId: 'org.example.demo',
        uninstallService: _RecordingUninstallService(),
        detailState: _detailState(versions: const []),
        installedApps: const [],
        installQueueState: const InstallQueueState(
          history: [
            InstallTask(
              id: 'history-task-without-output',
              appId: 'org.example.demo',
              appName: 'Demo',
              version: '2.0.0',
              status: InstallStatus.success,
              message: displayedMessage,
              createdAt: 0,
              finishedAt: 1,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final statusBar = find.byKey(const Key('app-detail-hero-status-bar'));
    expect(statusBar, findsOneWidget);
    expect(
      find.descendant(of: statusBar, matching: find.text(displayedMessage)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: statusBar, matching: find.text('复制日志')),
      findsNothing,
    );
    expect(
      find.descendant(of: statusBar, matching: find.byType(TextButton)),
      findsNothing,
    );
  },
);
```

- [ ] **Step 4: Run focused tests and verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart --plain-name "header installing state renders independent copyable status bar"
/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart --plain-name "header hides install log copy action when matched task has no command output"
```

Expected: the first test fails because the current UI still shows `复制` and copies `statusMessage`; the second test fails because the current UI still renders a copy button even when `commandOutput` is empty.

## Task 2: Detail Page Data Flow

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`

- [ ] **Step 1: Add a log resolver**

Add this helper near the existing status-copy helper:

```dart
String? _resolveInstallLogCopyText(InstallTask? installTask) {
  final output = installTask?.commandOutput.trim();
  if (output == null || output.isEmpty) {
    return null;
  }
  return output;
}
```

- [ ] **Step 2: Pass log text to the header**

In `_buildHeader()`, replace `statusCopyText` usage with:

```dart
final installLogCopyText = _resolveInstallLogCopyText(installTask);
```

Pass the value to `AppDetailHeroHeader`:

```dart
statusLogCopyText: installLogCopyText,
```

Remove `_resolveFailedInstallStatusCopyText()` if no remaining caller uses it.

## Task 3: Header Rendering

**Files:**
- Modify: `lib/presentation/widgets/app_detail_hero_header.dart`

- [ ] **Step 1: Rename the constructor parameter**

Replace:

```dart
this.statusCopyText,
```

with:

```dart
this.statusLogCopyText,
```

Replace the field and comment:

```dart
/// 状态条复制按钮使用的下载管理安装日志。
final String? statusLogCopyText;
```

- [ ] **Step 2: Copy only install logs**

In `_buildStatusBar()`, resolve log text:

```dart
final logCopyText = statusLogCopyText?.trim();
final hasLogCopyText = logCopyText != null && logCopyText.isNotEmpty;
```

Pass `logCopyText` only when `hasLogCopyText` is true:

```dart
? _buildFailedStatusContent(context, statusText, hasLogCopyText ? logCopyText : null)
: _buildNormalStatusContent(context, statusText, hasLogCopyText ? logCopyText : null)
```

- [ ] **Step 3: Make copy button conditional**

Change `_buildNormalStatusContent()` and `_buildFailedStatusContent()` to accept `String? logCopyText`.

In the normal row, render:

```dart
if (logCopyText != null) ...[
  const SizedBox(width: 8),
  _buildStatusCopyButton(context, logCopyText),
],
```

In the failed layout, render the aligned copy button only when `logCopyText != null`.

- [ ] **Step 4: Use log-copy localization**

Change `_buildStatusCopyButton()` to:

```dart
Widget _buildStatusCopyButton(BuildContext context, String logCopyText) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final label = l10n.copyLog;

  return Semantics(
    label: label,
    button: true,
    child: Tooltip(
      message: label,
      child: TextButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: logCopyText));
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}
```

## Task 4: Verification And Commit

**Files:**
- Verify modified source, tests, and docs.

- [ ] **Step 1: Run focused app-detail tests**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart --plain-name "header installing state renders independent copyable status bar"
/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart --plain-name "header hides install log copy action when matched task has no command output"
```

Expected: both tests pass.

- [ ] **Step 2: Run the full app-detail page widget test file**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart
```

Expected: all tests in the file pass.

- [ ] **Step 3: Run static analysis**

Run:

```bash
/home/han/flutter/bin/flutter analyze
```

Expected: exits 0 with no errors or warnings introduced by this change.

- [ ] **Step 4: Review diff**

Run:

```bash
git diff -- lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/widgets/app_detail_hero_header.dart test/widget/presentation/pages/app_detail/app_detail_page_test.dart docs/superpowers/specs/2026-06-08-app-detail-install-log-copy-design.md docs/superpowers/plans/2026-06-08-app-detail-install-log-copy.md
```

Expected: diff only contains the documented app-detail install-log copy behavior, tests, and docs.

- [ ] **Step 5: Commit code changes**

Run:

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/widgets/app_detail_hero_header.dart test/widget/presentation/pages/app_detail/app_detail_page_test.dart docs/superpowers/specs/2026-06-08-app-detail-install-log-copy-design.md docs/superpowers/plans/2026-06-08-app-detail-install-log-copy.md
git commit -m "fix: 详情页复制安装日志"
```

Expected: commit succeeds with a Conventional Commits message.
