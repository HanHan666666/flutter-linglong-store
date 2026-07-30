# 下载管理弹窗拆分设计

## 1. 文档定位

本文定义 `DownloadManagerDialog` 的展示层拆分方案。目标是在保持安装队列唯一业务
入口、现有工作面板视觉和任务操作语义不变的前提下，把队列订阅、任务展示数据、
面板区域和有状态任务卡拆成清晰边界。

本次只做结构迁移，不修改下载中心交互、文案、进度、慢安装提示、日志复制或错误
解决方案行为。

## 2. 现状与问题

`lib/presentation/widgets/download_manager_dialog.dart` 当前约 1130 行，同时包含：

- Dialog 尺寸与工作面板框架；
- 安装队列、语言、发行版和网速 Provider 订阅；
- 标题栏、概览条、任务内容和底部状态栏；
- 当前任务、等待队列和历史记录的业务回调；
- 结构化任务状态到本地化文案的格式化；
- 任务卡片的进度、慢安装计时器、日志复制反馈；
- 错误帮助、任务动作、状态标签；
- 标题、概览指标和 hover 关闭按钮。

主要风险：

1. 面板布局和任务卡状态机混在同一文件，任何小改动都需要审查全部 1100 行；
2. `_resolveTaskPresentation()` 在每个任务构建路径中重复 `ref.watch` 相同全局依赖，
   依赖边界不直观；
3. 当前、等待、历史三类任务的差异由多个私有 builder 隐式表达；
4. 任务卡自身包含合理的局部状态，但被埋在弹窗文件中，难以独立维护；
5. 标题、概览和底栏是稳定面板区域，却无法脱离队列业务阅读。

## 3. 保持不变的业务契约

- 公共入口继续是 `showDownloadManagerDialog(context)`；
- 公共 Widget 继续是 `DownloadManagerDialog`；
- 安装队列继续是任务状态和命令的唯一入口；
- 当前任务取消、等待项移除、失败项重试和历史项删除保持现有参数语义；
- 成功历史项继续通过 `linglongCliRepositoryProvider` 启动应用；
- 当前任务优先使用 CLI 速度，缺失时回退系统网速；
- 任务展示文案继续由当前 locale 的 `InstallMessages` 和发行版画像生成；
- `InstallTask.commandOutput` 继续是“复制日志”的唯一来源；
- 复制成功反馈继续只更新当前卡片，不触发全局通知；
- 慢安装提示继续只在当前安装任务达到阈值后每 5 秒更新；
- 当前任务的阶段文案只出现在进度条上方，标题区不重复；
- 错误帮助继续使用未经替换的 `diagnosticMessage`；
- 现有 Key、面板尺寸、颜色、间距和 Widget 测试可观察行为保持不变。

## 4. 方案比较

### 4.1 方案 A：只把 `_TaskCard` 移到单独文件

可以显著缩短原文件，但标题、概览、内容分组、底栏和 Provider 格式化仍混在一起，
没有解决面板区域和任务业务回调的边界。

### 4.2 方案 B：每个任务卡自行订阅语言、发行版和网速

参数更少，但每一张历史卡都会持有多个全局 Provider 依赖。队列较长时重建来源难以
追踪，也违反“页面聚合全局状态后下发轻量属性”的性能约定。

### 4.3 方案 C：单一容器订阅 + 纯展示区域 + 局部有状态任务卡

弹窗容器只订阅一次队列、消息格式器、发行版和网速，把每个任务转换为轻量展示数据；
标题、概览、内容和底栏作为纯展示区域；任务卡单独保留只属于自己的计时器与复制反馈。

**选择方案 C。** 它保持单向数据流，同时避免把任务卡局部状态提升到全局。

## 5. 目标结构

```text
download_manager_dialog.dart
  ├─ DownloadManagerHeader
  ├─ DownloadManagerOverview
  ├─ DownloadManagerTaskContent
  │    ├─ current task section
  │    ├─ waiting task section
  │    ├─ history task section
  │    └─ DownloadTaskCard
  └─ DownloadManagerFooter
```

目录：

```text
lib/presentation/widgets/download_manager/
  download_manager_header.dart
  download_manager_overview.dart
  download_manager_task_content.dart
  download_manager_footer.dart
  download_task_card.dart
  download_task_view_data.dart
```

## 6. 组件职责

### 6.1 `DownloadManagerDialog`

只负责：

- 单次订阅 `installQueueProvider`；
- 单次订阅 `InstallMessages`、发行版画像和系统网速；
- 把任务转换为 `DownloadTaskViewData`；
- 把安装队列命令包装为区域回调；
- 计算面板尺寸并组合四个稳定区域。

它不再实现具体卡片、区块标题或复制计时器。

### 6.2 `DownloadTaskViewData`

只保存任务渲染需要的不可变数据：

- 原始 `InstallTask`；
- 当前 locale 下的状态文案；
- 当前 locale 下的失败摘要。

不保存 Provider、`BuildContext` 或操作回调。任务日志和诊断仍从原始任务读取，避免
创建第二份状态。

### 6.3 `DownloadManagerHeader`

负责标题、清空记录入口和关闭按钮。清空和关闭由回调注入。

### 6.4 `DownloadManagerOverview`

只根据当前任务、等待队列和历史数量显示三个概览指标。

### 6.5 `DownloadManagerTaskContent`

负责：

- 空状态；
- 当前、等待和历史三个区块；
- 把不同区块的操作回调传给任务卡；
- 当前任务的下载速度回退结果。

三个区块的差异在该文件显式表达，但不读取 Riverpod。

### 6.6 `DownloadTaskCard`

保留局部 StatefulWidget，因为以下状态只属于单张卡：

- 慢安装时间提示 ticker；
- 日志复制成功的短时反馈；
- Widget 更新时同步 ticker 和复制反馈。

任务卡只接收 `DownloadTaskViewData`、速度和操作回调；禁止新增 Provider 订阅。

### 6.7 `DownloadManagerFooter`

只显示实时速度和历史记录数量，不读取队列或网速 Provider。

## 7. 性能和状态约束

- 同一种全局 Provider 在弹窗容器中只订阅一次；
- 历史项不单独订阅 locale、发行版或网速；
- 文案格式化在容器重建时每个任务执行一次；
- 任务列表仍由现有队列状态提供，不复制或持久化第二份任务集合；
- 卡片 ticker 只在当前安装任务满足慢安装阈值条件时启动；
- 日志复制只触发对应卡片的 `setState`；
- 不把 `commandOutput` 截断、缓存或迁移到其他状态；
- 本次不改变 `SingleChildScrollView + Column`，列表虚拟化若需要必须基于真实任务规模
  独立测量和设计，不能夹带在结构迁移中。

## 8. 依赖约束

- 只有 `download_manager_dialog.dart` 允许读取 Riverpod；
- 子区域和任务卡禁止导入 Application Provider；
- `DownloadTaskViewData` 是 Presentation 模型，不进入 Domain；
- 所有队列动作继续由容器调用 `installQueueProvider.notifier`；
- 子组件只接收必要数据和按 taskId/appId 语义明确的回调；
- 不使用事件总线、GlobalKey 或新的状态管理层。

## 9. 迁移和验证

迁移顺序：

1. 提取 `DownloadTaskViewData`；
2. 提取有状态任务卡；
3. 提取内容分组；
4. 提取标题、概览和底栏；
5. 收敛原弹窗为单一 Provider 容器；
6. 更新开发指南；
7. 运行现有下载管理 Widget 测试、静态分析和 Linux 构建。

不为了拆文件新增测试。现有测试已经覆盖：

- 面板关键区域和 Key；
- 当前、等待、历史任务；
- 清空、取消、重试、删除和打开；
- 进度、CLI 速度和系统速度回退；
- 慢安装提示；
- 复制日志及反馈；
- 结构化错误和错误帮助。

完成标准：

- 原弹窗文件只保留 Provider 聚合、回调和框架；
- 子区域不含 Riverpod 依赖；
- 现有下载管理测试全部通过；
- `flutter analyze` 无错误和警告；
- Linux debug 构建通过；
- 无视觉和业务语义变化。
