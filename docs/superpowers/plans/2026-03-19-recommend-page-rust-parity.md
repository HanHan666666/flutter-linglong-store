# Recommend Page Rust Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 Flutter 推荐页在结构、分页和缓存首屏行为上严格对齐当前 Rust 首页，仅保留轮播区、`玲珑推荐` 标题和推荐应用列表。

**Architecture:** 保持现有路由、卡片状态聚合和 KeepAlive 体系不变，把对齐范围收敛在推荐页闭环。先补齐当前 worktree 缺失的代码生成基线，再通过 TDD 改造推荐页 Provider、缓存承载和页面结构，最后同步更新文档与验证。

**Tech Stack:** Flutter, Dart, Riverpod, Freezed, build_runner, flutter_test

---

### Task 1: 修复 worktree 基线并确认测试入口可运行

**Files:**
- Modify: `pubspec.lock`（仅在 `flutter pub get` 导致变更时检查）
- Generate: `lib/**/*.g.dart`, `lib/**/*.freezed.dart`, `test/**/*.mocks.dart`（如命令产出）

- [ ] **Step 1: 记录当前基线失败原因**

Run: `/home/han/flutter/bin/flutter test test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: FAIL，且失败原因为缺少 `*.g.dart` / `*.freezed.dart` 等生成文件，不是本次推荐页需求导致。

- [ ] **Step 2: 运行代码生成补齐基线**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 生成缺失的 `*.g.dart` / `*.freezed.dart` / `*.mocks.dart` 文件。

- [ ] **Step 3: 重新运行基线测试**

Run: `/home/han/flutter/bin/flutter test test/widget/core/config/keepalive_visibility_sync_test.dart`
Expected: 不再因缺失生成文件报错；若仍失败，需先定位是否为仓库现存问题。

- [ ] **Step 4: 提交基线修复（如有生成产物变更）**

```bash
git add -A
git commit -m "chore: 补齐代码生成产物"
```

### Task 2: 为推荐页 Rust 对齐写失败测试

**Files:**
- Modify: `test/unit/application/providers/recommend_provider_test.dart`
- Create or Modify: `test/widget/presentation/pages/recommend/recommend_page_test.dart`

- [ ] **Step 1: 为 Provider 增加缓存优先与分页大小测试**

```dart
test('recommend provider hydrates cached data before remote refresh', () async {});
test('recommend provider loads more with page size 10', () async {});
test('recommend provider keeps app list when carousel request fails', () async {});
```

- [ ] **Step 2: 为页面增加 Rust 结构对齐测试**

```dart
testWidgets('recommend page renders carousel title and list without category filter', (tester) async {});
```

- [ ] **Step 3: 运行推荐页相关测试并确认失败**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/recommend_provider_test.dart`
Expected: FAIL，断言当前 Provider 仍包含旧分页/旧状态流。

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/recommend/recommend_page_test.dart`
Expected: FAIL，断言当前页面仍渲染分类筛选栏或旧 Banner 结构。

### Task 3: 收敛推荐页模型与缓存承载

**Files:**
- Modify: `lib/domain/models/recommend_models.dart`
- Create: `lib/core/storage/recommend_page_cache.dart`（如现有缓存服务无法直接承载）

- [ ] **Step 1: 从推荐页状态中移除分类字段并加入缓存首屏语义字段**

```dart
const factory RecommendState({
  @Default(false) bool isLoading,
  @Default(false) bool isLoadingMore,
  @Default(false) bool hasHydratedFromCache,
  String? error,
  RecommendData? data,
  @Default(1) int currentPage,
}) = _RecommendState;
```

- [ ] **Step 2: 定义推荐页缓存快照结构**

```dart
class RecommendPageCacheSnapshot {
  const RecommendPageCacheSnapshot({
    required this.banners,
    required this.apps,
    required this.currentPage,
    required this.total,
    required this.hasMore,
  });
}
```

- [ ] **Step 3: 提供推荐页专用缓存读写入口**

```dart
abstract final class RecommendPageCache {
  static Future<RecommendPageCacheSnapshot?> read() async {}
  static Future<void> write(RecommendPageCacheSnapshot snapshot) async {}
}
```

- [ ] **Step 4: 重新运行模型/Provider 相关测试，确认仍为红灯但已指向实现缺失**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/recommend_provider_test.dart`
Expected: FAIL，从旧状态字段缺失转为缓存逻辑或行为断言失败。

### Task 4: 实现推荐页 Provider 的 Rust 对齐数据流

**Files:**
- Modify: `lib/application/providers/recommend_provider.dart`
- Test: `test/unit/application/providers/recommend_provider_test.dart`

- [ ] **Step 1: 推荐页首屏先读缓存，再请求远端第一页**

```dart
Future<void> loadData() async {
  await _hydrateFromCacheIfPresent();
  await _fetchRemoteFirstPage();
}
```

- [ ] **Step 2: 推荐列表分页固定为 10**

```dart
static const _pageSize = 10;
```

- [ ] **Step 3: 轮播与列表保持解耦，轮播失败不拖垮列表**

```dart
List<BannerInfo> banners = await _loadBannersOrFallback(existing: cached?.banners ?? const []);
final apps = await _loadFirstPage();
```

- [ ] **Step 4: `loadMore()` 追加成功后写回缓存**

```dart
final mergedApps = [...currentApps, ...newApps.items];
await _persistSnapshot(...);
```

- [ ] **Step 5: 运行 Provider 单测确认通过**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/recommend_provider_test.dart`
Expected: PASS

- [ ] **Step 6: 提交 Provider 与缓存改造**

```bash
git add lib/domain/models/recommend_models.dart lib/core/storage/recommend_page_cache.dart lib/application/providers/recommend_provider.dart test/unit/application/providers/recommend_provider_test.dart
git commit -m "feat: 对齐推荐页缓存与分页逻辑"
```

### Task 5: 实现 Rust 风格推荐页 UI

**Files:**
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Modify: `lib/presentation/widgets/app_card.dart`（仅在推荐页布局需要极小兼容调整时）
- Test: `test/widget/presentation/pages/recommend/recommend_page_test.dart`

- [ ] **Step 1: 删除分类筛选栏及其引用**

```dart
// remove SliverPersistentHeader(CategoryFilterHeaderDelegate(...))
```

- [ ] **Step 2: 改造轮播为 Rust 卡片式布局**

```dart
Row(
  children: [
    AppIcon(..., size: 128),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...],
      ),
    ),
  ],
)
```

- [ ] **Step 3: 在轮播下方渲染 `玲珑推荐` 标题，再接推荐列表**

```dart
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: Text(l10n.linglongRecommend),
  ),
)
```

- [ ] **Step 4: 底部文案对齐 Rust**

```dart
if (isLoadingMore) const Text('加载中...');
if (!isLoadingMore && !hasMore && apps.isNotEmpty) const Text('没有更多数据了');
```

- [ ] **Step 5: 运行页面测试确认通过**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/recommend/recommend_page_test.dart`
Expected: PASS

- [ ] **Step 6: 提交推荐页 UI 改造**

```bash
git add lib/presentation/pages/recommend/recommend_page.dart lib/presentation/widgets/app_card.dart test/widget/presentation/pages/recommend/recommend_page_test.dart
git commit -m "feat: 对齐推荐页 Rust 首页布局"
```

### Task 6: 同步项目文档约束

**Files:**
- Modify: `docs/03d-ui-pages.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 更新推荐页页面规范，删除旧分类栏描述，补充 Rust 对齐约束**

```md
- 推荐页当前与 Rust 首页保持一致，仅保留轮播区、`玲珑推荐` 标题和推荐列表。
- 推荐页分页大小固定为 `10`，并支持缓存优先展示。
```

- [ ] **Step 2: 在仓库约定中补充推荐页约束**

```md
- 2026-03-19：推荐页必须严格对齐当前 Rust 首页，仅保留轮播区、`玲珑推荐` 标题和推荐列表；分页大小固定为 10，支持缓存优先展示，但暂不做页面重新可见后的后台刷新。
```

- [ ] **Step 3: 检查文档文本与实现一致**

Run: `rg -n "推荐页.*分页大小|玲珑推荐|缓存优先展示" docs/03d-ui-pages.md AGENTS.md`
Expected: 能定位到新约束文本。

- [ ] **Step 4: 提交文档同步**

```bash
git add docs/03d-ui-pages.md AGENTS.md
git commit -m "docs: 更新推荐页 Rust 对齐约束"
```

### Task 7: 最终验证

**Files:**
- Modify: `lib/application/providers/recommend_provider.dart`
- Modify: `lib/presentation/pages/recommend/recommend_page.dart`
- Modify: `lib/domain/models/recommend_models.dart`
- Create or Modify: `lib/core/storage/recommend_page_cache.dart`
- Modify: `test/unit/application/providers/recommend_provider_test.dart`
- Create or Modify: `test/widget/presentation/pages/recommend/recommend_page_test.dart`
- Modify: `docs/03d-ui-pages.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 运行推荐页相关测试**

Run: `/home/han/flutter/bin/flutter test test/unit/application/providers/recommend_provider_test.dart`
Expected: PASS

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/recommend/recommend_page_test.dart`
Expected: PASS

- [ ] **Step 2: 运行静态分析**

Run: `/home/han/flutter/bin/flutter analyze`
Expected: 0 error / 0 warning；若存在仓库既有问题，需明确区分本次引入与既有问题。

- [ ] **Step 3: 检查本次改动范围**

Run: `git status --short`
Expected: 仅包含本次推荐页 Rust 对齐相关改动与必要生成产物。

- [ ] **Step 4: 准备收尾说明**

Run: `git log --oneline --decorate -n 5`
Expected: 能看到本次文档、代码、测试相关提交链。
