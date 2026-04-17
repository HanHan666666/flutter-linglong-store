# 应用详情页版本历史列表折叠功能设计

> 版本: 1.0 | 创建日期: 2026-04-17

---

## 背景

应用详情页的版本历史列表在某些情况下会非常长，影响用户体验。需要对列表实现折叠功能，默认显示精简版本，用户可展开查看完整历史。

---

## 需求

### 用户需求

1. **折叠状态展示：**
   - 默认折叠，只显示 2 种版本：
     - 最新版本（版本历史列表第一条）
     - 已安装版本（如果用户已安装旧版本）

2. **去重规则：**
   - 如果已安装版本恰好是最新版本，只显示一条（不重复）

3. **折叠按钮：**
   - 位置：版本列表标题"版本历史"右侧，同一行
   - 样式：简单的文本按钮（"展开全部"/"收起"），与描述区展开按钮风格一致
   - 交互：点击切换折叠/展开状态

4. **展开状态：**
   - 展开后显示完整版本历史列表，逻辑与现有实现一致

---

## 技术方案

### 架构设计

采用 **最小改动方案**：在现有 Provider 中添加折叠状态，与描述区展开逻辑保持一致。

**状态管理层：**
- `AppDetailState` 新增 `isVersionListExpanded` 字段
- `AppDetailProvider` 新增 `toggleVersionList()` 方法

**视图层：**
- `_buildVersionList` 方法根据折叠状态动态计算展示列表
- 折叠状态下调用 `_computeCollapsedVersions()` 计算显示版本

---

### 实现细节

#### 1. 状态管理

**文件：`lib/application/providers/app_detail_provider.dart`**

```dart
class AppDetailState {
  const AppDetailState({
    // ... 现有字段
    this.isVersionListExpanded = false,  // 新增：版本列表折叠状态
  });

  final bool isVersionListExpanded;  // false = 折叠（默认），true = 展开

  AppDetailState copyWith({
    // ... 现有参数
    bool? isVersionListExpanded,
  }) {
    return AppDetailState(
      // ... 现有字段复制
      isVersionListExpanded: isVersionListExpanded ?? this.isVersionListExpanded,
    );
  }
}

@riverpod
class AppDetail extends _$AppDetail {
  // ... 现有方法

  /// 切换版本列表展开状态
  void toggleVersionList() {
    state = state.copyWith(
      isVersionListExpanded: !state.isVersionListExpanded,
    );
  }
}
```

#### 2. 版本列表计算逻辑

**文件：`lib/presentation/pages/app_detail/app_detail_page.dart`**

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

#### 3. UI 结构调整

**文件：`lib/presentation/pages/app_detail/app_detail_page.dart`**

修改 `_buildVersionList` 方法：

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
                    l10n.versionHistory ?? '版本历史',
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

        // 错误提示区域（保持现有逻辑）
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

---

## 国际化

**新增/复用国际化键（已在现有 l10n 中存在）：**

| 键名 | 中文 | 英文 | 说明 |
|------|------|------|------|
| `collapse` | 收起 | Collapse | 折叠按钮（复用描述区） |
| `expandAll` | 展开全部 | Expand All | 展开按钮（复用描述区） |

无需新增国际化条目，直接复用现有键。

---

## 测试要点

### 单元测试

**文件：`test/unit/presentation/pages/app_detail/app_detail_page_test.dart`**

测试 `_computeCollapsedVersions` 方法：

```dart
test('折叠状态：最新版本 + 已安装版本（去重）', () {
  final versions = [
    AppVersion(versionNo: '3.0'),
    AppVersion(versionNo: '2.0'),
    AppVersion(versionNo: '1.0'),
  ];
  final installedVersions = {'2.0'};  // 已安装旧版本

  final collapsed = _computeCollapsedVersions(versions, installedVersions);

  expect(collapsed.length, 2);
  expect(collapsed[0].versionNo, '3.0');  // 最新版本
  expect(collapsed[1].versionNo, '2.0');  // 已安装版本
});

test('折叠状态：最新版本恰好是已安装版本（去重）', () {
  final versions = [
    AppVersion(versionNo: '3.0'),
    AppVersion(versionNo: '2.0'),
    AppVersion(versionNo: '1.0'),
  ];
  final installedVersions = {'3.0'};  // 已安装最新版本

  final collapsed = _computeCollapsedVersions(versions, installedVersions);

  expect(collapsed.length, 1);  // 只显示一条
  expect(collapsed[0].versionNo, '3.0');
});

test('折叠状态：未安装任何版本', () {
  final versions = [
    AppVersion(versionNo: '3.0'),
    AppVersion(versionNo: '2.0'),
  ];
  final installedVersions = <String>{};  // 未安装

  final collapsed = _computeCollapsedVersions(versions, installedVersions);

  expect(collapsed.length, 1);  // 只显示最新版本
  expect(collapsed[0].versionNo, '3.0');
});
```

### Widget 测试

**文件：`test/widget/presentation/pages/app_detail/app_detail_page_test.dart`**

测试 UI 交互：

```dart
testWidgets('版本列表折叠按钮显示条件', (tester) async {
  // 版本数 <= 2 时，不显示折叠按钮
  await tester.pumpWidget(/* 2 个版本的详情页 */);
  expect(find.text('展开全部'), findsNothing);

  // 版本数 > 2 时，显示折叠按钮
  await tester.pumpWidget(/* 3 个版本的详情页 */);
  expect(find.text('展开全部'), findsOneWidget);
});

testWidgets('点击展开按钮切换状态', (tester) async {
  await tester.pumpWidget(/* 5 个版本的详情页 */);

  // 默认折叠，显示 2 条
  expect(find.byType(ListTile), findsNWidgets(2));

  // 点击展开
  await tester.tap(find.text('展开全部'));
  await tester.pump();

  // 展开后，显示全部 5 条
  expect(find.byType(ListTile), findsNWidgets(5));
  expect(find.text('收起'), findsOneWidget);
});
```

---

## 边界情况

1. **版本列表为空：** 不显示折叠按钮，显示"暂无版本历史"
2. **版本数 ≤ 2：** 不显示折叠按钮，直接显示全部版本
3. **版本列表加载失败：** 折叠按钮不影响错误提示逻辑
4. **页面刷新：** 折叠状态重置为默认折叠（状态随 Provider 重建）

---

## 性能影响

- **计算开销：** `_computeCollapsedVersions` 为 O(n) 遍历，n 为版本数（通常 ≤ 50），影响极小
- **内存开销：** 新增 1 个 bool 字段，无显著影响
- **渲染性能：** 折叠状态减少列表项数量，提升渲染效率

---

## 兼容性

- **现有逻辑：** 展开状态下逻辑与现有实现完全一致，无破坏性改动
- **国际化：** 复用现有键，不新增翻译条目
- **状态持久化：** 折叠状态不持久化（随页面重建重置），符合当前架构

---

## 实施步骤

1. 修改 `lib/application/providers/app_detail_provider.dart`
   - 在 `AppDetailState` 中添加 `isVersionListExpanded` 字段
   - 在 `copyWith` 方法中添加参数
   - 在 `AppDetail` provider 中添加 `toggleVersionList()` 方法

2. 修改 `lib/presentation/pages/app_detail/app_detail_page.dart`
   - 添加 `_computeCollapsedVersions` 方法
   - 修改 `_buildVersionList` 方法，添加折叠逻辑和按钮

3. 运行代码生成
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. 编写单元测试和 Widget 测试

5. 手动验证
   - 启动应用，打开详情页
   - 验证折叠按钮显示/隐藏条件
   - 验证点击切换逻辑
   - 验证去重逻辑（已安装最新版本场景）

---

## 总结

本设计采用最小改动方案，在现有 Provider 中添加折叠状态，与描述区展开逻辑保持架构一致性。实现简单、风险可控、性能影响极小，无破坏性改动，符合项目状态管理原则和 UI 规范。