# Sidebar Local Config Design

**Date:** 2026-03-22

## Background

当前 Flutter 侧边栏的动态菜单来自 `/app/sidebar/config`，但后端接口仅返回 `code/name/icon/activeIcon/...`，没有语言字段，也没有按 locale 切换菜单名称的能力。Flutter 现状直接渲染 `menuName`，导致英文环境下动态菜单和自定义分类页标题仍显示中文。

同时，接口返回的 base64 图标与当前 Flutter 侧边栏的视觉风格不一致。本期需求要求暂时不再使用接口图标，改为 Flutter 本地选择与现有设计更一致的图标。

## Confirmed Requirements

- 将动态菜单配置暂时固化到 Flutter 前端，本期以本地配置为唯一展示来源
- 保留请求 `/app/sidebar/config` 的能力和统一接入点，未来若后端补齐完整配置，可低成本切回接口驱动
- 动态菜单的展示信息统一基于 `menuCode` 管理，至少包含：
  - 本地化标题
  - 默认图标
  - 选中图标
- 侧边栏动态菜单与自定义分类页标题必须共用同一份展示映射，避免一处英文、一处中文
- 不再使用接口返回的 `icon/activeIcon` 参与 UI 渲染
- 已知菜单 code 采用本地配置；未知 code 需要可回退，避免未来服务端新增菜单时直接崩溃
- 改动需要尽量收敛，不影响近期已完成的侧边栏英文宽度与单行展示修复

## Design

### Source of Truth

- 新增一个前端侧边栏动态菜单展示配置层，作为本期动态菜单的唯一展示来源
- 配置项按 `menuCode` 建模，封装：
  - `menuCode`
  - `localizedLabel(AppLocalizations)`
  - `icon`
  - `selectedIcon`
  - `sortOrder`
  - 可选的兜底后端名称
- 本期 provider 默认返回本地配置生成的菜单列表，不再以接口响应作为展示数据来源
- 为未来切回接口保留收口点：
  - 保留现有 `sidebarConfigProvider`
  - 将“本地模式 / 接口模式”的选择集中在 provider 内部，而不是散落到 Widget
  - 本期先固定使用本地模式，但实现结构上允许后续在 provider 中切换数据源

### UI Mapping

- 侧边栏动态菜单项不再读取 `menu.menuName` 和 `menu.menuIcon`
- 动态菜单文案改为读取本地展示配置中的 `localizedLabel`
- 动态菜单图标改为读取本地展示配置中的 `icon / selectedIcon`
- 已知 code 先覆盖以下菜单：
  - `office`
  - `system`
  - `dev`
  - `entertainment`
- 如果本地配置中不存在某个 `menuCode`：
  - 标签回退到接口 `menuName`
  - 图标回退到统一的通用分类图标
  - 仍允许导航到 `/custom_category/:code`

### Custom Category Parity

- `CustomCategoryProvider` 中查找分类信息时，名称和图标要走与侧边栏相同的本地展示映射
- 自定义分类页头部标题必须与侧边栏中的该菜单标签一致
- `appCount`、`categoryIds`、排序/过滤规则仍来自当前菜单配置数据，不改变业务查询链路

### Data Strategy

- 本地配置中保留当前已知动态菜单顺序和 code，确保页面结构与现网保持一致
- 接口请求能力保留，但本期不依赖接口返回的名称和图标
- 若后端未来补齐多语言和设计可用图标，只需要在 provider 层切换数据源或做 merge，不需要重写 sidebar 和 category 页面

### Testing

- 新增 widget / unit 测试覆盖：
  - 英文环境下动态菜单显示本地英文文案
  - 中文环境下动态菜单显示本地中文文案
  - 自定义分类页标题与侧边栏菜单标签一致
  - 未知 `menuCode` 时走名称与通用图标兜底
- 回归已有侧边栏展开宽度与英文单行展示测试，确认本次改动不引入换行回归

## Risks

- 当前仓库存在较多未生成代码与全局 analyze 错误，无法将全量 `flutter analyze` 作为本次改动的有效回归基线
- 若未来后端菜单顺序或 code 集发生变化，本地配置需要同步维护；因此需要将配置集中在单一文件，降低维护成本
