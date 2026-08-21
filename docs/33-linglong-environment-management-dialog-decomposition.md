# 玲珑环境管理界面拆分设计

## 1. 文档定位

本文定义 `LinglongEnvironmentManagementDialog` 的展示层拆分方案。服务层已经通过
稳定门面和单职责协作者完成拆分，本阶段继续收敛环境管理对话框中的页面框架、
交互编排和三个业务区域。

本次只迁移结构，不改变视觉、尺寸、文案、交互顺序、Provider 状态或系统操作。

## 2. 现状与问题

`lib/presentation/widgets/linglong_environment_management_dialog.dart`
当前约 1500 行，虽然已经存在多个私有 Widget，但仍把以下职责放在同一文件：

- 对话框框架、Tab 切换、加载遮罩和刷新；
- 保存位置输入控制器生命周期；
- 本地数据修复、权限修复和迁移二次确认；
- 仓库新增、修改、删除、默认、优先级和镜像交互；
- 打开日志目录和 Toast 反馈；
- 环境分析区域及其指标、问题卡片；
- 仓库管理区域及其仓库卡片；
- 保存位置区域；
- 通用空状态、信息面板、修复结果、警示横幅和分段 Tab。

主要维护问题不是 Widget 数量，而是文件边界没有表达业务区域：

1. 修改一个仓库弹窗需要在包含所有环境 UI 的 1500 行文件中审查；
2. StatefulWidget 同时拥有资源生命周期、Provider 调用和九类弹窗交互；
3. 三个 Tab 只能通过私有类存在于同一文件，无法独立阅读和复用；
4. 通用展示组件与业务卡片混排，组件的适用边界不清晰；
5. 后续做国际化或无障碍治理时，单次改动容易跨越所有区域。

## 3. 保持不变的契约

- 公共入口继续是 `showLinglongEnvironmentManagementDialog(context)`；
- 公共 Widget 名称继续是 `LinglongEnvironmentManagementDialog`；
- 对话框保持 760×560、三个 Tab 和操作按钮（顶部稳定性警示横幅已随功能稳定移除）；
- 打开时继续在首帧后调用 Provider `load()`；
- `TextEditingController` 继续由 StatefulWidget 创建和释放；
- 所有系统变更继续只通过 `linglongEnvironmentManagementProvider`；
- 本地数据修复、权限修复和保存位置迁移继续二次确认；
- 仓库操作的成功/失败反馈、校验和刷新语义保持不变；
- 忙碌状态继续禁用操作并显示阻塞遮罩；
- 日志目录继续通过 `localPathOpenerProvider` 打开；
- 不在结构重构中修改硬编码文案或视觉令牌；国际化作为后续独立变更；
- 不新增为了拆文件而存在的测试。

## 4. 方案比较

### 4.1 方案 A：使用 `part` 文件保留全部私有符号

该方案修改量较小，但所有文件仍属于同一个 Dart library，可以任意访问彼此私有
实现。物理拆分没有建立依赖边界，未来很容易继续跨区域耦合。

### 4.2 方案 B：每个 Tab 自己读取 Provider 并执行操作

该方案减少回调参数，但会让多个 Tab 重复订阅全局状态并各自实现副作用。确认弹窗、
Toast 和 Provider 调用重新散落，违背统一入口约定，也不利于控制重建范围。

### 4.3 方案 C：对话框壳 + 交互控制器 + 无状态区域

对话框壳只订阅一次 Provider 状态，向三个无状态区域下发轻量状态和回调；交互控制器
集中处理确认弹窗、表单弹窗、Provider 命令和反馈；区域文件只负责渲染。

**选择方案 C。** 它保持单向数据流，同时把“渲染变化”和“交互流程变化”拆成
不同文件。

## 5. 目标结构

```text
linglong_environment_management_dialog.dart
  ├─ LinglongEnvironmentManagementActions
  ├─ EnvironmentAnalysisTab
  ├─ RepositoryManagementTab
  ├─ StorageManagementTab
  └─ environment_management_components.dart
```

目录为：

```text
lib/presentation/widgets/linglong_environment_management/
  environment_management_dialog_actions.dart
  environment_management_components.dart
  environment_analysis_tab.dart
  repository_management_tab.dart
  storage_management_tab.dart
```

### 5.1 对话框壳

保留在原公共文件，职责限定为：

- 公共展示入口；
- `TextEditingController` 生命周期；
- 首帧加载；
- 单次订阅 Provider 状态；
- 对话框尺寸和 Tab 框架；
- 把状态、控制器和交互回调传给区域组件。

壳不再构建业务卡片，不再包含仓库表单或特权操作确认文案。

### 5.2 `LinglongEnvironmentManagementActions`

定位为 Presentation 交互编排器：

- 每个公开方法都接收本次调用的 `BuildContext`；
- 不长期保存 `BuildContext`，异步返回后通过 `context.mounted` 校验；
- 统一调用环境管理 Provider；
- 统一显示确认弹窗、输入弹窗和成功/失败反馈；
- 统一通过 `localPathOpenerProvider` 打开日志目录；
- 不保存业务状态，不执行 Shell 命令；
- 不在控制器中复制 Provider 的状态转换。

控制器由对话框 State 创建，持有 `WidgetRef` 用于读取依赖。它不是 Application
Controller，也不进入 Domain/Data 层。

### 5.3 `EnvironmentAnalysisTab`

负责：

- 空分析状态；
- 环境指标摘要；
- 问题列表和修复入口；
- 最近一次修复结果。

指标卡和问题卡与分析区域一起变化，保留在同一文件，不抽成全局通用组件。

### 5.4 `RepositoryManagementTab`

负责：

- 默认仓库摘要；
- 仓库说明；
- 仓库列表；
- 单个仓库卡片和操作菜单。

仓库别名选择规则跟随仓库卡片，作为该文件内扩展保留。

### 5.5 `StorageManagementTab`

负责：

- 当前保存位置；
- 目标路径输入；
- bind mount 方案说明；
- 运行中应用阻断提示；
- 迁移结果和日志入口。

它接收外部创建的 `TextEditingController`，自身保持无状态。

### 5.6 通用展示组件

`environment_management_components.dart` 只放至少被两个区域或对话框壳复用的组件：

- `EnvironmentManagementInfoPanel`；
- `EnvironmentManagementRepairResultPanel`；
- `EnvironmentManagementEmptyState`；
- `EnvironmentManagementBlockingOverlay`；
- `EnvironmentManagementSegmentedTabBar`。

这些组件只接收展示属性和回调，不读取 Riverpod，不执行导航或业务命令。

## 6. 性能与状态约束

- 对话框仍只 `ref.watch` 一次环境管理状态；
- Tab 区域使用构造参数接收状态，不新增 Provider 订阅；
- 不把完整 Provider Notifier 传给子组件；
- 不在 `build` 中执行命令、解析或 IO；
- `TextEditingController` 不因 Provider 状态变化重建；
- 列表继续使用 `ListView.separated`；
- 本次不引入额外状态管理包、GlobalKey 或事件总线。

## 7. 可见性与依赖约束

- 只有原对话框文件提供仓库外公共入口；
- 子文件中的 Widget 使用明确的环境管理前缀，避免与全局组件重名；
- 子组件只能依赖 Provider 状态模型、Domain 展示模型、主题和本地化；
- 只有交互控制器允许依赖 Provider、路径打开器和通知帮助函数；
- 禁止 Tab 组件自行 `ref.read` 或 `ref.watch`；
- 禁止交互控制器持久保存 `BuildContext`。

## 8. 迁移步骤

1. 提取通用纯展示组件；
2. 提取环境分析 Tab；
3. 提取仓库管理 Tab；
4. 提取保存位置 Tab；
5. 提取交互控制器并迁移所有异步弹窗流程；
6. 把原文件收敛为公共入口和框架；
7. 更新开发指南；
8. 运行环境管理 Widget/Provider 测试、静态分析和 Linux 构建。

迁移过程中保持 Widget 树的关键结构、Key、文本和回调顺序不变，使现有测试继续保护
真实行为。

## 9. 完成标准

- 原公共文件只保留对话框框架和资源生命周期；
- 三个 Tab 可独立阅读，且不直接访问 Riverpod；
- 所有弹窗、反馈和 Provider 命令集中在交互控制器；
- 通用组件不包含业务副作用；
- 现有环境管理 Widget 和 Provider 测试全部通过；
- `flutter analyze` 无错误和警告；
- Linux debug 构建通过；
- 无无关视觉或业务变化。
