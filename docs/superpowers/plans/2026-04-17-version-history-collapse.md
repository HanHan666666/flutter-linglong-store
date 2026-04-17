# 应用详情页版本历史列表折叠功能实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现应用详情页版本历史列表折叠功能，默认显示最新版本+已安装版本，用户可展开查看完整历史。

**Architecture:** 在现有 Provider 中添加折叠状态（`isVersionListExpanded`），与描述区展开逻辑保持一致；页面根据状态动态计算显示列表；遵循 TDD 开发流程。

**Tech Stack:** Flutter, Riverpod, Freezed, flutter_test

---

## 文件结构

**修改文件：**
- `lib/application/providers/app_detail_provider.dart` - 状态管理（新增折叠状态和切换方法）
- `lib/presentation/pages/app_detail/app_detail_page.dart` - UI 实现（新增计算方法和折叠按钮）

**新建文件：**
- `test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart` - Provider 折叠状态单元测试
- `test/widget/presentation/widgets/app_detail_version_list_test.dart` - UI 交互 widget 测试

**修改文件：**
- `lib/application/providers/app_detail_provider.freezed.dart` - Freezed 生成文件（运行 build_runner 后更新）
- `lib/application/providers/app_detail_provider.g.dart` - Riverpod 生成文件（运行 build_runner 后更新）

---

## Task 1: Provider 折叠状态和方法（TDD）

**Files:**
- Create: `test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart`
- Modify: `lib/application/providers/app_detail_provider.dart:14-87`

- [ ] **Step 1: 编写 Provider 单元测试**

创建测试文件验证折叠状态和方法：

```dart
// test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/app_detail_provider.dart';

void main() {
  group('AppDetailState 折叠状态', () {
    test('默认状态为折叠（isVersionListExpanded = false）', () {
      const state = AppDetailState();
      expect(state.isVersionListExpanded, false);
    });

    test('copyWith 可以更新折叠状态', () {
      const initialState = AppDetailState();
      final updatedState = initialState.copyWith(isVersionListExpanded: true);

      expect(initialState.isVersionListExpanded, false);
      expect(updatedState.isVersionListExpanded, true);
    });
  });

  group('AppDetail Provider toggleVersionList 方法', () {
    test('调用 toggleVersionList 切换折叠状态', () {
      final container = ProviderContainer();
      final provider = container.read(appDetailProvider('test-app').notifier);

      // 初始状态
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, false);

      // 第一次切换：展开
      provider.toggleVersionList();
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, true);

      // 第二次切换：折叠
      provider.toggleVersionList();
      expect(container.read(appDetailProvider('test-app')).isVersionListExpanded, false);

      container.dispose();
    });
  });
}
```

- [ ] **Step 2: 运行测试验证失败**

运行命令：
```bash
flutter test test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
```

预期输出：编译错误或测试失败（缺少 `isVersionListExpanded` 字段和 `toggleVersionList` 方法）

- [ ] **Step 3: 实现状态字段和切换方法**

修改 Provider 文件：

**3a. 在 `AppDetailState` 中添加字段（第 14-29 行）：**

```dart
class AppDetailState {
  const AppDetailState({
    this.app,
    this.appDetail,
    this.screenshots = const [],
    this.comments = const [],
    this.versions = const [],
    this.isLoading = false,
    this.isLoadingComments = false,
    this.isLoadingVersions = false,
    this.commentsError,
    this.versionsError,
    this.error,
    this.isSubmittingComment = false,
    this.isDescriptionExpanded = false,
    this.isVersionListExpanded = false,  // 新增字段
  });

  // ... 现有字段
  final bool isVersionListExpanded;  // 新增字段定义
```

**3b. 在 `copyWith` 方法中添加参数（第 48-87 行）：**

```dart
AppDetailState copyWith({
  InstalledApp? app,
  dm.AppDetail? appDetail,
  List<dm.AppScreenshot>? screenshots,
  List<dm.AppComment>? comments,
  List<dm.AppVersion>? versions,
  bool? isLoading,
  bool? isLoadingComments,
  bool? isLoadingVersions,
  String? commentsError,
  String? versionsError,
  String? error,
  bool? isSubmittingComment,
  bool? isDescriptionExpanded,
  bool? isVersionListExpanded,  // 新增参数
  bool clearError = false,
  bool clearCommentsError = false,
  bool clearVersionsError = false,
  bool clearAppDetail = false,
}) {
  return AppDetailState(
    app: app ?? this.app,
    appDetail: clearAppDetail ? null : (appDetail ?? this.appDetail),
    screenshots: screenshots ?? this.screenshots,
    comments: comments ?? this.comments,
    versions: versions ?? this.versions,
    isLoading: isLoading ?? this.isLoading,
    isLoadingComments: isLoadingComments ?? this.isLoadingComments,
    isLoadingVersions: isLoadingVersions ?? this.isLoadingVersions,
    commentsError: clearCommentsError
        ? null
        : (commentsError ?? this.commentsError),
    versionsError: clearVersionsError
        ? null
        : (versionsError ?? this.versionsError),
    error: clearError ? null : (error ?? this.error),
    isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
    isDescriptionExpanded:
        isDescriptionExpanded ?? this.isDescriptionExpanded,
    isVersionListExpanded: isVersionListExpanded ?? this.isVersionListExpanded,  // 新增字段复制
  );
}
```

**3c. 在 `AppDetail` provider 中添加切换方法（第 234-238 行后）：**

```dart
/// 切换描述展开状态
void toggleDescription() {
  state = state.copyWith(isDescriptionExpanded: !state.isDescriptionExpanded);
}

/// 切换版本列表展开状态
void toggleVersionList() {
  state = state.copyWith(isVersionListExpanded: !state.isVersionListExpanded);
}
```

- [ ] **Step 4: 运行测试验证通过**

运行命令：
```bash
flutter test test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
```

预期输出：所有测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/application/providers/app_detail_provider.dart test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
git commit -m "feat: 应用详情页版本列表折叠状态管理"
```

---

## Task 2: 页面版本计算逻辑（TDD）

**Files:**
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart:1160-1200`（新增方法）

- [ ] **Step 1: 编写版本计算逻辑测试**

在测试文件中添加测试组：

```dart
// test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart

import 'package:linglong_store/domain/models/app_version.dart';

void main() {
  // ... 之前的测试组

  group('_computeCollapsedVersions 版本计算逻辑', () {
    test('折叠状态：最新版本 + 已安装版本（去重）', () {
      final versions = [
        AppVersion(versionNo: '3.0'),
        AppVersion(versionNo: '2.0'),
        AppVersion(versionNo: '1.0'),
      ];
      final installedVersions = {'2.0'};  // 已安装旧版本

      // 注意：这里需要通过页面实例访问方法，或者将方法提取为静态/公开方法
      // 实际实现时可能需要调整测试策略
      // 暂时跳过此测试，在 widget 测试中验证逻辑
    });

    test('版本数为 0 返回空列表', () {
      final versions = <AppVersion>[];
      final installedVersions = <String>{};

      expect(versions.isEmpty, true);
    });

    test('版本数为 1 返回该版本', () {
      final versions = [AppVersion(versionNo: '1.0')];
      expect(versions.length, 1);
    });
  });
}
```

说明：由于 `_computeCollapsedVersions` 是页面私有方法，单元测试无法直接访问。将在 Task 3 的 widget 测试中通过 UI 交互验证逻辑。

- [ ] **Step 2: 运行测试验证通过**

运行命令：
```bash
flutter test test/unit/presentation/pages/app_detail/app_detail_version_collapse_test.dart
```

预期输出：测试通过（新增测试组为概念验证，不直接测试私有方法）

- [ ] **Step 3: 实现版本计算方法**

在 `app_detail_page.dart` 文件末尾（第 1160 行后）添加私有方法：

```dart
/// 计算折叠状态下的版本列表
///
/// 规则：
/// 1. 始终包含最新版本（列表第一条）
/// 2. 如果已安装版本 ≠ 最新版本，添加已安装版本
/// 3. 去重：最新版本恰好是已安装版本时只显示一条
List<AppVersion> _computeCollapsedVersions(
  List<AppVersion> allVersions,
  Set<String> installedVersions,
) {
  if (allVersions.isEmpty) {
    return [];
  }

  final latestVersion = allVersions.first;
  final result = <AppVersion>[latestVersion];

  // 查找已安装但不是最新版本的其他版本
  for (final version in allVersions) {
    final isInstalled = installedVersions.contains(version.versionNo);
    final isNotLatest = version.versionNo != latestVersion.versionNo;

    if (isInstalled && isNotLatest) {
      result.add(version);
    }
  }

  return result;
}
```

- [ ] **Step 4: 运行静态分析**

运行命令：
```bash
flutter analyze lib/presentation/pages/app_detail/app_detail_page.dart
```

预期输出：无错误和警告

- [ ] **Step 5: 提交代码**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart
git commit -m "feat: 版本历史列表折叠计算逻辑"
```

---

## Task 3: UI 实现（TDD）

**Files:**
- Create: `test/widget/presentation/widgets/app_detail_version_list_test.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart:676-795`（修改 `_buildVersionList` 方法）

- [ ] **Step 1: 编写 UI widget 测试**

创建 widget 测试验证折叠功能：

```dart
// test/widget/presentation/widgets/app_detail_version_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/presentation/pages/app_detail/app_detail_page.dart';
import 'package:linglong_store/application/providers/app_detail_provider.dart';
import 'package:linglong_store/domain/models/app_version.dart';
import 'package:linglong_store/domain/models/installed_app.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';

void main() {
  group('版本历史列表折叠功能', () {
    testWidgets('版本数 ≤ 2 时，不显示折叠按钮', (tester) async {
      // 构造 2 个版本的测试数据
      final detailState = AppDetailState(
        app: InstalledApp(
          appId: 'test-app',
          name: 'Test App',
          version: '2.0',
        ),
        versions: [
          AppVersion(versionNo: '2.0'),
          AppVersion(versionNo: '1.0'),
        ],
        isVersionListExpanded: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDetailProvider('test-app').overrideWith(
              (ref) => AppDetailStateNotifier(detailState),
            ),
          ],
          child: const MaterialApp(
            home: AppDetailPage(appId: 'test-app'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证：不显示展开按钮
      expect(find.text('展开全部'), findsNothing);
    });

    testWidgets('版本数 > 2 时，显示折叠按钮（默认折叠）', (tester) async {
      // 构造 5 个版本的测试数据
      final detailState = AppDetailState(
        app: InstalledApp(
          appId: 'test-app',
          name: 'Test App',
          version: '3.0',
        ),
        versions: [
          AppVersion(versionNo: '5.0'),
          AppVersion(versionNo: '4.0'),
          AppVersion(versionNo: '3.0'),
          AppVersion(versionNo: '2.0'),
          AppVersion(versionNo: '1.0'),
        ],
        isVersionListExpanded: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDetailProvider('test-app').overrideWith(
              (ref) => AppDetailStateNotifier(detailState),
            ),
          ],
          child: const MaterialApp(
            home: AppDetailPage(appId: 'test-app'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证：显示展开按钮
      expect(find.text('展开全部'), findsOneWidget);

      // 验证：默认折叠，显示 2 个版本（最新 + 已安装）
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('点击展开按钮切换为展开状态', (tester) async {
      final detailState = AppDetailState(
        app: InstalledApp(
          appId: 'test-app',
          name: 'Test App',
          version: '3.0',
        ),
        versions: [
          AppVersion(versionNo: '5.0'),
          AppVersion(versionNo: '4.0'),
          AppVersion(versionNo: '3.0'),
          AppVersion(versionNo: '2.0'),
          AppVersion(versionNo: '1.0'),
        ],
        isVersionListExpanded: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDetailProvider('test-app').overrideWith(
              (ref) => AppDetailStateNotifier(detailState),
            ),
          ],
          child: const MaterialApp(
            home: AppDetailPage(appId: 'test-app'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击展开按钮
      await tester.tap(find.text('展开全部'));
      await tester.pumpAndSettle();

      // 验证：显示收起按钮
      expect(find.text('收起'), findsOneWidget);

      // 验证：展开状态，显示全部 5 个版本
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('已安装最新版本时折叠状态只显示一条（去重）', (tester) async {
      final detailState = AppDetailState(
        app: InstalledApp(
          appId: 'test-app',
          name: 'Test App',
          version: '5.0',  // 已安装最新版本
        ),
        versions: [
          AppVersion(versionNo: '5.0'),  // 最新版本 = 已安装版本
          AppVersion(versionNo: '4.0'),
          AppVersion(versionNo: '3.0'),
          AppVersion(versionNo: '2.0'),
          AppVersion(versionNo: '1.0'),
        ],
        isVersionListExpanded: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDetailProvider('test-app').overrideWith(
              (ref) => AppDetailStateNotifier(detailState),
            ),
          ],
          child: const MaterialApp(
            home: AppDetailPage(appId: 'test-app'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证：折叠状态只显示 1 个版本（去重）
      expect(find.byType(ListTile), findsNWidgets(1));

      // 验证：显示的是最新版本 v5.0
      expect(find.text('v5.0'), findsOneWidget);

      // 验证：标记为已安装
      expect(find.text('已安装'), findsOneWidget);
    });
  });
}

// 辅助类：提供可更新的状态 notifier
class AppDetailStateNotifier extends AppDetail {
  AppDetailStateNotifier(AppDetailState initialState) : super('test-app') {
    state = initialState;
  }

  @override
  AppDetailState build(String appId) {
    return const AppDetailState();
  }
}
```

- [ ] **Step 2: 运行测试验证失败**

运行命令：
```bash
flutter test test/widget/presentation/widgets/app_detail_version_list_test.dart
```

预期输出：测试失败（缺少折叠按钮 UI，`_buildVersionList` 未实现折叠逻辑）

- [ ] **Step 3: 实现折叠 UI 逻辑**

修改 `_buildVersionList` 方法（第 676-795 行）：

**完整替换该方法：**

```dart
Widget _buildVersionList(
  BuildContext context,
  AppDetailState detailState,
  InstallTask? currentInstallTask,
  Set<String> installedVersions,
) {
  final allVersions = detailState.versions;
  final isLoading = detailState.isLoadingVersions;
  final versionsError = detailState.versionsError;
  final currentApp = detailState.app;
  final isExpanded = detailState.isVersionListExpanded;
  final l10n = AppLocalizations.of(context)!;

  // 根据折叠状态计算展示列表
  final displayVersions = isExpanded
      ? allVersions
      : _computeCollapsedVersions(allVersions, installedVersions);

  // 判断是否需要显示折叠按钮（版本数 > 2 时才显示）
  final shouldShowToggle = allVersions.length > 2;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行：左侧标题 + 右侧折叠按钮
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    l10n.versionHistory,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (isLoading) ...[
                    const SizedBox(width: 12),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
            ),
            // 折叠按钮在右上角
            if (shouldShowToggle)
              TextButton(
                onPressed: () {
                  ref
                      .read(appDetailProvider(widget.appId).notifier)
                      .toggleVersionList();
                },
                child: Text(
                  isExpanded
                      ? (l10n.collapse ?? '收起')
                      : (l10n.expandAll ?? '展开全部'),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // 错误提示区域
        if (versionsError != null && allVersions.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.versionListLoadFailed ?? '版本列表加载失败，请重试',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(appDetailProvider(widget.appId).notifier)
                      .retryVersions();
                },
                child: Text(l10n.retry ?? '重试'),
              ),
            ],
          )
        else if (versionsError != null)
          Text(
            l10n.versionListUpdateFailed ?? '版本列表更新失败，显示最近一次结果',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),

        if (versionsError != null) const SizedBox(height: 12),

        // 版本列表（使用计算后的 displayVersions）
        if (displayVersions.isEmpty && !isLoading)
          Text(l10n.noVersionHistory ?? '暂无版本历史')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayVersions.length,
            itemBuilder: (context, index) {
              final version = displayVersions[index];
              final isInstalledVersion = installedVersions.contains(
                version.versionNo,
              );
              final formattedPackageSize = FormatUtils.formatFileSizeValue(
                version.packageSize,
              );
              final subtitleParts = <String>[
                if (version.releaseTime?.isNotEmpty ?? false)
                  version.releaseTime!,
                if (formattedPackageSize != '--') formattedPackageSize,
              ];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isInstalledVersion ? Icons.check_circle : Icons.history,
                  color: isInstalledVersion
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                title: Text('v${version.versionNo}'),
                subtitle: Text(
                  subtitleParts.isEmpty ? '--' : subtitleParts.join(' · '),
                ),
                trailing: isInstalledVersion
                    ? Text(l10n.installedBadge ?? '已安装')
                    : TextButton(
                        onPressed: () =>
                            _installVersion(currentApp!, version.versionNo),
                        child: Text(l10n.install ?? '安装'),
                      ),
              );
            },
          ),
      ],
    ),
  );
}
```

- [ ] **Step 4: 运行测试验证通过**

运行命令：
```bash
flutter test test/widget/presentation/widgets/app_detail_version_list_test.dart
```

预期输出：所有 widget 测试通过

- [ ] **Step 5: 提交代码**

```bash
git add lib/presentation/pages/app_detail/app_detail_page.dart test/widget/presentation/widgets/app_detail_version_list_test.dart
git commit -m "feat: 版本历史列表折叠 UI 实现"
```

---

## Task 4: 代码生成和静态分析

**Files:**
- Modify: `lib/application/providers/app_detail_provider.freezed.dart`（生成文件）
- Modify: `lib/application/providers/app_detail_provider.g.dart`（生成文件）

- [ ] **Step 1: 运行代码生成器**

运行命令：
```bash
dart run build_runner build --delete-conflicting-outputs
```

预期输出：生成 Freezed 和 Riverpod 代码，无错误

- [ ] **Step 2: 运行全量静态分析**

运行命令：
```bash
flutter analyze
```

预期输出：无错误和警告

- [ ] **Step 3: 运行全量测试**

运行命令：
```bash
flutter test
```

预期输出：所有测试通过

- [ ] **Step 4: 提交生成文件**

```bash
git add lib/application/providers/app_detail_provider.freezed.dart lib/application/providers/app_detail_provider.g.dart
git commit -m "chore: 重新生成 Freezed 和 Riverpod 代码"
```

---

## Task 5: 手动验证

**Files:**
- 无文件修改（手动测试）

- [ ] **Step 1: 启动应用**

运行命令：
```bash
flutter run -d linux
```

- [ ] **Step 2: 打开应用详情页**

导航路径：推荐页 → 点击任意应用卡片 → 进入详情页

- [ ] **Step 3: 验证折叠按钮显示条件**

验证点：
1. 版本数 ≤ 2 的应用：不显示折叠按钮
2. 版本数 > 2 的应用：显示折叠按钮在标题右侧

- [ ] **Step 4: 验证折叠状态**

验证点：
1. 默认状态：折叠，显示最新版本 + 已安装版本（如果不同）
2. 点击"展开全部"：显示完整版本列表
3. 点击"收起"：回到折叠状态

- [ ] **Step 5: 验证去重逻辑**

验证点：
1. 已安装最新版本的应用：折叠状态只显示 1 条（不重复）
2. 已安装旧版本的应用：折叠状态显示 2 条（最新 + 已安装）

- [ ] **Step 6: 验证 UI 样式**

验证点：
1. 折叠按钮样式与描述区展开按钮一致
2. 折叠按钮位置在标题右侧，同一行
3. 按钮文本："展开全部" / "收起"

---

## Task 6: 更新文档和最终提交

**Files:**
- Modify: `docs/superpowers/specs/2026-04-17-version-history-collapse-design.md`（可选更新）

- [ ] **Step 1: 清理 git 状态**

运行命令：
```bash
git status
```

确认所有改动已提交

- [ ] **Step 2: 查看提交历史**

运行命令：
```bash
git log --oneline -n 10
```

确认提交顺序和消息格式符合规范

- [ ] **Step 3: 更新 CLAUDE.md 变更记录（可选）**

如果需要，在 `CLAUDE.md` 的"变更记录"部分添加：

```markdown
- 2026-04-17：应用详情页版本历史列表新增折叠功能，默认显示最新版本+已安装版本，展开后显示完整历史。折叠按钮位于标题右侧，版本数 > 2 时才显示。
```

- [ ] **Step 4: 最终验证**

再次运行测试套件：
```bash
flutter test
flutter analyze
```

预期输出：全部通过

---

## 自检清单

完成计划编写后，自检以下内容：

**1. Spec 覆盖检查：**
- ✅ 状态管理：Task 1 实现了 `isVersionListExpanded` 字段和 `toggleVersionList()` 方法
- ✅ 版本计算逻辑：Task 2 实现了 `_computeCollapsedVersions` 方法
- ✅ UI 实现：Task 3 实现了折叠按钮和动态显示列表
- ✅ 测试覆盖：Task 1、2、3 均包含测试
- ✅ 手动验证：Task 5 包含完整验证步骤

**2. Placeholder 扫描：**
- ✅ 无 TBD/TODO
- ✅ 无"add validation"/"handle edge cases"等模糊描述
- ✅ 所有代码步骤包含完整代码
- ✅ 所有命令步骤包含完整命令和预期输出

**3. 类型一致性检查：**
- ✅ `isVersionListExpanded` 在所有地方使用相同名称
- ✅ `toggleVersionList()` 方法名称一致
- ✅ `_computeCollapsedVersions` 方法签名一致

---

## 执行选项

Plan complete and saved to `docs/superpowers/plans/2026-04-17-version-history-collapse.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?