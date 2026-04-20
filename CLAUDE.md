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
### 核心开发技能，必须遵守这些规范，否则不要开发
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

## 打包约定
- AUR `linglong-store-bin` 的 `LICENSE`、`.desktop`、`metainfo`、应用图标必须作为 AUR 仓库内的本地 `source` 一起发布，不要再依赖 GitHub release tarball 是否额外打入这些文件。
- AUR 包仅在确有安装/卸载钩子时才保留 `.install`；纯提示信息应收敛到 `PKGBUILD` 元数据或文档，不要在 `.install` 里硬编码 `yay` 等 helper 命令。
- AUR 校验必须通过 `build/scripts/validate-aur-package.sh` 在 Arch Linux Docker 中执行；`ubuntu-latest` 上不要直接 `apt-get install namcap`，因为 runner 默认仓库里没有这个包。

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
- 2026-03-23：应用详情页评论区统一对接 `/app/getAppCommentList` 与 `/app/saveAppComment`；当前只支持匿名文本评论和只读的帮助数展示，不允许前端擅自增加评分、头像、点赞提交等后端不存在的交互。评论提交成功后必须回源刷新最新评论，不能本地伪造一条临时评论。
- 2026-03-23：评论区“关联版本”禁止继续使用承载大量版本的桌面下拉框；统一改为横向胶囊选择，默认只展示前 `8` 个版本，超出部分通过“展开全部 / 收起”切换。提交评论时使用当前胶囊选中的版本值。
- 2026-03-23：全局提示统一迁移为 `AppShell` 内容区右上角通知中心：页面/组件只能通过 `app_notification_helpers.dart` 触发提示，业务服务层不得直接依赖通知 UI；涉及卸载等应用层流程时，服务返回 typed result，由页面决定展示文案，`lib/` 内禁止继续新增 `ScaffoldMessenger/showSnackBar`。
- 2026-04-09：侧边栏 KeepAlive 页面切换时，隐藏页不能只更新 `isVisible` 做副作用暂停；`KeepAlivePageWrapper` 必须同时把隐藏页移出绘制树、命中测试树、焦点树和 ticker 树（如 `Offstage + IgnorePointer + ExcludeFocus + TickerMode`），否则新页面骨架屏会与旧页面内容重叠透出，且隐藏页仍可能偷走键盘焦点。
- 2026-04-20：Linux 桌面主题必须在 `AppTheme` 统一配置中文 `fontFamilyFallback`，并通过同一 helper 覆盖 `textTheme` 与所有从 `AppTextStyles` 派生的组件主题文本样式；禁止在页面或单个组件里零散维护不同的字体回退列表。
- 2026-04-20：玲珑环境检测与自动安装必须统一走 Flutter 侧服务层：环境检测只允许通过 `LinglongEnvironmentService` 聚合 `ll-cli --help`、`repo show`、版本号和系统诊断信息；`ll-cli < 1.9.0` 只记 warning、不阻断启动；自动安装脚本必须从后端 `/app/findShellString` 获取，并以 `pkexec bash <temp-script>` 执行，禁止再回退到硬编码脚本 URL、`curl/wget` 直链下载，或通过 `CliExecutor/ll-cli` 间接执行安装脚本。
