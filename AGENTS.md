# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 文档指引
/home/han/code/linglong-store/linglong-server 这个是后端代码，你在对接接口的时候需要参考。


## 重点（极其重要）
- 未经允许，禁止使用git worktree功能。
- 所有的业务细节都要落实到文档里面去，详细的细节文档，docs目录
- 当前项目要求绝对的高性能，高UI响应速度。
- 严禁使用 `PopupMenuButton`。按钮和设置字段展开的轻量菜单必须统一复用
  `AppAnchoredMenu<T>` / `AppAnchoredMenuButton<T>`；右键上下文操作继续使用项目既有
  原生菜单入口，禁止以 `showMenu` 或页面私有 Overlay 规避此约定。
- 严禁硬编码物理方向做布局对齐：禁止新增 `Alignment.centerLeft/centerRight/topLeft` 等、
  `EdgeInsets.only(left:/right:)`、`TextAlign.left/right`、`Positioned(left:/right:)`，
  必须使用方向感知写法（`AlignmentDirectional` / `EdgeInsetsDirectional` /
  `TextAlign.start/end` / `PositionedDirectional`），否则 RTL（阿拉伯语）下布局不镜像；
  方向性图标（如展开箭头）按 `Directionality` 镜像。CI 门禁
  `build/scripts/verify_directional_layout.dart` 会拦截违规；确属窗口物理几何等合理豁免时，
  在源码加 `// ignore: hardcoded_direction` 注释说明理由。
- 每开发一个功能点就进行一次commit
- Git commit 必须遵循 Conventional Commits，统一使用 `type: 简短描述`，不要再写无类型前缀的自然语句提交信息。
- 在接到用户的任务的时候，先不要着急开始修改代码，要先分析需求，分析代码，列举解决方案，
- 详细的向用户说明你的思路，和你打算如何实现这个需求。
- 要分析整个项目的架构，一切都要从整个项目的角度入手，不能直接看完一个文件就写代码。
- 先问清楚、绝对不允许猜测：遇到需求或现状不确定时，先明确提问，不要主观假设；方案需先得到用户确认再开工。
- 每一处代码修改都要有必要的注释
- 先方案后编码：先梳理背景/现状 → 列备选方案（含改动面、影响范围、取舍理由）→ 让用户确认 → 再动手。**只有在用户确认你的方案后，才开始动手写代码, 不然你很快就会被关机，更换下一个AI，一定要小心。**
- 统一入口：能收敛的业务逻辑要集中封装（如卸载流程用 `useAppUninstall`），避免在多个页面/组件里写重复弹窗或副作用。
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

## 代码注释规则（强制）

## 注释规范

所有生成或修改的代码必须遵守以下注释要求：
1. 注释语言统一使用中文。
2. 注释格式必须符合当前编程语言的标准文档注释规范，例如 JavaDoc、JSDoc、docstring、GoDoc 等。
3. 核心文件顶部应添加文件级注释，说明该文件的业务定位、适用场景，以及为什么需要该文件。
4. 字段、接口、类型、类、方法、函数上方必须添加中文注释。
5. 注释不能只是复述代码逻辑，也不要逐行解释代码本身。
6. 注释应重点说明设计原因、适用场景、边界条件、调用注意事项，以及该代码在整体流程中的作用。
7. 对显而易见的代码不要添加低价值注释，例如“获取名称”“设置值”“返回结果”等。
8. 涉及业务规则、兼容逻辑、异常兜底、性能取舍、安全限制或历史原因时，必须在注释中说明为什么这样处理。
9. 修改代码时必须同步维护相关注释，避免注释与实际代码行为不一致。

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

## 应用自更新约定

- 应用自更新只支持当前实际运行身份为 DEB、RPM 或 AppImage 的场景；其它身份提示用户手动下载安装。
- 当前运行身份必须由 `LinuxAppInstallationProbe` 判断：有效 `APPIMAGE` 优先，否则查询 `Platform.resolvedExecutable` 的 dpkg/RPM 文件归属。禁止按发行版名称或机器上是否残留同名包推断。
- `AppSelfUpdateController` 是唯一任务状态和生命周期所有者，必须禁止并发；Presentation 只观察状态并发送开始、重试、取消、关闭事件。
- 下载工作区必须位于 `$XDG_CACHE_HOME/<application-id>/self-update/session-*`，并在成功、下载失败、SHA256 失败、取消授权和用户取消等所有退出路径清理。
- Release 安装包按当前身份与架构的宽松文件名后缀选择，随后必须下载同一 Release 的 `hashes.sha256`，按完整文件名读取摘要并校验本地 SHA256；缺少或不一致时禁止安装。
- 当前方案明确不使用签名更新清单、Ed25519 发布密钥或额外 GitHub Secret，禁止在没有新需求评审时自行增加。
- DEB、RPM、AppImage 必须保持三个独立 `AppUpdateInstaller`；AppImage 替换后必须设置 `0755`，避免下载文件权限导致应用无法再次启动。
- 安装成功后不自动退出、不拉起新进程、不引入 PID 重启协调器；只提示用户手动关闭并重新打开应用。

## RPM 打包双轨约定

- RPM spec 存在两条独立轨道，禁止互相混用模式：
  - 二进制重打包：`build/packaging/linux/rpm/linglong-store.spec.in`（`%build` 为空，
    仅复制 `@PAYLOAD_DIR@` 预编译产物，服务官方 Debian 10 容器链路）；
  - Copr 源码构建：`build/packaging/linux/copr/linglong-store.spec.in`（stable 渠道
    专用，在 mock/Copr 内完成 Flutter SDK 引导与 Release 编译，禁止引入本地
    payload 依赖）。
- Copr spec 的 `flutter_version`/`flutter_commit`/`flutter_sha256` 必须与
  `build/docker/debian10-release.Dockerfile` 的 `FLUTTER_VERSION` 同步升级；
  aarch64 分支必须保留 commit 锚点校验。
- 源码归档由 `build/scripts/package-source-archive.sh` 制作（git HEAD 树 +
  版本文件覆盖 + 预渲染 `packaging-dist/`），Copr 构建端禁止新增渲染依赖
  （dart 脚本、rsvg 等）；元数据变更时同步维护该脚本与两份 spec 模板。
- 完整设计决策与 Copr 维护者操作指南见 `docs/44-copr-source-build-design.md`。

## 变更记录

- 2026-08-27：新增 Fedora Copr 源码构建支持：RPM 打包拆分为「二进制重打包」与
  「Copr 源码构建」双轨，发版随 release 附件发布 `linglong-store-<version>.copr.spec`
  与自包含源码归档（版本号与 Source0 已渲染好，Copr 维护者直接提交附件 URL 即可）；
  Flutter SDK 按架构双路引导（x86_64 官方 tarball + sha256，aarch64 git clone +
  commit 锚点），版本锚点与发布容器 `FLUTTER_VERSION` 同步维护。设计文档见
  `docs/44-copr-source-build-design.md`。
- 2026-08-01：新增阿拉伯语（ar）支持后，项目强制方向感知布局约定：新代码禁止
  硬编码物理方向（`Alignment.centerLeft` 等、`EdgeInsets.only(left:/right:)`、
  `TextAlign.left/right`、`Positioned(left:/right:)`），统一使用
  `AlignmentDirectional` / `EdgeInsetsDirectional` / `TextAlign.start/end` /
  `PositionedDirectional`；方向性图标按 `Directionality` 镜像。CI 门禁
  `build/scripts/verify_directional_layout.dart`（已挂进
  `verify-generated-sources.sh`）自动拦截违规，合理豁免需用
  `// ignore: hardcoded_direction` 注释说明理由。阿拉伯语复数（CLDR
  zero/one/two/few/many/other）与 RTL 细节见 `docs/41-arabic-localization-design.md`。
- 2026-07-31：紧邻按钮或设置字段展开的轻量菜单统一使用
  `lib/presentation/widgets/app_anchored_menu.dart` 中的 `AppAnchoredMenu<T>`；标准三点
  入口使用 `AppAnchoredMenuButton<T>`，禁止在 Presentation 重新引入上述旧式组件、
  `showMenu` 或页面私有 Overlay。右键上下文菜单继续使用既有原生
  菜单边界。设置页语言选择保持 `AppLanguageSelector` 单一入口，候选语言只允许来自
  `selectableAppLocales`，新增语言按 `docs/38-arb-driven-linux-metadata.md` 的 ARB 流程
  接入，禁止维护第二份语言白名单。菜单不得读取高频 Provider、执行 IO 或增加展开动画；
  动作项统一保持至少 48px 高度，并保留键盘、焦点恢复和本地化无障碍语义。
