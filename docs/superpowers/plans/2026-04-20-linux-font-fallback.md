# Linux Font Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Linux desktop theme explicitly provide Chinese-capable font fallbacks so packaged builds no longer depend on fragile distro-specific default font selection.

**Architecture:** Keep the fix inside the global theme entry point. Add one shared helper in `AppTheme` that applies a Linux-oriented fallback list to both the global `textTheme` and any component-theme `TextStyle` instances derived from `AppTextStyles`, then lock that behavior with focused unit tests.

**Tech Stack:** Flutter, Material 3 `ThemeData`, `flutter_test`, existing theme/config test suite

---

### Task 1: Lock Theme Font Fallback Expectations

**Files:**
- Modify: `test/unit/core/config/app_theme_test.dart`
- Modify: `lib/core/config/theme/app_theme.dart`

- [ ] **Step 1: Write the failing tests**

Add expectations covering the shared fallback list on both text-theme and component-theme styles:

```dart
const expectedFallback = <String>[
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'WenQuanYi Micro Hei',
  'WenQuanYi Zen Hei',
  'Noto Color Emoji',
];

expect(
  AppTheme.lightTheme.textTheme.bodyMedium?.fontFamilyFallback,
  expectedFallback,
);
expect(
  AppTheme.darkTheme.textTheme.bodyMedium?.fontFamilyFallback,
  expectedFallback,
);
expect(
  AppTheme.lightTheme.appBarTheme.titleTextStyle?.fontFamilyFallback,
  expectedFallback,
);
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
build/scripts/run-in-release-container.sh flutter test test/unit/core/config/app_theme_test.dart
```

Expected: FAIL because the current theme styles do not set `fontFamilyFallback`

- [ ] **Step 3: Write minimal implementation**

In `lib/core/config/theme/app_theme.dart`, add a shared fallback list and helpers shaped like:

```dart
static const _linuxFontFamilyFallback = <String>[
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'WenQuanYi Micro Hei',
  'WenQuanYi Zen Hei',
  'Noto Color Emoji',
];

static TextStyle _withLinuxFontFallback(TextStyle style, {Color? color}) {
  return style.copyWith(
    color: color,
    fontFamilyFallback: _linuxFontFamilyFallback,
  );
}
```

and apply that helper to:

```dart
textTheme: _withLinuxFontFallbacks(AppTextStyles.textTheme),
titleTextStyle: _withLinuxFontFallback(AppTextStyles.title2, color: ...),
hintStyle: _withLinuxFontFallback(AppTextStyles.caption, color: ...),
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
build/scripts/run-in-release-container.sh flutter test test/unit/core/config/app_theme_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/theme/app_theme.dart test/unit/core/config/app_theme_test.dart
git commit -m "fix: 为 Linux 主题补充中文字体回退"
```

### Task 2: Record the New Theme Constraint

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Document the rule**

Append a change-log entry describing:

```text
Linux 桌面主题必须在 AppTheme 统一配置中文 fontFamilyFallback，所有从 AppTextStyles 派生的组件主题文本样式也必须复用同一 helper，禁止页面内各自散写字体回退列表。
```

- [ ] **Step 2: Run focused verification**

Run:

```bash
build/scripts/run-in-release-container.sh flutter analyze lib/core/config/theme/app_theme.dart test/unit/core/config/app_theme_test.dart
build/scripts/run-in-release-container.sh flutter test test/unit/core/config/app_theme_test.dart
```

Expected: analyze and test both succeed

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md docs/superpowers/specs/2026-04-20-linux-font-fallback-design.md docs/superpowers/plans/2026-04-20-linux-font-fallback.md
git commit -m "docs: 记录 Linux 字体回退修复方案"
```
