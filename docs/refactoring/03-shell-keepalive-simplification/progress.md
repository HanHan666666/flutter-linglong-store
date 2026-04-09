# Shell KeepAlive Simplification Progress

> Last updated: 2026-04-09 ~18:20 **COMPLETED**

## Final Status

| Phase | Task | Status |
|-------|------|--------|
| 1. Core | Task 1: Create shell_primary_route.dart | DONE |
| 1. Core | Task 2: Create shell_branch_visibility.dart | DONE |
| 1. Core | Task 3: Refactor app_shell.dart | DONE |
| 2. Routes | Task 4: Rewrite routes.dart | DONE |
| 2. Pages | Task 6: Migrate RecommendPage | DONE |
| 2. Pages | Task 7: Migrate AllAppsPage | DONE |
| 2. Pages | Task 8: Migrate RankingPage | DONE |
| 2. Pages | Task 9: Migrate MyAppsPage | DONE |
| 2. Pages | Task 10: Migrate CustomCategoryPage | DONE |
| 3. Cleanup | Task 11: Delete old KeepAlive files | DONE |
| 3. Cleanup | Task 13: Delete ProcessManager | DONE |
| 3. Cleanup | Task 14: Extract sidebar hover surface | DONE |
| 4. Tests | Task 12: Create new tests | DONE |

## Files Created
- `lib/core/config/shell_primary_route.dart`
- `lib/core/config/shell_branch_visibility.dart`
- `lib/presentation/widgets/sidebar_interaction_surface.dart`
- `test/widget/core/config/shell_branch_visibility_test.dart`
- `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`

## Files Deleted
- `lib/core/config/keepalive_paint_gate.dart`
- `lib/core/config/keepalive_visibility_sync.dart`
- `lib/core/config/page_visibility.dart`
- `lib/core/config/visibility_aware_mixin.dart`
- `lib/core/platform/process_manager.dart`
- `test/widget/core/config/keepalive_paint_gate_test.dart`
- `test/widget/core/config/keepalive_visibility_sync_test.dart`
- `test/unit/core/config/visibility_aware_mixin_test.dart`

## Files Modified
- `lib/core/config/routes.dart`
- `lib/presentation/widgets/app_shell.dart`
- `lib/presentation/widgets/sidebar.dart`
- `lib/presentation/pages/recommend/recommend_page.dart`
- `lib/presentation/pages/all_apps/all_apps_page.dart`
- `lib/presentation/pages/ranking/ranking_page.dart`
- `lib/presentation/pages/my_apps/my_apps_page.dart`
- `lib/presentation/pages/custom_category/custom_category_page.dart`

## Verification
- `flutter analyze`: **0 errors, 0 warnings** (only info-level hints remain)
- Old KeepAlive tests deleted, new tests created

## Recommended Commits
1. `refactor: 用 IndexedStack 替换自定义 KeepAlive 架构`
2. `refactor: 迁移主页面可见性逻辑并移除旧 KeepAlive 基础设施`
3. `test: 补充主页面保活与可见性切换测试`
4. `refactor: 删除遗留 ProcessManager 并收敛侧边栏 hover 逻辑`
