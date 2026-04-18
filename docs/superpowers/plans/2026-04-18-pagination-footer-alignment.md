# 分页尾部对齐修复实施计划

日期：2026-04-18

## 文件边界

- `lib/presentation/widgets/responsive_app_grid.dart`
  - 收敛为纯网格组件
  - 新增共享分页 footer sliver 组件
- `lib/presentation/widgets/widgets.dart`
  - 继续导出共享组件
- `lib/presentation/pages/all_apps/all_apps_page.dart`
  - 网格后追加分页 footer sliver
- `lib/presentation/pages/custom_category/custom_category_page.dart`
  - 网格后追加分页 footer sliver
- `lib/presentation/pages/search_list/search_list_page.dart`
  - 网格后追加分页 footer sliver
- `lib/presentation/pages/ranking/ranking_page.dart`
  - 网格后追加 no-more footer sliver
- `lib/presentation/pages/recommend/recommend_page.dart`
  - 复用共享分页 footer sliver，统一样式
- `test/widget/widgets/responsive_app_grid_test.dart`
  - 新增分页 footer 相关测试
- `AGENTS.md`
  - 记录分页 footer 必须脱离 grid 的约定

## 任务

### 任务 1：先写失败测试

- 在 `test/widget/widgets/responsive_app_grid_test.dart` 新增 widget 测试，覆盖：
  - `ResponsiveAppGrid` 仅渲染传入 items，不额外生成 loading/no-more 节点
  - 共享 footer 组件在 `isLoadingMore=true` 时显示居中 loading
  - 共享 footer 组件在 `hasMore=false && hasItems=true` 时显示 no-more 文案
  - `hasItems=false` 时 footer 不渲染
- 先运行单测，确认新增断言在实现前失败

### 任务 2：收敛共享组件

- 修改 `lib/presentation/widgets/responsive_app_grid.dart`
  - 删除 `isLoadingMore` / `hasMore`
  - 删除 grid 内追加 footer item 的逻辑
  - 新增共享 `PaginationFooterSliver`

### 任务 3：逐页接入共享 footer

- 修改 `all_apps_page.dart`
- 修改 `custom_category_page.dart`
- 修改 `search_list_page.dart`
- 修改 `ranking_page.dart`
- 修改 `recommend_page.dart`

要求：

- 只改 footer 结构，不改分页触发逻辑
- 所有 footer 统一使用共享组件

### 任务 4：补项目约定并验证

- 在 `AGENTS.md` 增补分页 footer 约定
- 运行：
  - `flutter test test/widget/widgets/responsive_app_grid_test.dart`
  - `flutter analyze`

## 执行说明

- 用户已明确要求直接在当前分支修改，不创建 worktree
- 本次修复以最小行为变更为原则，不扩展到新的分页功能或样式重构
