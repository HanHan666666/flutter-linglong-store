# 分页尾部对齐修复设计

日期：2026-04-18

## 背景

当前多个应用列表页复用 `lib/presentation/widgets/responsive_app_grid.dart`。该组件在分页模式下会把“加载更多”和“没有更多了”作为 `SliverGrid` 的最后一个 item 插入网格。结果是：

- loading 圈只占一个卡片格子，视觉上不居中
- “没有更多了”像占用了一个 `AppCard` 的位置
- 所有复用页面同时存在该问题

受影响页面包括：

- `lib/presentation/pages/all_apps/all_apps_page.dart`
- `lib/presentation/pages/custom_category/custom_category_page.dart`
- `lib/presentation/pages/search_list/search_list_page.dart`
- `lib/presentation/pages/ranking/ranking_page.dart`

推荐页当前已经使用独立 footer，但文案和间距与其他列表页不统一。

## 目标

- 分页 loading/footer 必须以整行 sliver 渲染，而不是 grid item
- 所有复用 `ResponsiveAppGrid` 的页面统一修复
- 保持现有分页逻辑、滚动触发逻辑和卡片布局不变
- 推荐页的 footer 与共享分页 footer 视觉对齐

## 非目标

- 不调整分页策略
- 不改动卡片视觉样式
- 不引入新的 Provider 或状态流

## 方案对比

### 方案 A：页面层拆分 grid 和 footer sliver

做法：

- `ResponsiveAppGrid` 只负责渲染卡片网格
- 新增共享分页 footer sliver helper/组件
- 各页面在 `CustomScrollView.slivers` 中自行拼接 footer

优点：

- 职责最清晰，grid 不再混入分页尾部语义
- footer 真实占据整行，可稳定居中
- 页面可按需定制 footer 文案和底部间距

缺点：

- 需要改动多个页面接入

### 方案 B：由 `ResponsiveAppGrid` 返回 grid + footer 组合

优点：

- 页面接入改动少

缺点：

- 一个组件承载多 sliver 责任，边界变糊
- 后续页面差异化 footer 更难扩展

## 选型

采用方案 A。

## 设计细节

### 共享网格职责收敛

`ResponsiveAppGrid` 改为：

- 只接收 `items` 和 `itemBuilder`
- 不再接收 `isLoadingMore` / `hasMore`
- 不再渲染 `LoadingMoreIndicator` / `NoMoreDataIndicator`

### 新的分页 footer 表现

新增共享分页 footer 组件，统一提供：

- `isLoadingMore`
- `hasMore`
- `hasItems`
- `bottomPadding`

行为：

- `hasItems=false` 时不渲染任何 footer
- `isLoadingMore=true` 时显示整行居中的 `CircularProgressIndicator`
- `hasMore=false` 时显示整行居中的“没有更多了”

结构要求：

- 使用 `SliverToBoxAdapter`
- 内容通过 `Align(alignment: Alignment.center)` + `SizedBox(width: double.infinity)` 或等价结构保证整行居中
- 统一使用共享文字样式和语义标签

### 页面改造边界

以下页面将改为 “网格 sliver + footer sliver”：

- `all_apps_page.dart`
- `custom_category_page.dart`
- `search_list_page.dart`
- `ranking_page.dart`

推荐页：

- 保留独立 footer 结构
- 统一改用新的共享 footer 组件，避免再次分叉

## 测试策略

- 在 `test/widget/widgets/responsive_app_grid_test.dart` 补充 widget 测试
- 验证分页 footer 不再由 `ResponsiveAppGrid` 本体渲染
- 验证共享 footer 在 loading / no-more / no-items 三种状态下行为正确

## 风险与控制

- 风险：页面忘记追加 footer，导致没有更多提示丢失
  控制：逐页修改并通过搜索 `ResponsiveAppGrid(` 复查接入点
- 风险：推荐页和通用列表页文案 key 不一致
  控制：优先复用现有 `l10n.noMore` / `l10n.loading`，避免新增文案
