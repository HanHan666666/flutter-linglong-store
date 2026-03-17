# 07 - 其他优化与内存监控

> **优先级：P2~P3** | **预估节省：10~20 MB + 辅助工具**

---

## 7.1 GPU 光栅缓存优化

### 问题

Flutter 默认会缓存很多已光栅化的 Layer。对于商店这种大量卡片列表的场景，缓存可能过量。

### 方案

在复杂列表中对不需要缓存的 Widget 取消 `RepaintBoundary`：

```dart
// 列表卡片组件中，避免不必要的光栅缓存
// Flutter 默认会为每个 ListView item 加 RepaintBoundary
// 对于简单卡片可以用 addRepaintBoundaries: false 减少缓存
GridView.builder(
  addRepaintBoundaries: false,  // 简单卡片不需要独立光栅缓存
  itemBuilder: ...,
)
```

> **注意**：需要 profile 验证。如果卡片包含复杂绘制（阴影、圆角图片等），移除 RepaintBoundary 可能导致重绘增加。建议先在开发模式下用 `flutter run --profile` 对比 FPS。

### 预估节省

- 减少 GPU 纹理缓存 = **5~15 MB**（需实测）

---

## 7.2 Shimmer 骨架屏优化

### 问题

`shimmer` 包在列表加载时渲染骨架屏动画。如果大量骨架屏同时渲染，Animation + Gradient 会占用 GPU 内存。

### 方案

限制骨架屏渲染数量，超出可视区域的不渲染：

```dart
// 骨架屏列表使用 builder 模式，限制可见数量
ListView.builder(
  itemCount: min(shimmerCount, 6), // 最多展示 6 个骨架屏
  itemBuilder: (context, index) => const AppCardShimmer(),
)
```

### 预估节省

- **2~5 MB**（主要减少 GPU 开销）

---

## 7.3 依赖包审计

### 当前依赖及内存影响评估

| 依赖 | 功能 | 内存影响 | 建议 |
|------|------|----------|------|
| `cached_network_image` | 图片缓存 | 中 | ✅ 保留，统一使用 |
| `hive` + `hive_flutter` | 本地缓存 | 中-高 | ⚠️ 见第 06 章优化 |
| `dio` | HTTP | 低 | ✅ 保留 |
| `flutter_riverpod` | 状态管理 | 低 | ✅ 保留 |
| `shared_preferences` | KV 存储 | 低 | ✅ 保留 |
| `flutter_svg` | SVG 渲染 | 中 | ⚠️ 确认使用量 |
| `shimmer` | 骨架屏 | 低 | ✅ 保留 |
| `uuid` | UUID 生成 | 低 | ✅ 保留 |
| `logger` | 日志 | 低 | ✅ 保留 |
| `device_info_plus` | 设备信息 | 低 | ✅ 保留 |
| `package_info_plus` | 包信息 | 低 | ✅ 保留 |

### flutter_svg 注意事项

`flutter_svg` 会将 SVG 解析为 `PictureInfo` 并缓存。如果项目中使用了大量不同的 SVG 图标，缓存会累积。

```dart
// 如果 SVG 使用量大，可手动清理不需要的缓存
import 'package:flutter_svg/flutter_svg.dart';

// 清理 SVG 缓存
void clearSvgCache() {
  // flutter_svg 2.x 的缓存由 vg 包管理
  // 特定场景下可调用
}
```

当前项目 SVG 使用量不大，**暂不需要优化**。

---

## 7.4 内存监控工具集成

### 目的

量化每项优化的效果，建立内存基线。

### 方案 A：开发期内存观测（推荐）

```dart
// lib/core/debug/memory_monitor.dart

import 'dart:developer' as developer;
import 'dart:async';

/// 内存监控工具（仅在 debug/profile 模式下生效）
class MemoryMonitor {
  MemoryMonitor._();

  static Timer? _timer;

  /// 启动定期内存报告
  static void start({Duration interval = const Duration(seconds: 30)}) {
    assert(() {
      _timer?.cancel();
      _timer = Timer.periodic(interval, (_) => _reportMemory());
      _reportMemory(); // 立即报告一次
      return true;
    }());
  }

  /// 停止
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 报告当前内存状态
  static void _reportMemory() {
    final imageCache = PaintingBinding.instance.imageCache;
    developer.log(
      'Memory Report: '
      'ImageCache(count=${imageCache.currentSize}/'
      '${imageCache.maximumSize}, '
      'bytes=${(imageCache.currentSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB/'
      '${(imageCache.maximumSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB)',
      name: 'MemoryMonitor',
    );
  }

  /// 手动触发一次报告（供调试用）
  static void report() => _reportMemory();
}
```

在 `main.dart` 中启动：

```dart
// 仅在 debug/profile 模式下启动内存监控
assert(() {
  MemoryMonitor.start();
  return true;
}());
```

### 方案 B：利用 DevTools

```bash
# 使用 Flutter DevTools 的 Memory 面板
flutter run -d linux --profile
# 打开 DevTools → Memory 标签页
# 对比优化前后的 Heap 快照
```

### 方案 C：自动化内存基准测试

```dart
// test/benchmarks/memory_benchmark.dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('memory baseline after startup', (tester) async {
    // 启动应用
    await tester.pumpWidget(const LinglongStoreApp());
    await tester.pumpAndSettle();

    // 等待初始化完成
    await Future.delayed(const Duration(seconds: 5));

    // 记录 ImageCache 状态
    final cache = PaintingBinding.instance.imageCache;
    expect(cache.currentSizeBytes, lessThan(64 * 1024 * 1024),
        reason: 'ImageCache should not exceed 64MB');

    // 记录基线数据
    debugPrint('Baseline: ImageCache = '
        '${(cache.currentSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB, '
        'count=${cache.currentSize}');
  });
}
```

---

## 7.5 Release 模式构建优化

### 确认当前是否开启了 tree-shaking

```bash
# 生产构建应使用 --release 确保无效代码被裁剪
flutter build linux --release
```

### 字体子集化

如果项目用了自定义字体（`assets/fonts/`），确保只包含需要的字符子集：

```yaml
# pubspec.yaml
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/CustomFont.ttf
```

检查字体文件大小，必要时用 `fonttools` 工具裁剪。

---

## 7.6 本章改动汇总

| 编号 | 改动 | 文件数 | 风险 | 节省内存 | 阶段 |
|------|------|--------|------|----------|------|
| 7.1 | 列表取消 RepaintBoundary | 3~5 | 低-中 | 5~15 MB | Phase 3 |
| 7.2 | 骨架屏数量限制 | 1~2 | 低 | 2~5 MB | Phase 3 |
| 7.4 | 内存监控工具 | 1（新增） | 无 | 0（辅助） | Phase 1 |
| **合计** | | **5~8 文件** | | **7~20 MB** | |
