# 应用详情页版本历史展示说明

## 目标
- 解决应用详情页版本历史使用大下拉列表时的展开卡顿和桌面端滚动体验差问题。
- 将“选择历史版本安装”改为详情页内常驻展示，减少一次性弹出超长 overlay 带来的布局和重绘压力。
- 保持当前版本历史业务语义不变：仍然展示真实后端版本列表，仍然支持安装指定版本。

## 现状问题
- 大量版本集中在下拉面板中展开时，桌面端会出现明显的首帧卡顿。
- 超长 overlay 的可读性差，用户需要在浮层中滚动查找目标版本，信息密度过高。
- 原生下拉更适合少量离散选项，不适合“历史版本浏览 + 安装动作”这种半列表型场景。

## 新方案
- 版本历史改为应用详情页中的常驻区域，不再使用大下拉 UI。
- 默认展示前 `8` 个版本卡片。
- 当版本数超过 `8` 个时，区域底部显示“展开全部 / 收起”按钮。
- 已安装版本显示只读徽标；未安装版本显示安装按钮，继续复用现有版本安装链路。

## 布局约束
- 使用横向排布的卡片式布局，桌面大宽度下优先一行展示更多版本。
- 通过响应式列数控制宽度：
  - 宽屏约 4 列
  - 中屏约 3 列
  - 较窄布局约 2 列
  - 极窄布局退化为 1 列
- 卡片内只展示高频信息：
  - 版本号
  - 发布时间
  - 包大小
  - 已安装状态 / 安装按钮

## 性能原则
- 禁止再把完整版本历史塞进桌面下拉 overlay。
- 折叠态只渲染前 `8` 个版本，避免首屏详情页创建过多版本节点。
- 版本区组件只消费页面层提供的已排序版本数据，不在组件内再做仓库请求或复杂排序。
- 页面层只负责传递 `versions / installedVersions / retry / installVersion`，展示细节收敛到独立组件，避免 `app_detail_page.dart` 持续膨胀。

## 组件职责
- [app_detail_page.dart](/home/han/linglong-store/flutter-linglong-store/.worktrees/app-detail-comments/lib/presentation/pages/app_detail/app_detail_page.dart)
  - 负责拉取版本数据
  - 负责提供重试和安装回调
- [app_detail_version_section.dart](/home/han/linglong-store/flutter-linglong-store/.worktrees/app-detail-comments/lib/presentation/widgets/app_detail_version_section.dart)
  - 负责版本卡片布局
  - 负责展开/收起交互
  - 负责错误态、空态、加载态展示

## 测试覆盖
- Widget 测试覆盖：
  - 默认仅展示前 8 个版本
  - 点击“展开全部”后展示完整版本
  - 点击“收起”后回到前 8 个版本
  - 未安装版本点击安装按钮时能触发回调
