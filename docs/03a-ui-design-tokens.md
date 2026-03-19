# UI 设计规范 — 第一章：设计系统基础

> 文档版本: 1.0 | 创建日期: 2026-03-15  
> 基于 rust-linglong-store v2.1.2 截图和源码逆向整理

---

## 一、设计令牌（Design Tokens）

### 1.1 色彩系统

#### 品牌色

| 令牌名称 | 值 | 用途 |
|----------|------|------|
| `primaryColor` | `#016FFD` | 主色。按钮、链接、激活态、侧边栏选中、indicator 竖条 |
| `primaryBgHover` | Ant Design 算法生成 | 卡片 hover 背景 |
| `primaryBorderHover` | Ant Design 算法生成 | 卡片 hover 边框 |
| `primaryText` | Ant Design 算法生成 | 主色文字（链接、速度数值等） |

> **Flutter 映射**：`ColorScheme.fromSeed(seedColor: Color(0xFF016FFD))`，再提取 `primary`、`primaryContainer`、`onPrimaryContainer` 等值。

#### 功能色

| 令牌名称 | 值 | 用途 |
|----------|------|------|
| `errorColor` | Ant Design `colorError` | 卸载按钮、关闭 hover、取消安装 hover |
| `warningColor` | Ant Design `colorWarning` | 取消下载按钮默认态、Alert warning |
| `successColor` | 无直接硬编码 | 安装进度渐变终点 `#87d068` |
| `infoColor` | Ant Design `colorInfo` | 关于页竖条 indicator |

#### 中性色（硬编码值）

| 令牌名称 | 值 | 用途 |
|----------|------|------|
| `cardBg` | `#F6F6F6` | 应用卡片背景色 |
| `cardBorder` | `#F6F6F6` | 应用卡片默认边框色 |
| `openBtnBg` | `#FFFFFF` | "打开"按钮背景 |
| `openBtnBorder` | `#D8D8D8` | "打开"按钮边框 |
| `openBtnText` | `#2C2C2C` | "打开"按钮文字 |
| `topLabel` | `#CDA354` | "精品/TOP" 标签文字 |
| `titleDark` | `#383838` | 推荐页标题色（非 CSS 变量） |
| `logoBlue` | `#025BFF` | SVG Logo 蓝色方块背景 |

#### 主题级 CSS 变量 → Flutter 令牌对照

| Ant Design CSS 变量 | 用途场景 | Flutter 对应 |
|---------------------|---------|-------------|
| `--ant-color-bg-layout` | 整体布局背景 | `Theme.of(context).colorScheme.surfaceContainerLow` |
| `--ant-color-bg-container` | 主内容区/搜索框背景 | `Theme.of(context).colorScheme.surface` |
| `--ant-color-bg-elevated` | 搜索框 focus 背景 | `Theme.of(context).colorScheme.surfaceContainerHighest` |
| `--ant-color-text` | 主文字 | `Theme.of(context).colorScheme.onSurface` |
| `--ant-color-text-secondary` | 次级文字（描述/图标标签） | `Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65)` |
| `--ant-color-text-tertiary` | 三级文字（版本/注意事项） | `...withOpacity(0.45)` |
| `--ant-color-text-light-solid` | 主色按钮内白字 | `Colors.white` |
| `--ant-color-fill-secondary` | 菜单项 hover 填充 | `Theme.of(context).colorScheme.surfaceContainerHigh` |
| `--ant-color-fill-quaternary` | 骨架屏背景 | `Theme.of(context).colorScheme.surfaceContainerLowest` |
| `--ant-color-border-secondary` | 搜索框边框/骨架屏边框 | `Theme.of(context).dividerColor` |
| `--ant-color-border-bg` | 搜索框默认背景 | `Theme.of(context).colorScheme.outlineVariant` |
| `--ant-color-split` | 下载列表分隔线 | `Theme.of(context).dividerColor` |

### 1.2 字体系统

#### 字体族

```
font-family: Inter, Avenir, Helvetica, Arial, sans-serif
```

Flutter 中使用系统默认字体即可（Linux 下通常为 Noto Sans CJK），如需严格一致可嵌入 Inter 字体。

#### 字号层级（基准 16px = 1rem）

| 层级 | 原值 | px | Flutter TextStyle | 使用场景 |
|------|------|-----|-------------------|---------|
| Display | `2rem` | 32 | `displayLarge` / 自定义 | 启动页应用名 |
| H1 | `1.625rem` | 26 | `headlineLarge` | 详情页应用名 |
| H2 | `1.5rem` | 24 | `headlineMedium` | 详情页 section 标题、关于/更新页标题 |
| H3 | `1.25rem` | 20 | `titleLarge` | 推荐标题、搜索结果标题、启动步骤 |
| Body | `1rem` | 16 | `titleMedium` | 正文、轮播详情、Tab 文字 |
| Caption | `0.875rem` | 14 | `bodyLarge` | 菜单文字、加载提示、说明文字 |
| Small | `0.75rem` | 12 | `bodyMedium` | 描述、搜索输入、速度显示、版本 |
| XSmall | `0.625rem` | 10 | `bodySmall` | 下载状态文字、底栏 |
| Tiny | `10px` | 10 | 自定义 `TextStyle(fontSize: 10)` | "精品/TOP" 标签 |

#### 字重

| 场景 | font-weight | FontWeight |
|------|-------------|------------|
| 标题 (display/h1/h2) | 500~600 | `FontWeight.w500` / `FontWeight.w600` |
| 正文 | 400 | `FontWeight.w400` |
| 菜单激活 | 500 | `FontWeight.w500` |
| 进程表格应用名 | 500 | `FontWeight.w500` |

#### 行高

| 场景 | line-height | Flutter |
|------|-------------|---------|
| 全局默认 | 24px (1.5) | `height: 1.5` |
| 说明文字 | `1.5rem` = 24px | `height: 1.5` |
| 紧凑 | 无特别设定 | 默认 |

### 1.3 间距系统

#### 基础间距（rem 转 px，基准 16px）

| 令牌 | rem | px | 使用场景 |
|------|-----|-----|---------|
| `spacing-xs` | 0.25rem | 4 | 菜单项间距、badge 偏移 |
| `spacing-sm` | 0.5rem | 8 | 内容区内边距、标签间距、搜索框左边距 |
| `spacing-md` | 0.75rem | 12 | Tab间距、速度指标间距、侧边栏菜单项水平内边距 |
| `spacing-lg` | 1rem | 16 | 标题栏左右内边距、卡片网格间距、图标右间距 |
| `spacing-xl` | 1.5rem | 24 | 页面统一内边距（最常用）、轮播下方间距 |
| `spacing-2xl` | 2rem | 32 | 详情页顶部、轮播内边距、底部导航图标尺寸 |
| `spacing-3xl` | 2.625rem | 42 | 详情页水平内边距 |
| `spacing-4xl` | 4rem | 64 | 启动页进度条水平内边距 |

#### 页面级内边距规律

| 页面 | 内边距 | 说明 |
|------|--------|------|
| 推荐 / 排行 / 搜索 / 自定义分类 | `1.5rem` (24px) | 统一 |
| 全部应用 | `1.5rem` (24px) | 统一 |
| 应用详情 | `2rem~2.625rem` | 头部区域更大 |
| 我的应用 / 进程 | `0~1.5rem` | 容器无边距，子组件有 |
| 设置 | `20px` | 使用 px 非 rem |
| 更新 | `1.5rem` (24px) | 统一 |

### 1.4 圆角系统

| 令牌 | 值 | px | 使用场景 |
|------|-----|-----|---------|
| `radius-xs` | 0.25rem | 4 | 菜单项、图标、下载项图标 |
| `radius-sm` | 0.5rem | 8 | 卡片、骨架屏、内容区左上角、详情页图标背景 |
| `radius-md` | 0.75rem | 12 | 截图卡片 |
| `radius-lg` | 1rem | 16 | 搜索框、设置页按钮、浮动更新按钮、TabBar ink-bar |
| `radius-full` | 50% / StadiumBorder | — | 按钮(shape=round)、头像、进度圆环 |

### 1.5 阴影系统

| 场景 | 值 | Flutter |
|------|-----|---------|
| Modal | `0 18px 48px rgba(15, 23, 42, 0.16)` → border: `1px solid rgba(15, 23, 42, 0.08)` | `BoxShadow(color: Color.fromRGBO(15,23,42,0.16), blurRadius: 48, offset: Offset(0,18))` |
| 分类筛选栏 | `0 8px 32px rgba(31,38,135,0.16)` + 毛玻璃 `rgba(255,255,255,0.92)` | `BoxShadow(...)` + `BackdropFilter` |
| 浮动更新按钮 | `0 4px 12px rgba(0,0,0,0.15)` | `BoxShadow(...)` |
| 一般卡片 | 无阴影（elevation: 0） | 无 |

### 1.6 动画系统

| 场景 | 持续时间 | 缓动曲线 | Flutter |
|------|---------|---------|---------|
| 侧边栏宽度切换 | 0.2s | ease-in-out | `Duration(milliseconds: 200)`, `Curves.easeInOut` |
| 菜单项 hover 背景 | 0.2s | ease-in-out | 同上 |
| 卡片透明度过渡 | 0.3s | ease | `Duration(milliseconds: 300)`, `Curves.ease` |
| 分类栏折叠 | 0.2s | linear | `Duration(milliseconds: 200)`, `Curves.linear` |
| Shimmer 滑动 | 1.5s | infinite | `shimmer` 包默认 |
| 截图 shimmer | 1.4s | ease-in-out infinite | 自定义 Animation |
| 轮播自动切换 | Ant Carousel default (~4s) | — | `PageView` + `Timer.periodic` |

### 1.7 图标系统

#### 来源分类

| 来源 | 原项目引用 | Flutter 替代 |
|------|-----------|-------------|
| @ant-design/icons | `CopyOutlined`, `LinkOutlined`, `LoadingOutlined`, `ReloadOutlined`, `CheckCircleOutlined`, `MoreOutlined` | `Icons.copy`, `Icons.link`, `CircularProgressIndicator`, `Icons.refresh`, `Icons.check_circle`, `Icons.more_horiz` 或 [fluentui_system_icons] |
| @icon-park/react | `Close`, `Copy` (窗口), `Minus`, `Square`, `DoubleUp`, `DoubleDown`, `Download`, `Upload` | 自定义 SVG 或 Material Icons 对应 |
| 自定义 SVG | logo.svg, linyaps.svg, carouselBG.svg, my_apps.svg, download.svg, setting.svg, feedback.svg, upgrade.svg | 直接复用 SVG 资源，用 `flutter_svg` 渲染 |

#### 图标尺寸规范

| 场景 | 尺寸 | Flutter |
|------|------|---------|
| 全局 .ant-icon | 1rem = 16px | `size: 16` |
| 窗口控制按钮 | 18px | `size: 18` |
| 速度工具图标 | 16px | `size: 16` |
| 侧边栏菜单图标 | 1rem = 16px | `size: 16` |
| 侧边栏底部动作图标 | 1rem = 16px | `size: 16` |
| 标题栏 logo | 2rem = 32px | `width: 32, height: 32` |
| "更多" 操作 | 默认 | `size: 16` |

---

## 二、窗口规格

### 2.1 窗口配置

| 属性 | 值 |
|------|-----|
| 默认尺寸 | 1200 × 800 |
| 最小尺寸 | 600 × 400 |
| 装饰 | 无系统装饰（自定义标题栏） |
| 标题 | `玲珑应用商店社区版` |
| 居中 | 是 |

### 2.2 整体布局结构

```
┌─────────────────────────────────────────────┐ ← 窗口 (1200×800)
│ ┌─────────────────────────────────────────┐ │
│ │            Title Bar (3.6rem=57.6px)     │ │ ← 固定高度
│ ├───────┬─────────────────────────────────┤ │
│ │       │                                 │ │
│ │ Side  │       Main Content              │ │
│ │ bar   │                                 │ │
│ │       │  height: calc(100vh - 3.6rem)   │ │
│ │ 10rem │  overflow: auto                 │ │
│ │=160px │  左上圆角 0.5rem                │ │
│ │       │                                 │ │
│ │       │                                 │ │
│ ├───────┴─────────────────────────────────┤ │
└─────────────────────────────────────────────┘

响应式 (≤768px): 侧边栏压缩到 3.5rem=56px
```

### 2.3 标题栏详细布局

```
┌──────────────────────────────────────────────────────────┐
│ [Logo 32×32] 玲珑应用商店社区版  [  搜索框 50%宽  🔍 ]   ─ □ ✕ │
│←─ titlebarLeft ─→              ←─ Center ─→        ←Right→│
│   gap:0.5rem                    max:33.4375rem       gap:1rem│
└──────────────────────────────────────────────────────────┘
高度: 3.6rem (57.6px)
内边距: 0 1rem
可拖拽区域: 整个标题栏 (data-tauri-drag-region)
```

**搜索框**：
- 宽度: 50%，最大 33.4375rem (~534px)
- 高度: 2rem (32px)
- 圆角: 1rem (16px) — 胶囊形
- 默认边框: `1px solid borderSecondary`
- Focus 边框: 主色 `#016FFD`
- 左侧搜索图标区: 宽 3rem, 高 1.5rem, margin-left 0.5rem
- 输入字号: 0.75rem (12px)

**窗口控制按钮**：
- 最小化 (Minus icon, size 18)
- 最大化/还原 (Square/Copy icon, size 18, 切换状态)
- 关闭 (Close icon, size 18)
- 间距: gap 1rem
- cursor: pointer

---

## 三、响应式断点

| 断点 | 宽度 | 影响 |
|------|------|------|
| 紧凑模式 | ≤ 768px | 侧边栏压缩到 3.5rem, 菜单文字隐藏(opacity:0), 底部动作区切换为竖排图标 |
| 详情页 | ≤ 768px | 隐藏 `.appDesc`（应用模块信息行） |
| 卡片网格 | 自适应 | `repeat(auto-fill, minmax(18rem, 1fr))` 自动列数 |

---

## 四、文件索引

本 UI 设计规范由以下文件组成：

| 文件 | 内容 |
|------|------|
| `03a-ui-design-tokens.md` (本文件) | 设计令牌、色彩、字体、间距、圆角、阴影、动画、图标、窗口布局 |
| `03b-ui-layout-components.md` | 标题栏、侧边栏、启动页等布局组件详细规范 |
| `03c-ui-core-widgets.md` | ApplicationCard、骨架屏、轮播、下载管理等核心组件详细规范 |
| `03d-ui-pages.md` | 所有 10 个页面的详细 UI 规范 |
