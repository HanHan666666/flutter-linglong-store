# UI 设计规范 — 第二章：布局组件

> 文档版本: 1.0 | 创建日期: 2026-03-15

---

## 一、标题栏（TitleBar）

### 1.1 结构与尺寸

```
┌──────────────────────────────────────────────────────────────┐
│ [Logo] AppName          [    搜索框    🔍]       ─  □  ✕    │
└──────────────────────────────────────────────────────────────┘
```

| 属性 | 值 | Flutter |
|------|-----|---------|
| 总高度 | 3.6rem = 57.6px | `PreferredSize(preferredSize: Size.fromHeight(57.6))` |
| 左侧内容内边距 | 0 1rem = 0 16px | 左侧 Logo/标题/搜索区保留 `16px` 起始边距 |
| 右侧窗口控制区 | 贴齐窗口右边缘 | 不额外保留右侧容器留白，保持桌面端系统按钮观感 |
| 背景色 | 透明（继承布局背景） | 无 |
| 可拖拽 | 整个区域 | `GestureDetector` + `windowManager.startDragging()` |

### 1.2 左侧区域

| 元素 | 尺寸 | 属性 |
|------|------|------|
| Logo 图片 | 32×32px (2rem) | `Image.asset('assets/icons/logo.svg')` |
| 应用名文字 | 字号 14px (0.875rem) | 普通权重，紧跟 Logo |
| 间距 | 0.5rem = 8px | `gap: 8` |

### 1.3 搜索框

| 属性 | 值 |
|------|-----|
| 宽度 | 父容器 50%，最大 534px |
| 高度 | 2rem = 32px |
| 圆角 | 1rem = 16px（胶囊形） |
| 默认背景 | `--ant-color-border-bg` → `surfaceContainerLow` |
| 默认边框 | `1px solid borderSecondary` |
| Focus 背景 | `--ant-color-bg-container` → `surface` |
| Focus 边框 | `--ant-color-primary` = `#016FFD` |
| 图标区 | 左侧，宽 3rem=48px，高 1.5rem=24px，margin-left 0.5rem |
| 输入字号 | 0.75rem = 12px |
| 占位符 | "在这里搜索你想搜索的应用" |
| 交互 | Enter → 跳转搜索页；无内容时不跳转；Delete 键清空 |

### 1.4 右侧窗口控制

| 按钮 | 图标 | 尺寸 | 操作 |
|------|------|------|------|
| 最小化 | Minus (线性) | 18px | `windowManager.minimize()` |
| 最大化/还原 | Square(未最大化) / Copy(已最大化) | 18px | `windowManager.maximize()` / `windowManager.unmaximize()` |
| 关闭 | Close (线性) | 18px | 检查安装队列 → 有任务弹确认 → `windowManager.close()` |

补充约定：
- 窗口控制按钮组独立于左侧内容区布局，整体贴齐窗口右边缘，避免关闭按钮右侧出现额外留白。
- 单个按钮点击热区保持完整矩形，不为了贴边而缩小 hover/点击范围。

```dart
// Flutter 实现参考
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(onPressed: _minimize, icon: Icon(Icons.remove, size: 18)),
    IconButton(onPressed: _toggleMaximize, icon: Icon(isMaximized ? Icons.filter_none : Icons.crop_square, size: 18)),
    IconButton(onPressed: _handleClose, icon: Icon(Icons.close, size: 18)),
  ],
)
```

### 1.5 关闭确认弹窗

触发条件：`installQueueStore.hasActiveTasks()` 为 true（队列有正在进行或等待的任务）

弹窗内容：
- 标题：无
- 内容文字：`t('layout.closeConfirmMessage')` — "正在安装应用，关闭窗口将中断安装过程。确定要关闭吗？"
- 确认按钮：关闭并退出
- 取消按钮：取消

---

## 二、侧边栏（Sidebar）

### 2.1 整体结构

```
┌──────────┐
│ 推 荐 ✓  │ ← 菜单区（上方，可滚动）
│ 分 类    │
│ 排 行    │
│ ──────── │ ← 动态分隔符
│ 办 公    │ ← 自定义菜单（服务端配置）
│ 系 统    │
│ 开 发    │
│ 娱 乐    │
│          │
│----------|
│   📦   📥   ⚙   │ ← 展开态底部横排按钮
└──────────┘
```

### 2.2 容器属性

| 属性 | 值 |
|------|-----|
| 宽度 | 10rem = 160px |
| 响应式宽度 (≤768px) | 3.5rem = 56px |
| 过渡动画 | `all 0.2s ease-in-out` |
| 内边距 | 0.5rem = 8px |
| 布局 | flex column, `justify-content: space-between` |
| 背景 | 继承布局背景色 |

### 2.3 菜单项

| 属性 | 值 |
|------|-----|
| 高度 | 2.25rem = 36px |
| 水平内边距 | 0.75rem = 12px |
| 图文间距 | 0.5rem = 8px |
| 项间距 | 0.25rem = 4px |
| 圆角 | 0.25rem = 4px |

#### 状态样式

| 状态 | 背景 | 文字颜色 | 字重 |
|------|------|---------|------|
| 默认 | 透明 | `onSurface` | 400 |
| Hover | `::before` 伪元素 → `fillSecondary`，opacity 0→1 | 不变 | 不变 |
| 激活 | `primaryBgHover` | `primaryText` | 500 |

Hover 效果通过 `::before` 伪元素实现毛玻璃背景动画（opacity 过渡 0.2s ease-in-out）。

Flutter 实现：
```dart
InkWell(
  borderRadius: BorderRadius.circular(4),
  hoverColor: theme.colorScheme.surfaceContainerHigh,
  child: Container(
    height: 36,
    padding: EdgeInsets.symmetric(horizontal: 12),
    decoration: isActive ? BoxDecoration(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(4),
    ) : null,
    child: Row(
      children: [
        icon, SizedBox(width: 8), text,
      ],
    ),
  ),
)
```

#### 菜单文字样式

| 属性 | 值 |
|------|-----|
| 字号 | 0.875rem = 14px |
| 字间距 | `letter-spacing: 0.5rem = 8px` |
| 响应式 (≤768px) | `opacity: 0`（隐藏文字，仅显示图标） |

> ⚠️ **注意**：菜单文字有 8px 的 letter-spacing，这导致 "推 荐"、"分 类" 等文字间有明显间隔，需要在 Flutter 中精确还原。

### 2.4 红点/Badge

| 属性 | 值 |
|------|-----|
| 尺寸 | 1.2rem × 1.2rem = 19.2px |
| 字号 | 0.75rem = 12px |
| 位置 | 菜单项右侧 |
| 数据来源 | `useMenuBadges` → `{ '/update_apps': updateCount }` |

目前仅"更新"菜单有红点，显示可更新应用数量。

### 2.5 静态菜单配置

| 序号 | 文字 | 路径 | 图标 | 可见 |
|------|------|------|------|------|
| 1 | 推 荐 | `/` | 心形线性图标 | ✅ |
| 2 | 排 行 | `/ranking` | 无 | ❌ 隐藏 |
| 3 | 分 类 | `/allapps` | 方格线性图标 | ✅ |

> 当前 Flutter 侧边栏顶部固定静态入口为 `推荐 / 全部 / 排行`，其中 "排行" 菜单配置了但 `isHidden: true` 时可继续隐藏。

### 2.6 动态菜单（自定义分类）

来源：API `getCustomMenuCategory` → `useGlobalStore.customMenuCategory`

每个动态菜单项结构：
```typescript
{
  categoryName: string,   // 显示名
  categoryCode: string,   // 路由参数
  categoryIcon: string,   // 图标 URL
  categoryIds: string[],  // 分类 ID 列表
}
```

路由：`/custom_category/:code`

动态菜单渲染在静态菜单之后，多条时可滚动（隐藏滚动条）。

示例（来自截图）：办公、系统、开发、娱乐

### 2.7 底部固定动作区

```
┌─────────────────────────┐
│   📦   📥   ⚙            │  ← 展开态横排
│   📦                     │
│   📥                     │  ← 折叠态竖排
│   ⚙                      │
└─────────────────────────┘
```

| 条目 | 图标尺寸 | 路径/操作 |
|------|----------|----------|
| 我的应用 | 16px | 导航到 `/my_apps` |
| 下载管理 | 16px | 弹出下载管理 Modal |
| 设置 | 16px | 导航到 `/setting` |

布局：固定在侧边栏底部。展开态使用横向并排图标按钮；自动折叠到紧凑宽度后切换为竖向图标按钮，保证点击热区。

响应式 (≤768px)：改为竖向图标排列，仅保留图标与 tooltip。

**下载管理弹窗**：点击下载图标弹出 `Modal`，宽度 400px，centered，内容为 `DownloadProgress` 组件。

---

## 三、启动页（LaunchPage）

### 3.1 整体布局

```
┌─────────────────────────────────────┐
│                                     │
│          60% 高度 — 主区域           │
│                                     │
│         [Logo SVG]                  │
│      玲珑应用商店社区版              │  ← 2rem, w600
│       正在初始化...                  │  ← 1.25rem, textSecondary
│     ████████████████░░░░░            │  ← Ant Progress
│                                     │
├─────────────────────────────────────┤
│                                     │
│          40% 高度 — 底部说明         │
│                                     │
│   注意：                             │  ← 0.875rem, textTertiary
│   1. 当运行程序时...                 │
│   2. 点击安装时...                   │
│   3. 执行操作时...                   │
│   4. 如出现特殊现象...              │
│                                     │
│         [LinglongEnvDialog]          │  ← 条件渲染
└─────────────────────────────────────┘
```

### 3.2 主区域样式

| 元素 | 属性 |
|------|------|
| 容器 | 宽 100vw, 高 100% |
| 主区域 | 高 60%, flex column 居中 |
| 应用名 | `font-weight: 600, font-size: 2rem = 32px, color: --ant-color-text` |
| 步骤文字 | `font-size: 1.25rem = 20px, color: --ant-color-text-secondary` |
| 进度条 | 水平 padding `0 4rem = 0 64px`，使用标准 LinearProgressIndicator |
| 底部区域 | 高 40%, padding `0 4rem` |
| 注意文字 | `font-size: 0.875rem = 14px, color: --ant-color-text-tertiary, line-height: 1.5rem` |

### 3.3 初始化步骤文案

| 步骤 | 文案 | 进度范围 |
|------|------|---------|
| 1 | "正在获取系统信息..." | 0~15% |
| 2 | "正在获取已安装应用列表..." | 15~40% |
| 3 | "正在检查已安装应用更新情况..." | 40~70% |
| 4 | "正在恢复未完成的安装任务..." | 70~85% |
| 5 | "正在初始化统计服务..." | 85~100% |

### 3.4 环境检测弹窗（LinglongEnvDialog）

触发条件：`envChecked === true && envReady === false`

弹窗样式：
- Ant Design `Modal`
- `centered: true`
- `closable: false`（不可关闭）
- `maskClosable: false`（点外部不关闭）

弹窗内容：

```
┌────────────────────────────────────────────┐
│ 检测到当前系统缺少玲珑环境                    │  ← 标题行
│                                            │
│ ⚠️ 检测到系统中不存在或版本过低的玲珑组件，    │  ← 红色(danger)
│   需先安装后才能使用商店。                    │
│                                            │
│ 检测到系统未安装玲珑环境，请先安装             │
│                                            │
│ 自动安装适配 Deepin 23/25、UOS 1070、       │
│ openEuler 23.09/24.03、Ubuntu 24.04、       │
│ Debian 12/13、openKylin 2.0、Fedora 41/42、 │
│ AnolisOS 8、Arch/Manjaro/Parabola。         │
│                                            │
│ 自动安装完成后，无需重启应用。                 │  ← secondary color
│                                            │
│  [退出商店] [手动安装] [自动安装(primary)] [重新检测(link)] │
└────────────────────────────────────────────┘
```

Flutter 实现要点：
- AlertDialog + 自定义 content
- 4 个按钮横排：`OutlinedButton`、`OutlinedButton`、`ElevatedButton`(primary)、`TextButton`
- "手动安装" → 打开外部链接
- "自动安装" → 获取安装脚本 → `installLinglongEnv(script)`
- "重新检测" → `checkLinglongEnv()` 重新检测

---

## 四、内容区域

### 4.1 基本属性

| 属性 | 值 |
|------|-----|
| 背景色 | `--ant-color-bg-container` → `surface` |
| 溢出 | `overflow: auto` |
| flex | `1`（占满剩余宽度） |
| 左上圆角 | `0.5rem = 8px` |
| 其他圆角 | `0`（贴合窗口边缘） |

### 4.2 页面保活区域

内容区域由 `KeepAliveOutlet` 管理，保活机制：
- 白名单路由缓存：`/`, `/allapps`, `/search_list`, `/ranking`, `/custom_category/*`
- 最多缓存 10 个页面（LRU 淘汰）
- 通过 `display: none/block` 切换（Flutter 中用 `Offstage` 或 `IndexedStack`）
- 每个缓存页注入 `KeepAliveVisibilityContext`（`isVisible`, `pathname`, `isVisibleRef`）
- 隐藏页面必须暂停所有副作用（定时器、滚动监听、ResizeObserver）
