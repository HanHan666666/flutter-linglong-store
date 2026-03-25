# 全局字体语义重映射设计

## 背景

Flutter 商店当前的文字体系已经形成了两套互相打架的规则：

1. `AppTextStyles` 里定义了一套看似完整的字号层级。
2. `ThemeData.textTheme` 又把 `bodyMedium/bodySmall/titleMedium` 等语义映射到更小的实际字号。
3. 页面和组件里还散落着大量 `fontSize: 12/13/14` 的局部硬编码。

结果是：

1. 语义名和实际视觉大小不一致，开发者很难凭名称判断最终效果。
2. 主内容区、详情页、卡片、壳层的文字密度普遍偏小。
3. 同一类信息在不同页面上会出现 `12px/13px/14px` 混用，缺少统一阅读节奏。
4. 只改某个页面无法根治问题，因为主题层和局部硬编码会继续相互覆盖。

本次设计的唯一视觉基准是用户提供的左侧参考应用截图，不再以旧版 Rust 商店源码为基准。

## 目标

1. 重新定义 Flutter 商店的全局文字语义映射，让语义名和实际视觉大小一致。
2. 把当前偏小的主内容文字整体提升到桌面端更易读的密度。
3. 明确 `TextTheme`、`AppTextStyles`、局部特例三者的职责边界。
4. 为壳层、组件层、页面层提供统一整改规则，避免继续写散乱小字号。
5. 输出可执行整改计划，支持多名 AI worker 并行落地。

## 非目标

1. 本次不引入新的设计风格或全量重做布局。
2. 不在本次方案中切换到自定义字体文件。
3. 不追求 100% 机械复刻某个现有应用的数值，只追求相同阅读密度和层级关系。
4. 不在本次设计中处理颜色、圆角、间距以外的大规模视觉改版。

## 现状分析

### 1. 主题语义映射过小

当前 `AppTextStyles` 中：

1. `body = 14`
2. `bodyMedium = 16`
3. `caption = 12`
4. `tiny = 10`

但当前 `TextTheme` 中：

1. `titleMedium = 16`
2. `bodyLarge = 14`
3. `bodyMedium = 12`
4. `bodySmall = 10`

这会直接导致大量使用 `Theme.of(context).textTheme.bodyMedium` 的组件实际只显示 `12px`。

### 2. 当前仓库小字号使用面广

本次排查结果显示，高频问题主要集中在三类：

1. `AppTextStyles.caption`
2. `Theme.textTheme.bodyMedium`
3. `Theme.textTheme.bodySmall`

典型文件分布在：

1. 壳层：`title_bar.dart`、`sidebar.dart`
2. 通用组件：`app_card.dart`、`download_manager_dialog.dart`、`empty_state.dart`、`error_state.dart`、`linglong_process_panel.dart`
3. 页面：`app_detail_page.dart`、`recommend_page.dart`、`setting_page.dart`、`update_app_page.dart`

### 3. 局部硬编码破坏全局一致性

当前仓库存在多处 `fontSize: 12/13/14` 的直接写法。即使主题层修正，这些地方也不会自动跟随。

因此本次整改必须同时做三件事：

1. 修正主题语义映射
2. 修正 `AppTextStyles`
3. 清理关键页面和组件上的局部硬编码

## 方案比较

### 方案 A：只改 `TextTheme`

做法：

1. 仅在 `theme.dart` 中调大 `TextTheme`
2. 保留 `AppTextStyles` 和局部 `fontSize` 现状

优点：

1. 改动快
2. 主题引用点能立刻变大

缺点：

1. `AppTextStyles` 与 `TextTheme` 仍然继续漂移
2. 写死字号的组件和页面不会自动修正
3. 许多固定高度控件会出现文字变大但容器不跟的问题

结论：不采用。

### 方案 B：重映射 `TextTheme + AppTextStyles`，再按壳层/组件层/页面层扫一遍

做法：

1. 统一重写 `TextTheme` 和 `AppTextStyles` 的字号语义
2. 将通用组件和关键页面逐层扫点
3. 把散落的小字号硬编码收敛到新语义体系

优点：

1. 能从源头修正语义和视觉的不一致
2. 改完后后续页面更容易复用统一规则
3. 风险可控，可按写入范围并行拆分执行

缺点：

1. 联动面较大
2. 需要同步检查固定高度和紧凑布局控件

结论：采用本方案。

### 方案 C：新建一套全新 Typography API，再逐步迁移

做法：

1. 引入新的命名体系
2. 旧的 `AppTextStyles` 保留一段过渡期

优点：

1. 长期最干净

缺点：

1. 迁移期会出现两套体系并存
2. 当前开发阶段收益不如直接纠偏现有体系

结论：本次不采用。

## 选型

采用方案 B：重映射 `TextTheme + AppTextStyles`，并按壳层、组件层、页面层做全仓整改。

原因：

1. 这是唯一既能修正根因又能兼顾落地效率的方案。
2. 当前项目仍在开发阶段，可以接受较大范围但结构化的视觉纠偏。
3. 方案天然适合拆给多个 worker 并行执行。

## 设计原则

### 1. 阅读密度原则

1. 主阅读正文不低于 `16px`。
2. 常规说明文字不低于 `14px`。
3. `12px` 只保留给标签、角标、极次要元信息。
4. `10px` 仅允许用于极小状态标识，禁止承载主要可读信息。

### 2. 语义一致原则

1. 同一语义名称必须稳定对应同一视觉级别。
2. 页面正文不能再借用 `caption/tiny`。
3. 主按钮、卡片标题、说明文字、元信息必须各归其位，禁止互相串层。

### 3. 桌面端可读性原则

1. 行高统一维持 `1.45 ~ 1.5`。
2. 放大字号时同步复核固定高度容器。
3. 优先保证桌面窗口 `1200x800` 下的阅读舒适度，再兼顾窄窗口。

### 4. 特例最小化原则

1. 默认优先走 `Theme.textTheme` 和 `AppTextStyles`。
2. 只有非常明确的视觉特例才允许手写 `fontSize`。
3. 继续保留 raw `fontSize` 的地方必须能说明它不是通用语义。

## 新的文字语义规范

### 1. TextTheme 目标映射

| Flutter 语义 | 目标字号 | 字重 | 使用场景 |
|---|---:|---:|---|
| `displayLarge` | 32 | 700 | 启动页主标题 |
| `headlineLarge` | 28 | 700 | 应用详情主标题、页面 Hero 标题 |
| `headlineMedium` | 24 | 600 | 大区块标题 |
| `headlineSmall` | 22 | 600 | 次级区块标题 |
| `titleLarge` | 20 | 600 | 页面主标题、重要列表标题 |
| `titleMedium` | 18 | 600 | 弹窗标题、分组标题、强调标题 |
| `titleSmall` | 16 | 500 | Tab、列表主文字、设置项主标签 |
| `bodyLarge` | 16 | 400 | 正文、应用介绍、设置页正文 |
| `bodyMedium` | 14 | 400 | 菜单文字、搜索输入、卡片描述、通用说明 |
| `bodySmall` | 13 | 400 | 版本、仓库、辅助元信息 |
| `labelLarge` | 14 | 500 | 常规按钮文字 |
| `labelMedium` | 13 | 500 | 紧凑按钮、次级操作、Badge 文本 |
| `labelSmall` | 12 | 500 | 标签、胶囊、极小强调信息 |

### 2. AppTextStyles 目标映射

| `AppTextStyles` 字段 | 目标字号 | 字重 | 职责 |
|---|---:|---:|---|
| `display` | 32 | 700 | 超大标题 |
| `title1` | 28 | 700 | 页面级主标题 |
| `title2` | 24 | 600 | 分区标题 |
| `title3` | 20 | 600 | 组件级标题 |
| `body` | 16 | 400 | 主正文 |
| `bodyMedium` | 14 | 400 | 常规说明、菜单、输入 |
| `caption` | 13 | 400 | 辅助说明、元信息 |
| `tiny` | 12 | 400 | 标签、极小提示 |
| `menuActive` | 16 | 500 | 展开态侧边栏菜单文字 |

### 3. 语义边界

正式约束如下：

1. `bodyLarge` / `AppTextStyles.body` 只承载主内容正文。
2. `bodyMedium` / `AppTextStyles.bodyMedium` 承载常规说明，不再承载过小元信息。
3. `bodySmall` / `AppTextStyles.caption` 只承载次级元信息。
4. `labelSmall` / `tiny` 只用于标签、胶囊和角标，不得承载详情页或设置页正文。

## 分层整改规范

### 1. 壳层

范围：

1. `title_bar.dart`
2. `sidebar.dart`

规则：

1. 标题栏应用名提升到 `16px` 级别。
2. 搜索框输入和 placeholder 统一到 `14px` 语义。
3. 展开态侧边栏菜单文字提升到 `16px`。
4. 侧边栏菜单项高度从当前紧凑值适度上调到 `40px` 左右。
5. 折叠态图标按钮不因字号调整改变交互热区。

### 2. 通用组件层

范围：

1. `app_card.dart`
2. `download_manager_dialog.dart`
3. `empty_state.dart`
4. `error_state.dart`
5. `linglong_process_panel.dart`
6. `app_detail_comment_section.dart`
7. `category_filter_header.dart`

规则：

1. 卡片标题统一使用 `16px` 级别。
2. 卡片描述、列表说明统一使用 `14px`。
3. 版本、时间、下载速度、补充提示统一使用 `13px`。
4. 对话框标题、分组标题统一使用 `18~20px`。
5. 标签、胶囊、Badge 文本统一压到 `12px`。

### 3. 页面层

范围：

1. `app_detail_page.dart`
2. `recommend_page.dart`
3. `search_list_page.dart`
4. `setting_page.dart`
5. `update_app_page.dart`
6. `all_apps_page.dart`
7. `custom_category_page.dart`
8. `launch_page.dart`

规则：

1. 应用详情主标题提升到 `28px`。
2. 详情页应用介绍正文提升到 `16px`。
3. 详情页元信息统一收敛到 `13~14px`。
4. 推荐页、搜索页、设置页的说明文字统一收敛到 `14px` 级别。
5. 页面中的 `fontSize: 12/13` 必须逐项判断是否真的是极次要信息，不能保留习惯性小字。

## 实施边界与约束

### 1. 允许保留 raw `fontSize` 的场景

1. 自定义截图预览叠层上的极小元信息
2. Badge / Tag / 胶囊
3. 极小占位水印或调试信息

### 2. 不允许继续保留 raw `fontSize` 的场景

1. 页面正文
2. 卡片描述
3. 搜索输入
4. 设置说明
5. 详情页元信息
6. 空状态和错误态描述

### 3. 代码约束

1. 新增或调整样式时优先复用 `Theme.of(context).textTheme.*`。
2. `AppTextStyles` 只用于跨页面复用的稳定样式，不用来替代所有局部微调。
3. 修改字体后如果容器高度不足，必须同步修改布局，不允许让文字裁切。

## 风险与应对

### 风险 1：固定高度容器被撑破

典型区域：

1. 侧边栏菜单项
2. 标题栏搜索框
3. 卡片按钮
4. 对话框紧凑行

应对：

1. 逐层整改时同步检查高度
2. 对高风险控件增加 widget test 或 golden

### 风险 2：元信息层级被放大过头

应对：

1. 严格把 `13px` 作为次级元信息层
2. 不把所有文字一律升到 `16px`

### 风险 3：局部硬编码遗漏导致体系继续漂移

应对：

1. 在整改过程中强制扫描 `fontSize: 12/13/14`
2. 把剩余允许存在的特例列入验收清单

## 验收标准

### 视觉验收

1. 主内容区不再出现“正文像注释”的观感。
2. 应用详情页首屏、推荐页应用卡片、侧边栏、标题栏搜索框的阅读密度接近用户参考截图。
3. 主标题、正文、说明、元信息、标签之间的层级关系清晰稳定。

### 技术验收

1. `theme.dart` 中 `TextTheme` 与 `AppTextStyles` 语义一致。
2. 主要页面不再依赖散乱的 `12/13px` 硬编码承载正文和说明文字。
3. 放大字体后无明显截断、垂直不居中、按钮被撑坏的问题。

### 过程验收

1. 工作拆分能按壳层、组件层、页面层并行推进。
2. 每个任务都能单独提交并单独验证。
3. 设计规范与执行计划保持一致。

## 后续建议

1. 本次整改完成后，应补一轮 typography 相关 golden 基线。
2. 后续如果仍存在“同 px 视觉偏小”的问题，再单独评估字体族对齐，不与本次字号语义整改混做。
