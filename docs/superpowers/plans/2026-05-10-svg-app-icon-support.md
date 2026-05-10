# AppIcon SVG Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让后端返回的 SVG 应用图标在 Flutter 商店中正常显示，同时保持现有 raster 图标的缓存策略不变。

**Architecture:** 保持 `AppIcon` 作为唯一图标渲染入口，在组件内部按资源类型分流：SVG 走 `flutter_svg`，位图继续走 `CachedNetworkImage`。测试聚焦分流行为，避免在页面层分散判断图标格式。

**Tech Stack:** Flutter, cached_network_image, flutter_svg, flutter_test

---

## Task 1: 为 AppIcon 增加回归测试

**Files:**
- Create: `test/widget/presentation/widgets/app_icon_test.dart`

- [ ] **Step 1: 编写 SVG 分流失败测试**

```dart
testWidgets('renders svg urls with SvgPicture', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppIcon(
          iconUrl: 'https://example.com/icon.svg',
          size: 48,
          appName: 'Demo',
        ),
      ),
    ),
  );

  expect(find.byType(SvgPicture), findsOneWidget);
  expect(find.byType(CachedNetworkImage), findsNothing);
});
```

- [ ] **Step 2: 编写 raster 分流失败测试**

```dart
testWidgets('renders raster urls with CachedNetworkImage', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppIcon(
          iconUrl: 'https://example.com/icon.png',
          size: 48,
          appName: 'Demo',
        ),
      ),
    ),
  );

  expect(find.byType(CachedNetworkImage), findsOneWidget);
  expect(find.byType(SvgPicture), findsNothing);
});
```

- [ ] **Step 3: 编写空 URL 占位符测试**

```dart
testWidgets('renders placeholder when icon url is empty', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppIcon(
          iconUrl: '',
          size: 48,
          appName: 'Demo',
        ),
      ),
    ),
  );

  expect(find.text('D'), findsOneWidget);
});
```

- [ ] **Step 4: 运行测试并确认当前失败**

Run: `flutter test test/widget/presentation/widgets/app_icon_test.dart`
Expected: SVG 分流断言失败，因为当前实现只渲染 `CachedNetworkImage`

## Task 2: 在统一入口实现 SVG 分流

**Files:**
- Modify: `lib/presentation/widgets/app_icon.dart`

- [ ] **Step 1: 增加 SVG 识别 helper**

```dart
bool _isSvgIconUrl(String url) {
  final normalized = url.trim().toLowerCase();
  if (normalized.startsWith('data:image/svg+xml')) {
    return true;
  }

  final uri = Uri.tryParse(normalized);
  final path = uri?.path ?? normalized;
  return path.endsWith('.svg');
}
```

- [ ] **Step 2: 为 SVG URL 渲染 SvgPicture.network**

```dart
if (_isSvgIconUrl(iconUrl!)) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      width: size,
      height: size,
      child: SvgPicture.network(
        iconUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildPlaceholder(context, bgColor!),
      ),
    ),
  );
}
```

- [ ] **Step 3: 保留 raster 图标缓存逻辑**

```dart
return ClipRRect(
  borderRadius: BorderRadius.circular(borderRadius),
  child: CachedNetworkImage(
    imageUrl: iconUrl!,
    width: size,
    height: size,
    fit: BoxFit.cover,
    memCacheWidth: effectiveMemCacheWidth,
    maxWidthDiskCache: effectiveDiskCacheWidth,
    placeholder: (context, url) => _buildPlaceholder(context, bgColor!),
    errorWidget: (context, url, error) => _buildErrorWidget(context, bgColor!),
  ),
);
```

## Task 3: 验证实现并同步文档

**Files:**
- Modify: `docs/03c-ui-core-widgets.md`

- [ ] **Step 1: 运行回归测试确认通过**

Run: `flutter test test/widget/presentation/widgets/app_icon_test.dart`
Expected: 3 tests passed

- [ ] **Step 2: 运行受影响组件测试**

Run: `flutter test test/widget/presentation/widgets/download_manager_dialog_test.dart`
Expected: existing tests passed

- [ ] **Step 3: 更新文档中的图标来源说明**

```md
图标来源优先级：
1. `appInfo.icon`（远程 URL，SVG 由 `flutter_svg` 渲染，位图由 `CachedNetworkImage` 渲染）
2. 构建时内置的 category 默认图标
3. 全局默认 SVG 图标
```
