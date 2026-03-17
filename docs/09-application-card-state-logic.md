# 应用卡片三态逻辑说明

## 目标
- 将旧版 Rust 商店中“安装 / 更新 / 打开”三态按钮逻辑完整迁移到 Flutter。
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
   作用：判断应用是否应显示“更新”。

3. 安装队列
   来源：`installQueueProvider`
   作用：仅作为 loading/progress 来源，不参与“安装 / 更新 / 打开”三态决策。

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
- 安装队列中的进行中任务不会把“打开”改成“安装”，也不会把“更新”改成别的文案。
- 失败、取消、成功的历史任务不会继续影响卡片状态。
- 页面层只 watch 一次 `applicationCardStateIndexProvider`，然后把解析后的轻量结果传给 `AppCard`。
- `AppCard` 只负责展示和交互分发，不再自行读取安装列表、更新列表或安装队列。

## 多版本处理
### 一般列表
- 同一 `appId` 若已安装多个版本，卡片状态统一按“最高已安装版本”参与比较。

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
- 更新判断兼容“更新列表命中优先，版本比较兜底”
- 我的应用页无更新时统一显示“打开”，不再单独走一套按钮语义

## 已知性能原则
- 禁止在卡片组件的 `build()` 中解析版本、扫描安装列表或安装队列。
- 禁止在每个页面内部再复制一套 `_AppCard` 和状态判断。
- 页面聚合、卡片纯展示是当前 Flutter 版本的统一实现约束。
