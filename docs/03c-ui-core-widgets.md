# UI 设计规范 — 第三章：核心组件

> 文档版本: 1.0 | 创建日期: 2026-03-15

---

## 一、ApplicationCard（应用卡片）

### 1.1 整体尺寸

```
┌──────────────────────────────────────┐
│  ┌──────┐  名称                       │
│  │  图标  │  描述信息（单行截断） [按钮]  │
│  │ 64×64 │  4.5 ★★★★☆ (122)       │
│  └──────┘                            │
└──────────────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 最小宽度 | 18rem = 288px |
| 高度 | 7.5rem = 120px |
| 内边距 | 0.5rem 1rem = 8px 16px |
| 圆角 | 0.5rem = 8px |
| 背景色 | `#F6F6F6`（固定值，非 token） |
| Hover 效果 | `translateY(-2px)`，0.3s ease |
| 布局 | `Row: [icon, Expanded(Column), button]` |
| 点击 | 导航到 `/app_detail/:appId` |
| 鼠标 | `cursor: pointer` |

### 1.2 图标区域

| 属性 | 值 |
|------|-----|
| 尺寸 | 4rem × 4rem = 64×64px |
| 圆角 | 0.375rem = 6px |
| 右侧间距 | 0.75rem = 12px |
| 默认图标 | `assets/icons/default-icon.svg` |
| 加载失败 | 显示默认图标 |

图标来源优先级：
1. `appInfo.icon`（远程 URL）
2. 构建时内置的 category 默认图标
3. 全局默认 SVG 图标

### 1.3 信息区域

| 元素 | 字号 | 颜色 | 行为 |
|------|------|------|------|
| 名称 | 0.875rem=14px, w500 | `onSurface` | 单行截断 ellipsis |
| 描述 | 0.75rem=12px | `onSurfaceVariant` | 单行截断 ellipsis |
| 评分 | 0.75rem=12px | `secondary` | 星 + 评分 + (评论数) |

评分组件：
- 使用 Rate 组件（Flutter: `RatingBar`）
- 只读，`disabled: true`
- 可小数 `allowHalf: true`
- 字号 0.75rem
- 评分数字 + 括号中评论数

### 1.4 操作按钮

卡片右侧显示一个操作按钮，根据应用状态显示不同内容：

| 状态 | 按钮文字 | 按钮类型 | 操作 |
|------|---------|---------|------|
| 未安装 | "安装" | `primary round small` | 加入安装队列 |
| 已安装/无更新 | "打开" | `default round small` | `runApp(appId, version)` |
| 已安装/有更新 | "更新" | `primary round small` | 加入安装队列(升级) |
| 安装中/更新中 | 进度环 | — | 显示 `CircularProgress` |

按钮尺寸：
| 属性 | 值 |
|------|-----|
| 宽度 | 4.25rem = 68px |
| 高度 | Ant `small` ≈ 24px |
| 圆角 | round = 全圆 |
| 字号 | 12px |

进度环规格：
| 属性 | 值 |
|------|-----|
| 直径 | 32px |
| 线宽 | 6px (strokeWidth) |
| 颜色 | `primary` |
| 内部文字 | 百分比数字，10px |

### 1.5 连接卡片组件（ConnectedApplicationCard）

这是对 `ApplicationCard` 的增强包装，负责注入以下数据：

```dart
// 由页面级 hook 预先计算好，通过 props 传入
class ConnectedCardProps {
  final AppInfo appInfo;
  final bool isInstalled;
  final bool hasUpdate;
  final bool isInstalling;
  final double? installProgress;
}
```

> **性能约束**：卡片禁止直接订阅全局 store。页面负责从 `installedAppsStore`、`updateAppsStore`、`installQueueStore` 提取索引数据，作为轻量 `props` 传入。

---

## 二、ApplicationCardSkeleton（骨架屏卡片）

### 2.1 布局

与 `ApplicationCard` 完全相同的外形尺寸，内部替换为灰色脉冲块。

```
┌──────────────────────────────────────┐
│  ┌──────┐  ███████████               │
│  │ ████ │  ████████████████   ████   │
│  │ ████ │  ██████                    │
│  └──────┘                            │
└──────────────────────────────────────┘
```

### 2.2 骨架元素

| 元素 | 尺寸 | 圆角 |
|------|------|------|
| 图标占位 | 64×64px | 6px |
| 名称占位 | 宽60%, 高14px | 4px |
| 描述占位 | 宽80%, 高12px | 4px |
| 评分占位 | 宽40%, 高12px | 4px |
| 按钮占位 | 68×24px | 12px |

### 2.3 Shimmer 动画

```dart
// 使用 shimmer 包或自定义
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  period: Duration(milliseconds: 1500),
  child: skeletonLayout,
)
```

动画：从左到右的渐变流光效果，周期 1.5s，无限循环。

### 2.4 使用场景

| 场景 | 骨架屏数量 |
|------|----------|
| 首次加载（无缓存） | 填满一屏(通常 8-12 个) |
| 分页追加 | 不使用骨架屏，底部 "加载中..." |
| 筛选/搜索切换 | 如有缓存则直接显示，否则骨架屏 |

---

## 三、ApplicationCarousel（应用轮播）

### 3.1 结构

```
┌─────────────────────────────────────────────┐
│  ┌─────背景 SVG 区域─────────────────────┐  │
│  │                                       │  │
│  │    ┌──────────────────────┐           │  │
│  │    │  [icon 128]  名称     │           │  │
│  │    │             描述      │           │  │
│  │    │             [按钮]    │           │  │
│  │    └──────────────────────┘           │  │
│  │                                       │  │
│  │    ○ ○ ● ○ ○   ← 指示器               │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 3.2 容器属性

| 属性 | 值 |
|------|-----|
| 外层 padding | 2rem = 32px |
| 背景 | SVG 图案（自定义 CarouselBackground） |
| 轮播项宽度 | 父容器 64% |
| 切换效果 | fade（Ant `effect="fade"`） |
| 自动播放 | `autoplay: true, autoplaySpeed: 5000` |
| 分页器 | 底部圆点 |

### 3.3 轮播项

| 元素 | 属性 |
|------|------|
| 图标 | 8rem × 8rem = 128×128px, 圆角 12px |
| 名称 | 字号 1.25rem=20px, w600, 白色 |
| 描述 | 字号 0.875rem=14px, 白色70%透明度, 两行截断 |
| 安装按钮 | 与 ApplicationCard 按钮一致 |
| 布局 | Row: [icon 128, gap 24, Column(name, desc, btn)] |

### 3.4 背景 SVG（CarouselBackground）

自定义 SVG 背景图案，渲染为轮播区域的底图。

Flutter 实现：
```dart
CustomPaint(
  painter: CarouselBackgroundPainter(),
  child: carouselContent,
)
```

```dart
// 或直接使用 SvgPicture
SvgPicture.asset('assets/images/carousel_bg.svg', fit: BoxFit.cover)
```

---

## 四、DownloadProgress（下载管理）

### 4.1 整体布局

弹窗由 Sidebar 底部下载图标触发。

```
┌─────────────────────────────────┐
│  下载管理                   × │  ← Modal 标题
├─────────────────────────────────┤
│  [等待中]  [下载中]  [已完成]    │  ← Tab 切换
├─────────────────────────────────┤
│                                 │
│  列表区域  (scrollable)          │
│  ┌─[ icon ] AppName ── [操作]─┐ │
│  │         版本号  状态        │ │
│  └────────────────────────────┘ │
│  ┌─[ icon ] AppName ── [操作]─┐ │
│  │         版本号  状态        │ │
│  └────────────────────────────┘ │
│                                 │
│   (空态: "暂无数据")             │
└─────────────────────────────────┘
```

### 4.2 弹窗属性

| 属性 | 值 |
|------|-----|
| 宽度 | 400px |
| 列表高度 | 18.75rem = 300px |
| 位置 | `centered` |
| Modal 阴影 | 全局统一覆盖 |

### 4.3 Tab 切换

三个 Tab：等待中、下载中、已完成

```dart
TabBar(
  tabs: [
    Tab(text: '等待中 (${waitingCount})'),
    Tab(text: '下载中 (${downloadingCount})'),
    Tab(text: '已完成 (${completedCount})'),
  ],
)
```

### 4.4 列表项

| 元素 | 属性 |
|------|------|
| 图标 | 2.5rem × 2.5rem = 40×40px |
| 名称 | 14px, w500 |
| 版本号 | 12px, secondary |
| 进度 | CircularProgress 32×32px, strokeWidth 6 |
| 操作按钮 | 取消/重试/删除 |

#### 等待中列表项

```
[icon 40]  AppName v1.0.0              [取消]
           等待安装...
```

#### 下载中列表项

```
[icon 40]  AppName v1.0.0          [进度环 32]
           正在下载... 35%      1.2 MB/s
```

#### 已完成列表项

```
[icon 40]  AppName v1.0.0              [打开]
           安装完成 ✓
```

---

## 五、SpeedTool（网络速度工具）

### 5.1 位置与用途

固定在标题栏或状态区域,  展示实时上传/下载速度。

### 5.2 样式

```
┌──────────────────────┐
│  ↑ 0.5 MB/s          │
│  ↓ 2.3 MB/s          │
└──────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 字号 | 0.75rem = 12px |
| 颜色 | `onSurfaceVariant` |
| 上传图标 | ↑ (ArrowUp) |
| 下载图标 | ↓ (ArrowDown) |
| 更新频率 | 1s（Rust 端通过 `/proc/net/dev` 读取） |
| 格式 | 自动单位：B/s → KB/s → MB/s → GB/s |

---

## 六、全局 Modal 样式规范

### 6.1 统一阴影

所有 Modal (包括 `Modal` 和 `Modal.confirm`) 的 `.ant-modal-content` 统一覆盖：

```dart
// Flutter Dialog 统一样式
showDialog(
  context: context,
  builder: (context) => Dialog(
    elevation: 4,                    // 低阴影
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: Colors.black.withOpacity(0.06),
        width: 1,
      ),
    ),
    child: content,
  ),
);
```

| 属性 | 值 |
|------|-----|
| elevation | 4（Material 标准层级） |
| 圆角 | 8px |
| 边框 | 1px `rgba(0,0,0,0.06)` |
| 关闭按钮 | 右上角 × |

### 6.2 确认弹窗（Confirm Dialog）

用于卸载确认、关闭确认等场景。

```
┌─────────────────────────────────┐
│   确认卸载                   ×  │
│                                 │
│   确定要卸载 AppName 吗？        │
│                                 │
│            [取消]  [确定]        │
└─────────────────────────────────┘
```

Flutter 实现统一封装为 `AppConfirmDialog`：
```dart
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? confirmText,
  String? cancelText,
  bool isDanger = false,
});
```

---

## 七、Empty 状态

### 7.1 空数据展示

当列表无数据时，显示 Ant Design 标准 Empty 组件。

| 属性 | 值 |
|------|-----|
| 图片 | `Empty.PRESENTED_IMAGE_SIMPLE`（简洁灰色线条） |
| 文案 | "暂无数据" |
| 位置 | 列表区域居中 |

Flutter 实现：
```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset('assets/images/empty.svg', width: 120),
      SizedBox(height: 8),
      Text('暂无数据', style: TextStyle(color: onSurfaceVariant, fontSize: 14)),
    ],
  ),
)
```

---

## 八、InstallButton（安装按钮）

### 8.1 概述

`InstallButton` 是一个通用的安装状态按钮组件，根据 `InstallButtonState` 枚举值渲染不同的按钮样式。该组件被设计为**自包含**，调用方只需传入状态和回调，无需关心内部渲染细节。

**核心设计原则**：
- 组件根据 `InstallStatus` 决定显示内容，实现 UI 与业务逻辑解耦
- 任何页面（更新页、详情页、列表页）都可以复用同一组件
- 支持**悬停交互**：`pending` 状态下悬停可切换为"取消安装"

### 8.2 状态枚举

```dart
enum InstallButtonState {
  notInstalled,  // 未安装
  installing,    // 安装中
  pending,       // 等待安装（排队中）
  installed,     // 已安装
  update,        // 需要更新
  open,          // 打开应用
  uninstall,     // 卸载
}
```

### 8.3 各状态渲染

| 状态 | 按钮样式 | 文案 | 图标 | 交互 |
|------|---------|------|------|------|
| `notInstalled` | 主色实心按钮 | "安 装" | `Icons.download` | 点击触发 `onPressed` |
| `installing` | 进度条样式 | "xx% · 网速" | — | 显示进度，可取消 |
| `pending` | 禁用态容器 | "等待安装" | 转圈图标 | 悬停切换为"取消安装" |
| `installed` | 描边按钮 | "打 开" | `Icons.open_in_new` | 点击触发 `onPressed` |
| `update` | 主色实心按钮 | "更 新" | `Icons.update` | 点击触发 `onPressed` |
| `open` | 描边按钮 | "打 开" | `Icons.open_in_new` | 点击触发 `onPressed` |
| `uninstall` | 红色描边按钮 | "卸 载" | `Icons.delete_outline` | 点击触发 `onPressed` |

### 8.4 pending 状态详解

**问题背景**：
系统采用**严格串行安装**机制，同一时刻只允许一个安装任务执行。当用户点击"一键更新"时，所有应用被批量入队，状态为 `InstallStatus.pending`。

**解决方案**：
- `pending` 状态显示为独立的"等待安装"样式
- 鼠标悬停时切换为"取消安装"（红色），允许用户从队列中移除
- 组件内部使用 `StatefulWidget` 维护悬停状态

**悬停交互实现**：

```dart
Widget _buildPendingButton(BuildContext context) {
  // 默认：转圈 + "等待安装"
  // 悬停：关闭图标 + "取消安装"（红色）
  return MouseRegion(
    onEnter: (_) => setState(() => _isHovering = true),
    onExit: (_) => setState(() => _isHovering = false),
    cursor: widget.onCancel != null ? SystemMouseCursors.click : MouseCursor.defer,
    child: GestureDetector(
      onTap: isHovering ? widget.onCancel : null,
      child: AnimatedContainer(
        // 动画过渡
      ),
    ),
  );
}
```

**视觉规格**：

| 属性 | 默认态 | 悬停态 |
|------|--------|--------|
| 背景 | `surfaceContainerHighest` | `errorContainer` (30%透明) |
| 边框 | `outlineVariant` | `error` (50%透明) |
| 图标 | 转圈 `CircularProgressIndicator` | `Icons.close` |
| 文字 | "等待安装", `onSurfaceVariant` | "取消安装", `error` |
| 光标 | `defer` | `click` |

### 8.5 installing 状态详解

**进度显示**：
- 使用 `LinearProgressIndicator` 显示安装进度
- 进度值由 `progress` 参数传入（0.0 - 1.0）
- 显示格式：`75%` 或 `75% · 2.5 MB/s`

**网速来源**：
- 网速由 `networkSpeedProvider` 提供
- 该 Provider 通过读取 `/proc/net/dev` 计算全局网络速度
- **只有 `installing` 状态才显示网速**，`pending` 状态不显示

**网速显示条件**：
```dart
downloadSpeed: buttonState == InstallButtonState.installing
    ? ref.watch(networkSpeedProvider).formatted
    : null,
```

### 8.6 按钮尺寸

```dart
enum ButtonSize { small, medium, large }
```

| 尺寸 | 高度 | 图标 | 水平内边距 |
|------|------|------|-----------|
| `small` | 28px | 14px | 12px |
| `medium` | 32px | 16px | 16px |
| `large` | 40px | 18px | 20px |

### 8.7 组件 API

```dart
class InstallButton extends StatefulWidget {
  /// 按钮状态
  final InstallButtonState state;

  /// 安装进度 (0.0 - 1.0)
  final double progress;

  /// 按钮点击回调
  final VoidCallback? onPressed;

  /// 取消安装回调（用于 pending 和 installing 状态）
  final VoidCallback? onCancel;

  /// 下载速度文本（如 "2.5 MB/s"）
  final String? downloadSpeed;

  /// 是否禁用
  final bool disabled;

  /// 按钮大小
  final ButtonSize size;
}
```

### 8.8 使用示例

**更新页面中使用**：

```dart
InstallButton(
  state: _getButtonState(),  // 根据 InstallTask 状态映射
  progress: installTask?.progress ?? 0.0,
  downloadSpeed: buttonState == InstallButtonState.installing
      ? ref.watch(networkSpeedProvider).formatted
      : null,
  onPressed: onUpdate,
  onCancel: onCancel,
  size: ButtonSize.small,
);
```

**状态映射示例**：

```dart
InstallButtonState _getButtonState() {
  if (installTask != null) {
    switch (installTask!.status) {
      case InstallStatus.pending:
        return InstallButtonState.pending;
      case InstallStatus.downloading:
      case InstallStatus.installing:
        return InstallButtonState.installing;
      case InstallStatus.success:
      case InstallStatus.failed:
      case InstallStatus.cancelled:
        break;
    }
  }
  return InstallButtonState.update;
}
```

### 8.9 相关文件

| 文件 | 说明 |
|------|------|
| `lib/presentation/widgets/install_button.dart` | 组件实现 |
| `lib/presentation/pages/update_app/update_app_page.dart` | 更新页面使用示例 |
| `test/widget/widgets/install_button_test.dart` | 单元测试（24 个测试用例） |
| `test/widget/presentation/pages/update_app/update_app_page_test.dart` | 更新页面测试 |

### 8.10 设计决策记录

**为什么 pending 和 installing 是两个独立状态？**

1. **语义清晰**：`pending` 表示"在队列中等待"，`installing` 表示"正在执行"
2. **UI 区分**：用户需要知道哪些应用"正在下载"（显示进度），哪些"排队等待"
3. **交互不同**：`installing` 显示进度条，`pending` 显示转圈并支持悬停取消
4. **网速显示**：只有当前执行的任务才显示网速，避免所有按钮都显示相同的全局网速

**为什么使用 StatefulWidget？**

为了支持悬停交互，组件需要维护 `_isHovering` 状态。如果使用 `StatelessWidget`，需要在父组件管理悬停状态，增加了耦合度。使用 `StatefulWidget` 使组件自包含，复用更简单。
