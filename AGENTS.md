# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 文档指引
/home/han/linglong-store/linglong-server 这个是后端代码，你在对接接口的时候需要参考
/home/han/linglong-store/rust-linglong-store 这里是旧版rust商店，你要参考这里的逻辑


## 重点（极其重要）
- 每个需求的开发必须开git worktree
- 所有的业务细节都要落实到文档里面去，详细的细节文档，docs目录
- 当前项目要求绝对的高性能，高UI响应速度。
- 每开发一个功能点就进行一次commit
- Git commit 必须遵循 Conventional Commits，统一使用 `type: 简短描述`，不要再写无类型前缀的自然语句提交信息。
- 在接到用户的任务的时候，先不要着急开始修改代码，要先分析需求，分析代码，列举解决方案，
- 详细的向用户说明你的思路，和你打算如何实现这个需求。
- 要分析整个项目的架构，一切都要从整个项目的角度入手，不能直接看完一个文件就写代码。
- 先问清楚、绝对不允许猜测：遇到需求或现状不确定时，先明确提问，不要主观假设；方案需先得到用户确认再开工。
- 每一处代码修改都要有必要的注释
- 先方案后编码：先梳理背景/现状 → 列备选方案（含改动面、影响范围、取舍理由）→ 让用户确认 → 再动手。**只有在用户确认你的方案后，才开始动手写代码, 不然你很快就会被关机，更换下一个AI，一定要小心。**
- 统一入口：能收敛的业务逻辑要集中封装（如卸载流程用 `useAppUninstall`），避免在多个页面/组件里写重复弹窗或副作用。
- 完成功能后，将关键经验和约定同步到本指南，方便后续遵循。
- 在编写代码前先**明确用户需求并确认方案**；优先**复用已有的 hooks/store**，避免新增零散的 `invoke` 或 `ll-cli` 调用。
- 保持 ll-cli 的使用**最小化且可预测**：优先使用现有的 **Rust 命令与 IPC 事件**，而不是新增 Shell 调用。


## 代码要求
1. 代码要求结构清晰，不应付事情，长远维护考虑，遵循设计模式最佳实践，遵循项目代码风格。
2. 保证代码逻辑严谨，整洁，结构清晰，容易理解和维护，不要过度设计增加系统复杂性
3. 工程优化，以工程化，能安全正常使用不出错为主，考虑周全，遵循越复杂越容易出错，越简单越容易可控原则，一个健康的系统 越简单越可控
4. 遵循合理的组件化设计原则，要考虑组件复用性的可能。
5. 在你发现架构不合理的时候，要及时的提出来。
6. 编写代码的过程中，必须牢记以下几个原则：
    - 开闭原则（Open Closed Principle，OCP）
    - 单一职责原则（Single Responsibility Principle, SRP）
    - 里氏代换原则（Liskov Substitution Principle，LSP）
    - 依赖倒转原则（Dependency Inversion Principle，DIP）
    - 接口隔离原则（Interface Segregation Principle，ISP）
    - 合成/聚合复用原则（Composite/Aggregate Reuse Principle，CARP）
    - 最少知识原则（Least Knowledge Principle，LKP）或者迪米特法则（Law of  Demeter，LOD）

## 八荣八耻
1.以暗猜接口为耻，以认真查阅为荣
2.以模糊执行为耻，以寻求确认为荣
3.以盲想业务为耻，以人类确认为荣
4.以创造接口为耻，以复用现有为荣
5.以跳过验证为耻，以主动测试为荣
6.以破坏架构为耻，以遵循规范为荣
7.以假装理解为耻，以诚实无知为荣
8.以盲目修改为耻，以谨慎重构为荣

Shame in guessing APIs, Honor in careful research.
Shame in vague execution, Honor in seeking confirmation.
Shame in assuming business logic, Honor in human verification.
Shame in creating interfaces, Honor in reusing existing ones.
Shame in skipping validation, Honor in proactive testing.
Shame in breaking architecture, Honor in following specifications.
Shame in pretending to understand, Honor in honest ignorance.
Shame in blind modification, Honor in careful refactoring.

## 根据需要，必须严格遵守这些skill
### 核心开发技能
brainstorming - 创意工作前必须使用，探索用户意图和设计
writing-plans - 编写实施计划
executing-plans - 执行实施计划
test-driven-development - 测试驱动开发
systematic-debugging - 系统化调试
verification-before-completion - 完成前验证
requesting-code-review - 请求代码审查
receiving-code-review - 接收代码审查反馈
subagent-driven-development - 子代理驱动开发
dispatching-parallel-agents - 并行代理调度
using-git-worktrees - 使用 git worktrees
finishing-a-development-branch - 完成开发分支
### Flutter 专项技能
flutter-architecting-apps - Flutter 应用架构
flutter-building-layouts - Flutter 布局构建
flutter-building-forms - Flutter 表单构建
flutter-managing-state - Flutter 状态管理
flutter-testing-apps - Flutter 应用测试
flutter-animating-apps - Flutter 动画
flutter-theming-apps - Flutter 主题
flutter-localizing-apps - Flutter 国际化
flutter-caching-data - Flutter 数据缓存
flutter-handling-concurrency - Flutter 并发处理
flutter-handling-http-and-json - Flutter HTTP 和 JSON 处理
flutter-implementing-navigation-and-routing - Flutter 导航和路由
flutter-working-with-databases - Flutter 数据库
flutter-embedding-native-views - Flutter 嵌入原生视图
flutter-interoperating-with-native-apis - Flutter 与原生 API 互操作
flutter-building-plugins - Flutter 插件构建
flutter-adding-home-screen-widgets - Flutter 主屏幕小部件
flutter-improving-accessibility - Flutter 无障碍
flutter-reducing-app-size - Flutter 应用大小优化
flutter-setting-up-on-linux - Flutter Linux 环境设置
flutter-setting-up-on-macos - Flutter macOS 环境设置
flutter-setting-up-on-windows - Flutter Windows 环境设置

## 项目概览
- 本仓库是玲珑应用商店从旧版 Tauri/React 迁移到 Flutter 的实现，目标是 **UI 像素级一致** 与 **业务逻辑等价**。
- 仅面向 Linux 桌面端，核心系统能力通过 `ll-cli` 完成，必要时使用 Rust FFI（见 `lib/rust/`）。
- 详细迁移背景与对照见：`/home/han/linglong-store/flutter-linglong-store/docs/01-migration-plan.md`。

## 常用命令
```bash
# 开发运行（Linux）
flutter run -d linux

# 生产构建
flutter build linux --release

# 代码生成（Freezed/Retrofit/Riverpod）
dart run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 全量测试
flutter test

# 单测/组件/Golden/集成测试（按目录）
flutter test test/unit/
flutter test test/widget/
flutter test test/golden/
flutter test integration_test/

# 运行单个测试文件（示例）
flutter test test/unit/core/format_utils_test.dart

# Profile 性能验证（建议）
flutter run -d linux --profile

# 打包脚本
time ./build/package-deb.sh
./build/package-rpm.sh
./build/package-appimage.sh
```

## Git Commit 规范
- 每个功能点、修复点、文档点各自单独提交，不要把无关改动混在一个 commit 里。
- 提交信息统一使用 `type: 描述`，`type` 小写，后面跟英文冒号和一个空格。
- 描述优先写中文，要求简短、明确、可直接看出本次变更目的，不写空泛语句。
- 推荐类型：`feat:` 新功能，`fix:` 缺陷修复，`refactor:` 重构，`docs:` 文档，`test:` 测试，`chore:` 杂项维护。
- 单个 commit 只表达一个主目的；如果同时改代码和文档，且文档不是代码变更的必要组成部分，拆成两个 commit。
- 提交信息不要带无意义前缀或编号，不要写成长段说明，不要把多件事并列塞进同一标题。
- 与仓库现有历史对齐，优先使用 `feat: ...`、`fix: ...`、`refactor: ...` 这种格式；像 `add memory optimization documentation`、`fix app card primary button text color` 这类无类型前缀写法后续不再使用。
- 示例：
  - `feat: 完善取消安装功能，迁移 Rust 版本实现`
  - `fix: 修复安装按钮文字颜色错误`
  - `refactor: 统一应用列表卡片状态逻辑`
  - `docs: 补充内存优化设计文档`

## 架构与模块（高层）
整体为分层架构（依赖方向：Presentation → Application → Domain ← Data ← Platform）：
- **Presentation**：页面与通用组件，Riverpod Provider 读取状态并渲染 UI。
- **Application**：业务编排（Controllers/Services/Providers），负责启动流程、安装队列、更新检查等。
- **Domain**：纯模型与 Repository 接口（Freezed 模型不可变）。
- **Data**：Repository 实现、API/CLI 数据源与输出解析（如 `cli_output_parser`）。
- **Platform**：`ll-cli` 执行器、进程管理、窗口管理、单实例、可选 Rust FFI。

关键入口与配置：
- 入口初始化（单实例、窗口、日志、存储、语言）在 `main.dart`。
- 路由使用 `go_router`，集中在 `core/config/routes.dart`。
- 设计与目录结构详见：`/home/han/linglong-store/flutter-linglong-store/docs/02-flutter-architecture.md`。

## 关键业务约束（迁移一致性）
- **启动流程**：环境检测 → 已安装列表 → 更新检查 → 安装队列恢复 → 进入首页；失败必须可诊断。
- **安装队列**：同一时刻仅允许 1 个任务执行；失败/取消需区分；完成后刷新已安装、更新与列表缓存。
- **KeepAlive**：页面 LRU 缓存上限 10；隐藏页面必须暂停滚动监听/自动补页/轮询等副作用；恢复时仅轻量刷新。
- **分页与缓存**：列表页统一分页与自动补页策略，缓存 key 必须包含 locale，seed 数据位于 `assets/seeds/`。
- **UI 性能**：列表必须用 builder；`build` 中禁止重计算/解析/IO；卡片组件不要直接订阅多个全局 Provider，应由页面聚合后下发轻量 props。

时序与状态机参考：`/home/han/linglong-store/flutter-linglong-store/docs/07-runtime-sequence-and-state-diagrams.md`。

## 测试与质量门禁（硬性要求）
- 测试分层：单元 → Widget → Golden → 集成 → MCP UI 驱动。
- 目录约定：`test/unit/`、`test/widget/`、`test/golden/`、`test/integration/`、`test/mcp/`。
- 覆盖目标（按规范）：单元测试行覆盖率 ≥ 90%，核心组件/核心页面 100% 场景覆盖。
- 发布门禁：`flutter analyze` 0 error/0 warning + 关键测试通过 + 性能/内存指标达标。

详见：`/home/han/linglong-store/flutter-linglong-store/docs/06-testing-and-performance-spec.md`。

## UI 规范入口
- 设计令牌与布局/组件/页面规范：`/home/han/linglong-store/flutter-linglong-store/docs/03a-ui-design-tokens.md` ~ `03d-ui-pages.md`。

## 迁移对照与限制
- 功能与 UI 需与旧版对齐，避免引入新功能或改动行为语义。
- 对应关系与风险评估见：`/home/han/linglong-store/flutter-linglong-store/docs/01-migration-plan.md`。

## 无障碍与屏幕阅读器（Accessibility）

本项目已建立完整的无障碍支持体系，位于 `lib/core/accessibility/`。**所有页面和组件开发必须遵循以下约定。**

### 核心模块

| 模块 | 文件 | 职责 |
|------|------|------|
| `A11yButton` | `a11y_semantics.dart` | 无障碍按钮，自动提供 `Semantics(button: true)` + 最小 48×48 交互尺寸 |
| `A11yIconButton` | `a11y_semantics.dart` | 无障碍图标按钮，内部图标用 `ExcludeSemantics` 包裹 |
| `A11yListItem` | `a11y_semantics.dart` | 无障碍列表项，使用 `MergeSemantics` 合并内部子组件语义 |
| `A11yTab` | `a11y_semantics.dart` | 无障碍 Tab，支持 `selected` 状态标注 + 48px 高度 |
| `A11yCard` | `a11y_semantics.dart` | 无障碍卡片，支持 `label` 和 `hint` 语义 |
| `A11yFocusScope` | `a11y_focus_traversal.dart` | 焦点范围隔离，防止焦点泄漏到背景层 |
| `ReadingOrderTraversalPolicy` | `a11y_focus_traversal.dart` | Tab 遍历策略：从上到下、从左到右 |
| `A11yKeyboardHandler` | `a11y_shortcuts.dart` | 全局键盘快捷键（Enter/Space 激活、Escape 关闭） |
| `A11yDirectionalNavigation` | `a11y_shortcuts.dart` | 方向键导航 wrapper，用于列表/TabBar 等 |
| `A11yText` / `clampTextScaler` | `a11y_text_scaler.dart` | 无障碍文本，字体缩放限制在 0.8x ~ 1.5x 安全范围 |

### 开发约定

#### 1. 装饰性图标必须排除语义

所有纯装饰性图标（默认图标、错误图标、加载图标等）必须用 `ExcludeSemantics` 包裹，避免屏幕阅读器朗读无意义内容：

```dart
// ✅ 正确
ExcludeSemantics(
  child: Icon(Icons.apps, size: size * 0.5),
)

// ❌ 错误：屏幕阅读器会朗读 "apps icon"
Icon(Icons.apps, size: size * 0.5),
```

#### 2. 骨架屏/加载状态必须标注

骨架屏和加载 shimmer 必须使用 `Semantics(label: l10n.loading)` 包裹，让屏幕阅读器知道当前处于加载状态：

```dart
Semantics(
  label: l10n.loading,
  child: Shimmer.fromColors(...),
)
```

#### 3. 列表/网格区域必须标注

列表和网格容器必须使用 `Semantics` 标注区域用途，使用 `l10n.a11yAppListArea` 等语义标签：

```dart
Semantics(
  label: l10n.a11yAppListArea,
  child: CustomScrollView(...),
)
```

#### 4. 错误信息必须支持复制和无障碍

错误信息展示时必须：
- 使用 `Tooltip` 悬浮显示完整内容
- 提供蓝色「复制」按钮（`TextButton`），支持 Tab 聚焦和 Enter/Space 激活
- 使用 `Semantics` 标注按钮用途，屏幕阅读器可正确识别

#### 5. 按钮/卡片/列表项使用无障碍组件

新建可交互组件时，优先使用 `A11yButton`、`A11yIconButton`、`A11yListItem`、`A11yTab`、`A11yCard` 等封装，不要手写缺失 `Semantics` 的交互控件。

#### 6. 焦点隔离

页面级或弹窗级组件必须使用 `A11yFocusScope` 包裹，防止焦点泄漏到背景层。KeepAlive 页面隐藏时必须使用 `ExcludeFocus` 移出焦点树（见 `KeepAlivePageWrapper` 约定）。

#### 7. 字体缩放

文本组件不要硬编码 `textScaler`，使用系统默认缩放。如需自定义上限，使用 `clampTextScaler(context, max: 1.5)` 限制在安全范围。

#### 8. 多语言无障碍标签

所有 `Semantics.label` 必须使用 `l10n` 国际化，不要硬编码中文/英文字符串。`l10n` 文件位于 `lib/core/i18n/l10n/`，以 `a11y` 前缀命名（如 `a11yInstallApp`、`a11yAppListArea`、`a11yClose`）。

### 测试要求

无障碍组件必须通过 Widget 测试，覆盖：
- **语义标志**：`Semantics.label` / `Semantics.value` / `Semantics.hint` 正确
- **语义类型**：`SemanticsFlag.isButton`、`SemanticsFlag.isSelected`、`SemanticsFlag.hasEnabledState`/`isEnabled` 正确
- **交互尺寸**：按钮/Tab 最小 48×48 或 48px 高度
- **交互行为**：`enabled: false` 时不可点击，`onTap` 回调正确触发
- **合并语义**：`MergeSemantics` 内部子节点被正确合并

测试文件位于 `test/unit/core/accessibility/a11y_semantics_test.dart`。

## 变更记录
- 2026-03-17：应用列表卡片状态统一迁移到页面级索引 `application_card_state_provider.dart`，由公共 `AppCard` 渲染；列表页禁止再各自复制 `_AppCard` 并手写“安装/更新/打开”判断。
- 2026-03-17：卡片主按钮统一采用三态规则：未安装显示“安装”，已安装且可更新显示“更新”，已安装且无更新显示“打开”；安装队列仅作为 loading/progress 来源，不改变三态决策。
- 2026-03-17：`我的应用` 页按 `appId` 合并多版本，仅展示最高版本；卸载乐观更新必须按 `appId + version` 精确移除，不能整包删除同应用的其他已安装版本。
- 2026-03-17：玲珑进程功能统一迁移回 `我的应用 / 玲珑进程` 双 Tab，进程轮询必须由 `running_process_provider.dart` 统一管理；页面只负责传递“Tab 是否激活”和“页面是否可见”，不要在多个 Widget 里各自起 Timer。
- 2026-03-17：桌面端右键菜单统一使用 `flutter_desktop_context_menu`；进程列表右键菜单与“更多”按钮必须复用同一套菜单动作和同一套行级 loading 状态，避免双份逻辑漂移。
- 2026-03-17：Linux 原生右键菜单深色模式通过 Flutter -> runner 的轻量 MethodChannel 同步当前实际亮度；不要修改第三方菜单插件源码，也不要在 Dart 层伪造一套自绘菜单替代原生菜单。
- 2026-03-17：进程列表右键菜单弹出位置固定为鼠标点击点右下方 `4px`，这是当前与桌面视觉校准后的约定，后续不要随意改回零偏移。
- 2026-03-17：应用图标的远端富化结果统一在 `AppRepositoryImpl.enrichInstalledAppsWithDetails()` 做 TTL 缓存，缓存 key 必须包含 `locale + appId + version + arch + channel + module`；不要在 Provider 刷新链路里每次重新打应用详情接口补图标。
- 2026-03-17：分类筛选胶囊按钮的标签文字需要显式使用紧凑行高并居中对齐，避免中文在 `36px` 高按钮内出现视觉偏上；后续不要直接复用正文默认 `height: 1.5`。
- 2026-03-17：应用安装队列显式区分 `InstallTaskKind.install/update`；更新页、卡片按钮和批量更新入口必须统一走 `app_operation_queue_provider.dart`，不要在页面里直接循环 `enqueueInstall()` 或手写“更新即安装”的入队逻辑。
- 2026-03-17：安装/更新成功后的 installed apps 与 updates 刷新统一走 `app_collection_sync_provider.dart`；不要在页面 build 期监听里分散刷新，也不要在按钮点击回调里各自补写 refresh。
- 2026-03-18：`updateAppsProvider` 必须保持 `keepAlive`；启动页的首次 `_checkUpdates()` 结果要直接供侧边栏红点和更新页复用，不能依赖“进入更新页后再查一次”来驱动红点出现。
- 2026-03-18：缓存系统必须由 `CacheService.init()` 统一初始化，并在 `main()` 中于 `runApp()` 前执行；`CacheService.init()` 不仅要 `Hive.initFlutter()`，还要预先打开 `cache` box，避免业务侧同步 `Hive.box('cache')` 读取时崩溃。
- 2026-03-18：启动流程只保留一个正式 `LaunchPage/LaunchSequence`；`MaterialApp` 首帧依赖的语言、主题和基础设置必须在 Provider `build()` 阶段同步从 `SharedPreferences` 恢复，禁止再增加路由外的“正在初始化”占位页。
- 2026-03-18：修改 Riverpod 注解或 Mockito `@GenerateMocks` 后，必须同步重新执行代码生成并核对生成产物已更新；不要出现源码已改、`*.g.dart`/`*.mocks.dart` 仍保留旧生命周期或旧接口的假修复。
- 2026-03-18：应用详情页版本列表必须统一走 `AppRepository.getVersions()`，并显式传递 `appId + repoName + arch`；仓储层负责“同版本优先保留 binary + 语义版本倒序排序”，页面层只消费规范化结果。版本列表失败时只能显示轻量错误态与重试入口，不能伪装成空列表。
- 2026-03-18：自定义标题栏的 `16px` 水平留白只用于左侧 Logo/标题/搜索内容区；右侧窗口控制按钮组必须贴齐窗口右边缘，且不能通过缩小按钮热区来消除留白。
- 2026-03-18：应用详情页的“创建桌面快捷方式”“卸载”必须直接放在头部主按钮右侧，与主按钮同一行展示；只有 `installedAppsProvider` 确认当前 `appId` 存在本地安装实例时才显示，不能继续藏在更多菜单里，也不能在未安装态展示禁用入口。
- 2026-03-18：应用详情页截图列表必须显式随 `/app/getAppDetail` 请求传 `lang`，并在仓储层把前台 locale 归一成后端约定值（`zh* -> zh_CN`、`en* -> en_US`）；截图可见性以后端按语言精确过滤结果为准，Flutter 页面不做本地回退筛选。
- 2026-03-19：侧边栏顶部固定区只保留 `推荐 / 全部 / 排行 / 服务端动态菜单`；`我的应用 / 下载管理 / 设置` 固定在底部，展开态使用横向并排图标按钮，自动折叠态切换为竖向图标按钮，不要再改回底部文字菜单。
- 2026-03-19：推荐页必须严格对齐当前 Rust 首页，只保留轮播区、`玲珑推荐` 标题和推荐应用列表；分页大小固定为 `10`，首屏支持缓存优先展示，但暂不做页面重新可见后的后台刷新缓存页。
- 2026-03-19：推荐页自动补页不能只依赖滚动触底；当首屏或窗口尺寸变化后内容仍不足一屏时，页面必须在可见态下继续 `loadMore()`，直到列表可滚动或 `hasMore=false`，隐藏态继续暂停这类副作用。
- 2026-03-19：全局搜索入口统一收敛到标题栏真实搜索框；用户在 header 输入后按 Enter 或点击搜索图标进入 `/search_list?q=...`。`SearchListPage` 只负责结果展示，不得再内置第二个搜索框。
- 2026-03-20：Flutter 商店不支持“用户可配置仓库源”；设置页、Provider 和本地偏好都不要再保存/恢复 `repo_name`。接口层和埋点若需要 `repoName`，统一使用 `AppConfig.defaultStoreRepoName`，不要把协议字段误删成业务配置。
- 2026-03-20：GitHub Actions 统一拆为 `ci.yml`（仅 `pull_request` 轻量校验）、`nightly.yml`（`UTC+8 03:00` 的 `amd64` nightly 预发布）和 `release.yml`（正式双架构发版）；`package-smoke-test.sh` 只允许留在 nightly，禁止再放回 PR CI。
- 2026-03-20：Gitee 镜像仓库固定为 `hanplus/flutter-linglong-store`；Git refs 先推 `master` 与 tags，再统一通过 `build/scripts/sync-gitee-release.sh` 同步 GitHub Release，禁止手工在 Gitee 页面逐个上传资产。
- 2026-03-20：`GITEE_REPO` 允许写 `owner/repo` 或完整 `https://gitee.com/...(.git)` URL，但同步脚本内部必须先归一成 `owner/repo` 后再调用 Gitee API。
- 2026-03-22：侧边栏动态菜单配置当前以 Flutter 本地目录 `local_sidebar_menu_catalog.dart` 为准；未来若要切回接口配置，只允许从 `sidebarConfigProvider` 这一处切换数据源，侧边栏项标签与自定义分类页标题必须继续复用同一套菜单解析 helper，禁止各自直接读取后端 `menuName`。
- 2026-03-22：自定义分类页状态必须按 `menuCode` 使用 `customCategoryProvider(code)` 分片管理，禁止再用单例 provider 在 `initState/didUpdateWidget` 中手动切换分类；页头应用数量必须使用 `/app/sidebar/apps` 返回的真实 `total`，分页大小固定与 Rust 旧版对齐为 `30`，语言切换时通过失效 `sidebarConfigProvider` 驱动当前分类 family 重新加载，禁止直接 `invalidate(customCategoryProvider)`。
- 2026-03-22：安装/更新进度链路必须先在仓储层把 `ll-cli --json` 输出正规化，再写入队列；`task.message` 只允许承载可直接展示的规范化文案，原始后端 message 只能放在 `rawMessage/errorDetail` 这类诊断字段里，禁止任何页面直接渲染整段 JSON 原文。
- 2026-03-23：应用详情页评论区统一对接 `/app/getAppCommentList` 与 `/app/saveAppComment`；当前只支持匿名文本评论和只读的帮助数展示，不允许前端擅自增加评分、头像、点赞提交等后端不存在的交互。评论提交成功后必须回源刷新最新评论，不能本地伪造一条临时评论。
- 2026-03-23：评论区“关联版本”禁止继续使用承载大量版本的桌面下拉框；统一改为横向胶囊选择，默认只展示前 `8` 个版本，超出部分通过“展开全部 / 收起”切换。提交评论时使用当前胶囊选中的版本值。
- 2026-03-23：全局提示统一迁移为 `AppShell` 内容区右上角通知中心：页面/组件只能通过 `app_notification_helpers.dart` 触发提示，业务服务层不得直接依赖通知 UI；涉及卸载等应用层流程时，服务返回 typed result，由页面决定展示文案，`lib/` 内禁止继续新增 `ScaffoldMessenger/showSnackBar`。
- 2026-03-23：正式 `release.yml` 必须先完成版本文件产物化、双架构构建与签名，再进入独立 `finalize-release-state` job 推送 release commit 和 tag；禁止在 `prepare-release` 阶段提前改远端分支或打 tag。
- 2026-03-23：release 工具链禁止再硬编码 `/home/han/flutter` 一类维护者本机路径；统一优先使用显式环境变量，其次使用 runner `PATH` 或容器标准路径解析 Dart/Flutter。
- 2026-03-24：GitHub Actions 中的 RPM 签名禁止继续使用 `echo "$GPG_PASSPHRASE" | rpmsign --addsign ...`；`nightly.yml` / `release.yml` 必须在 `~/.rpmmacros` 里显式覆盖 `%__gpg_sign_cmd`，统一走 `gpg --batch --pinentry-mode loopback --passphrase-file ...`，并在签名前先校验 `GPG_KEY_ID` 对应 secret key 已导入。
- 2026-03-24：`linglong-store-nightly-bin` 是替换稳定版的 nightly AUR 包，不允许与 `linglong-store-bin` 并装；nightly 的桌面项、AppStream 和其他用户可见元数据必须显式渲染为 `Nightly`。
- 2026-03-25：卸载拦截约定——所有卸载入口必须通过 `AppUninstallService`（`appUninstallServiceProvider`）；当 `installQueueProvider.currentTask` 存在且 `isProcessing=true` 时，卸载操作必须显示 `UninstallBlockedDialog` 拦截弹窗，不得直接进入卸载确认流程；"查看下载管理"必须复用 `showDownloadManagerDialog(context)`，不允许重复实现下载管理界面；仅运行中任务（`isProcessing=true`）触发拦截，排队等待的任务不阻断卸载。
- 2026-03-25：全局字体语义整改约定——字体唯一真相源为 `lib/core/config/theme.dart`；`AppTextStyles.body=16px`（主正文）、`AppTextStyles.bodyMedium=14px`（标准辅助）、`AppTextStyles.caption=13px`（次要元信息）、`AppTextStyles.tiny=12px`（仅标签/徽章）；**12px 严格限定于标签/徽章/极度受限空间**，普通列表项和页面正文禁止缩减到 12px；修改字体大小时必须同步评估容器高度与对齐，禁止只改字号不验布局。以下四处保留硬编码例外，后续不得擅自修改：①`screenshot_preview_lightbox.dart` 遮罩层小字（13/12px）；②`recommend_page.dart` banner 紧凑按钮（12px, height 30）；③`app_card.dart` 28×28 排名徽章（12px）；④`error_state.dart` 等宽错误详情（12px）。
- 2026-03-25：全部应用页分类筛选约定——统一走 `/visit/getSearchAppList`；分类值必须传 `getDisCategoryList` 返回的真实 `categoryId`，不能再把它当成 `menuCode` 传给 `/app/sidebar/apps`；"全部"态传 `categoryId: null`；全部应用页分页大小与 Rust 旧版对齐为 `30`；`SearchAppListRequest.categoryId` 标注 `@JsonKey(includeIfNull: false)`，`null` 时不参与 JSON 序列化，禁止改回 `includeIfNull: true` 或移除该注解。
- 2026-04-09：侧边栏 KeepAlive 页面切换时，隐藏页不能只更新 `isVisible` 做副作用暂停；`KeepAlivePageWrapper` 必须同时把隐藏页移出绘制树、命中测试树、焦点树和 ticker 树（如 `Offstage + IgnorePointer + ExcludeFocus + TickerMode`），否则新页面骨架屏会与旧页面内容重叠透出，且隐藏页仍可能偷走键盘焦点。
- 2026-04-18：所有分页列表的 loading / “没有更多了” footer 必须独立成整行 sliver（统一复用 `PaginationFooterSliver`）；禁止再把 footer 当成 `ResponsiveAppGrid` 或其他 `SliverGrid` 的最后一个 item 塞进网格，否则视觉上会像占用一个 `AppCard` 坑位并导致居中失真。
