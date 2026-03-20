# 02 - 内存现状分析

## 2.1 内存构成拆解

Flutter Linux 桌面应用的内存主要由以下部分组成：

```
┌──────────────────────────────────────────┐
│              总 RSS ~700 MB              │
├──────────────────────────────────────────┤
│  Flutter Engine 基础开销     ~80-120 MB  │
│  Dart VM Heap（对象/状态）    ~50-80 MB   │
│  图片解码缓存（ImageCache）  ~100-200 MB  │
│  GPU 纹理/光栅缓存           ~80-150 MB  │
│  Hive Box 内存映射            ~10-30 MB  │
│  KeepAlive 页面 Widget 树     ~50-80 MB  │
│  其他（字体/SVG/Skia缓冲）    ~30-50 MB  │
└──────────────────────────────────────────┘
```

## 2.2 热点定位

根据代码审计，以下是 **最可能导致 700MB 高占用** 的原因（按影响程度排序）：

### ✅ 热点 1：图片解码未限尺寸（预估 100~200MB 浪费）— **已修复**

> **修复提交：** `e4af3b0` — 2026-03-20

**已修复文件：**

| 位置 | 修复内容 |
|------|----------|
| `lib/presentation/pages/app_detail/app_detail_page.dart` L442 | 截图缩略图添加 `cacheWidth`/`cacheHeight`（280×180 × DPR） |
| `lib/presentation/pages/app_detail/app_detail_page.dart` L1138 | 截图预览添加 `cacheWidth`（屏幕宽度 × DPR） |
| `lib/presentation/pages/recommend/widgets/recommend_banner_background.dart` L131 | Banner 装饰图添加 `memCacheWidth`/`memCacheHeight`（392×392） |

**内存计算示例：**
- 一张 1920×1080 的图片解码到内存 = 1920 × 1080 × 4bytes = **~7.9 MB**
- 截图缩略图列表 5 张 = **~40 MB**（实际只需 280×180×4 = 0.2 MB/张）
- 截图预览 PageView 3 张（当前页+前后各1） = **~24 MB**
- Banner 轮播 3~5 张 = **~24~40 MB**

**单单图片这一项就可能浪费 80~100+ MB。**

### ✅ 热点 2：ImageCache 限额配置未生效（预估 36MB 多占）— **已修复**

> **修复提交：** `e4af3b0` — 2026-03-20

**问题文件：** `lib/core/config/app_config.dart` L36

```dart
// 声明了 64MB 限制
static const int imageCacheSizeBytes = 64 * 1024 * 1024; // 64MB
```

**已修复：** 在 `lib/main.dart` 中添加了 ImageCache 配置：

```dart
PaintingBinding.instance.imageCache.maximumSizeBytes = AppConfig.imageCacheSizeBytes;
PaintingBinding.instance.imageCache.maximumSize = 200;
```

ImageCache 现已生效 64MB / 200 张限制。

### ✅ 热点 3：KeepAlive 页面缺乏可见性暂停（预估 30~60MB）— **已修复**

> **修复提交：** `e4af3b0` — 2026-03-20

**修复后状态：**

| 页面 | KeepAlive | VisibilityAwareMixin | 隐藏时暂停副作用 |
|------|-----------|---------------------|-----------------|
| 推荐页 ✅ | ✅ | ✅ | ✅ 暂停轮播/滚动 |
| 全部应用 ✅ | ✅ | ✅ | ✅ 滚动监听暂停 |
| 排行榜 ✅ | ✅ | ✅ | ✅ Tab 切换暂停 |
| 搜索列表 ✅ | ❌ 已移除 | — | — 不再 KeepAlive |
| 自定义分类 ✅ | ✅ | ✅ | ✅ 滚动监听暂停 |

**修复内容：**
- `all_apps_page.dart` — 补 `VisibilityAwareMixin`，`_onScroll` 加可见性守卫
- `ranking_page.dart` — 补 `VisibilityAwareMixin`，Tab 切换加可见性守卫
- `custom_category_page.dart` — 补 `VisibilityAwareMixin`，`_onScroll` 加可见性守卫
- `search_list_page.dart` — 移除 `AutomaticKeepAliveClientMixin`（不在 `keepAliveRoutes` 白名单中）

### 🟡 热点 4：排行榜一次加载 100 条（预估 10~20MB）

**问题文件：** `lib/application/providers/ranking_provider.dart` L57-66

```dart
// 4 个排行榜 Tab 各加载 100 条
const PageParams(pageNo: 1, pageSize: 100)
```

- 4 个 Tab × 100 条 × 每条含图标 URL + 名称 + 描述 ≈ **1~2 KB/条**
- 数据层 = 4 × 100 × 2 KB = **~800 KB**（可接受）
- 但 100 条卡片的 Widget 对象 + 100 个 AppIcon 图片 = 显著内存占用
- 且 KeepAlive 保活 + 无可见性暂停，切走后图片仍在缓存

### 🟢 热点 5：Hive Box 全量加载（预估 10~30MB）

**问题文件：** `lib/core/storage/cache_service.dart`

```dart
// 使用 openBox 全量加载到内存（非 LazyBox）
final box = await Hive.openBox('cache');
```

- `Hive.openBox()` 会将 Box 内所有数据加载到内存
- 过期数据只在 `get()` 时判断，不主动删除
- 无 Box 大小/条目上限
- 长期运行后可能累积大量过期但未清理的缓存数据

### 🟢 热点 6：installedAppsProvider 全量持有（预估 5~15MB）

**问题文件：** `lib/application/providers/installed_apps_provider.dart` L44

```dart
@Riverpod(keepAlive: true)  // 永驻内存
class InstalledApps extends _$InstalledApps { ... }
```

- `keepAlive: true` 使列表永驻
- `enrichInstalledAppsWithDetails()` 会通过 API 富化每个应用（图标URL、中文名等）
- 若用户安装了数百个应用，该列表会持续占据内存

## 2.3 内存热点总结图

```
  图片解码(已修复✅)      ImageCache(已修复✅)      KeepAlive页面(已修复✅)
       ▼                      ▼                         ▼
  ┌─────────┐          ┌─────────────┐           ┌──────────────┐
  │节省~70MB│          │ 节省 ~36 MB │           │ 节省 ~30-60MB│
  └─────────┘          └─────────────┘           └──────────────┘
```

## 2.4 修复状态

| 热点 | 问题 | 状态 | 预估节省 |
|------|------|------|----------|
| 热点 1 | 图片解码未限尺寸 | ✅ 已修复 | ~70 MB |
| 热点 2 | ImageCache 限额未生效 | ✅ 已修复 | ~36 MB |
| 热点 3 | KeepAlive 页面无可见性暂停 | ✅ 已修复 | ~30-60 MB |
| 热点 4 | 排行榜一次加载 100 条 | 🟡 待优化 | ~10-20 MB |
| 热点 5 | Hive Box 全量加载 | 🟡 待优化 | ~10-30 MB |
| 热点 6 | installedAppsProvider 全量持有 | 🟡 待优化 | ~5-15 MB |

**已修复三项预计节省：141~181 MB**，可将内存从 700MB 降至 **520~560MB** 区间。
