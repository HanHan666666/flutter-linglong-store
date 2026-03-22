# Sidebar Local Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace sidebar dynamic menu display/config with a front-end local source of truth, keep the interface entry point available for future rollback to server-driven config, and make sidebar labels and custom category titles use the same localized mapping.

**Architecture:** Introduce one focused local sidebar menu catalog that owns menu code, localized label resolution, icons, sort order, and query rule metadata. Keep `sidebarConfigProvider` as the single integration point, but have it emit the local catalog for now; make both `Sidebar` and `CustomCategoryProvider` consume the same catalog helpers so UI labels and category headers cannot drift.

**Tech Stack:** Flutter, Riverpod, Freezed DTOs, flutter_test

---

### Task 1: Restore The Codegen Baseline Needed For Targeted Tests

**Files:**
- Modify: `lib/application/providers/sidebar_config_provider.g.dart`
- Modify: `lib/application/providers/custom_category_provider.freezed.dart`
- Modify: `lib/application/providers/custom_category_provider.g.dart`
- Modify: `lib/data/models/api_dto.freezed.dart`
- Modify: `lib/data/models/api_dto.g.dart`
- Modify: `lib/domain/models/recommend_models.freezed.dart`
- Verify: `pubspec.lock`

- [ ] **Step 1: Regenerate the missing generated sources before writing tests**

Run:

```bash
/home/han/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

Expected: generated `*.g.dart` / `*.freezed.dart` files are recreated without build errors.

- [ ] **Step 2: Do not change production behavior yet**

Stop after code generation. The new RED cycle will come from the new focused tests in Task 2, not from the existing sidebar widget test file, which already contains an unrelated stale width assertion.

- [ ] **Step 3: Commit the regenerated baseline only if the output changed and is required for the feature**

```bash
git add lib/application/providers/sidebar_config_provider.g.dart \
  lib/application/providers/custom_category_provider.freezed.dart \
  lib/application/providers/custom_category_provider.g.dart \
  lib/data/models/api_dto.freezed.dart \
  lib/data/models/api_dto.g.dart \
  lib/domain/models/recommend_models.freezed.dart
git commit -m "chore: 重新生成侧边栏相关代码产物"
```

### Task 2: Add Failing Coverage For Local Sidebar Menu Resolution

**Files:**
- Create: `test/unit/core/config/local_sidebar_menu_catalog_test.dart`
- Create: `test/widget/presentation/widgets/sidebar_local_menu_test.dart`
- Verify: `test/unit/core/config/local_sidebar_menu_catalog_test.dart`
- Verify: `test/widget/presentation/widgets/sidebar_local_menu_test.dart`

- [ ] **Step 1: Write the failing catalog unit tests**

Add tests that describe the new behavior:

```dart
test('known menu code resolves localized labels for zh and en', () {
  final office = lookupLocalSidebarMenuConfig('office')!;

  expect(office.resolveLabel(const Locale('zh')), '办 公');
  expect(office.resolveLabel(const Locale('en')), 'Office');
});

test('unknown menu code falls back to backend name and generic icons', () {
  final fallback = buildSidebarMenuPresentation(
    menuCode: 'unknown',
    fallbackName: '未知分类',
  );

  expect(fallback.labelFor(const Locale('en')), '未知分类');
  expect(fallback.icon, Icons.widgets_outlined);
});
```

- [ ] **Step 2: Write the failing sidebar widget assertions**

Create a new focused sidebar widget test file that asserts English dynamic menu labels are local:

```dart
expect(find.text('Office'), findsOneWidget);
expect(find.text('System'), findsOneWidget);
expect(find.text('Development'), findsOneWidget);
expect(find.text('Entertainment'), findsOneWidget);
```

Also add a fallback case using an overridden unknown `SidebarMenuDTO`.

- [ ] **Step 3: Run the unit test to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/core/config/local_sidebar_menu_catalog_test.dart
```

Expected: FAIL because the local catalog/helper does not exist yet.

- [ ] **Step 4: Run the widget test to verify RED**

Run:

```bash
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/sidebar_local_menu_test.dart
```

Expected: FAIL because dynamic menu labels still come from `menuName`.

- [ ] **Step 5: Commit after the tests pass in Task 3**

```bash
git add test/unit/core/config/local_sidebar_menu_catalog_test.dart \
  test/widget/presentation/widgets/sidebar_local_menu_test.dart
git commit -m "test: 补充侧边栏本地菜单配置断言"
```

### Task 3: Implement The Local Sidebar Catalog And Wire It Into Provider/UI

**Files:**
- Create: `lib/core/config/local_sidebar_menu_catalog.dart`
- Modify: `lib/application/providers/sidebar_config_provider.dart`
- Modify: `lib/application/providers/custom_category_provider.dart`
- Modify: `lib/presentation/widgets/sidebar.dart`
- Verify: `test/unit/core/config/local_sidebar_menu_catalog_test.dart`
- Verify: `test/widget/presentation/widgets/sidebar_local_menu_test.dart`

- [ ] **Step 1: Add the local catalog as the new source of truth**

Create a focused catalog with one entry per known menu code:

```dart
class LocalSidebarMenuConfig {
  const LocalSidebarMenuConfig({
    required this.menu,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
  });

  final SidebarMenuDTO menu;
  final IconData icon;
  final IconData selectedIcon;
  final _SidebarMenuLabelKey labelKey;
}

const localSidebarMenuCatalog = [
  LocalSidebarMenuConfig(
    menu: SidebarMenuDTO(
      menuCode: 'office',
      menuName: '办公',
      sortOrder: 1,
      enabled: true,
      categoryIds: ['07', '19'],
      rule: SidebarMenuRuleDTO(sortBy: 'last30Downloads'),
    ),
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center,
    labelKey: _SidebarMenuLabelKey.office,
  ),
  // system / dev / entertainment ...
];
```

- [ ] **Step 2: Centralize label and fallback resolution**

Expose helpers that both provider and widgets will use:

```dart
LocalSidebarMenuConfig? lookupLocalSidebarMenuConfig(String menuCode);

String resolveSidebarMenuLabel({
  required String menuCode,
  required Locale locale,
  String? fallbackName,
});

IconData resolveSidebarMenuIcon(String menuCode, {required bool selected});
```

Use `lookupAppLocalizations(locale)` so the catalog reuses existing ARB translations (`office/system/develop/entertainment`) instead of hard-coded duplicated strings.

- [ ] **Step 3: Keep `sidebarConfigProvider` as the integration point, but switch it to local mode**

Replace the current network-backed provider body with a local return:

```dart
@Riverpod(keepAlive: true)
Future<List<SidebarMenuDTO>> sidebarConfig(Ref ref) async {
  return localSidebarMenuCatalog.map((item) => item.menu).toList(growable: false);
}
```

Keep a small commented note explaining that interface-backed loading is intentionally preserved at the `appApiService.getSidebarConfig()` layer for future rollback, but not used in the current local-only mode.

- [ ] **Step 4: Route sidebar rendering through the catalog helpers**

Update `sidebar.dart` so dynamic items no longer render `menu.menuName` directly:

```dart
final locale = Localizations.localeOf(context);
final label = resolveSidebarMenuLabel(
  menuCode: widget.menu.menuCode,
  locale: locale,
  fallbackName: widget.menu.menuName,
);

final icon = resolveSidebarMenuIcon(
  widget.menu.menuCode,
  selected: widget.isSelected,
);
```

Preserve current hover, width, selected indicator, and routing behavior.

- [ ] **Step 5: Route custom category title lookup through the same helpers**

In `CustomCategoryProvider._findCategoryInfo`, replace direct `menu.menuName` usage with shared resolution:

```dart
final locale = Locale(ApiClient.getLocale?.call() ?? 'zh');
return CategoryInfo(
  code: menu.menuCode,
  name: resolveSidebarMenuLabel(
    menuCode: menu.menuCode,
    locale: locale,
    fallbackName: menu.menuName,
  ),
  appCount: menu.categoryIds.length,
);
```

This keeps the custom category page header aligned with the sidebar item label.

- [ ] **Step 6: Run the targeted tests to verify GREEN**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/core/config/local_sidebar_menu_catalog_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/sidebar_local_menu_test.dart
```

Expected: PASS, including English local labels and unknown-code fallback coverage.

- [ ] **Step 7: Commit the feature**

```bash
git add lib/core/config/local_sidebar_menu_catalog.dart \
  lib/application/providers/sidebar_config_provider.dart \
  lib/application/providers/custom_category_provider.dart \
  lib/presentation/widgets/sidebar.dart \
  test/unit/core/config/local_sidebar_menu_catalog_test.dart \
  test/widget/presentation/widgets/sidebar_local_menu_test.dart
git commit -m "feat: 侧边栏动态菜单改为前端本地配置"
```

### Task 4: Sync Documentation, Project Conventions, And Final Verification

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/plans/2026-03-22-sidebar-local-config.md`
- Verify: `docs/superpowers/specs/2026-03-22-sidebar-local-config-design.md`
- Verify: `lib/core/config/local_sidebar_menu_catalog.dart`

- [ ] **Step 1: Record the new project convention in `AGENTS.md`**

Add one change-log bullet stating:
- sidebar dynamic menu display config is currently front-end local
- `sidebarConfigProvider` remains the only switchover point for future server rollback
- sidebar item labels and custom category titles must reuse the same catalog helper

- [ ] **Step 2: Run focused verification again after docs sync**

Run:

```bash
/home/han/flutter/bin/flutter test test/unit/core/config/local_sidebar_menu_catalog_test.dart
/home/han/flutter/bin/flutter test test/widget/presentation/widgets/sidebar_local_menu_test.dart
```

Expected: PASS after the docs-only update, proving no accidental regressions.

- [ ] **Step 3: Run a focused analysis pass on touched files if the repo baseline allows it**

Run:

```bash
/home/han/flutter/bin/dart analyze \
  lib/core/config/local_sidebar_menu_catalog.dart \
  lib/application/providers/sidebar_config_provider.dart \
  lib/application/providers/custom_category_provider.dart \
  lib/presentation/widgets/sidebar.dart \
  test/unit/core/config/local_sidebar_menu_catalog_test.dart \
  test/widget/presentation/widgets/sidebar_local_menu_test.dart
```

Expected: no new diagnostics in touched files. If unrelated baseline diagnostics still block the command, record that clearly in the final handoff.

- [ ] **Step 4: Commit the convention sync**

```bash
git add AGENTS.md docs/superpowers/plans/2026-03-22-sidebar-local-config.md
git commit -m "docs: 同步侧边栏本地菜单配置约定"
```
