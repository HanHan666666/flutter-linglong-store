# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 文档指引
/home/han/linglong-store/linglong-server 这个是后端代码，你在对接接口的时候需要参考
/home/han/linglong-store/rust-linglong-store 这里是旧版rust商店，你要参考这里的逻辑


## 重点（极其重要）
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
- 变更记录：完成功能后，将关键经验和约定同步到本指南，方便后续遵循。
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
7.以假装理解为耻，以诚实无知为菜
8.以盲目修改为耻，以谨慎重构为荣

Shame in guessing APIs, Honor in careful research.
Shame in vague execution, Honor in seeking confirmation.
Shame in assuming business logic, Honor in human verification.
Shame in creating interfaces, Honor in reusing existing ones.
Shame in skipping validation, Honor in proactive testing.
Shame in breaking architecture, Honor in following specifications.
Shame in pretending to understand, Honor in honest ignorance.
Shame in blind modification, Honor in careful refactoring.

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
- 入口初始化（单实例、NVIDIA workaround、窗口、日志、存储、语言）在 `main.dart`。
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

## 变更记录
- 2026-03-17：应用列表卡片状态统一迁移到页面级索引 `application_card_state_provider.dart`，由公共 `AppCard` 渲染；列表页禁止再各自复制 `_AppCard` 并手写“安装/更新/打开”判断。
- 2026-03-17：卡片主按钮统一采用三态规则：未安装显示“安装”，已安装且可更新显示“更新”，已安装且无更新显示“打开”；安装队列仅作为 loading/progress 来源，不改变三态决策。
- 2026-03-17：`我的应用` 页按 `appId` 合并多版本，仅展示最高版本；卸载乐观更新必须按 `appId + version` 精确移除，不能整包删除同应用的其他已安装版本。
- 2026-03-17：玲珑进程功能统一迁移回 `我的应用 / 玲珑进程` 双 Tab，进程轮询必须由 `running_process_provider.dart` 统一管理；页面只负责传递“Tab 是否激活”和“页面是否可见”，不要在多个 Widget 里各自起 Timer。
- 2026-03-17：桌面端右键菜单统一使用 `flutter_desktop_context_menu`；进程列表右键菜单与“更多”按钮必须复用同一套菜单动作和同一套行级 loading 状态，避免双份逻辑漂移。
