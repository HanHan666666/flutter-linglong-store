# 03 - 图片内存优化

> **优先级：P0** | **预估节省：80~150 MB** | **风险：低**

图片是本次优化的最大收益点。分为 3 个子任务。

---

## 3.1 启用 ImageCache 全局限额

### 问题

`AppConfig.imageCacheSizeBytes = 64MB` 已声明但从未应用到 Flutter ImageCache。  
Flutter 默认 ImageCache = **100MB / 1000 张**。

### 方案

在 `main.dart` 的 `WidgetsFlutterBinding.ensureInitialized()` 之后，添加一行配置：

```dart
// main.dart — WidgetsFlutterBinding.ensureInitialized() 之后

// 应用图片缓存限额（默认 100MB，压缩到 64MB）
PaintingBinding.instance.imageCache.maximumSizeBytes =
    AppConfig.imageCacheSizeBytes; // 64 MB
PaintingBinding.instance.imageCache.maximumSize = 200; // 最多缓存 200 张
```

### 改动文件

| 文件 | 改动 |
|------|------|
| `lib/main.dart` ~L22 | 新增 2 行 ImageCache 配置 |

### 预估节省

- 缓存上限从 100MB → 64MB = **节省 ~36 MB**
- 张数上限从 1000 → 200，避免大量小图累积

### 验证方式

```dart
// 调试时打印验证
debugPrint('ImageCache: '
  'maxSize=${PaintingBinding.instance.imageCache.maximumSize}, '
  'maxBytes=${PaintingBinding.instance.imageCache.maximumSizeBytes}');
```

---

## 3.2 修复 Image.network 裸用（3 处）

### 问题

3 处 `Image.network()` 直接加载原始分辨率图片，无 `cacheWidth`/`cacheHeight` 限制。

一张 1920×1080 截图解码到内存 = **~7.9 MB**，而实际显示只需 280×180 = **0.2 MB**。

### 方案

#### 改动 1：截图缩略图（app_detail_page.dart L372）

```dart
// ❌ 修改前
child: Image.network(
  screenshot.screenshotUrl,
  width: 280,
  height: 180,
  fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Container(...),
),

// ✅ 修改后
child: Image.network(
  screenshot.screenshotUrl,
  width: 280,
  height: 180,
  fit: BoxFit.cover,
  // 限制解码尺寸，避免原图 1920x1080 全量解码到内存
  cacheWidth: (280 * MediaQuery.devicePixelRatioOf(context)).toInt(),
  cacheHeight: (180 * MediaQuery.devicePixelRatioOf(context)).toInt(),
  errorBuilder: (_, __, ___) => Container(...),
),
```

> **注意：** `cacheWidth`/`cacheHeight` 需要乘以设备像素比（DPR），确保在高分屏上不模糊。  
> 由于 `Image.network` 在 `build()` 中使用，可直接通过 `MediaQuery.devicePixelRatioOf(context)` 获取。

#### 改动 2：轮播 Banner（recommend_page.dart L468）

```dart
// ❌ 修改前
Image.network(
  banner.imageUrl,
  fit: BoxFit.cover,
  errorBuilder: ...
),

// ✅ 修改后 — Banner 通常全宽显示，限高 200
Image.network(
  banner.imageUrl,
  fit: BoxFit.cover,
  // Banner 全宽显示，按实际高度限制解码尺寸
  cacheWidth: (MediaQuery.sizeOf(context).width *
      MediaQuery.devicePixelRatioOf(context)).toInt(),
  cacheHeight: (200 * MediaQuery.devicePixelRatioOf(context)).toInt(),
  errorBuilder: ...
),
```

#### 改动 3：截图预览页（app_detail_page.dart L949）

此处需要特殊处理——预览页用户需要看高清大图，但不能全量解码 4K 原图。

```dart
// ❌ 修改前
child: Image.network(
  widget.screenshots[index],
  fit: BoxFit.contain,
  errorBuilder: ...
),

// ✅ 修改后 — 限制到屏幕分辨率即可
child: Image.network(
  widget.screenshots[index],
  fit: BoxFit.contain,
  // 限制解码尺寸为屏幕分辨率（足够清晰，避免超大图撑爆内存）
  cacheWidth: (MediaQuery.sizeOf(context).width *
      MediaQuery.devicePixelRatioOf(context)).toInt(),
  errorBuilder: ...
),
```

### 改动文件

| 文件 | 改动点 | 行号 |
|------|--------|------|
| `lib/presentation/pages/app_detail/app_detail_page.dart` | 截图缩略图 | L372 |
| `lib/presentation/pages/app_detail/app_detail_page.dart` | 截图预览 | L949 |
| `lib/presentation/pages/recommend/recommend_page.dart` | Banner | L468 |

### 预估节省

| 场景 | 修改前 | 修改后 | 节省 |
|------|--------|--------|------|
| 5 张截图缩略图 | 5 × 7.9 MB = 39.5 MB | 5 × 0.4 MB = 2 MB | **~37 MB** |
| 3 张 Banner | 3 × 7.9 MB = 23.7 MB | 3 × 1.5 MB = 4.5 MB | **~19 MB** |
| 3 张截图预览 | 3 × 7.9 MB = 23.7 MB | 3 × 3.2 MB = 9.6 MB | **~14 MB** |
| **合计** | **~87 MB** | **~16 MB** | **~70 MB** |

---

## 3.3 截图预览页 PageView 优化

### 问题

`_ScreenshotPreviewPage` 使用 `PageView.builder` 展示全屏截图，默认 Flutter PageView 会预加载前后各 1 页（`cacheExtent` 默认值），大图场景下 3 张同时驻内存。

### 方案

限制 PageView 的 `allowImplicitScrolling` 为 false（默认），并考虑对非可见页面显示占位符：

```dart
// 截图预览页的 PageView
PageView.builder(
  controller: _pageController,
  itemCount: widget.screenshots.length,
  // 不预加载相邻页面，仅当前页加载
  allowImplicitScrolling: false,
  itemBuilder: (context, index) {
    return InteractiveViewer(
      child: Center(
        child: Image.network(
          widget.screenshots[index],
          fit: BoxFit.contain,
          cacheWidth: (MediaQuery.sizeOf(context).width *
              MediaQuery.devicePixelRatioOf(context)).toInt(),
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 64,
          ),
        ),
      ),
    );
  },
),
```

### 进阶方案：手动清除已滑走的图片

如果截图数量很多（>10 张），可以在 `onPageChanged` 中手动 evict 已远离当前页的图片：

```dart
onPageChanged: (index) {
  setState(() => _currentIndex = index);
  // 清除距离当前页超过 2 页的图片缓存
  for (int i = 0; i < widget.screenshots.length; i++) {
    if ((i - index).abs() > 2) {
      final provider = NetworkImage(widget.screenshots[i]);
      PaintingBinding.instance.imageCache.evict(provider);
    }
  }
},
```

### 预估节省

- 避免同时驻留 3 张全屏大图 → 减少 **~10~20 MB**

---

## 3.4 可选进阶：CachedNetworkImage 统一替代

当前只有 `AppIcon` 使用了 `CachedNetworkImage`，其余 3 处用裸 `Image.network`。

**建议**：将截图和 Banner 也统一用 `CachedNetworkImage`，好处：
- 磁盘缓存减少重复网络请求
- `memCacheWidth`/`memCacheHeight` 控制内存解码尺寸
- `fadeInDuration` 提供更好的加载体验

**暂不作为 P0，可在 Phase 2 考虑。**

---

## 3.5 本章改动汇总

| 编号 | 改动 | 文件数 | 代码行数 | 节省内存 |
|------|------|--------|----------|----------|
| 3.1 | ImageCache 限额生效 | 1 | +2 行 | ~36 MB |
| 3.2 | 3 处 Image.network 加 cacheWidth | 2 | +6 行 | ~70 MB |
| 3.3 | 截图预览 PageView 优化 | 1 | +3 行 | ~10~20 MB |
| **合计** | | **2 文件** | **~11 行** | **~116~126 MB** |
