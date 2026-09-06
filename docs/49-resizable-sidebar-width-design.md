# 49 侧边栏可拖拽调宽设计

- 状态：已实现
- 来源：issue #27（Dumitru88888：侧边栏在左侧，应支持拖拽加宽/收窄）
- 关联文档：`03b-ui-layout-components.md`（侧边栏原始规范）、`06-testing-and-performance-spec.md`

## 1. 背景与需求

侧边栏当前宽度完全固定：展开态 176px（`Sidebar.defaultWidth`），窗口宽度
≤768px 时自动折叠为 56px 图标栏。用户无法为更宽的菜单文案、更长的自定义
专题名称预留空间，也无法收窄以换取更大的内容区。issue #27 要求侧边栏支持
拖拽调整宽度（可加宽、可变窄）。

## 2. 目标与非目标

**目标**

1. 侧边栏与内容区之间提供拖拽手柄，宽度可实时跟随指针调整；
2. 宽度跨会话持久化，重启后恢复；
3. 阿拉伯语 RTL 下交互语义正确镜像；
4. 键盘与屏幕阅读器可操作（项目无障碍约定）；
5. 拖拽帧零 IO、子树零重建，满足「绝对高 UI 响应速度」约束。

**非目标**

- 不支持折叠态（56px 图标栏）下的宽度调整——折叠是窗口宽度驱动的
  固定响应式形态，与手动宽度是两套正交语义；
- 不新增设置页入口（拖拽 + 双击重置已覆盖全部需求，避免无诉求的
  设置项膨胀）；
- 不支持把宽度拖入「图标模式」（收窄下限仍保留菜单文字）。

## 3. 方案总览

```
AppShell
 └─ Expanded                       ← 必须以 Expanded 挂载（见 §6 布局约束）
     └─ ResizableSidebar           ← 新组件：宽度协商 + 拖拽手柄
         ├─ SizedBox(width: W)     ← 拖拽帧仅改此紧约束
         │   └─ Sidebar            ← 原组件零改动（紧约束覆盖其内部宽度）
         ├─ _SidebarResizeHandle   ← 8px 热区 + 指示线 + 语义/键盘
         └─ Expanded(child)        ← 内容区（AppShell 注入）
```

宽度状态的唯一事实来源是 Application 层 `sidebarWidthProvider`
（`lib/application/providers/sidebar_width_provider.dart`），与
主题模式、语言等偏好的既有归属方式一致；组件层不直接触碰
SharedPreferences。

### 3.1 宽度策略常量（`SidebarWidthPolicy`）

| 常量 | 值 | 依据 |
|------|----|------|
| `defaultWidth` | 176px | 沿用既有展开态宽度（英文菜单单行） |
| `minWidth` | 120px | 底部三个 32px 图标按钮横排最小可容纳宽度（3×32+8×2=112px），菜单文字进入 ellipsis 但仍可读 |
| `maxWidth` | 400px | 窗口最小宽度 1280px 下内容区仍保留 ≥880px |
| `keyboardStep` | 16px | 方向键 / 无障碍 increase/decrease 单步量（`AppSpacing.lg`） |
| `prefsKey` | `sidebar_expanded_width` | shared_preferences 持久化键 |

### 3.2 两阶段持久化契约

- `previewWidth(w)`：拖拽帧高频调用，只更新内存状态（钳制后），
  **帧内零 IO**；
- `commitWidth()`：拖拽结束调用一次，`unawaited(setDouble)` 落盘，
  失败仅记日志（内存状态仍有效，下次会话回退默认）；
- `resetWidth()`：双击手柄触发，恢复默认并 `remove` 持久化键。

`build()` 同步恢复：SharedPreferences 在 `main` 阶段（`PreferencesService.init`
→ `production_dependency_overrides`）已就绪，读值 + 钳制一次完成，
无异步竞态、不阻塞首帧；读取异常回退默认宽度。

## 4. 性能设计

1. **拖拽帧只改一个紧约束**：`ResizableSidebar` 在拖拽帧内重建时，
   `sidebar` 与 `child` 是构造器传入的既有 widget 实例，Flutter
   `updateChild` 短路，不重 build 侧边栏与内容区子树，仅因宽度变化
   重新排版（该 reflow 是宽度调整的必要代价，无法回避）。
2. **紧约束覆盖内部宽度**：`Sidebar` 内部 `AnimatedContainer` 仍写
   176px，外层 `SizedBox(width: W)` 的紧约束优先级更高，因此
   `Sidebar` 无需感知「可调宽度」特性、保持独立可用。
   `AppAnimation.fast = Duration.zero`（全局零动画模式）下无动画干扰。
3. **帧内零 IO**：持久化只发生在 `onHorizontalDragEnd` 一次。
4. **不引入高频 Provider 广播**：宽度变化只影响挂载它的
   `ResizableSidebar` 一层；`MediaQuery.sizeOf` 仅在窗口尺寸变化时触发。

## 5. 交互细节

### 5.1 指针拖拽

- 手柄为 8px 宽全高热区（`HitTestBehavior.opaque`），悬停/拖拽中显示
  2px 强调色（`colorScheme.primary` 45% 透明）指示线，光标
  `resizeLeftRight`；
- `dragStartBehavior: DragStartBehavior.down`：拖拽生效首帧即包含
  触摸 slop 位移，宽度变化与指针位移严格 1:1（默认 `start` 会吞掉
  起手 ~18px，跟手迟滞明显，不符合原生 resize 手柄手感）；
- RTL：`Row` 整体镜像后侧边栏位于物理右侧，宽度增量取反
  （`delta.dx → -delta.dx`），方向换算只存在于
  `ResizableSidebar._onDragUpdate` 一处，手柄保持方向无关。

### 5.2 双击重置

双击手柄恢复 176px 默认宽度并清除持久化键，作为「拖过头」的标准
逃生门；不新增设置页重置入口。

### 5.3 键盘与无障碍

- 手柄可聚焦（Tab 遍历可达），点按/起拖即接管焦点；
- 左右方向键 ±16px：LTR 下 Right 加宽、RTL 语义翻转（Left 加宽）；
  支持 KeyRepeat 长按连发；
- `Semantics(label: a11ySidebarResizeHandle, hint: a11ySidebarResizeHint)`
  并暴露 `onIncrease/onDecrease` 语义动作，与键盘路径共用
  `_adjustWidth`（一步 + 落盘，离散交互等价一次完整拖拽）；
- 新增本地化键（10 语言同步）：`a11ySidebarResizeHandle`、
  `a11ySidebarResizeHint`。

### 5.4 自动折叠互斥

窗口宽度 ≤768px（`Sidebar.autoCollapseBreakpoint`，原硬编码值收敛为
共享常量）时：侧边栏固定 56px、手柄隐藏，手动宽度不参与；恢复宽窗口
后继续使用用户上次拖拽的宽度。

## 6. 布局约束（易错点）

`ResizableSidebar` 内部含 `Expanded`（内容区），**必须以 `Expanded`
挂载在 AppShell 的 Row 中**。Row 的非 flex 子项拿到的是无界宽度，
内部 `Expanded` 将无法求解并触发
`RenderFlex children have non-zero flex but incoming width constraints
are unbounded` 崩溃（集成测试 `app_shell_setting_route_test` 已覆盖该
回归）。

## 7. 测试

`test/widget/widgets/resizable_sidebar_test.dart`（挂载真实 `Sidebar`
验证紧约束集成点，`installQueueProvider` 覆盖为空队列）：

1. 默认渲染：宽度 176 + 手柄存在；
2. 拖拽 +80px → 256px；
3. 拖拽超出上限 → 钳制 400px；
4. 拖拽低于下限 → 钳制 120px；
5. 拖拽结束持久化；
6. 双击重置（宽度 + 清除持久化键）；
7. RTL（ar）向左拖 = 加宽；
8. 方向键微调 + 持久化；
9. ≤768px 折叠态隐藏手柄、宽度 56px；
10. 重启恢复持久化宽度。

门禁：`flutter analyze` 0 告警、`build/scripts/verify_directional_layout.dart`
通过、既有 `app_shell_setting_route_test` / `rtl_arabic_smoke_test` 全绿。

## 8. 影响面与回滚

- 新增 2 文件（provider + 组件）+ 1 测试文件；`app_shell.dart` 仅替换
  Row 子项结构，`sidebar.dart` 仅收敛折叠断点常量；arb 各 +2 行；
- 宽度持久化独立成键，回滚（删除组件）后残留键无副作用，不迁移。
