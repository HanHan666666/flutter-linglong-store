# Global Typography Realignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-map Flutter text semantics to a larger desktop-readable typography system, then sweep shell, shared components, and pages so the app matches the approved reading density target.

**Architecture:** Treat `lib/core/config/theme.dart` as the single source of truth for typography semantics, then push the new contract through shell widgets, shared presentation widgets, and high-traffic pages. Any local `fontSize` that still exists after the sweep must be an explicit visual exception rather than a surrogate for broken theme semantics.

**Tech Stack:** Flutter desktop, Material 3 theme system, Riverpod presentation layer, widget tests, golden or screenshot verification where available

---

### Task 1: Write And Land The Approved Documents

**Files:**
- Create: `docs/superpowers/specs/2026-03-25-global-typography-realignment-design.md`
- Create: `docs/superpowers/plans/2026-03-25-global-typography-realignment.md`

- [ ] **Step 1: Write the approved design spec**

Capture:

- the new `TextTheme` scale
- the new `AppTextStyles` scale
- the shell/component/page layering strategy
- the rule that the benchmark is the user-provided reference screenshot, not legacy Rust code

- [ ] **Step 2: Write the execution plan**

Break implementation into source-of-truth theme work, shell work, shared widget work, page sweeps, and final verification.

- [ ] **Step 3: Commit the docs**

Run:

```bash
git add docs/superpowers/specs/2026-03-25-global-typography-realignment-design.md docs/superpowers/plans/2026-03-25-global-typography-realignment.md
git commit -m "docs: 补充全局字体语义整改方案"
```

### Task 2: Rebuild Typography Source Of Truth

**Files:**
- Modify: `lib/core/config/theme.dart`
- Modify: `docs/03a-ui-design-tokens.md`

- [ ] **Step 1: Write failing expectations for typography semantics if a stable test location already exists**

Preferred targets:

- a theme unit test if the repo already has theme-focused tests
- otherwise add a focused widget test that asserts the intended sizes from `Theme.of(context).textTheme`

Suggested expectations:

- `headlineLarge.fontSize == 28`
- `titleMedium.fontSize == 18`
- `bodyLarge.fontSize == 16`
- `bodyMedium.fontSize == 14`
- `bodySmall.fontSize == 13`
- `labelSmall.fontSize == 12`

- [ ] **Step 2: Run the focused test to verify RED**

Run the exact new test file or test case.

Expected: FAIL because current typography semantics are still mapped to smaller values.

- [ ] **Step 3: Update `AppTextStyles` and `TextTheme`**

Implement the approved target scale:

- `display = 32`
- `title1 = 28`
- `title2 = 24`
- `title3 = 20`
- `body = 16`
- `bodyMedium = 14`
- `caption = 13`
- `tiny = 12`
- `menuActive = 16`

And update `textTheme` accordingly:

- `headlineLarge = 28`
- `headlineMedium = 24`
- `headlineSmall = 22`
- `titleLarge = 20`
- `titleMedium = 18`
- `titleSmall = 16`
- `bodyLarge = 16`
- `bodyMedium = 14`
- `bodySmall = 13`
- `labelLarge = 14`
- `labelMedium = 13`
- `labelSmall = 12`

- [ ] **Step 4: Update the design-token doc**

Rewrite the typography section in `docs/03a-ui-design-tokens.md` so it matches the new contract and clearly marks:

- `12px` as label/tiny only
- `13px` as secondary metadata
- `14px` as standard supportive text
- `16px` as normal readable body text

- [ ] **Step 5: Run focused verification to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test <theme-test-path>
/home/han/flutter/bin/flutter analyze lib/core/config/theme.dart
```

Expected: PASS

- [ ] **Step 6: Commit the source-of-truth update**

```bash
git add lib/core/config/theme.dart docs/03a-ui-design-tokens.md <theme-test-path>
git commit -m "refactor: 重映射全局字体语义"
```

### Task 3: Adjust App Shell Typography

**Files:**
- Modify: `lib/presentation/widgets/title_bar.dart`
- Modify: `lib/presentation/widgets/sidebar.dart`
- Test: `test/widget/presentation/widgets/title_bar_test.dart`
- Test: `test/widget/presentation/widgets/sidebar_test.dart`

- [ ] **Step 1: Add or update shell-focused widget tests**

Cover:

- title bar app title uses the larger shell title style
- search input and placeholder render at the new supportive-text size
- expanded sidebar menu text uses the larger menu typography
- sidebar rows still fit within the intended desktop shell layout

- [ ] **Step 2: Run shell widget tests to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/title_bar_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/sidebar_test.dart
```

Expected: FAIL if current sizes or row heights still reflect the smaller typography contract.

- [ ] **Step 3: Update title bar typography**

Change:

- app title to `16px`-class shell text
- search field text and placeholder to `14px`
- search box height if needed to keep vertical centering after the font-size increase

- [ ] **Step 4: Update sidebar typography and row density**

Change:

- expanded menu text to the new `menuActive` scale
- row height from the current compact height to a more stable desktop-friendly height around `40`
- badge alignment so the larger text still feels centered

- [ ] **Step 5: Re-run shell verification**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/title_bar_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/sidebar_test.dart
/home/han/flutter/bin/flutter analyze lib/presentation/widgets/title_bar.dart lib/presentation/widgets/sidebar.dart
```

- [ ] **Step 6: Commit shell typography changes**

```bash
git add lib/presentation/widgets/title_bar.dart lib/presentation/widgets/sidebar.dart test/widget/presentation/widgets/title_bar_test.dart test/widget/presentation/widgets/sidebar_test.dart
git commit -m "refactor: 调整壳层字体层级"
```

### Task 4: Sweep Shared Presentation Widgets

**Files:**
- Modify: `lib/presentation/widgets/app_card.dart`
- Modify: `lib/presentation/widgets/download_manager_dialog.dart`
- Modify: `lib/presentation/widgets/empty_state.dart`
- Modify: `lib/presentation/widgets/error_state.dart`
- Modify: `lib/presentation/widgets/category_filter_header.dart`
- Modify: `lib/presentation/widgets/linglong_process_panel.dart`
- Modify: `lib/presentation/widgets/app_detail_comment_section.dart`
- Modify: `lib/presentation/widgets/app_detail_info_section.dart`
- Modify: `lib/presentation/widgets/feedback_dialog.dart`
- Modify: `lib/presentation/widgets/linglong_env_dialog.dart`

- [ ] **Step 1: Add or update focused widget coverage for the most reusable typography surfaces**

Priority:

- `app_card`
- `download_manager_dialog`
- `empty_state`
- `error_state`

Cover:

- card title is at least `16px`-class
- card description is `14px`-class
- dialog section titles and supporting text follow the new hierarchy
- empty/error descriptions no longer render using tiny text semantics

- [ ] **Step 2: Run focused widget tests to verify RED**

Run the exact focused widget test files for these shared widgets.

Expected: FAIL where current widget typography still depends on `12px` or `13px` raw values for normal-readable content.

- [ ] **Step 3: Replace raw small sizes with the approved semantic styles**

Apply these rules:

- card title -> `titleSmall` or equivalent `16px`
- card description -> `bodyMedium` or equivalent `14px`
- section title -> `titleMedium/titleLarge`
- metadata -> `bodySmall/caption`
- tags/badges only -> `labelSmall/tiny`

- [ ] **Step 4: Fix any layout regressions introduced by larger text**

Examples:

- increase row heights
- adjust icon/text spacing
- widen button padding where labels now feel cramped

- [ ] **Step 5: Re-run widget and analyze verification**

Run:

```bash
/home/han/flutter/bin/flutter test <shared-widget-test-files>
/home/han/flutter/bin/flutter analyze lib/presentation/widgets/app_card.dart lib/presentation/widgets/download_manager_dialog.dart lib/presentation/widgets/empty_state.dart lib/presentation/widgets/error_state.dart lib/presentation/widgets/category_filter_header.dart lib/presentation/widgets/linglong_process_panel.dart lib/presentation/widgets/app_detail_comment_section.dart lib/presentation/widgets/app_detail_info_section.dart lib/presentation/widgets/feedback_dialog.dart lib/presentation/widgets/linglong_env_dialog.dart
```

- [ ] **Step 6: Commit shared widget sweep**

```bash
git add lib/presentation/widgets/app_card.dart lib/presentation/widgets/download_manager_dialog.dart lib/presentation/widgets/empty_state.dart lib/presentation/widgets/error_state.dart lib/presentation/widgets/category_filter_header.dart lib/presentation/widgets/linglong_process_panel.dart lib/presentation/widgets/app_detail_comment_section.dart lib/presentation/widgets/app_detail_info_section.dart lib/presentation/widgets/feedback_dialog.dart lib/presentation/widgets/linglong_env_dialog.dart <shared-widget-test-files>
git commit -m "refactor: 统一通用组件字体语义"
```

### Task 5: Sweep High-Traffic Pages

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart`
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Modify: `lib/presentation/pages/search_list/search_list_page.dart`
- Modify: `lib/presentation/pages/setting/setting_page.dart`
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`
- Modify: `lib/presentation/pages/all_apps/all_apps_page.dart`
- Modify: `lib/presentation/pages/custom_category/custom_category_page.dart`
- Modify: `lib/presentation/pages/launch/launch_page.dart`
- Modify: `lib/core/config/routes.dart`

- [ ] **Step 1: Add or update page-level focused tests for typography-critical pages**

Priority order:

- app detail page
- recommend page
- setting page
- update page

Cover:

- detail page headline is the new large title scale
- detail description uses readable body text
- recommendation card clusters no longer rely on tiny description text
- settings descriptions and update metadata are no longer visually undersized

- [ ] **Step 2: Run focused page tests to verify RED**

Run the exact focused test files or cases for these pages.

Expected: FAIL where current text still reflects the old smaller typography contract.

- [ ] **Step 3: Update the app detail page first**

Implement:

- app title -> `headlineLarge` (`28px`)
- body description -> `bodyLarge` (`16px`)
- section titles -> `headlineSmall/titleMedium` depending on hierarchy
- metadata -> `bodySmall/bodyMedium`
- tag chips -> `labelSmall`

- [ ] **Step 4: Update list and content pages**

Sweep:

- `recommend_page.dart`
- `search_list_page.dart`
- `setting_page.dart`
- `update_app_page.dart`
- `all_apps_page.dart`
- `custom_category_page.dart`
- `launch_page.dart`
- `routes.dart`

Replace raw `12/13px` text wherever it is acting as body text or normal supportive copy.

- [ ] **Step 5: Re-run page verification**

Run:

```bash
/home/han/flutter/bin/flutter test <page-test-files>
/home/han/flutter/bin/flutter analyze lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart lib/presentation/pages/recommend/recommend_page.dart lib/presentation/pages/search_list/search_list_page.dart lib/presentation/pages/setting/setting_page.dart lib/presentation/pages/update_app/update_app_page.dart lib/presentation/pages/all_apps/all_apps_page.dart lib/presentation/pages/custom_category/custom_category_page.dart lib/presentation/pages/launch/launch_page.dart lib/core/config/routes.dart
```

- [ ] **Step 6: Commit page sweep**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart lib/presentation/pages/recommend/recommend_page.dart lib/presentation/pages/search_list/search_list_page.dart lib/presentation/pages/setting/setting_page.dart lib/presentation/pages/update_app/update_app_page.dart lib/presentation/pages/all_apps/all_apps_page.dart lib/presentation/pages/custom_category/custom_category_page.dart lib/presentation/pages/launch/launch_page.dart lib/core/config/routes.dart <page-test-files>
git commit -m "refactor: 调整页面字体语义层级"
```

### Task 6: Run Residual Scan And Final Verification

**Files:**
- Review all typography-related changes above

- [ ] **Step 1: Scan for remaining low-size hardcodes**

Run:

```bash
rg -n "fontSize: 12|fontSize: 13|fontSize: 14|AppTextStyles\\.caption|textTheme\\.bodyMedium|textTheme\\.bodySmall" lib/presentation lib/core -g '!**/*.g.dart'
```

Expected:

- remaining `12px` uses are only true tiny/badge/tag cases
- remaining `13px` uses are only secondary metadata or intentional compact UI
- no obvious page body text still depends on old tiny semantics

- [ ] **Step 2: Run global verification**

Run:

```bash
/home/han/flutter/bin/flutter analyze
/home/han/flutter/bin/flutter test
```

If the full suite is too expensive for one worker batch, at minimum run:

```bash
/home/han/flutter/bin/flutter analyze
/home/han/flutter/bin/flutter test test/widget/
```

- [ ] **Step 3: Capture visual verification**

Take before/after evidence for:

- title bar
- expanded sidebar
- recommendation card list
- app detail page first screen

Preferred methods:

- golden updates if present
- otherwise deterministic screenshot capture in the desktop app

- [ ] **Step 4: Review acceptance criteria**

Confirm:

- major readable text is no longer visually undersized
- shell, cards, dialogs, and page content share a consistent text hierarchy
- no clipped text or vertically misaligned controls were introduced
- the result tracks the approved screenshot-based reading density target

- [ ] **Step 5: Prepare handoff summary**

Report:

- changed files by layer
- verification evidence
- remaining intentional typography exceptions

### Task 7: Update Repository Guidance

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Add the new typography agreement to the repo guidance**

Record:

- global typography source of truth is `theme.dart`
- `12px` is reserved for tags/tiny-only usage
- page and component body text must not fall back to tiny styles
- larger typography changes must always review container height and alignment together

- [ ] **Step 2: Analyze the modified guidance file**

Run:

```bash
/home/han/flutter/bin/flutter analyze
```

Expected: no new issues introduced elsewhere by the completed sweep.

- [ ] **Step 3: Commit the guidance update**

```bash
git add AGENTS.md
git commit -m "docs: 补充字体语义整改约定"
```
