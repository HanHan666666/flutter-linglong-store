# OpenCode Shell List UI Implementation Plan

> **For agentic workers:** Implement this plan task-by-task. User explicitly requested a simplified plan and no TDD, so do not add a test-first workflow.

**Goal:** First-stage UI refresh for the Flutter store shell and main list pages, reducing heavy gray backgrounds and hard visual seams while preserving business behavior.

**Architecture:** Keep the current `AppShell + CustomTitleBar + Sidebar + content pages` structure. Centralize the visual change in theme tokens, shell chrome, sidebar interaction surfaces, shared app cards, and list-page container spacing. Do not change providers, routes, API contracts, `ll-cli`, install/update/uninstall flows, or KeepAlive behavior.

**Tech Stack:** Flutter, Riverpod, go_router, window_manager, existing Aurora Layer theme files.

---

## Scope

Implement only stage one from [2026-07-04-opencode-shell-list-ui-design.md](/home/han/code/linglong-store/flutter-linglong-store/docs/superpowers/specs/2026-07-04-opencode-shell-list-ui-design.md):

- Shell, title bar, sidebar, content work area.
- Main list pages: recommend, all apps, ranking, search results, my apps, update apps.
- Shared list components: `AppCard`, `ResponsiveAppGrid`, sidebar interaction surface.

Defer detail page, settings page internals, download manager internals, and complex dialogs to a later plan.

## Files

Modify:

- `lib/core/config/theme/app_colors.dart`  
  Adjust shallow surface, card, border, and hover palette values. Add semantic comments for the lighter shell/list style if new fields are needed.

- `lib/core/config/theme/app_theme.dart`  
  Map updated tokens into `ThemeData`, especially scaffold, card, input, chip, and divider theme defaults.

- `lib/core/config/theme/app_spacing.dart`  
  Add or adjust reusable shell/content radius helpers only if needed. Avoid broad spacing churn.

- `lib/presentation/widgets/app_shell.dart`  
  Replace the large gray content background with a light content work area: subtle border, radius, clipping, and max/normal window-aware padding.

- `lib/presentation/widgets/title_bar.dart`  
  Align title bar and search box with the lighter shell surface. Preserve drag, double-click maximize, tag search mode, suggestions, and window button behavior.

- `lib/presentation/widgets/sidebar.dart`  
  Soften selected and hover states, reduce the hard blue indicator, and keep dynamic menu and bottom actions intact.

- `lib/presentation/widgets/sidebar_interaction_surface.dart`  
  Centralize softer hover and selected backgrounds for sidebar rows and bottom buttons.

- `lib/presentation/widgets/app_card.dart`  
  Add light default border, softer hover treatment, and consistent radius without changing card props or actions.

- `lib/presentation/widgets/responsive_app_grid.dart`  
  Tune grid spacing or bottom padding only where needed to reduce visible gray gutters.

- `lib/presentation/pages/recommend/recommend_page.dart`  
  Align banner/list padding and background with the new content plane.

- `lib/presentation/pages/all_apps/all_apps_page.dart`  
  Align category/list area with the new content plane.

- `lib/presentation/pages/ranking/ranking_page.dart`  
  Soften the Tab bar background and divider.

- `lib/presentation/pages/search_list/search_list_page.dart`  
  Ensure the nested `Scaffold` does not reintroduce old gray backgrounds.

- `lib/presentation/pages/my_apps/my_apps_page.dart`  
  Align tab header, search field fill, and app list padding.

- `lib/presentation/pages/update_app/update_app_page.dart`  
  Align update header/list cards with the new shared style.

- `docs/03e-aurora-layer-linux-desktop-design-system.md` or a focused docs note if implementation creates a new convention that future work must follow.

## Tasks

### Task 1: Update Theme Tokens

- Modify `app_colors.dart` and `app_theme.dart`.
- Make the light palette use a near-white shell/list surface instead of large-area `#F5F5F5`.
- Keep dark theme readable and avoid drastic dark-mode redesign.
- Keep comments in Chinese for changed token fields.
- Verify no API or provider files changed.
- Commit with `refactor: 调整轻量壳层主题令牌`.

### Task 2: Rework Shell Content Plane

- Modify `app_shell.dart`.
- Add a unified window body/background and right-side content work area with subtle border and 12-16px radius.
- Use `_isMaximized` to avoid awkward outer gaps in maximized state.
- Keep `_PrimaryIndexedStack`, secondary route overlay, KeepAlive visibility, and install queue listener behavior unchanged.
- Commit with `refactor: 统一应用壳层内容工作区`.

### Task 3: Soften Title Bar And Sidebar

- Modify `title_bar.dart`, `sidebar.dart`, and `sidebar_interaction_surface.dart`.
- Title bar: lighter search field, subtle focus border, subtle non-close window hover.
- Sidebar: lighter default background, soft selected pill, softer hover, reduced hard indicator.
- Preserve semantics, tooltips, routes, dynamic menu rendering, download flyout target, and bottom entry behavior.
- Commit with `refactor: 统一标题栏与侧边栏轻量交互`.

### Task 4: Tune Shared List Cards And Grid

- Modify `app_card.dart` and `responsive_app_grid.dart`.
- Add a light border to app cards and soften hover shadow/border.
- Keep `AppCard` public constructor, `A11yCard`, install button states, menu actions, and card action callbacks unchanged.
- Tune list/grid spacing only if it improves the gray-gutter issue without reducing readability.
- Commit with `refactor: 优化应用卡片与网格视觉层级`.

### Task 5: Align Main List Pages

- Modify recommend, all apps, ranking, search list, my apps, and update pages.
- Remove nested old gray backgrounds where they conflict with the new content plane.
- Keep existing providers, refresh/load-more behavior, route visibility, Tab behavior, search behavior, and pagination footer semantics unchanged.
- Commit with `refactor: 统一主列表页面轻量背景`.

### Task 6: Verify And Document

- Run `flutter analyze`.
- Run focused tests that exist for changed shared components. At minimum:
  - `flutter test test/unit/core/accessibility/a11y_semantics_test.dart`
- If there are existing widget tests for shell/sidebar/app card/title bar, run those specific files.
- Launch with `flutter run -d linux` if the local environment supports it, then inspect:
  - normal window shell radius and content border,
  - maximized window spacing,
  - recommend/all apps/ranking/search/my apps/update pages,
  - scrolling to the bottom of long lists,
  - light and dark themes.
- Update docs only if the implementation introduces a concrete new convention not already covered by the design spec.
- Commit docs/test adjustments separately if they are not directly part of the visual code commit.

## Acceptance Criteria

- Main window no longer shows a heavy gray content floor like the current screenshot.
- Content area has a subtle OpenCode-like work-surface boundary without a hard bottom strip.
- Sidebar active/hover states are lighter and visually consistent with the title bar.
- Main list cards read as light bordered rows/cards, not white blocks separated by gray trenches.
- No install/update/uninstall/search/routing behavior changes.
- `flutter analyze` passes, or any failure is documented with the exact existing blocker.
- Relevant focused tests pass, or any failure is documented with exact output and ownership.
