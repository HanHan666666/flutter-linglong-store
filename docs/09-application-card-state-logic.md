# 应用卡片三态逻辑说明

## 目标
- 将旧版 Rust 商店中”安装 / 更新 / 打开”三态按钮逻辑完整迁移到 Flutter。
- 所有应用列表页复用同一套状态解析规则和同一个 `AppCard` 组件，避免页面各自复制判断逻辑。
- 保持高性能：卡片只接收页面层聚合后的轻量状态，不直接订阅多个全局 Provider。

## 适用范围
- 推荐页
- 全部应用页
- 搜索结果页
- 自定义分类页
- 排行榜页
- 我的应用页

## 状态来源
统一由 [application_card_state_provider.dart](/home/han/linglong-store/flutter-linglong-store/lib/application/providers/application_card_state_provider.dart) 聚合三类数据：

1. 已安装列表
   来源：`installedAppsProvider`
   作用：判断应用是否已安装，并记录同一 `appId` 的最高已安装版本。

2. 待更新列表
   来源：`updateAppsProvider`
   作用：判断应用是否应显示”更新”。

3. 安装队列
   来源：`installQueueProvider`
   作用：仅作为 loading/progress 来源，不参与”安装 / 更新 / 打开”三态决策。

## 三态决策规则
统一使用 `ApplicationCardStateIndex.resolve()` 解析单个卡片状态。

### 1. 未安装
- 条件：`installedVersionByAppId` 中不存在该 `appId`
- 主按钮：`安装`
- 视觉样式：蓝底白字

### 2. 已安装且可更新
- 条件：
  - `updateAppsProvider` 明确命中该 `appId`
  - 或者卡片携带的远端 `latestVersion` 高于当前已安装版本
- 主按钮：`更新`
- 视觉样式：蓝底白字

### 3. 已安装且无更新
- 条件：已安装，且不满足更新条件
- 主按钮：`打开`
- 视觉样式：描边按钮

## 明确约束
- 安装队列中的进行中任务不会把”打开”改成”安装”，也不会把”更新”改成别的文案。
- 失败、取消、成功的历史任务不会继续影响卡片状态。
- 页面层只 watch 一次 `applicationCardStateIndexProvider`，然后把解析后的轻量结果传给 `AppCard`。
- `AppCard` 只负责展示和交互分发，不再自行读取安装列表、更新列表或安装队列。

## 多版本处理
### 一般列表
- 同一 `appId` 若已安装多个版本，卡片状态统一按”最高已安装版本”参与比较。

### 我的应用
- [my_apps_page.dart](/home/han/linglong-store/flutter-linglong-store/lib/presentation/pages/my_apps/my_apps_page.dart) 会先按 `appId` 合并，只展示最高版本。
- 卸载时必须按 `appId + version` 精确删除，不能整包删除同应用的其他版本。

## 按钮样式约束
- `安装` 和 `更新` 使用主色实心按钮，文字固定为白色。
- `打开` 使用描边按钮，保持桌面应用列表的次级操作视觉层级。

## 组件职责划分
### 页面层
- 聚合 Provider
- 解析卡片状态
- 传递主按钮回调和菜单回调

### `AppCard`
- 展示图标、名称、描述、排名
- 渲染主按钮
- 渲染更多菜单
- 展示安装进度和 loading

## 与 Rust 迁移对齐点
- 三态优先级与旧版 Rust 保持一致：`安装` < `更新` < `打开`
- 更新判断兼容”更新列表命中优先，版本比较兜底”
- 我的应用页无更新时统一显示”打开”，不再单独走一套按钮语义

## 安装/升级命令约束
- 只有应用详情页“版本历史”中的指定版本安装入口允许传 `version`，最终命令形态为 `ll-cli install --json <appId>/<version>`。
- 推荐页、全部应用页、搜索结果页、自定义分类页、排行榜页、我的应用页、更新页，以及详情页主按钮，统一不再透传 `version`。
- 所有升级入口统一走 `InstallTaskKind.update`，底层执行 `ll-cli upgrade --json <appId>`，不再伪装成带版本的 install。
- 队列层即使收到旧的 update `version` 字段，也必须忽略，避免未来回归到“更新命令携带版本号”的错误链路。

## 已知性能原则
- 禁止在卡片组件的 `build()` 中解析版本、扫描安装列表或安装队列。
- 禁止在每个页面内部再复制一套 `_AppCard` 和状态判断。
- 页面聚合、卡片纯展示是当前 Flutter 版本的统一实现约束。

---

## 安装队列状态与按钮映射

### 安装队列机制

系统采用**严格串行安装**，同一时刻只允许一个安装任务执行。队列数据结构：

```dart
class InstallQueueState {
  final List<InstallTask> queue;      // 等待中的任务
  final InstallTask? currentTask;     // 当前正在执行的任务（唯一）
  final List<InstallTask> history;    // 已完成的历史记录
  final bool isProcessing;            // 是否正在处理
}
```

### InstallStatus 与 InstallButtonState 映射

`InstallTask.status` 与按钮显示的映射关系：

| InstallStatus | InstallButtonState | 显示内容 |
|---------------|---------------------|---------|
| `pending` | `pending` | 转圈 + “等待安装”，悬停可取消 |
| `downloading` | `installing` | 进度条 + 百分比 + 网速 |
| `installing` | `installing` | 进度条 + 百分比 + 网速 |
| `success` | 由三态逻辑决定 | “打开”或”更新” |
| `failed` | 由三态逻辑决定 | “更新”或”安装” |
| `cancelled` | 由三态逻辑决定 | “更新”或”安装” |

### pending 与 installing 的区别

**问题背景**：
点击”一键更新”后，所有应用被批量入队。如果 `pending` 和 `installing` 不区分，会导致所有按钮都显示进度条和网速，但实际上只有一个任务在执行。

**解决方案**：

```dart
InstallButtonState _getButtonState() {
  if (installTask != null) {
    switch (installTask!.status) {
      case InstallStatus.pending:
        return InstallButtonState.pending;  // 等待中，不显示进度
      case InstallStatus.downloading:
      case InstallStatus.installing:
        return InstallButtonState.installing;  // 执行中，显示进度
      // ...
    }
  }
  return InstallButtonState.update;
}
```

**视觉对比**：

| 状态 | 队列位置 | 按钮显示 | 网速 |
|------|---------|---------|------|
| `pending` | `queue` 列表中 | 转圈 + “等待安装” | 不显示 |
| `installing` | `currentTask` | 进度条 + 百分比 | 显示 |

### 取消功能

**pending 状态取消**：
- 鼠标悬停时显示”取消安装”（红色）
- 点击后调用 `InstallQueue.removeFromQueue(appId)`
- 任务从队列中移除，不影响其他任务

**installing 状态取消**：
- 调用 `InstallQueue.cancelTask(appId)`
- 终止当前安装进程
- 自动处理队列中的下一个任务

### 相关代码位置

| 文件 | 说明 |
|------|------|
| `lib/presentation/widgets/install_button.dart` | 按钮组件，支持 pending 状态悬停取消 |
| `lib/presentation/pages/update_app/update_app_page.dart` | 更新页面，状态映射实现 |
| `lib/application/providers/install_queue_provider.dart` | 安装队列 Provider，串行安装逻辑 |
| `docs/03c-ui-core-widgets.md#八installbutton安装按钮` | 按钮组件详细文档 |
