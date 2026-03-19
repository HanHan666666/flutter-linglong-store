# App Detail Size Formatting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让详情页版本历史与应用信息中的应用体积展示统一为对齐 Rust 旧版的人性化格式，避免继续渲染裸字节串。

**Architecture:** 保持仓储层与 DTO 契约不变，只在 `FormatUtils` 增加安全的体积格式化入口，页面层统一调用。实现范围限定在详情页两个展示点、对应单元测试和业务文档，不扩散到其他页面。

**Tech Stack:** Flutter, Dart, flutter_test

**Status:** ✅ 已完成 (2026-03-18)

---

### Task 1: 补齐格式化工具测试

**Files:**
- Modify: `test/unit/core/utils/format_utils_test.dart`

- [x] **Step 1: 写失败测试，覆盖新格式化入口**

```dart
expect(FormatUtils.formatFileSizeValue('759577252'), equals('724.39 MB'));
expect(FormatUtils.formatFileSizeValue(null), equals('--'));
expect(FormatUtils.formatFileSizeValue(''), equals('--'));
expect(FormatUtils.formatFileSizeValue('invalid'), equals('--'));
expect(FormatUtils.formatFileSizeValue(512), equals('0.50 KB'));
```

- [x] **Step 2: 运行单测并确认失败**

Run: `flutter test test/unit/core/utils/format_utils_test.dart`
Expected: FAIL，提示 `FormatUtils.formatFileSizeValue` 不存在或断言失败。

- [x] **Step 3: 保持现有 `formatFileSize` 用例不被破坏**

```dart
expect(FormatUtils.formatFileSize(1024), equals('1.0 KB'));
expect(FormatUtils.formatSpeed(1024), equals('1.0 KB/s'));
```

- [x] **Step 4: 提交前重新运行该测试文件**

Run: `flutter test test/unit/core/utils/format_utils_test.dart`
Expected: PASS

### Task 2: 实现安全文件大小格式化工具

**Files:**
- Modify: `lib/core/utils/format_utils.dart`
- Test: `test/unit/core/utils/format_utils_test.dart`

- [x] **Step 1: 新增安全格式化入口**

```dart
static String formatFileSizeValue(Object? size) {
  if (size == null) return '--';
  final normalized = size is String ? size.trim() : size.toString();
  if (normalized.isEmpty) return '--';
  final bytes = num.tryParse(normalized);
  if (bytes == null) return '--';
  return _formatHumanReadableSize(bytes.toDouble());
}
```

- [x] **Step 2: 提取内部私有格式化逻辑，避免重复**

```dart
static String _formatHumanReadableSize(double bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;

  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
  return '${(bytes / kb).toStringAsFixed(2)} KB';
}
```

- [x] **Step 3: 保持旧接口兼容**

```dart
static String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  ...
}
```

- [x] **Step 4: 运行单测确认通过**

Run: `flutter test test/unit/core/utils/format_utils_test.dart`
Expected: PASS

### Task 3: 统一详情页两个体积展示点

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`

- [x] **Step 1: 版本历史 subtitle 改为调用统一格式化工具**

```dart
final formattedPackageSize =
    FormatUtils.formatFileSizeValue(version.packageSize);
```

- [x] **Step 2: 应用信息区域的“大小”改为统一格式化**

```dart
final formattedAppSize = FormatUtils.formatFileSizeValue(app.size);
```

- [x] **Step 3: 做轻量清理但不扩散重构**

```dart
final subtitleParts = <String>[
  if (version.releaseTime?.isNotEmpty ?? false) version.releaseTime!,
  if (formattedPackageSize != '--') formattedPackageSize,
];
```

- [x] **Step 4: 运行相关测试确保未引入回归**

Run: `flutter test test/unit/core/utils/format_utils_test.dart`
Expected: PASS

### Task 4: 补充业务文档

**Files:**
- Modify: `docs/03d-ui-pages.md`

- [x] **Step 1: 在详情页版本列表约束中补充体积展示规则**

```md
- 版本历史与应用信息中的体积字段必须通过统一格式化工具展示，禁止直接渲染后端返回的裸字节串。
```

- [x] **Step 2: 明确 Rust 迁移对齐范围**

```md
- 详情页版本历史文件大小展示需对齐旧版 Rust 商店：空值/非法值显示 `--`，其余按 KB/MB/GB 人性化显示。
```

- [x] **Step 3: 重新检查文档与实现一致**

Run: `rg -n "裸字节串|体积字段|文件大小展示" docs/03d-ui-pages.md`
Expected: 能定位到新约束文本

### Task 5: 最终验证

**Files:**
- Modify: `lib/core/utils/format_utils.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `test/unit/core/utils/format_utils_test.dart`
- Modify: `docs/03d-ui-pages.md`

- [x] **Step 1: 运行本次相关单测**

Run: `flutter test test/unit/core/utils/format_utils_test.dart`
Expected: PASS

- [x] **Step 2: 运行静态分析的最小验证**

Run: `flutter analyze lib/core/utils/format_utils.dart lib/presentation/pages/app_detail/app_detail_page.dart test/unit/core/utils/format_utils_test.dart`
Expected: 0 issues found

- [x] **Step 3: 检查改动范围**

Run: `git diff -- lib/core/utils/format_utils.dart lib/presentation/pages/app_detail/app_detail_page.dart test/unit/core/utils/format_utils_test.dart docs/03d-ui-pages.md`
Expected: 仅包含本次体积展示链路相关改动
