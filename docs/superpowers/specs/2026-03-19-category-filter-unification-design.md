# 分类筛选栏收敛设计

**日期**: 2026-03-19

## 背景

推荐页与全部应用页已经复用同一个 `CategoryFilterHeaderDelegate`，但页面层仍然保留了两类重复：

1. 分类栏的 sliver 接线仍散落在页面里。
2. 分类骨架屏在两个页面各自维护一份。

另外，全部应用页当前把展开态放进 `SliverPersistentHeaderDelegate` 内部，并在内容区使用 `SingleChildScrollView`。分类较多时，展开区域会出现内部滚动条，破坏桌面端交互和视觉一致性。

## 目标

1. 保留现有 `CategoryFilterHeaderDelegate` 作为共享头部。
2. 增加一个薄公共封装，统一推荐页/全部应用页的分类栏 sliver 接线。
3. 增加一个共享分类骨架屏，收敛重复 UI。
4. 展开态改为“直接撑开页面高度”，不再出现分类区域内部滚动条。

## 方案

### 1. 保留现有头部 Delegate

`CategoryFilterHeaderDelegate` 继续负责固定高度的顶部分类栏容器、阴影、按钮和单行横向分类胶囊。

展开态不再由 Delegate 自身承担多行布局，避免把动态高度问题塞进 `SliverPersistentHeaderDelegate.maxExtent`。

### 2. 新增薄封装 `CategoryFilterSection`

新增共享 sliver 组件，统一负责：

- 渲染固定高度的 `SliverPersistentHeader`
- 在需要时追加展开内容 sliver
- 透传分类数据、选中状态、点击回调、是否显示数量、展开状态与切换回调

这样页面只保留业务 Provider 接线，不再重复拼装分类栏 sliver。

### 3. 展开内容改为独立 sliver

全部应用页的展开态改为在 header 后追加一个普通 sliver 内容区，由页面主滚动容器承载全部滚动。

约束：

- 分类面板一次性完整展示全部分类
- 不再在分类面板内部放 `SingleChildScrollView`
- 页面整体滚动时，展开区随页面自然滚动

### 4. 共享分类骨架屏

抽出 `CategoryFilterSkeleton`，推荐页与全部应用页通过参数控制占位数量和胶囊宽度，避免重复实现。

## 影响范围

- `lib/presentation/widgets/category_filter_header.dart`
- `lib/presentation/widgets/category_filter_section.dart`（新增）
- `lib/presentation/widgets/widgets.dart`
- `lib/presentation/pages/recommend/recommend_page.dart`
- `lib/presentation/pages/all_apps/all_apps_page.dart`
- `test/widget/presentation/widgets/category_filter_section_test.dart`（新增）

## 取舍

不合并推荐页与全部应用页的 Provider 分类逻辑。两页底层接口语义不同，当前只收敛展示层接线和骨架屏，避免为了“统一”把不同业务路径硬耦合到一起。
