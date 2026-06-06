# 安装图标飞入下载中心动画

## 背景

为了给安装/更新动作提供更直接的空间反馈，应用在成功进入安装队列时，会把当前可见应用图标以弹射飞行动画送往左下角下载中心入口。

该反馈只负责视觉确认，不参与任何安装业务逻辑，不得影响原有入队、取消、打开应用等行为。

## 入口范围

- 列表卡片入口：`AppCard` 体系覆盖的推荐、全部应用、排行、搜索、自定义分类、我的应用。
- 更新页入口：单个应用更新按钮触发图标飞行动画；`全部更新` 只触发下载中心脉冲，不做多图标并发飞行。
- 详情页入口：头部主按钮的安装/更新，以及版本列表触发的指定版本安装，统一复用详情页头部图标作为动画源点。

## 架构约定

### 1. 动画宿主必须放在 `AppShell` 根层

统一由 `InstallToDownloadFlyoutLayer` 承载，挂在 `AppShell` 的 `Scaffold` 外层。

原因：右侧内容区已经被 `ClipRRect` 裁剪，如果把动画放进内容区内部，图标飞往左侧侧边栏时会被裁掉。

### 2. 下载中心目标锚点必须绑定侧边栏真实按钮

统一通过 `DownloadCenterFlyoutTarget` 包裹 `Sidebar` 底部的下载管理按钮交互面。

不要把目标锚点绑到 badge、Tooltip 或下载管理弹窗上。

### 3. 源点以“当前可见图标”优先

- `AppCard` 内部维护图标 `GlobalKey`，主按钮点击时把 source key 传给上层。
- 更新页和详情页分别在本地为 `AppIcon` 包装 source key。
- 动画层会校验 source rect 是否仍在可见区域；若图标已离开视口，则不强行从屏幕外飞入。

### 4. 动画触发必须以“成功入队”为准

只有 `enqueueInstall / enqueueOperation / enqueueBatchOperations` 返回有效任务 ID 后，才允许触发飞行动画或下载中心脉冲。

禁止把动画直接绑在按钮点击事件上，否则重复点击、已在队列中、禁用态等场景会出现假反馈。

### 5. 系统动画开关以 Flutter 暴露的系统偏好为准

动画层必须读取 `MediaQuery.disableAnimations`，并在缺少 `MediaQuery` 时回退到 `PlatformDispatcher.accessibilityFeatures.disableAnimations`。

这是当前 Flutter Linux 对系统“减少/禁用动画”偏好的统一入口。GNOME、Portal 等 Flutter 已支持来源会映射到该值；不同 Linux 桌面环境并不存在一个完全统一的“窗口动画开关”业务 API，因此本项目不在 Dart 层新增发行版专有分支，也不直接调用 `gsettings`、KDE 配置文件或 shell 命令读取动画设置。

如果系统设置关闭或减少动画，安装飞行和下载中心脉冲都必须跳过；安装/更新入队结果不得受影响。

## 视觉约定

- 飞行时长保持在约 `900ms` 量级，让用户能看清源点、轨迹和落点。
- 飞行图标必须包含主题色光晕和描边，避免在浅色内容区、深色侧边栏或复杂图标背景上不可见。
- 图标末段不应过早消失，淡出只发生在接近下载中心入口时。
- 下载中心落点必须使用主题色双层脉冲和中心高亮，不再依赖低透明白色圆环。
- 动画只用于“已加入下载管理”的空间反馈，不承载进度、错误或队列状态。

## 降级规则

- source 不可见、目标锚点不可用、动画宿主不存在时：不得阻断安装流程。
- 单项安装/更新：优先尝试飞行；若无法起飞，退化为下载中心脉冲。
- 批量更新：固定退化为下载中心脉冲，不做多图标飞行。
- 系统声明禁用动画时：直接跳过飞行和脉冲反馈。

## 测试约定

- `install_to_download_flyout_test.dart`：验证动画宿主的出现与回收。
- `install_to_download_flyout_test.dart`：验证系统禁用动画时不出现飞行或脉冲反馈。
- `install_to_download_flyout_test.dart`：验证增强视觉节点包含飞行光晕和下载中心落点高亮。
- `app_card_state_test.dart`：验证 `AppCard` 会把图标 source key 传给主动作回调。
- `sidebar_test.dart`：验证下载中心按钮存在稳定 flyout target。
- 更新页、详情页与 AppShell 继续依赖现有页面级 widget 测试覆盖回归。

## 后续维护约束

- 若新增新的安装入口，优先复用 `InstallToDownloadFlyoutLayer`，不要在页面内各自写 Overlay。
- 若未来需要更强的视觉一致性，应在动画层内升级轨迹或图标快照策略，而不是修改队列层。
- 若新增下载中心入口位置，必须保证整个应用仍然只有一个真实 target anchor。
