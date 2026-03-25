# All Apps Category Rust Parity Design

**Date:** 2026-03-25

## Background

Flutter 当前“全部应用”页的分类筛选逻辑和 Rust 旧版不一致：

- `getDisCategoryList()` 返回的是真实应用分类 `categoryId`
- `all_apps_provider.dart` 在选中具体分类后，却把这个 `categoryId` 当成 `/app/sidebar/apps` 的 `menuCode` 传给侧边栏菜单接口
- 后端 `/app/sidebar/apps` 只接受 `office/system/dev/entertainment` 这一类菜单 code，匹配不到时直接返回空分页
- “全部”态也没有走 Rust 的查询路径，而是改成了 `/visit/getWelcomeAppList`

Rust 旧版 `src/pages/allApps/index.tsx` 的行为很明确：

- 分类列表来自 `/visit/getDisCategoryList`
- 所有分页请求都走 `/visit/getSearchAppList`
- “全部应用”传空 `categoryId`
- 具体分类传真实 `categoryId`
- 每页大小固定为 `30`

当前 Flutter 另外还有一处契约缺口：`SearchAppListRequest` 只建了 `name/pageNo/pageSize` 等字段，没有 `categoryId`，导致“全部应用”页没法用正确接口表达分类过滤，只能被迫绕去错误的菜单接口。

## Confirmed Requirements

- 全部应用页必须和 Rust 旧版保持一致，统一使用 `/visit/getSearchAppList`
- “全部”分类传空 `categoryId`，具体分类传 `getDisCategoryList` 返回的真实 `categoryId`
- `SearchAppListRequest` 必须补齐 `categoryId` 字段，不能继续缺失后端契约
- `AppRepositoryImpl.getAllApps(category: ...)` 必须同步透传 `categoryId`，避免保留无效入参
- `all_apps_provider.dart` 首屏和翻页请求统一使用 `pageSize: 30`
- 全部应用页不得继续依赖 `/app/sidebar/apps` 或 `/visit/getWelcomeAppList`
- 必须补齐 DTO、provider、页面交互三层回归测试

## Design

### Request Contract

- 在 `SearchAppListRequest` 中新增 `String? categoryId`
- 继续保留 `keyword -> name` 的 JSON 映射，不改变现有搜索页行为
- 当 `categoryId` 为空时，不在调用方额外伪造别的语义，直接沿用后端“空值表示全部应用”的契约

### Repository Layer

- `AppRepositoryImpl.getAllApps()` 继续使用 `/visit/getSearchAppList`
- 当调用方传入 `category` 时，将其映射到 `SearchAppListRequest.categoryId`
- 仓储层不引入新的分类转换逻辑，不在这里混入侧边栏菜单 code

### Provider Layer

- `all_apps_provider.dart` 将选中分类语义明确成 `selectedCategoryId`
- 首屏和 `loadMore()` 统一调用 `getSearchAppList(SearchAppListRequest(...))`
- “全部”态传 `categoryId: null`
- 具体分类传 `CategoryInfo.code`，该值由 `getDisCategoryList()` 的 `categoryId` 填充
- 全部应用页分页大小与 Rust 对齐为 `30`

### Presentation Layer

- `AllAppsPage` 的交互结构保持不变，仍使用现有 `CategoryFilterSection`
- 不增加新 UI，不改分类栏视觉，只修正点击分类后的数据来源
- 页面级回归测试需要覆盖“点击分类后卡片列表切到该分类结果，而不是空态”

## Testing

- DTO/序列化测试：
  - `SearchAppListRequest.toJson()` 包含 `categoryId`
- Repository 测试：
  - `getAllApps(category: '07')` 会把 `categoryId: '07'` 传给 `getSearchAppList`
- Provider 测试：
  - 首屏“全部应用”走 `getSearchAppList`，不再调用 `getWelcomeAppList`
  - 切换分类后仍走 `getSearchAppList`，并携带真实 `categoryId`
  - 翻页保留当前分类并继续使用 `pageSize: 30`
- Widget 测试：
  - 点击分类胶囊后，页面渲染新分类返回的应用卡片，而不是“暂无应用”

## Risks

- 仓库未跟踪部分 `*.g.dart/*.freezed.dart` 产物，fresh worktree 中需要先执行一次 `build_runner` 才能运行相关测试
- `SearchAppListRequest` 改动会影响搜索与仓储层现有序列化产物，必须同步重新生成 `api_dto.g.dart`
- `all_apps_provider.dart` 继续使用 Riverpod codegen，修改后要同步更新 `all_apps_provider.g.dart` / `all_apps_provider.freezed.dart`
