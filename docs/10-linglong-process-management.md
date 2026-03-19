# 玲珑进程管理逻辑说明

## 目标
- 将旧版 Rust 商店中的“玲珑进程”功能迁移到 Flutter。
- 入口回归到“我的应用 / 玲珑进程”双 Tab。
- 右键菜单、轮询、停止进程、错误恢复等行为与 Rust 版本保持业务等价。

## 页面入口
- 页面： [my_apps_page.dart](/home/han/linglong-store/flutter-linglong-store/lib/presentation/pages/my_apps/my_apps_page.dart)
- 展示形式：`我的应用` / `玲珑进程` 双 Tab
- 激活约束：
  - 只有切到“玲珑进程”Tab 时才允许开启轮询
  - 页面隐藏时必须暂停轮询
  - 页面重新可见时立即补一次刷新
  - 页面可见性必须由 Shell 当前路由显式驱动，不能只依赖 KeepAlive widget 的 `activate/deactivate`

## 进程数据来源
统一由 [linglong_cli_repository_impl.dart](/home/han/linglong-store/flutter-linglong-store/lib/data/repositories/linglong_cli_repository_impl.dart) 获取。

### 1. 运行中进程
- 命令：`ll-cli ps`
- 用途：获取运行中的 `appId / containerId / pid`

### 2. 已安装详情
- 命令：`ll-cli list --json --type=all`
- 用途：补齐运行中条目的 `name / version / arch / channel / source / icon`

### 3. 合并规则
- 先解析 `ps`
- 再按 `appId` 与安装详情合并
- 避免对每个进程单独执行外部命令

## 运行中进程模型
[running_app.dart](/home/han/linglong-store/flutter-linglong-store/lib/domain/models/running_app.dart) 当前包含：
- `id`
- `appId`
- `name`
- `version`
- `arch`
- `channel`
- `source`
- `pid`
- `containerId`
- `icon`

其中：
- `id` 用于列表稳定 key 和行级 loading
- `containerId` 用于复制容器信息和右键菜单操作

## Provider 业务逻辑
统一由 [running_process_provider.dart](/home/han/linglong-store/flutter-linglong-store/lib/application/providers/running_process_provider.dart) 管理。

### 轮询启停
- 轮询前提：`进程 Tab 激活 && 页面可见`
- 默认刷新间隔：3 秒
- 切到进程 Tab：立即刷新一次，再进入轮询
- 页面恢复可见：立即刷新一次，再进入轮询
- 离开进程 Tab 或页面隐藏：立刻停止计时器
- 当用户切换到 `推荐 / 全部 / 排行 / 设置 / 更新` 等其他页面时，必须立即把 `我的应用` 路由标记为 hidden，后台不允许继续保留 3 秒轮询

### 并发保护
- `_isFetching` 防止同一时刻重复拉取
- 新一轮刷新前会取消旧 timer，避免重入

### 失败退避
- 第 1 次失败：3 秒后重试
- 第 2 次失败：6 秒后重试
- 第 3 次及以上失败：10 秒后重试

### 刷新态
- `isInitialLoading`：首屏无数据时显示全屏 loading
- `isRefreshing`：已有旧数据时静默刷新
- `lastRefreshedAt`：记录最近成功刷新时间
- `error`：记录最近一次错误；若已有旧数据则保留旧数据并显示 warning banner

### 行级停止 loading
- `killLoadingIds` 记录正在执行停止操作的行
- 某一行停止中，不影响其他行操作

## 停止进程逻辑
- 入口：`runningProcessProvider.killApp()`
- Repository 逻辑对齐 Rust：
  - 先读取当前运行列表确认目标仍存在
  - 执行 `ll-cli kill -s 9 <appId>`
  - 最多重试 5 次
  - 每轮之间等待 1 秒
  - 成功后立即刷新列表

## UI 与交互
- 面板组件： [linglong_process_panel.dart](/home/han/linglong-store/flutter-linglong-store/lib/presentation/widgets/linglong_process_panel.dart)
- 展示形式：桌面列表 / 表格风格
- 工具栏信息：
  - 当前运行进程数
  - 刷新状态
  - 最近刷新时间

## 右键菜单
统一使用 `flutter_desktop_context_menu` 原生菜单。

### 菜单动作
- 复制进入容器命令
- 复制应用 ID
- 复制 PID
- 复制容器 ID
- 刷新进程列表
- 停止进程

### 交互约束
- 行右键菜单与“更多”按钮必须复用同一套菜单定义
- “停止进程”在该行处于 killing 时禁用
- 菜单弹出位置保持在鼠标右键点的右下方 `4px`

## Linux 原生菜单主题同步
- 原生右键菜单由 GTK 绘制，不能直接使用 Flutter ThemeData
- 当前实现通过 Dart -> Linux runner 的轻量 MethodChannel 同步“当前实际是否深色”
- Linux runner 收到后设置 GTK 的 `gtk-application-prefer-dark-theme`
- 不修改第三方菜单插件源码，不 fork `flutter_desktop_context_menu`

## 错误与恢复
- 刷新失败但已有旧数据时：
  - 保留旧数据
  - 展示 warning banner
  - 继续按退避策略重试
- 停止进程失败时：
  - 仅弹出当前操作失败提示
  - 不清空现有列表

## 与 Rust 迁移对齐点
- 双 Tab 入口位置一致
- 进程列表数据由 `ps + list --json --type=all` 合并
- 轮询、失败退避、恢复可见补刷新、行级停止 loading 保持一致
- 右键菜单和更多按钮共用一套动作定义

## 验证建议
- 启动一个真实玲珑应用，例如 `org.deepin.calculator`
- 确认进程 Tab 能显示条目
- 验证右键菜单复制动作
- 验证停止进程后列表实时消失
- 验证切换离开 Tab 后轮询停止，切回来后自动补刷新
