# Remove Repo Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the user-configurable repository setting chain while preserving protocol-level `repoName` fields and default repository request behavior.

**Architecture:** Collapse repository selection to the existing default constant in `AppConfig`, remove repository preference state from settings/global providers, and delete the settings-page repository UI. Keep DTO/model `repoName` fields intact because they are part of backend and installed-app contracts.

**Tech Stack:** Flutter, Riverpod, Freezed, SharedPreferences, Flutter gen-l10n, Flutter test

---

### Task 1: Lock the intended behavior with failing tests

**Files:**
- Modify: `test/unit/application/providers/startup_state_restore_test.dart`
- Modify: `lib/presentation/pages/setting/setting_page.dart`
- Test: `test/unit/application/providers/startup_state_restore_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('setting provider restores locale and theme without repo preference', () async {
  SharedPreferences.setMockInitialValues({
    'linglong-store-language': 'en',
    'linglong-store-theme-mode': ThemeMode.light.index,
    'repo_name': 'repo:test',
  });

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  final state = container.read(settingProvider);

  expect(state.locale, const Locale('en'));
  expect(state.themeMode, ThemeMode.light);
  expect(state.cacheSize, 0);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/startup_state_restore_test.dart`
Expected: FAIL because the existing test and provider still expose `repoName`.

- [ ] **Step 3: Write minimal implementation**

```dart
const factory SettingState({
  @Default(Locale('zh')) Locale locale,
  @Default(ThemeMode.system) ThemeMode themeMode,
  @Default(0) int cacheSize,
  ...
}) = _SettingState;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/startup_state_restore_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/unit/application/providers/startup_state_restore_test.dart lib/application/providers/setting_provider.dart lib/application/providers/global_provider.dart lib/application/providers/launch_provider.dart
git commit -m "refactor: 移除仓库配置状态链路"
```

### Task 2: Remove the settings-page repository configuration UI

**Files:**
- Modify: `lib/presentation/pages/setting/setting_page.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Modify: `lib/core/i18n/l10n/app_localizations.dart`
- Modify: `lib/core/i18n/l10n/app_localizations_zh.dart`
- Modify: `lib/core/i18n/l10n/app_localizations_en.dart`
- Test: `test/widget/presentation/pages/setting/setting_page_test.dart` (create only if coverage is already present for the page)

- [ ] **Step 1: Write the failing test or assertion target**

```dart
expect(find.text('仓库配置'), findsNothing);
expect(find.text('Repository Config'), findsNothing);
```

- [ ] **Step 2: Run targeted verification**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/setting/setting_page_test.dart`
Expected: FAIL if the settings page test exists; otherwise skip file creation and rely on compile/analyze verification after removal.

- [ ] **Step 3: Remove the UI and string references**

```dart
// Delete the repo section from SettingPage and make app totals use AppConfig.defaultStoreRepoName.
SearchAppListRequest(
  keyword: '',
  pageNo: 1,
  pageSize: 1,
  repoName: AppConfig.defaultStoreRepoName,
);
```

- [ ] **Step 4: Regenerate localization outputs if ARB keys changed**

Run: `/home/han/flutter/bin/flutter gen-l10n`
Expected: generated localization classes no longer contain `repoConfig`, `editRepo`, or `repoSwitched`.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/setting/setting_page.dart lib/core/i18n/l10n/app_zh.arb lib/core/i18n/l10n/app_en.arb lib/core/i18n/l10n/app_localizations.dart lib/core/i18n/l10n/app_localizations_zh.dart lib/core/i18n/l10n/app_localizations_en.dart
git commit -m "refactor: 删除设置页仓库配置入口"
```

### Task 3: Remove dead persistence helpers and update docs

**Files:**
- Modify: `lib/core/storage/preferences_service.dart`
- Modify: `docs/11-startup-flow-and-first-frame-restore.md`
- Modify: `docs/03d-ui-pages.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Remove the obsolete preference helpers**

```dart
// Delete getRepoName()/setRepoName() from PreferencesService.
```

- [ ] **Step 2: Update documentation to match the new behavior**

```md
- Provider 首帧恢复只覆盖语言、主题、用户偏好和安装队列，不再恢复仓库配置。
- 设置页不提供仓库源配置入口；接口层继续统一使用默认 repoName。
```

- [ ] **Step 3: Run focused verification**

Run: `rg -n "repoConfig|editRepo|repoSwitched|setRepoName\\(|repo_name" lib docs AGENTS.md test --glob '!**/*.g.dart' --glob '!**/*.freezed.dart'`
Expected: only protocol/data references remain; no user-configurable repository preference code remains.

- [ ] **Step 4: Commit**

```bash
git add lib/core/storage/preferences_service.dart docs/11-startup-flow-and-first-frame-restore.md docs/03d-ui-pages.md AGENTS.md
git commit -m "docs: 同步移除仓库配置约定"
```

### Task 4: Final verification

**Files:**
- Verify only

- [ ] **Step 1: Run provider/unit verification**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/startup_state_restore_test.dart`
Expected: PASS

- [ ] **Step 2: Run localization/codegen verification if needed**

Run: `/home/han/flutter/bin/flutter gen-l10n`
Expected: exit 0

- [ ] **Step 3: Run analyzer**

Run: `/home/han/flutter/bin/flutter analyze`
Expected: 0 error / 0 warning for this branch

- [ ] **Step 4: Inspect the diff**

Run: `git diff --stat`
Expected: only repository-config removal, doc sync, and generated localization updates
