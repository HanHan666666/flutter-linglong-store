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

### 🔴 热点 1：图片解码未限尺寸（预估 100~200MB 浪费）

**问题文件：**

| 位置 | 问题 |
|------|------|
| `lib/presentation/pages/app_detail/app_detail_page.dart` L372 | 截图缩略图 `Image.network()` 无 `cacheWidth`，280×180 显示但原图可能 1920×1080 |
| `lib/presentation/pages/app_detail/app_detail_page.dart` L949 | 截图预览 `Image.network()` 全尺寸解码，PageView 多张同时驻留 |
| `lib/presentation/pages/recommend/recommend_page.dart` L468 | 轮播 Banner `Image.network()` 无尺寸限制 |

**内存计算示例：**
- 一张 1920×1080 的图片解码到内存 = 1920 × 1080 × 4bytes = **~7.9 MB**
- 截图缩略图列表 5 张 = **~40 MB**（实际只需 280×180×4 = 0.2 MB/张）
- 截图预览 PageView 3 张（当前页+前后各1） = **~24 MB**
- Banner 轮播 3~5 张 = **~24~40 MB**

**单单图片这一项就可能浪费 80~100+ MB。**

### 🔴 热点 2：ImageCache 限额配置未生效（预估 36MB 多占）

**问题文件：** `lib/core/config/app_config.dart` L36

```dart
// 声明了 64MB 限制
static const int imageCacheSizeBytes = 64 * 1024 * 1024; // 64MB
```

但 **全项目没有任何代码将这个值应用到 `PaintingBinding.instance.imageCache`**。

Flutter 默认 ImageCache = **100MB / 1000 张**，意味着比期望多缓存了 36MB 图片数据。

### 🟡 热点 3：KeepAlive 页面缺乏可见性暂停（预估 30~60MB）

**5 个带 KeepAlive 的页面中，只有 1 个正确实现了 VisibilityAwareMixin：**

| 页面 | KeepAlive | VisibilityAwareMixin | 隐藏时暂停副作用 |
|------|-----------|---------------------|-----------------|
| 推荐页 ✅ | ✅ | ✅ | ✅ 暂停轮播/滚动 |
| 全部应用 ❌ | ✅ | ❌ | ❌ 滚动监听持续活跃 |
| 排行榜 ❌ | ✅ | ❌ | ❌ TabController 持续 |
| 搜索列表 ❌ | ✅ | ❌ | ❌ 不应 KeepAlive |
| 自定义分类 ❌ | ✅ | ❌ | ❌ 滚动监听持续活跃 |

隐藏的页面仍保留完整 Widget 树 + 数据，且副作用（自动加载更多、滚动事件）仍在运行。

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
  图片解码(未限尺寸)    ImageCache(100MB默认)     KeepAlive页面(4个无暂停)
       ▼                      ▼                         ▼
  ┌─────────┐          ┌─────────────┐           ┌──────────────┐
  │80~150 MB│          │  多占 36 MB  │           │  30~60 MB    │
  └────┬────┘          └──────┬──────┘           └──────┬───────┘
       │                      │                         │
       └────────────┬─────────┘                         │
                    ▼                                   │
              ┌───────────┐                             │
              │ 700 MB    │◄────────────────────────────┘
              │ 总内存     │◄──── Hive全量加载 (10~30 MB)
              │           │◄──── 排行榜100条 (10~20 MB)
              │           │◄──── installedApps (5~15 MB)
              └───────────┘
```

## 2.4 经验判断

基于以上分析，**图片相关优化（热点 1 + 热点 2）是收益最大的方向**，仅修复这两项预计可节省 **120~230 MB**，单独就能将内存从 700MB 降至 500~580MB 区间。

结合 KeepAlive 优化，有信心将稳态内存控制在 **450MB 以内**。
