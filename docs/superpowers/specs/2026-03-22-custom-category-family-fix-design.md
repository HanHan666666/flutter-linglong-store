# Custom Category Family Fix Design

**Date:** 2026-03-22

## Background

当前 Flutter 自定义分类页复用单例 `customCategoryProvider`，页面切换分类时通过 `didUpdateWidget` 直接修改 provider 状态。运行日志显示 `/app/sidebar/apps` 已成功返回数据，但紧接着触发了 Riverpod 生命周期异常：在 widget tree build 期间修改 provider，导致 `Office -> System` 这类二次切换失效。

同时，分类页头部展示的应用数量目前取自 `menu.categoryIds.length`，这只是菜单关联的分类 ID 个数，不是接口真实应用总量，因而会把实际几百个应用的分类显示成 `1` 或 `2`。

Rust 旧版分类页的核心行为是：
- 路由参数 `code` 变更后，分页请求自然切换到新分类
- 主列表请求 `/app/sidebar/apps`
- 每页默认拉取 `30` 条
- 不用 `categoryIds.length` 冒充应用总量

## Confirmed Requirements

- 将 `customCategoryProvider` 重构成按 `code` 分片的 provider family
- 保留通过接口请求分类列表数据的能力，不能把分页数据写死到前端
- 侧边栏动态菜单配置本期继续走 Flutter 本地配置，但未来应允许切回接口配置
- 分类页头部应用数量改为接口返回的真实 `total`
- 自定义分类列表每页默认数量与 Rust 旧版对齐为 `30`
- 语言切换等全局失效逻辑仍需能刷新自定义分类数据

## Design

### Provider Structure

- 将 `CustomCategory` 改为 `@riverpod` family，参数为分类 `code`
- 每个分类拥有独立状态，避免多个分类共享单个 notifier 的 `_categoryCode / _sortType / _filter`
- provider `build(code)` 负责初始化首屏加载，页面层不再调用 `initCategory`

### Data Source Strategy

- `sidebarConfigProvider` 继续作为菜单配置统一入口
- 本期 `sidebarConfigProvider` 仍返回 Flutter 本地菜单配置；未来切回接口时，只改该 provider 内部实现
- `customCategoryProvider(code)` 仍通过 `appApiService.getSidebarApps()` 请求真实分类应用列表，不把应用数据本地化或写死

### Category Header

- `CategoryInfo.name` 继续复用本地菜单映射，保证侧边栏与分类页标题一致
- `CategoryInfo.appCount` 改为使用 `/app/sidebar/apps` 返回的 `total`
- 如果接口失败，则走已有错误态，不额外伪造数量

### Pagination

- 将自定义分类首屏和翻页请求的 `pageSize` 统一改为 `30`
- `hasMore` 继续依据接口 `current < pages`
- 滚动分页行为保持现状，不额外引入新的预取或缓存策略

### Invalidation

- 语言切换时不能再简单 `invalidate(customCategoryProvider)`，因为 family provider 需要按实例失效
- 页面实际应依赖 `sidebarConfigProvider` 和 `ApiClient.getLocale` 重新解析标题，因此 provider 内部需通过监听/依赖收敛刷新触发，而不是要求全局枚举所有 code
- 全局 provider 中对 `customCategoryProvider` 的直接失效调用应移除或改为失效其上游依赖

## Testing

- 新增 provider 单测覆盖：
  - `customCategoryProvider('office')` 与 `customCategoryProvider('system')` 状态互不污染
  - 首屏请求 `pageSize` 为 `30`
  - 页头数量来自接口 `total`，不是 `categoryIds.length`
- 新增 widget 测试覆盖：
  - 同一 `CustomCategoryPage` 实例切换 `code` 后能重新渲染新分类标题
  - 切换分类不会抛出 provider build 期修改异常

## Risks

- provider family 化会影响 `setting_provider.dart` 和 `global_provider.dart` 里现有的 `invalidate(customCategoryProvider)` 调用
- Riverpod 注解修改后必须重新生成 `*.g.dart`
- 仓库全量 analyze 目前不是稳定基线，本次只对变更文件做定向验证
