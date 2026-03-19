# 推荐页 Rust 对齐设计

> 日期：2026-03-19
> 状态：已确认，待用户审阅文档

## 1. 背景

当前 Flutter 推荐页实现与 Rust 现版首页存在明显偏差：

- Flutter 页面额外包含分类筛选栏，Rust 首页没有。
- Flutter 首页轮播为大图 Banner，Rust 首页为卡片式轮播内容。
- Flutter 首页列表分页大小为 `20`，Rust 首页为 `10`。
- Flutter 首页缺少 Rust `useCachedPaginatedList` 的“缓存优先展示”行为。

本次目标不是新增首页能力，而是把 Flutter 首页严格收敛到当前 Rust 首页的三段结构与核心逻辑：

- 轮播区
- `玲珑推荐` 标题
- 推荐应用列表

## 2. 目标与非目标

### 2.1 目标

- 页面结构严格对齐 Rust 当前首页。
- 首页列表分页参数改为 `10`。
- 首页支持推荐数据缓存优先展示，再发起远端请求覆盖缓存。
- 推荐列表继续复用 Flutter 现有卡片状态聚合与安装操作体系。
- 轮播区改成 Rust 当前首页的卡片式布局与交互语义。

### 2.2 非目标

- 不实现页面重新可见后的后台刷新缓存页。
- 不改全部应用页、分类页、搜索页、排行榜页的分页或缓存机制。
- 不抽象新的通用缓存框架。
- 不改全站卡片状态中心化架构。
- 不新增 Shell/`ll-cli` 调用。

## 3. Rust 现版对齐基准

本次对齐以下 Rust 文件的现状：

- `/home/han/linglong-store/rust-linglong-store/src/pages/recommend/index.tsx`
- `/home/han/linglong-store/rust-linglong-store/src/pages/recommend/index.module.scss`
- `/home/han/linglong-store/rust-linglong-store/src/components/ApplicationCarousel/index.tsx`
- `/home/han/linglong-store/rust-linglong-store/src/components/ApplicationCarousel/index.module.scss`
- `/home/han/linglong-store/rust-linglong-store/src/hooks/useCachedPaginatedList.ts`

以这些文件为准，Flutter 推荐页需要满足：

- 页面仅保留轮播区、标题、推荐列表三段。
- 推荐列表分页大小 `defaultPageSize = 10`。
- 首屏优先读取缓存；若存在缓存，先展示缓存，再请求远端第一页覆盖。
- 翻页后持续更新缓存。
- 轮播点击进入应用详情页。

## 4. 页面结构设计

### 4.1 页面骨架

Flutter 推荐页改为如下结构：

1. 外层 `CustomScrollView` 保持 KeepAlive 与滚动触底加载能力。
2. 顶部 `SliverToBoxAdapter` 渲染卡片式轮播区。
3. 标题区 `SliverToBoxAdapter` 渲染 `玲珑推荐`。
4. 列表区使用网格卡片布局渲染推荐应用。
5. 列表底部显示 `加载中...` / `没有更多数据了`。

### 4.2 明确移除项

- 删除当前 Flutter 推荐页的分类筛选栏。
- 删除分类选择状态与相关重新加载逻辑。
- 删除当前大图 Banner 文案叠加样式。

## 5. 数据与状态设计

### 5.1 Provider 责任

`recommend_provider.dart` 负责：

- 加载轮播数据。
- 加载推荐列表第一页与后续分页。
- 读取和写入推荐页缓存。
- 合并分页结果。
- 管理首页 loading / load more / no more / error 状态。

Provider 不负责：

- 页面恢复可见后的后台刷新。
- 分类切换。
- 卡片安装态判断。

### 5.2 状态字段调整

推荐页状态移除分类相关字段：

- 删除 `selectedCategoryIndex`

保留或新增的核心状态：

- `isLoading`
- `isLoadingMore`
- `error`
- `data`
- `currentPage`
- `hasHydratedFromCache` 或同等语义字段，用于区分缓存首屏与真正远端首屏完成

### 5.3 请求参数

推荐列表与轮播接口请求继续显式携带现有请求体对象，且首页分页改为：

- `pageSize = 10`

请求体沿用现有 DTO 默认字段能力，保持 `repoName` 默认值，并在可行时继续补齐全局 `arch`，避免 Flutter 端对 Rust/后端契约继续漂移。

## 6. 缓存设计

### 6.1 本次缓存目标

仅为推荐页实现轻量缓存闭环，行为对齐 Rust 当前首页的核心体验：

- 页面初始化先尝试读取推荐页缓存。
- 若缓存存在，立即渲染缓存内容，不显示首屏骨架。
- 同时继续请求远端第一页，并用最新结果覆盖缓存与界面。
- 后续 `loadMore()` 追加成功后，同步写回缓存。

### 6.2 本次不做的缓存能力

- 不做 seed 与运行时缓存的统一抽象重构。
- 不做“页面重新可见后自动刷新缓存页”。
- 不做跨页面共享缓存基建。

### 6.3 缓存粒度

推荐页缓存只覆盖：

- 轮播列表
- 推荐应用列表前若干已加载页
- 当前已缓存页数 / 总页数

缓存 key 固定为推荐首页主列表语义，不引入分类或排序维度。

## 7. 轮播区设计

> 2026-03-19 设计更新：
> 在保持推荐页整体三段结构、分页与缓存策略继续对齐 Rust 首页的前提下，
> 轮播视觉不再强制照搬 Rust 当前卡片式内容。
> 用户已确认恢复 Flutter 风格化 Banner 路线，采用品牌色背景 + 左下信息锚点的方案。

### 7.1 视觉结构

轮播区采用 `Soft Brand Glass` 方案：

- 外层仍为推荐页顶部 Banner 容器，保留当前 Flutter 自动轮播与指示器交互。
- 背景层使用“应用品牌色风格化背景”，而不是 Rust 当前的纯卡片式信息块。
- 前景信息统一收敛到左下角信息锚点：`Logo + 应用名 + 简介 + 查看详情`。
- 允许轻量光影与薄玻璃材质，但必须克制，不能出现活动页广告风。
- 视觉重点是“品牌色主导 + logo 作为背景元素”，不是直接把 logo 粗暴放大铺满。

关键约束：

- 保留推荐页整体结构与行为对齐 Rust：首页只保留轮播区、标题、推荐列表三段。
- 轮播内容不再展示“版本/分类”等高噪声字段。
- 轮播按钮与指示器在浅色/深色主题下都必须保持清晰可读。
- 背景层必须抽离为独立组件，后续支持替换为图片背景或其他风格实现。

### 7.2 背景组件抽象

新增独立背景组件，职责如下：

- 输入：当前 banner 的 `title / imageUrl / targetAppId` 等轻量信息。
- 输出：只负责渲染背景视觉，不负责文案布局、按钮与跳转。
- 默认实现：品牌色背景 + logo/图标风格化背景元素 + 轻量材质叠层。
- 扩展方向：后续可新增图片背景实现、专题背景实现或服务端配置背景实现。

组件边界要求：

- 轮播项主体通过组合方式使用背景组件，不能把背景绘制逻辑继续塞回 `recommend_page.dart`。
- 背景组件内部允许做主题适配和品牌色派生，但不能耦合页面滚动、自动播放、路由跳转等逻辑。

### 7.3 交互

- 点击“查看详情”进入应用详情页。
- 轮播项缺失图标时展示 Flutter 侧默认占位。
- 轮播加载失败不影响推荐列表主体。

## 8. 推荐列表设计

### 8.1 列表布局

推荐列表维持 Rust 当前首页的网格节奏：

- `grid-template-columns: repeat(auto-fill, minmax(18rem, 1fr))`
- gap `16px`

Flutter 侧继续使用现有 `AppCard`，但推荐页只负责组织列表，不再自带额外筛选区。

### 8.2 卡片状态

卡片安装态、更新态、打开态继续复用现有页面级索引与公共卡片能力：

- `application_card_state_provider.dart`
- `AppCard`
- `app_card_actions.dart`

不在推荐页内部重写“安装 / 更新 / 打开”判断，避免破坏全站统一三态规则。

## 9. KeepAlive 与副作用

推荐页继续保留当前 KeepAlive 可见性感知能力，确保：

- 页面隐藏时不触发滚动加载更多。
- 页面显示时维持正常交互。

本次明确不实现：

- 页面重新可见时自动后台刷新缓存数据。

因此 `performLightweightRefresh()` 可以保持空实现，或仅保留注释说明该能力延期。

## 10. 文件改动范围

预计改动文件：

- `lib/presentation/pages/recommend/recommend_page.dart`
- `lib/presentation/pages/recommend/widgets/recommend_banner_background.dart`
- `lib/application/providers/recommend_provider.dart`
- `lib/domain/models/recommend_models.dart`
- `test/unit/application/providers/recommend_provider_test.dart`
- `test/widget/presentation/pages/recommend/recommend_page_test.dart` 或当前项目实际推荐页测试路径

如需缓存存储承载，允许新增一个推荐页专用轻量缓存文件，但必须保证职责单一，不扩展成全站通用框架。

## 11. 测试设计

### 11.1 Provider 单测

覆盖以下场景：

- 有缓存时先输出缓存数据。
- 首屏远端请求成功后覆盖缓存数据。
- `loadMore()` 以 `pageSize=10` 追加列表。
- 轮播接口失败时列表仍可正常展示。

### 11.2 Widget 测试

覆盖以下场景：

- 页面不再渲染分类筛选栏。
- 页面渲染轮播区、`玲珑推荐` 标题、推荐列表三段结构。
- 轮播区渲染独立背景组件，而不是在页面文件内直接拼背景视觉。
- 浅色/深色主题下轮播主文案与按钮仍然可见。
- loading、empty、load more、no more 文案正确。

### 11.3 回归验证

- `flutter analyze`
- 推荐页相关单测 / Widget 测试
- KeepAlive 可见性相关现有测试不回退

## 12. 风险与取舍

### 12.1 风险

- 推荐页缓存如果直接揉进现有 Provider，容易把状态字段继续做大。
- 轮播从大图改为卡片式后，旧测试与 Golden 可能失效。
- 首页列表从 `20` 改为 `10` 后，测试桩和分页断言需要同步调整。

### 12.2 取舍

本次优先选择“结构继续对齐 Rust，轮播视觉回归 Flutter 优势”的折中方案，不做通用缓存平台化，也不继续追求轮播视觉 1:1 对齐 Rust。原因是用户明确确认：

- 推荐页整体结构仍需收敛到 Rust 首页；
- 但轮播 UI 应优先保证美观度与 Flutter 既有优势；
- 背景组件需要可替换，为后续图片背景和风格扩展预留接口。

## 13. 实施结论

按本设计实施后，Flutter 推荐页将与当前 Rust 首页在以下方面对齐：

- 页面结构
- 推荐列表分页大小
- 缓存优先展示行为

同时保留两个已确认差异：

- 轮播视觉采用 Flutter `Soft Brand Glass` 风格化 Banner，而非 Rust 当前卡片式内容。
- 暂不支持页面重新可见后的后台刷新缓存页
