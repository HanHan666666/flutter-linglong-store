# 04 - KeepAlive 与页面缓存优化

> **优先级：P1** | **预估节省：30~60 MB** | **风险：中**

---

## 4.1 现状

### KeepAlive 页面清单

| 页面 | 文件 | KeepAlive | VisibilityAwareMixin | 隐藏时暂停副作用 |
|------|------|-----------|---------------------|-----------------|
| 推荐页 | `recommend_page.dart` | ✅ | ✅ | ✅ |
| 全部应用 | `all_apps_page.dart` | ✅ | ❌ | ❌ |
| 排行榜 | `ranking_page.dart` | ✅ | ❌ | ❌ |
| 搜索列表 | `search_list_page.dart` | ✅ | ❌ | ❌ |
| 自定义分类 | `custom_category_page.dart` | ✅ | ❌ | ❌ |

### 问题总结

1. **4/5 页面缺少 VisibilityAwareMixin**：隐藏后 Widget 树 + 数据仍完整保留，滚动监听/loadMore 可能仍在触发
2. **搜索列表页不应 KeepAlive**：不在底部导航白名单 `keepAliveRoutes` 中，带搜索参数缓存会导致旧结果残留
3. **`maxCachedPages = 10` 未实现 LRU 淘汰**：`KeepAlivePageWrapper` 中声明了上限但无淘汰逻辑

---

## 4.2 方案 A：为 4 个页面补充 VisibilityAwareMixin

### 目标

让全部应用、排行榜、搜索列表、自定义分类在**不可见时暂停滚动监听和自动加载**。

### 改动模板

以 `all_apps_page.dart` 为例：

```dart
// ❌ 修改前
class _AllAppsPageState extends ConsumerState<AllAppsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

// ✅ 修改后
class _AllAppsPageState extends ConsumerState<AllAppsPage>
    with AutomaticKeepAliveClientMixin, VisibilityAwareMixin {
  @override
  bool get wantKeepAlive => true;
```

同时在 `_onScroll` 等方法中加入可见性检查：

```dart
void _onScroll() {
  // 页面不可见时跳过滚动加载
  if (!isVisible) return;

  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent - 200) {
    // loadMore...
  }
}
```

### 需要改动的 4 个文件

| 文件 | 改动点 |
|------|--------|
| `lib/presentation/pages/all_apps/all_apps_page.dart` | 添加 `VisibilityAwareMixin`，`_onScroll` 加可见性判断 |
| `lib/presentation/pages/ranking/ranking_page.dart` | 添加 `VisibilityAwareMixin`，Tab 切换加可见性判断 |
| `lib/presentation/pages/search_list/search_list_page.dart` | 添加 `VisibilityAwareMixin`，滚动加载加可见性判断 |
| `lib/presentation/pages/custom_category/custom_category_page.dart` | 添加 `VisibilityAwareMixin`，滚动加载加可见性判断 |

### 预估节省

- 每个隐藏页面减少不必要的数据加载和 Widget 重建
- 间接减少图片缓存压力（隐藏页不再触发 loadMore 加载新图片）
- 预估节省 **20~40 MB**

---

## 4.3 方案 B：搜索列表页移除 KeepAlive

### 理由

1. 搜索列表页不在 `keepAliveRoutes`（`'/'`, `'/all-apps'`, `'/ranking'`, `'/my-apps'`）白名单中
2. 搜索页携带查询参数，缓存会导致旧搜索结果残留
3. 搜索是低频操作，每次进入重新搜索体验更好

### 改动

```dart
// lib/presentation/pages/search_list/search_list_page.dart

// ❌ 修改前
class _SearchListPageState extends ConsumerState<SearchListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

// ✅ 修改后 — 移除 KeepAlive
class _SearchListPageState extends ConsumerState<SearchListPage> {
  // 移除 AutomaticKeepAliveClientMixin 和 wantKeepAlive
```

同时移除 `build()` 方法中的 `super.build(context)` 调用。

### 预估节省

- 搜索结果页释放 = Widget 树 + 列表数据 + 图片 = **5~15 MB**

---

## 4.4 方案 C：实现 LRU 页面淘汰机制

### 问题

`maxCachedPages = 10` 已声明，但 Go Router 的 `StatefulShellRoute` 不自带 LRU 淘汰。

当用户频繁进入不同分类页面时，所有 KeepAlive 页面都会保留，没有上限。

### 方案思路

在 `KeepAlivePageWrapper` 中维护一个全局 LRU 队列：

```dart
/// 全局 KeepAlive 页面 LRU 管理器
class KeepAliveLruManager {
  static final KeepAliveLruManager instance = KeepAliveLruManager._();
  KeepAliveLruManager._();

  final LinkedHashMap<String, KeepAlivePageWrapperState> _cache =
      LinkedHashMap();

  /// 记录页面访问（移到队尾 = 最近使用）
  void recordAccess(String routePath, KeepAlivePageWrapperState state) {
    _cache.remove(routePath);
    _cache[routePath] = state;
    _evictIfNeeded();
  }

  /// 淘汰超出上限的最久未访问页面
  void _evictIfNeeded() {
    while (_cache.length > AppConfig.maxKeepAlivePages) {
      final oldest = _cache.keys.first;
      final state = _cache.remove(oldest);
      // 通知 KeepAlive wrapper 释放该页面
      state?.markForRelease();
    }
  }
}
```

### 风险评估

- **中等风险**：需要在 `KeepAlivePageWrapper` 中加入释放逻辑
- 建议在 Phase 2 实现，Phase 1 先靠 VisibilityAwareMixin 减少内存占用

### 预估节省

- 限制同时保活的页面数 = **10~20 MB**（取决于用户浏览深度）

---

## 4.5 本章改动汇总

| 编号 | 改动 | 文件数 | 风险 | 节省内存 | 阶段 |
|------|------|--------|------|----------|------|
| 4.2 | 4 个页面补 VisibilityAwareMixin | 4 | 中 | 20~40 MB | Phase 2 |
| 4.3 | 搜索列表移除 KeepAlive | 1 | 低 | 5~15 MB | Phase 2 |
| 4.4 | LRU 页面淘汰 | 2 | 中 | 10~20 MB | Phase 2 |
| **合计** | | **5~6 文件** | | **35~75 MB** | |
