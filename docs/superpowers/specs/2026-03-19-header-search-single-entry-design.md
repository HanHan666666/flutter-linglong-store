# Header Search Single Entry Design

**Date:** 2026-03-19

## Background

当前 Flutter 搜索链路存在两层重复入口：
- 标题栏搜索框只是跳转占位，位于 `lib/presentation/widgets/title_bar.dart`
- 搜索页 `lib/presentation/pages/search_list/search_list_page.dart` 又单独维护了一套真实输入框与搜索按钮

这会带来两个问题：
- 用户从 header 点击进入搜索页后，会再次看到一个搜索框，交互冗余
- 标题栏搜索框不是实际可输入组件，和 Rust 版“从标题栏输入并进入结果页”的意图不一致

## Confirmed Requirements

- 统一为单一搜索入口，不再出现两个搜索框
- 标题栏搜索框必须是真实可输入的搜索入口
- 用户在标题栏输入关键词后，通过按回车进入搜索结果页
- 搜索结果页保留结果展示能力，但不再自带第二个搜索框
- 改动需要保持现有路由 `'/search_list?q=...'` 与搜索 Provider 兼容
- 保持桌面端高响应速度，不在 build 里增加额外重计算或重复状态源

## Approaches

### Option A: Header 真输入，搜索页降级为纯结果页

- 标题栏搜索框改为真实 `TextField`
- 回车或点击搜索图标后导航到 `/search_list?q=keyword`
- 搜索页只负责读取 query、触发搜索和展示结果，不再渲染本地输入框

**Pros**
- 完全消除双搜索框
- 和现有路由、Provider、时序文档最贴近
- 状态入口单一，后续维护成本最低

**Cons**
- 标题栏需要承担输入状态同步
- 需要避免标题栏拖拽逻辑影响输入体验

### Option B: Header 真输入，搜索页保留输入但隐藏标题栏搜索框

- 标题栏在非搜索页可输入
- 进入搜索页后隐藏标题栏搜索框，只保留页内输入框

**Pros**
- 搜索页内部仍然自洽

**Cons**
- 标题栏行为因页面不同而变化
- Shell 层和页面层要共同维护搜索入口，复杂度更高

### Option C: Header 继续做跳转入口，只移除搜索页中的多余按钮

- header 仍不是真输入框
- 仅减少搜索页的一部分重复控件

**Pros**
- 实现最省事

**Cons**
- 没有真正解决“header 搜索框是假的”这个核心问题
- 仍然和已确认交互不一致

## Recommended Design

选择 **Option A**。

### Interaction

- 标题栏搜索框成为全局唯一搜索输入入口
- 用户在任意主页面输入关键词后，按回车或点击搜索图标，导航到 `/search_list?q=<trimmed query>`
- 当当前路由已经是搜索页时，标题栏搜索框显示当前 query，便于继续改词再搜
- 当 query 为空时，不发起搜索请求

### Title Bar

- 现有 `_TitleSearchBox` 改为真实输入组件
- 输入组件内部自行维护 `TextEditingController` 和 `FocusNode`
- 通过 `currentQuery` 与当前路由同步显示值，避免页面切换后 header 文案陈旧
- 搜索框区域不再参与窗口拖拽；拖拽能力收敛到 logo 区和剩余空白拖拽区，避免输入时误触发窗口拖动

### Search Result Page

- 移除页内 `AppBar` 搜索框与页内搜索按钮
- 页面根据 `initialQuery` 直接触发 `searchProvider.search(query)`
- 页面只保留：
  - 无 query 时的引导态
  - loading / error / empty / result list
  - 结果头部的数量与关键词展示
- 无 query 时的空态文案改为引导用户使用顶部搜索框

### Routing and State

- 继续使用现有 `ContextRouterExtension.goToSearch()`
- `goToSearch()` 统一 trim query，空字符串走 `/search_list`
- 搜索页路由构建时使用基于 query 的 `ValueKey`，确保不同 query 导航时页面生命周期明确，避免旧状态残留

### Testing

- 新增 widget 测试覆盖标题栏搜索框提交后的路由跳转
- 新增 widget 测试覆盖搜索页已移除本地 `TextField`
- 保留原有搜索 Provider 单元测试，不扩散业务逻辑实现面
