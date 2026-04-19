# 应用详情页历史版本操作优化设计

## 背景

当前应用详情页的历史版本列表存在两个问题：

1. 右侧操作区仅使用 `TextButton`，视觉层级弱、对齐松散，在桌面端列表里显得单薄。
2. 已安装版本只显示纯文本“已安装”，不提供卸载入口；而底层 `LinglongCliRepositoryImpl.uninstallApp()` 虽然接口接收 `version`，实际调用仍是 `ll-cli uninstall <appId>`，没有精确卸载指定版本。

这会导致历史版本列表无法完成“查看版本后直接卸载指定版本”的闭环，也与当前仓库“同一应用可能并存多个版本，卸载必须按 `appId + version` 精确移除”的约束不一致。

## 现状确认

### 页面现状

- 页面位置：`lib/presentation/pages/app_detail/app_detail_page.dart`
- 版本列表当前使用 `ListTile`
- 已安装版本右侧仅渲染 `installedBadge`
- 未安装版本右侧渲染 `TextButton(安装)`

### 卸载链路现状

- 统一卸载交互入口：`AppUninstallFlow.run()`
- 统一卸载业务入口：`AppUninstallService.executeUninstall()`
- 仓储接口：`LinglongCliRepository.uninstallApp(String appId, String version)`
- 现有实现：`LinglongCliRepositoryImpl.uninstallApp()` 仍执行 `ll-cli uninstall <appId>`

### ll-cli 能力确认

已查阅 `/home/han/linyaps`：

- 文档 `docs/pages/guide/reference/commands/ll-cli/uninstall.md` 仅示例 `ll-cli uninstall org.deepin.calculator`
- 但源码 `libs/linglong/src/linglong/cli/cli.cpp` 中，`Cli::uninstall()` 会把 `APP` 解析为 `package::FuzzyReference`
- 若 `APP` 包含版本，如 `appId/version`，源码会将 `fuzzyRef->version` 填入 `params.package.version`

结论：`ll-cli uninstall appId/version` 是受支持的，Flutter 商店应修正为精确版本卸载。

## 目标

1. 优化历史版本列表右侧操作区视觉表现，保持当前页面风格，不做大改版。
2. 已安装版本显示“已安装 + 卸载”。
3. 未安装版本继续显示“安装”。
4. 历史版本卸载必须复用现有统一卸载流程，不新增第二套弹窗/副作用逻辑。
5. 仓储层必须真正执行按版本卸载，保证多版本并存时行为正确。

## 非目标

- 不改动详情页头部主操作区布局
- 不新增“打开指定历史版本”能力
- 不为版本列表增加右键菜单或更多菜单
- 不重做版本列表数据模型和排序逻辑

## 方案对比

### 方案 A：保守型列表增强（推荐）

- 保留 `ListTile` 结构
- 将右侧操作区改为紧凑的横向组合
- 已安装版本显示状态标签 + 卸载按钮
- 未安装版本显示单个安装按钮
- 卸载继续走 `AppUninstallFlow + AppUninstallService`
- 仓储层修正为 `ll-cli uninstall appId/version`

优点：

- 改动面小，和当前详情页视觉最一致
- 风险集中在版本列表和卸载精确性修复
- 能直接复用现有安装/卸载链路

缺点：

- 版本列表仍然是页面内嵌布局，组件复用性一般

### 方案 B：页面内自建一套版本卸载流程

- 版本列表自己弹确认框、自己调用仓储卸载

缺点：

- 与仓库“所有卸载入口统一走 `AppUninstallService`”冲突
- 逻辑分叉，后续维护成本高

### 方案 C：抽独立版本操作组件并顺手重构

- 为版本行单独抽 `VersionActionBar` / `VersionListItem`

优点：

- 长期结构更清晰

缺点：

- 超出本次需求，改动面偏大

## 推荐方案

采用 **方案 A：保守型列表增强**。

## 详细设计

### 1. 版本行 UI

版本行保持左信息、右操作的桌面列表结构：

- 左侧：
  - 版本号 `v{version}`
  - 发布时间、包体积副信息
- 右侧：
  - 未安装版本：小号主按钮“安装”
  - 已安装版本：状态标签“已安装” + 小号危险轮廓按钮“卸载”

视觉约定：

- 不再使用裸 `TextButton`
- 操作区使用固定高度的小号按钮，保证多行列表纵向节奏一致
- “已安装”是状态标签，不是可点击按钮
- “卸载”维持危险动作语义，但尺寸与“安装”对齐

### 2. 版本安装态判断

保留当前页面已有判断方式：

- `installedVersions.contains(version.versionNo)` 判断该版本是否已安装

原因：

- 当前详情页版本列表就是按 `versionNo` 展示
- 页面已基于 `installedAppsListProvider` 构造 `installedVersions`
- 本次需求不改变“已安装态”的展示规则，只增强操作区

### 3. 版本卸载目标解析

版本行点击卸载时，不能只拿 `appId + versionNo` 生造一个 `InstalledApp`，而要从真实已安装列表中解析目标实例。

解析规则：

1. 从 `installedAppsListProvider` 中筛选 `appId == detail.app.appId && version == versionNo`
2. 若仅匹配到一条，直接使用
3. 若匹配到多条，优先使用与当前详情页上下文更接近的实例：
   - `channel`
   - `module`
   - `arch`
4. 若仍无法唯一化，退回第一条，但在日志中记录该版本存在多实例匹配

设计理由：

- 当前仓库已有“卸载必须按 `appId + version` 精确移除”的约定
- 详情页版本列表来源于当前应用详情上下文，优先匹配同一 `channel/module/arch` 更合理
- 不在本次需求里新增更复杂的“按 module 显式展示多行版本实例”设计

### 4. 版本卸载交互

历史版本的卸载流程必须完全复用现有统一链路：

1. 版本行点击“卸载”
2. 解析出目标 `InstalledApp`
3. 调用 `AppUninstallFlow.run(context, targetApp, appUninstallServiceProvider)`
4. 成功后继续使用现有通知提示

不新增：

- 单独版本卸载确认框
- 单独版本卸载 service
- 页面内直接调用 `linglongCliRepository.uninstallApp()`

### 5. ll-cli 精确版本卸载修正

仓储层将 `LinglongCliRepositoryImpl.uninstallApp(appId, version)` 修正为：

- 调用 `ll-cli uninstall $appId/$version`

不再继续使用仅传 `appId` 的实现。

原因：

- 与 `/home/han/linyaps` 中 `Cli::uninstall()` 的真实能力保持一致
- 保证多版本并存时只卸载目标版本
- 与当前 `installedAppsProvider.removeApp(appId, version)` 的精确乐观移除语义一致

### 6. 错误与边界

#### 边界 1：版本显示为已安装，但找不到目标实例

处理：

- 不直接崩溃
- 记录 warning 日志
- 给用户提示“未找到对应已安装版本，建议刷新后重试”

#### 边界 2：版本正在安装/排队

本次不新增版本级 loading 态。

保持现状：

- 版本列表只负责安装/卸载入口
- 具体安装中的全局反馈继续依赖现有下载管理和通知中心

#### 边界 3：卸载被活跃任务拦截

保持现有 `AppUninstallFlow` 行为，不在版本列表单独改判。

#### 边界 4：已安装多个同版本实例

按“上下文优先匹配，找不到再选第一条”的规则处理，并打日志。

## 涉及文件

主要改动：

- `lib/presentation/pages/app_detail/app_detail_page.dart`
- `lib/data/repositories/linglong_cli_repository_impl.dart`
- `lib/core/i18n/l10n/app_zh.arb`
- `lib/core/i18n/l10n/app_en.arb`

测试：

- `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
- `test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart`

如版本行提取出局部控件，则新增小组件文件和对应 widget test。

## 测试策略

### 单元测试

- `LinglongCliRepositoryImpl.uninstallApp()` 必须发起 `['uninstall', '$appId/$version']`
- `stderr` 为空时仍保持错误文案回退逻辑有效

### Widget 测试

- 未安装版本显示“安装”
- 已安装版本显示“已安装 + 卸载”
- 点击“卸载”时走统一卸载流程
- 当解析不到目标安装项时显示错误提示，不崩溃

## 风险

1. 详情页当前 `installedVersions` 仅按版本号聚合，无法天然表达同版本多实例差异
2. 若版本行继续直接写在 `app_detail_page.dart` 内，代码体积会继续增大

本次处理策略：

- 优先保证行为正确和交互可用
- 不做超范围重构
- 若版本行逻辑继续增长，再在后续需求中抽出独立组件

## 验收标准

1. 历史版本列表右侧操作区视觉上明显优于当前裸 `TextButton`
2. 已安装版本显示“已安装 + 卸载”
3. 点击版本行卸载时，实际只卸载目标版本
4. 版本卸载继续遵守现有统一卸载拦截、确认、运行中处理和刷新链路
5. 对应单测和 Widget 测试覆盖新增行为
