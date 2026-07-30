# 应用详情页拆分设计

## 1. 文档定位

本文定义 `AppDetailPage` 的展示层和交互编排拆分方案。目标是在保持现有安装队列、
卸载语义、评论、截图、分享和快捷方式行为不变的前提下，把 1500 余行页面按
Provider 容器、纯派生规则、页面区域和异步动作拆成可独立维护的边界。

本次只做结构迁移，不调整视觉、接口、业务规则或文案。

## 2. 现状与问题

`lib/presentation/pages/app_detail/app_detail_page.dart` 当前约 1575 行，同时负责：

- 详情、安装队列、已安装应用、更新列表、发行版和网速等 Provider 聚合；
- 页面加载、错误和空状态；
- 头部安装按钮与次级动作；
- 截图、描述、应用信息、评论和版本历史；
- 安装、更新、取消、打开和下载飞入动画；
- 同版本重装和历史版本降级确认；
- 版本任务与列表行匹配；
- 历史版本精确卸载和头部整体卸载；
- 多安装实例的 arch/channel/module 打分选择；
- 评论提交、截图灯箱、分享和快捷方式；
- 描述与版本列表折叠规则。

这些职责具有不同变化原因。尤其需要保护两条高风险边界：

1. 头部“整体卸载”必须先从真实已安装列表选择实例，但调用 ll-cli 时不携带版本；
2. 历史版本列表必须解析对应本地实例并按版本精确卸载。

当前两条流程与所有页面渲染混在一起，任何详情 UI 调整都需要重新审查卸载和队列
规则，回归半径过大。

## 3. 保持不变的业务契约

- 公共页面继续是 `AppDetailPage(appId, appInfo)`；
- 首帧后继续调用 `appDetailProvider(appId).loadDetail(appInfo)`；
- 页面容器继续聚合详情、安装队列、已安装应用、更新列表、发行版和网速；
- 主按钮默认安装不指定版本，更新必须走 `InstallTaskKind.update`；
- 版本列表安装才允许指定版本；
- 同版本重装和降级安装继续显式使用 `force`；
- 当前任务成功后仍以真实已安装状态决定“打开/安装”；
- 当前应用更新判断继续优先读取更新列表，并用远端/最高已安装版本比较兜底；
- 下载飞入动画继续使用详情头部安装源 Key；
- 当前安装阶段文案继续由当前 locale 和发行版画像生成；
- 详情状态条只复制 `InstallTask.commandOutput`；
- 历史版本行继续按显式版本或“无版本的最新安装/更新任务”匹配；
- 头部整体卸载继续 `includeVersion: false`；
- 历史版本卸载继续 `includeVersion: true`；
- 多实例选择继续按 arch 4 分、channel 2 分、module 1 分；
- 评论版本、评论提交反馈、截图灯箱、分享 URL、剪贴板回退和快捷方式反馈保持；
- `shouldShowDescriptionExpandButton()` 继续作为测试可访问的公共函数；
- 现有 Key、Widget 树可观察文本和无障碍语义保持。

## 4. 方案比较

### 4.1 方案 A：只把截图、描述和信息表格移出

能减少部分 UI 代码，但安装、版本、卸载、分享和评论仍全部留在 State 中，最大的
业务风险没有隔离。

### 4.2 方案 B：每个区域直接读取自己的 Provider

参数较少，但一个详情页会出现多个 Provider 订阅和副作用入口。已安装状态、队列
状态和发行版变化可能触发不同区域各自重建和各自解释，容易造成规则漂移。

### 4.3 方案 C：单一 Provider 容器 + 纯规则 + 区域组件 + 动作控制器

页面容器集中订阅全局状态并生成轻量属性；纯函数处理按钮和版本派生；区域组件只
渲染；动作控制器统一处理所有异步弹窗、队列命令和用户反馈。

**选择方案 C。** 它保持单向数据流，同时把高风险命令流程从布局代码中移出。

## 5. 目标结构

```text
app_detail_page.dart
  ├─ AppDetailPageLogic
  ├─ AppDetailPageActions
  ├─ AppDetailHeaderSection
  ├─ AppDetailContentSections
  ├─ AppDetailCommentsPanel
  └─ AppDetailVersionSection
```

目录：

```text
lib/presentation/pages/app_detail/
  app_detail_page.dart
  app_detail_page_logic.dart
  app_detail_page_actions.dart
  app_detail_header_section.dart
  app_detail_content_sections.dart
  app_detail_comments_panel.dart
  app_detail_version_section.dart
  screenshot_preview_lightbox.dart
```

## 6. 组件职责

### 6.1 `AppDetailPage`

只负责：

- 页面生命周期和首帧加载；
- 单点订阅全局 Provider；
- 保存评论版本选择和安装动画源 Key；
- 使用纯规则生成按钮状态、安装版本和更新状态；
- 组合页面区域；
- 把 Provider 的同步状态切换回调传给区域；
- 把异步业务动作委托给 `AppDetailPageActions`。

### 6.2 `AppDetailPageLogic`

只包含无副作用规则：

- 安装按钮状态；
- 是否存在可用更新；
- 最高已安装版本；
- 评论版本选项和默认选择；
- 详情状态条日志；
- 折叠版本列表；
- 版本任务与行匹配；
- 多安装实例评分。

函数通过参数接收事实，不读取 Riverpod、`BuildContext` 或全局状态，便于在多个区域
复用同一规则。

### 6.3 `AppDetailPageActions`

定位为 Presentation 异步用例编排器：

- 安装、更新、取消和打开；
- 同版本重装与降级确认；
- 下载飞入动画；
- 评论提交；
- 版本卸载和头部卸载；
- 已安装实例解析；
- 分享及剪贴板回退；
- 截图灯箱；
- 创建快捷方式。

控制器持有 `WidgetRef` 读取既有 Provider，但不长期保存 `BuildContext`；每个方法
接收本次调用上下文并在异步返回后检查 `context.mounted`。它不执行 ll-cli Shell，
只调用现有 Repository、Provider 和 `AppUninstallFlow`。

### 6.4 `AppDetailHeaderSection`

负责把已派生的按钮状态、速度、状态文案和回调传给现有
`AppDetailHeroHeader`。不读取 Provider，不重新判断安装或更新状态。

### 6.5 `AppDetailContentSections`

包含截图、描述、应用信息和加载错误等稳定展示区域：

- 截图只接收灯箱回调；
- 描述只接收折叠状态和切换回调；
- 信息表格只从详情模型生成 `AppDetailInfoEntry`；
- 不读取 Provider。

`shouldShowDescriptionExpandButton()` 移到该文件，并由原页面文件重新导出，保持
测试和外部调用兼容。

### 6.6 `AppDetailCommentsPanel`

负责评论区域语义、版本选择和现有 `AppDetailCommentSection` 的属性适配。页面持有
当前选择，Panel 只接收选择和回调。

### 6.7 `AppDetailVersionSection`

负责：

- 加载、错误、空状态和折叠列表；
- 当前/等待/历史版本行；
- 版本任务匹配；
- 安装、卸载、已安装徽章和进度按钮。

组件不执行安装或卸载，只按明确的 `onInstallVersion`、`onUninstallVersion` 回调
交给动作控制器。版本匹配与折叠规则复用 `AppDetailPageLogic`。

## 7. 状态和性能约束

- 全局 Provider 只在页面容器订阅；
- 子区域禁止导入 Application Provider；
- 页面一次计算当前应用的已安装实例和版本集合；
- `InstallMessages`、发行版和系统网速只在容器订阅一次；
- 版本列表继续使用 builder 且禁用内部滚动，复用页面主滚动；
- 截图继续使用横向 builder 和受限解码尺寸；
- 描述行数测量继续只在 `LayoutBuilder` 中基于当前宽度执行；
- 不把详情或队列复制到第二套持久状态；
- 本次不引入新的 Riverpod Notifier、GlobalKey 或事件总线。

## 8. 依赖约束

- `app_detail_page.dart` 是唯一全局状态订阅容器；
- `app_detail_page_actions.dart` 是唯一异步副作用编排入口；
- 子区域只依赖 Domain 模型、Presentation 状态和明确回调；
- 纯逻辑文件禁止导入 Flutter Widget、Riverpod 或 Repository；
- 安装/更新继续只通过 `installQueueProvider`；
- 卸载继续只通过 `AppUninstallFlow + appUninstallServiceProvider`；
- Repository 具体实现不得在页面或控制器创建。

## 9. 迁移顺序

1. 提取纯派生规则；
2. 提取头部适配区；
3. 提取截图、描述、信息和错误区；
4. 提取评论适配区；
5. 提取版本列表；
6. 提取异步动作控制器；
7. 收敛原页面为 Provider 容器；
8. 更新开发指南；
9. 运行详情页逻辑与 Widget 测试、静态分析和 Linux 构建。

迁移时不顺手修改文案或 Provider API。若发现现有业务缺陷，单独记录并另开修复提交。

## 10. 验证范围

不为拆文件新增无业务价值的测试。现有测试必须继续覆盖：

- 描述展开按钮真实行数判断；
- 最新/已安装版本折叠；
- 版本安装、同版本重装和降级；
- 版本任务进度与行匹配；
- 头部安装、更新、打开和取消；
- 详情状态条日志复制；
- 历史版本卸载和头部整体卸载；
- 多已安装实例选择；
- 评论、截图、分享和快捷方式已有交互；
- 结构化错误展示。

完成标准：

- 原页面只保留生命周期、Provider 聚合、局部选择状态和区域组合；
- 纯逻辑无 Flutter/Riverpod 依赖；
- 子区域无 Provider 依赖；
- 高风险卸载语义保持不变；
- 详情页相关测试全部通过；
- `flutter analyze` 无错误和警告；
- Linux debug 构建通过。
