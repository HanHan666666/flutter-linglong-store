# App Detail Version Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make app detail history rows show better actions and allow uninstalling an installed historical version precisely.

**Architecture:** Keep the existing app detail page structure, but upgrade the version row action area and route uninstall clicks through the existing `AppUninstallFlow` and `AppUninstallService`. Fix repository uninstall to send `appId/version` to `ll-cli`, so UI and backend behavior stay aligned for multi-version installs.

**Tech Stack:** Flutter, Riverpod, existing uninstall flow helpers, ll-cli repository, Flutter widget/unit tests

---

### Task 1: Lock Precise Version Uninstall Behavior

**Files:**
- Modify: `test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart`
- Modify: `lib/data/repositories/linglong_cli_repository_impl.dart`

- [ ] **Step 1: Write the failing test**

Add a test asserting `uninstallApp('org.example.demo', '1.2.3')` records:

```dart
expect(executor.executeCalls.single, [
  'uninstall',
  'org.example.demo/1.2.3',
]);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/han/flutter/bin/flutter test test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart`
Expected: FAIL because repository still sends only `appId`

- [ ] **Step 3: Write minimal implementation**

Change repository uninstall call to:

```dart
final output = await _execute([
  'uninstall',
  '$appId/$version',
], timeout: const Duration(minutes: 5));
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/han/flutter/bin/flutter test test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/linglong_cli_repository_impl.dart test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart
git commit -m "fix: 详情页版本卸载改为精确版本命令"
```

### Task 2: Add App Detail Version Row UI and Uninstall Entry

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Test: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Add tests covering:

```dart
expect(find.text('已安装'), findsOneWidget);
expect(find.text('卸载'), findsOneWidget);
expect(find.text('安装'), findsOneWidget);
```

and a test that tapping version-row uninstall calls the existing uninstall flow path.

- [ ] **Step 2: Run tests to verify they fail**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
Expected: FAIL because page test file or expectations do not exist yet

- [ ] **Step 3: Write minimal implementation**

Implement in app detail page:

```dart
Widget _buildVersionActionArea(...)
Future<void> _uninstallVersion(...)
InstalledApp? _resolveInstalledVersionTarget(...)
```

Render:

```dart
Wrap(
  spacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    _buildInstalledVersionBadge(context),
    _buildVersionActionButton(...),
  ],
)
```

and call:

```dart
await AppUninstallFlow.run(context, targetApp, ref.read(appUninstallServiceProvider));
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb test/widget/presentation/pages/app_detail/app_detail_page_test.dart
git commit -m "feat: 优化详情页历史版本操作区"
```

### Task 3: Verify End-to-End Regressions

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Document the new constraint**

Append the version-action rule to `AGENTS.md` describing:

```text
应用详情页历史版本已安装态必须显示“已安装 + 卸载”，并通过统一卸载流程按 appId/version 精确卸载。
```

- [ ] **Step 2: Run focused verification**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart test/widget/presentation/pages/app_detail/app_detail_page_test.dart
/home/han/flutter/bin/flutter analyze lib/data/repositories/linglong_cli_repository_impl.dart lib/presentation/pages/app_detail/app_detail_page.dart test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart test/widget/presentation/pages/app_detail/app_detail_page_test.dart
```

Expected: all pass with no analyzer issues

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: 记录详情页历史版本操作约定"
```
