# 搜索候选增强设计

**Date:** 2026-05-27
**Supersedes:** 2026-05-27-title-bar-search-suggestions-design.md（候选数据源从后端 API 切换为 ll-cli 本地索引）

## 背景

当前标题栏搜索候选使用 `/visit/getSearchAppList` 后端接口。该接口存在严重性能问题：

1. 4 个 `LIKE '%keyword%'` 全表扫描，无全文索引
2. 单次查询扫描主表 3 次（CTE 窗口排序 + 安装量聚合 + 主查询关联）
3. Redis 缓存形同虚设——搜索词不同即缓存 miss，且定时任务每 2 分钟清空全部缓存
4. 实际响应时间 100-300ms，体验差

同时候选面板缺少基本交互能力：无 hover 高亮、无键盘导航、无回车跳转。

## 目标

1. 候选数据源切换为 `ll-cli search . --json` 本地内存索引，**端到端延迟 < 100ms**
2. 候选面板支持鼠标 hover 高亮、键盘 ↑↓ 选中、Enter 跳转详情、点击跳转详情
3. 用户体验与主流桌面应用搜索框对齐（VS Code、系统设置等）

## 非目标

1. 不修改后端代码
2. 不修改搜索结果页（仍走后端 `/visit/getSearchAppList`）
3. 不增加定时刷新（启动时加载一次即可）
4. 不在候选面板中展示图标、描述、评分等复杂信息

---

## 方案选型

### 选择：ll-cli 本地内存索引

`ll-cli search . --json` 输出约 7604 条应用的 `{id, name, arch, version}` 信息。启动时执行一次，解析后常驻内存。候选匹配在 Dart 侧做纯内存扫描，零网络延迟。

| 对比 | 之前（后端 API） | 现在（ll-cli 本地） |
|------|------------------|---------------------|
| 延迟 | 100-300ms | < 1ms |
| 网络依赖 | 是 | 否 |
| 后端改动 | 需要优化 | 无 |
| 数据新鲜度 | 实时 | 启动时快照 |
| 防抖 | 300ms | 100ms |

---

## 详细设计

### 一、数据层：本地搜索索引

**新增文件：** `lib/application/providers/app_search_index_provider.dart`

#### 1.1 数据模型

```dart
/// 轻量候选条目，只保留跳转详情页所需的最小字段
class SearchSuggestionEntry {
  const SearchSuggestionEntry({required this.appId, required this.name});

  /// 应用唯一标识，如 "org.example.browser"
  final String appId;

  /// 应用名称，用于候选展示和模糊匹配
  final String name;
}
```

#### 1.2 Provider 设计

```dart
@riverpod
class AppSearchIndex extends _$AppSearchIndex {
  @override
  AsyncValue<List<SearchSuggestionEntry>> build() {
    // 启动时异步加载，不阻塞 UI
    _loadIndex();
    return const AsyncLoading();
  }

  Future<void> _loadIndex() async {
    try {
      final output = await CliExecutor.execute(
        ['search', '.', '--json'],
        timeout: const Duration(seconds: 30),
      );
      if (!output.success) {
        state = const AsyncData([]);
        return;
      }
      final entries = _parseSearchJson(output.stdout);
      state = AsyncData(entries);
    } catch (_) {
      // 加载失败静默回退空列表
      state = const AsyncData([]);
    }
  }

  /// 本地模糊匹配，返回 top N 候选
  List<SearchSuggestionEntry> search(String query, {int maxResults = 8}) {
    // 仅在数据已就绪时匹配
  }
}
```

#### 1.3 JSON 解析

`ll-cli search . --json` 输出格式：

```json
{
  "stable": [
    {
      "id": "org.example.browser",
      "name": "浏览器",
      "arch": ["x86_64"],
      "version": "1.0.0",
      ...
    }
  ]
}
```

解析策略：
- 遍历所有 channel（`stable` 等）
- 去重：同一 `id` 只保留第一条（不同 arch 的同应用会重复）
- 只提取 `id` + `name`

#### 1.4 匹配算法

```
输入 query → 转小写
遍历 entries → name.toLowerCase().contains(query)
按以下优先级排序：
  1. name 以 query 开头 → 前缀匹配优先
  2. name 包含 query → 按出现位置排序
  3. 其余按 name 字母序
取 top 8
```

#### 1.5 防抖策略

因为匹配在纯内存中执行，防抖从 300ms 降为 **100ms**。用户连续快速输入时，100ms 内的中间状态不会触发匹配和重建，但响应又足够快。

### 二、候选状态 Provider 重构

**修改文件：** `lib/application/providers/title_search_suggestions_provider.dart`

原有的 `TitleSearchSuggestionsProvider` 改为消费本地索引，不再调用后端 API：

```dart
@riverpod
class TitleSearchSuggestions extends _$TitleSearchSuggestions {
  @override
  TitleSearchSuggestionsState build() {
    return const TitleSearchSuggestionsState();
  }

  void updateQuery(String query) {
    final index = ref.read(appSearchIndexProvider);
    final entries = index.valueOrNull ?? [];
    if (query.trim().isEmpty) {
      state = const TitleSearchSuggestionsState();
      return;
    }
    // 纯内存匹配，无 async
    final results = _matchEntries(entries, query.trim());
    state = TitleSearchSuggestionsState(items: results);
  }

  void clear() {
    state = const TitleSearchSuggestionsState();
  }
}
```

关键变化：
- `loadSuggestions` 从 `Future<void>` 变为同步 `void updateQuery`
- 不再调用 `appApiServiceProvider`
- 候选条目从 `RecommendAppInfo` 改为 `SearchSuggestionEntry`（更轻量）

### 三、前端交互增强

**修改文件：** `lib/presentation/widgets/title_bar.dart`

#### 3.1 状态扩展

在 `_TitleSearchBoxState` 中新增：

```dart
/// 当前键盘/hover 选中的候选项索引，-1 表示未选中
int _selectedIndex = -1;
```

#### 3.2 键盘导航

在 `TextField` 的 `onKey` 事件中处理：

| 按键 | 行为 |
|------|------|
| `ArrowDown` | `_selectedIndex++`，循环到底部后回到 -1（无选中） |
| `ArrowUp` | `_selectedIndex--`，循环到 -1 后跳到底部 |
| `Enter` | 有选中项（`_selectedIndex >= 0`）→ 跳详情页；无选中项 → 跳搜索结果页 |
| `Escape` | 关闭候选面板，清空选中 |

键盘导航的关键实现：

```dart
// 在 TextField 外层包裹 KeyboardListener
KeyboardListener(
  focusNode: _keyboardFocusNode,
  onKeyEvent: _onKeyEvent,
  child: TextField(...),
)

void _onKeyEvent(KeyEvent event) {
  if (!_shouldShowSuggestions(state)) return;

  final items = state.items;
  if (items.isEmpty) return;

  if (event is KeyDownEvent) {
    final logicalKey = event.logicalKey;
    if (logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1, items.length);
    } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1, items.length);
    } else if (logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < items.length) {
        _openSuggestion(items[_selectedIndex]);
      } else {
        _submitSearch();
      }
    } else if (logicalKey == LogicalKeyboardKey.escape) {
      _closeSuggestions();
    }
  }
}

void _moveSelection(int delta, int itemCount) {
  setState(() {
    _selectedIndex = (_selectedIndex + delta) % (itemCount + 1);
    // -1 在模运算后需要特殊处理
    if (_selectedIndex == itemCount) _selectedIndex = -1;
  });
  _ensureSelectedVisible();
}
```

#### 3.3 自动滚动

当键盘选中项超出视口时，自动滚动到选中项：

```dart
void _ensureSelectedVisible() {
  if (_selectedIndex < 0) return;
  // 通过 ScrollController 控制候选列表滚动
  _scrollController.position.ensureVisible(
    // 选中项的 RenderObject
  );
}
```

#### 3.4 鼠标 hover 高亮

每个候选项用 `InkWell` 或 `MouseRegion` 包裹：

```dart
Widget _buildSuggestionItem(
  BuildContext context,
  SearchSuggestionEntry entry,
  int index,
) {
  final isSelected = index == _selectedIndex;

  return MouseRegion(
    onEnter: (_) => setState(() => _selectedIndex = index),
    onExit: (_) {
      // 仅在鼠标离开且不是键盘选中时重置
      // 如果鼠标离开到面板外，不重置，保持键盘选中态
    },
    child: GestureDetector(
      onTap: () => _openSuggestion(entry),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.appColors.primaryLight : Colors.transparent,
          borderRadius: AppRadius.smRadius,
        ),
        child: Row(
          children: [
            // 应用名称
            Expanded(
              child: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.bodyMedium.copyWith(
                  color: isSelected
                    ? AppColors.primary
                    : context.appColors.textPrimary,
                ),
              ),
            ),
            // 选中时显示箭头指示器
            if (isSelected)
              Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}
```

#### 3.5 视觉规格

| 属性 | 值 | 说明 |
|------|----|------|
| 面板宽度 | 与搜索框对齐（~534px） | 现有行为不变 |
| 面板最大高度 | 240px | 约 8 项 × 30px |
| 面板圆角 | `AppRadius.mdRadius` | 与现有一致 |
| 面板阴影 | `Colors.black.withAlpha(20)`, blurRadius 12, offset (0, 4) | 现有不变 |
| 面板背景 | `surface` | 跟随主题 |
| 面板边框 | `borderSecondary` 1px | 现有不变 |
| 项高度 | ~30px（padding 8 + text 14 + padding 8） | 紧凑舒适 |
| 项间距 | 2px（项间 gap） | 替代 divider，更现代 |
| 未选中态文字 | `textPrimary` | 常规文字色 |
| 未选中态背景 | 透明 | 无背景 |
| hover/选中态文字 | `AppColors.primary`（#016FFD） | 品牌蓝 |
| hover/选中态背景 | `primaryLight`（#E6F0FF） | 浅蓝底 |
| 选中态右侧图标 | `Icons.arrow_forward` 14px | 蓝色小箭头 |
| 鼠标光标 | `SystemMouseCursors.click` | 手型指针 |
| 首次加载中 | 不显示面板 | 无候选项 = 不弹面板 |
| 索引加载失败 | 不显示面板 | 静默降级 |

#### 3.6 hover 和键盘选中的联动规则

1. 鼠标移入候选项 → `_selectedIndex = 该项索引` → 高亮
2. 鼠标移出面板 → `_selectedIndex` 保持不变（不清除）→ 保持高亮
3. 键盘 ↑↓ → `_selectedIndex` 更新 → 高亮跳转，自动滚动
4. 鼠标 hover 和键盘选中共享同一个 `_selectedIndex`，不会冲突

#### 3.7 面板打开/关闭时机

| 触发 | 行为 |
|------|------|
| 搜索框获得焦点 + 有输入 + 有候选 | 打开面板 |
| 输入为空 | 关闭面板 |
| 点击候选 | 跳转详情 + 关闭面板 + 取消焦点 |
| Enter（有选中） | 跳转详情 + 关闭面板 + 取消焦点 |
| Enter（无选中） | 跳转搜索页 + 关闭面板 + 取消焦点 |
| Escape | 关闭面板 + 清空选中（保留输入） |
| 搜索框失去焦点 | 延迟 200ms 关闭（给点击留窗口） |
| 点击面板外区域 | 关闭面板 |

#### 3.8 候选列表布局改进

将现有的 `ListView.separated` + `Divider` 替换为：

```dart
ListView.builder(
  padding: const EdgeInsets.all(6),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return _buildSuggestionItem(context, items[index], index);
  },
)
```

- 移除 `separatorBuilder` + `Divider`，改用紧凑间距
- 项之间留 2px 自然间隔
- 整体更现代、更紧凑

### 四、跳转详情页适配

当前 `_openSuggestion` 接收 `RecommendAppInfo` 并调用 `app.toInstalledApp()` 转换后跳转。切换为 `SearchSuggestionEntry` 后：

```dart
void _openSuggestion(SearchSuggestionEntry entry) {
  _closeSuggestions();
  _focusNode.unfocus();
  // 直接用 appId 跳转，详情页自己会拉取完整信息
  context.goToAppDetail(entry.appId);
}
```

详情页路由 `goToAppDetail` 已支持仅传 `appId` 的模式（内部会触发 `loadDetail` 拉取完整信息），因此无需额外适配。

### 五、启动流程集成

在 `main.dart` 的启动链中，`appSearchIndexProvider` 会在首次被 watch 时自动触发 `_loadIndex()`。无需在 `main()` 中手动调用。

加载时机：
1. 用户首次点击搜索框或开始输入 → provider 被 watch → 触发加载
2. 后续输入直接使用已加载的索引
3. 加载期间（首次）不显示候选面板（因为 `state = AsyncLoading`）

可选优化：在首页渲染完成后预触发 provider 初始化，避免用户首次输入时等待。

---

## 影响范围

### 直接修改

| 文件 | 变更 |
|------|------|
| `lib/application/providers/app_search_index_provider.dart` | **新增** - ll-cli 搜索索引 provider |
| `lib/application/providers/title_search_suggestions_provider.dart` | **重构** - 改为消费本地索引 |
| `lib/presentation/widgets/title_bar.dart` | **增强** - hover、键盘、跳转交互 |
| `test/unit/application/providers/app_search_index_provider_test.dart` | **新增** |
| `test/unit/application/providers/title_search_suggestions_provider_test.dart` | **修改** |
| `test/widget/presentation/widgets/title_bar_search_test.dart` | **修改** |

### 删除

| 文件 | 说明 |
|------|------|
| `lib/application/providers/title_search_suggestions_provider.dart` 中对 `appApiServiceProvider` 的依赖 | 候选不再调后端 API |

### 不受影响

- 搜索结果页（仍走后端接口）
- 后端代码（无需改动）
- 其他页面和组件

---

## 风险与缓解

### 风险 1：ll-cli search . --json 执行缓慢

**缓解：** 设置 30s 超时；加载失败静默降级为空候选；不影响正常搜索结果页。

### 风险 2：ll-cli 未安装

**缓解：** `CliExecutor` 会抛出 `ProcessException`，被 catch 静默处理，候选面板不显示。

### 风险 3：JSON 格式变化

**缓解：** 解析代码对缺失字段做 null 安全处理；解析失败静默降级。

### 风险 4：内存占用

**缓解：** 7604 条 × (id + name) ≈ 200KB，完全可接受。

### 风险 5：数据不够新

**缓解：** 候选只用于快速导航，精确搜索仍走后端；用户安装/卸载新应用后重启商店即可刷新索引。

---

## 测试策略

### 单元测试

1. `app_search_index_provider_test.dart`：
   - JSON 解析正确提取 id + name
   - 同一 id 去重
   - 空输入返回空候选
   - 前缀匹配优先排序
   - 匹配结果不超过 maxResults
   - 加载失败回退空列表

2. `title_search_suggestions_provider_test.dart`：
   - updateQuery 同步更新候选
   - clear 清空候选

### Widget 测试

3. `title_bar_search_test.dart`：
   - 输入后显示候选名称
   - hover 候选项高亮
   - 键盘 ↓ 选中下一项
   - 键盘 ↑ 选中上一项
   - Enter（有选中）跳详情页
   - Enter（无选中）跳搜索页
   - 点击候选跳详情页
   - Escape 关闭面板
   - 清空输入后面板消失

---

## 预期结果

完成后标题栏搜索候选将提供：

1. **极快响应**：端到端延迟 < 100ms（100ms 防抖 + <1ms 内存匹配）
2. **完整交互**：hover 高亮、键盘导航、回车/点击跳转、Escape 关闭
3. **视觉精致**：品牌色选中态、紧凑间距、手型指针、箭头指示器
4. **健壮降级**：ll-cli 不可用时不显示候选，不影响其他功能
