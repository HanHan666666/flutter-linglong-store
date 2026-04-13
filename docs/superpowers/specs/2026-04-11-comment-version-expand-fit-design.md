# Comment Version Expand Fit Design

**Date:** 2026-04-11

## Background

应用详情页评论区的“关联版本”当前使用横向胶囊按钮展示候选版本，组件实现在 `lib/presentation/widgets/app_detail_comment_section.dart`。现有折叠逻辑只根据 `versionOptions.length > 8` 决定是否展示“展开全部 / 收起”，并在折叠态固定 `take(8)`。

这个规则会产生两个错误行为：
- 明明所有版本胶囊在当前宽度下都能放进同一行，界面仍然隐藏后续版本并显示“展开全部”。
- 点击“展开全部”后，新增项依然全部落在同一行，视觉上没有任何展开效果，交互反馈失真。

本次优化需要让评论区版本折叠逻辑基于真实布局结果，而不是机械的固定数量阈值。

## Confirmed Requirements

- 只调整评论区“关联版本”胶囊的折叠判断与展示逻辑，不修改评论输入、评论列表、提交流程或其它详情页区块。
- 如果全部候选版本在当前可用宽度下能够完整放进一行，则直接全部展示，不显示“展开全部”。
- 如果全部候选版本无法放进一行，则默认折叠，只展示首行可见版本，并显示“展开全部”。
- 点击“展开全部”后必须出现明确的可见新增内容；点击“收起”后恢复折叠态。
- 展开判断必须随当前宽度变化而变化，不能继续只依赖候选数量。
- 需要补充文档与 widget 测试覆盖该行为。

## Design

### Layout Measurement Strategy

评论区版本胶囊组件继续由 `AppDetailCommentSection` 内部渲染，但折叠态可见项的计算改为基于真实布局宽度。

实现上，在版本胶囊区域外层继续使用 `LayoutBuilder` 获取当前可用宽度；新增一个轻量的首行计算函数，按以下输入计算：
- 当前宽度约束
- 版本文案列表
- 胶囊的水平 padding、边框与文本样式
- 胶囊之间的 `spacing`

该函数按当前 UI 样式逐个累加首行宽度，产出：
- `visibleVersionsInCollapsedState`：折叠态应展示的版本列表
- `hasHiddenVersions`：是否存在真实被折叠的版本

### Collapsed / Expanded Behavior

组件状态继续保留 `_isVersionExpanded`，但行为调整为：
- 当 `hasHiddenVersions == false` 时：
  - 始终展示全部版本
  - 不渲染“展开全部 / 收起”按钮
- 当 `hasHiddenVersions == true` 且 `_isVersionExpanded == false` 时：
  - 只展示 `visibleVersionsInCollapsedState`
  - 渲染“展开全部”按钮
- 当 `hasHiddenVersions == true` 且 `_isVersionExpanded == true` 时：
  - 展示全部版本
  - 按钮文案切换为“收起”

这样可以保证按钮只在“真实存在隐藏项”时出现，并保证点击展开后一定会看到新增版本。

### Selection Behavior

版本胶囊的选中与回调逻辑保持现状：
- 点击胶囊后仍通过 `_localSelectedVersion` 与 `onVersionChanged` 同步选中值。
- 已选中版本如果位于折叠态隐藏区，不额外插队到首行，也不修改首行布局顺序。
- 用户展开后，隐藏区中的已选中版本仍应保持原有选中态。

此设计优先保证折叠规则与布局稳定，不为了暴露隐藏选中项而破坏首行真实排布。

### Scope Boundaries

本次改动只收敛在评论区 UI 组件与对应测试/文档：
- 不改 `AppDetailProvider`、Repository、API 数据流。
- 不调整“默认优先展示前 8 个候选版本”的文档描述为新的数量规则，而是将规则修正为“默认展示首行可见版本，只有真实溢出时才显示展开入口”。
- 不引入新的全局状态或复用层抽象，避免为单一场景过度设计。

## Testing

需要补充/调整 `test/widget/presentation/widgets/app_detail_comment_section_test.dart`，至少覆盖以下场景：

- 宽度足够时：
  - 提供超过 8 个短版本文案
  - 所有胶囊都能显示在一行内
  - “展开全部”按钮不存在
- 宽度不足时：
  - 提供一组会真实溢出的版本文案
  - 折叠态仅展示首行可见项
  - “展开全部”按钮存在
  - 点击后新增隐藏项出现，按钮切换为“收起”
- 选择行为回归：
  - 展开后选择非首行项并提交，提交值仍为该版本

## Risks

- 首行可见项计算必须与实际胶囊样式保持一致；若 padding、字体或边框后续调整，测量逻辑也要同步调整，否则可能出现“计算认为能放下，但实际换行”的偏差。
- widget test 需要通过受控宽度约束稳定复现“一行可容纳 / 不可容纳”两种场景，否则测试会对默认测试窗口宽度过于敏感。
- 当前组件使用 `Wrap` 渲染，折叠态的计算必须严格以单行宽度为目标，不能误把第二行布局结果当成折叠态可见项。