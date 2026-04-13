# Recommend Grid Overlap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复推荐页应用列表卡片在共享响应式网格中的视觉重叠与拥挤问题，让网格高度与卡片真实视觉占位保持一致。

**Architecture:** 保持 `AppCard` 结构不变，只修正共享 `ResponsiveAppGrid` 的默认卡片高度基线。先用回归测试锁定网格高度计算，再最小化调整默认高度常量，并通过分析与针对性测试验证推荐页及复用页面不会回退。

**Tech Stack:** Flutter、flutter_test、Riverpod、共享展示组件 `ResponsiveAppGrid`

---

### Task 1: 为共享网格高度计算补回归测试

**Files:**
- Create: `test/widget/widgets/responsive_app_grid_test.dart`
- Modify: `lib/presentation/widgets/responsive_app_grid.dart:10-110`

- [ ] **Step 1: 写失败测试，锁定默认高度基线**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/presentation/widgets/responsive_app_grid.dart';

void main() {
  group('ResponsiveAppGrid.calculateChildAspectRatio', () {
    test('uses the shared 96px app card baseline when no override is provided', () {
      const width = 720.0;
      const crossAxisCount = 2;
      final itemWidth = (width - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

      final ratio = ResponsiveAppGrid<int>.calculateChildAspectRatio(
        width,
        crossAxisCount,
      );

      expect(ratio, closeTo(itemWidth / 96.0, 0.0001));
    });

    test('returns the explicit ratio override unchanged', () {
      final ratio = ResponsiveAppGrid<int>.calculateChildAspectRatio(
        720,
        2,
        childAspectRatio: 3.2,
      );

      expect(ratio, 3.2);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认先失败**

Run: `flutter test test/widget/widgets/responsive_app_grid_test.dart`
Expected: 第一条测试失败，当前默认比例仍按旧的 `80.0` 高度基线计算。

- [ ] **Step 3: 以最小改动修正共享网格默认高度**

```dart
/// 卡片网格按 96px 视觉高度计算，给图标、按钮和 hover 安全区留出稳定空间，
/// 避免列表项在桌面端显得拥挤或上下贴边。
const kAppCardHeight = 96.0;
```

- [ ] **Step 4: 重新运行测试确认通过**

Run: `flutter test test/widget/widgets/responsive_app_grid_test.dart`
Expected: 2 tests passed.

- [ ] **Step 5: 提交这一小步修改**

```bash
git add test/widget/widgets/responsive_app_grid_test.dart lib/presentation/widgets/responsive_app_grid.dart
git commit -m "fix: 调整共享应用网格高度基线"
```

### Task 2: 验证推荐页与共享网格页面无回退

**Files:**
- Modify: `lib/presentation/widgets/responsive_app_grid.dart`
- Verify: `lib/presentation/pages/recommend/recommend_page.dart:205-208`
- Verify: `lib/presentation/pages/all_apps/all_apps_page.dart:188-214`

- [ ] **Step 1: 跑静态分析确认共享组件无告警**

```bash
flutter analyze
```

Expected: 0 error, 0 warning.

- [ ] **Step 2: 跑针对性 Widget 测试，确认共享卡片与新网格测试一起通过**

```bash
flutter test test/widget/widgets/responsive_app_grid_test.dart test/widget/widgets/app_card_skeleton_test.dart
```

Expected: 全部通过，无新增失败。

- [ ] **Step 3: 如本机 Flutter 运行环境可用，启动 Linux 桌面手动查看推荐页应用列表**

```bash
flutter run -d linux
```

Expected: 推荐页列表卡片纵向间距恢复正常，不再出现重叠或贴边感；若环境不可用，需要在结果中明确说明阻塞原因。

- [ ] **Step 4: 记录验证结论并准备交付**

```text
已验证共享网格默认高度改为 96px；推荐页和复用共享网格的页面将统一获得更稳定的卡片纵向留白。
```
