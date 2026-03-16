# 多人开发任务规划

> 文档版本: 1.0 | 创建日期: 2026-03-15

---

## 团队角色定义

建议 **3~4 人**团队配置：

| 角色 | 代号 | 职责范围 |
|------|------|---------|
| 架构负责人 | **A** | 核心框架、路由、状态管理、CLI 对接、代码审查 |
| 前端开发 1 | **F1** | 布局壳、共享组件、推荐页、全部应用页 |
| 前端开发 2 | **F2** | 详情页、我的应用、更新页、设置页、进程页 |
| 前端开发 3（可选） | **F3** | 搜索、排行榜、自定义分类、缓存系统、测试 |
| 测试/性能负责人（建议） | **QA** | 单元测试基座、Golden、MCP 场景、性能基准、发布门禁 |

> 如果只有 2 人，F1+F2 合并，A 兼任 F3 范围。

---

## Phase 0: 初始化 — 并行任务分配

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P0-01 | 创建 Flutter 项目 + pubspec.yaml | A | 无 | 项目骨架 |
| P0-02 | 目录结构 + lint 规则 | A | P0-01 | 目录树 |
| P0-03 | 窗口管理配置 (window_manager) | A | P0-01 | 无边框窗口 |
| P0-04 | 静态资源迁移（图标、SVG） | F1 | P0-01 | assets/ |
| P0-05 | CI/CD 基础配置 | F2 | P0-01 | GitHub Actions |
| P0-06 | build_runner + Makefile | A | P0-02 | 构建流水线 |
| P0-07 | 测试目录/Golden/MCP/benchmark 脚手架 | QA/A | P0-01 | `test/`, `tool/` |

```
A:  P0-01 ──→ P0-02 ──→ P0-03 ──→ P0-06
F1: ─────────── P0-04 (等 P0-01)
F2: ─────────── P0-05 (等 P0-01)
```

---

## Phase 1: 核心框架 — 并行任务分配

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P1-01 | 主题系统 ThemeData | F1 | P0-02 | `core/theme/` |
| P1-02 | 路由系统 go_router | A | P0-02 | `core/router/` |
| P1-03 | KeepAlive 机制 | A | P1-02 | `shared/widgets/keep_alive_shell.dart` |
| P1-04 | API Client (dio + retrofit) | F2 | P0-02 | `core/network/` |
| P1-05 | CLI Executor | A | P0-03 | `core/cli/` |
| P1-06 | Freezed 数据模型 | F2 | P0-06 | `core/models/` |
| P1-07 | Riverpod Providers | A | P1-05, P1-06 | `core/providers/` |
| P1-08 | i18n 资源迁移 | F1 | P0-02 | `lib/l10n/` |
| P1-09 | 错误处理框架 | A | P1-04 | `core/error/` |
| P1-10 | Fake repository / fake cli 测试基座 | QA | P1-04, P1-05 | `test/helpers/` |
| P1-11 | Golden 基线规范 + MCP 场景模板 | QA | P0-07 | `test/golden/`, `test/mcp/` |

```
A:  P1-02 → P1-03 → P1-05 ──→ P1-07 → P1-09
F1: P1-01 ──→ P1-08
F2: P1-04 ──→ P1-06
```

### 关键集成点

- **P1-07** 依赖 P1-05 和 P1-06，这是核心阻塞点
- F1 和 F2 完成后需等待 A 完成 P1-07 才能开始 Phase 2 的页面开发
- 建议 F1/F2 等待期间可以先做 Phase 2 的纯 UI 组件（不依赖状态）

---

## Phase 2: 页面迁移 — 并行任务分配

### 前置：共享组件（可并行开发）

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P2-00a | ApplicationCard | F1 | P1-01 | `shared/widgets/` |
| P2-00b | ApplicationCardSkeleton | F1 | P2-00a | `shared/widgets/` |
| P2-00c | ApplicationCarousel | F1 | P1-01 | `shared/widgets/` |
| P2-00d | PaginatedGridView | A | P1-03 | `shared/widgets/` |
| P2-00e | DownloadProgressDialog | F2 | P1-07 | `shared/widgets/` |
| P2-00f | AppConfirmDialog | F2 | P1-01 | `shared/widgets/` |
| P2-00g | EmptyState | F2 | P1-01 | `shared/widgets/` |

### 布局壳

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P2-01 | AppShell (三分布局) | A | P1-02, P1-03 | `features/app_shell/` |
| P2-02 | CustomTitleBar | F1 | P2-01, P1-01 | `features/app_shell/` |
| P2-03 | Sidebar | F1 | P2-01, P1-07 | `features/app_shell/` |
| P2-04 | LaunchPage | F2 | P1-07 | `features/launch/` |

### 页面迁移（高度并行）

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P2-05 | 推荐页 | F1 | P2-02,03, P2-00a~d | `features/recommend/` |
| P2-06 | 全部应用页 | F1 | P2-00a,d | `features/all_apps/` |
| P2-07 | 应用详情页 | F2 | P2-00a, P1-07 | `features/app_detail/` |
| P2-08 | 我的应用页 | F2 | P1-07 | `features/my_apps/` |
| P2-09 | 更新页 | F2 | P1-07 | `features/update_app/` |
| P2-10 | 搜索列表页 | F3/F1 | P2-00a,d | `features/search/` |
| P2-11 | 自定义分类页 | F3/F1 | P2-00a,d | `features/custom_category/` |
| P2-12 | 设置页 | F2 | P1-07,08 | `features/setting/` |
| P2-13 | 进程管理页 | F2 | P1-05 | `features/process/` |
| P2-14 | 排行榜页 | F3/F1 | P2-00a,d | `features/ranking/` |

```
并行泳道图：

A:   P2-01 → P2-00d ─────────────────── (Code Review 全程)
F1:  P2-00a → P2-00b → P2-00c → P2-02 → P2-03 → P2-05 → P2-06 → P2-10 → P2-11
F2:  P2-00e → P2-00f → P2-00g → P2-04 → P2-07 → P2-08 → P2-09 → P2-12 → P2-13
F3:  (如有) P2-10 → P2-11 → P2-14
```

---

## Phase 3: 高级特性 — 任务分配

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P3-01 | 安装队列状态机（完整） | A | P2-07 | `core/providers/install_queue/` |
| P3-02 | 启动序列完整实现 | A | P2-04 | `features/launch/` |
| P3-03 | 系统托盘 | F2 | P2-01 | `core/platform/tray.dart` |
| P3-04 | 网络速度监控 | F1 | P1-05 | `core/platform/network_speed.dart` |
| P3-05 | 单实例控制 | A | Phase 2 | `core/platform/single_instance.dart` |
| P3-06 | 缓存系统 (Seed + Runtime) | F1 | P2-05 | `core/cache/` |
| P3-07 | NVIDIA 检测（如需） | A | Phase 2 | `core/platform/workarounds.dart` |

```
A:  P3-01 → P3-02 → P3-05 → P3-07
F1: P3-04 → P3-06
F2: P3-03
```

---

## Phase 4: 测试与发布 — 任务分配

| 任务 ID | 任务 | 负责人 | 依赖 | 产出 |
|---------|------|--------|------|------|
| P4-01 | Provider 单元测试 | A | Phase 3 | `test/providers/` |
| P4-02 | Model 单元测试 | F2 | P1-06 | `test/models/` |
| P4-03 | CLI 解析器测试 | A | P1-05 | `test/cli/` |
| P4-04 | Widget 测试 (组件) | F1 | Phase 2 | `test/widgets/` |
| P4-05 | Widget 测试 (页面) | F1+F2 | Phase 2 | `test/pages/` |
| P4-06 | Golden 截图测试 | QA+F1 | Phase 2 | `test/golden/` |
| P4-07 | MCP Smoke/Regression 场景 | QA+A | Phase 3 | `test/mcp/` |
| P4-08 | 集成测试 | A | Phase 3 | `integration_test/` |
| P4-09 | 性能基准与内存审计 | QA+A | Phase 3 | `tool/benchmarks/`, 报告 |
| P4-10 | 视觉还原逐页检查 | F1+F2 | Phase 2 | 截图对比报告 |
| P4-11 | deb/rpm 打包 | A | Phase 3 | `build/` |
| P4-12 | 文档更新 | F2 | Phase 3 | README, docs |

---

## Git 分支策略

```
main ──────────────────────────────────────── (稳定发布)
  │
  └─ develop ─────────────────────────────── (集成分支)
       │
       ├─ feature/phase0-init         (A)
       ├─ feature/theme-system        (F1)
       ├─ feature/router-keepalive    (A)
       ├─ feature/api-client          (F2)
       ├─ feature/cli-executor        (A)
       ├─ feature/models-providers    (A+F2)
       ├─ feature/app-shell           (A)
       ├─ feature/shared-widgets      (F1)
       ├─ feature/recommend-page      (F1)
       ├─ feature/detail-page         (F2)
       ├─ feature/install-queue       (A)
       └─ ...
```

**规则**：
1. 每个功能模块一个 feature 分支
2. PR 合并到 `develop`，需至少 1 人 Code Review
3. 每完成一个 Phase，`develop` 合并到 `main` 打 tag
4. 使用 Conventional Commits

---

## 代码冲突避免策略

### 目录隔离

每个开发人员主要在自己负责的 `features/` 子目录工作：
- A: `core/`, `features/launch/`, `features/app_shell/`
- F1: `shared/widgets/`, `features/recommend/`, `features/all_apps/`, `features/search/`
- F2: `features/app_detail/`, `features/my_apps/`, `features/update_app/`, `features/setting/`, `features/process/`

### 共享文件协作规则

| 共享文件 | 协作方式 |
|---------|---------|
| `pubspec.yaml` | A 统一管理，其他人 PR 提依赖需求 |
| `core/router/routes.dart` | A 维护，新页面路由在 feature PR 中提 |
| `core/theme/app_theme.dart` | F1 主导，新增 token 需 PR 说明 |
| `core/providers/*.dart` | A 主导，F1/F2 只读使用 |
| `l10n/*.arb` | 各自为负责页面添加 key，合并时解决冲突 |

### 每日同步

- 每天 merge develop 到自己的 feature 分支
- 冲突当天解决，不累积

---

## 质量门禁

### PR 合并前检查

- [ ] `flutter analyze` 零错误零警告
- [ ] 单元测试通过（覆盖新增代码）
- [ ] 受影响 Widget/Golden 测试通过
- [ ] 至少 1 人 Code Review 通过
- [ ] 无 TODO/FIXME 未标注 issue

### Phase 完成前检查

- [ ] 该 Phase 所有任务标记完成
- [ ] 集成测试通过
- [ ] MCP smoke / regression 通过（适用阶段）
- [ ] 性能预算达标（适用阶段）
- [ ] 视觉还原检查（Phase 2+）
- [ ] 文档同步更新

---

## 沟通与协作工具

| 用途 | 工具 |
|------|------|
| 任务跟踪 | GitHub Issues + Project Board |
| 代码审查 | GitHub PR |
| 即时沟通 | 微信群/钉钉群 |
| 文档协作 | 仓库 docs/ 目录 |
| 设计稿对比 | 截图 + docs/ 中的 UI 规范 |

---

## 任务优先级矩阵

### P0 — 阻塞型（必须先完成）

| 优先级 | 任务 |
|--------|------|
| P0 | 项目初始化 + 窗口配置 |
| P0 | CLI Executor（ll-cli 对接） |
| P0 | Riverpod Providers（状态管理） |
| P0 | AppShell（布局壳） |

### P1 — 核心体验

| 优先级 | 任务 |
|--------|------|
| P1 | 推荐页（首页） |
| P1 | 应用详情页 |
| P1 | 安装队列状态机 |
| P1 | ApplicationCard |
| P1 | 启动序列 |

### P2 — 功能完整

| 优先级 | 任务 |
|--------|------|
| P2 | 全部应用页、搜索页 |
| P2 | 我的应用页、更新页 |
| P2 | 下载管理弹窗 |
| P2 | 缓存系统 |

### P3 — 增强优化

| 优先级 | 任务 |
|--------|------|
| P3 | 排行榜页 |
| P3 | 系统托盘 |
| P3 | 网络速度监控 |
| P3 | 单实例控制 |
| P3 | 性能优化 |

---

## 每周交付物建议

| 周次 | A (架构) | F1 (前端1) | F2 (前端2) |
|------|----------|-----------|-----------|
| W1 | 项目初始化 + 窗口 + 路由 | 主题 + 资源迁移 | CI + 模型定义 |
| W2 | CLI Executor + KeepAlive | i18n + ApplicationCard | API Client + 模型生成 |
| W3 | Providers + 错误处理 | Skeleton + Carousel | DownloadDialog + Confirm |
| W4 | AppShell + PaginatedGrid | Titlebar + Sidebar | LaunchPage |
| W5 | Code Review 全程 | 推荐页 | 详情页 |
| W6 | 安装队列状态机 | 全部应用页 | 我的应用页 + 更新页 |
| W7 | 启动序列完整 | 搜索页 + 自定义分类 | 设置页 + 进程页 |
| W8 | 单实例 + 系统集成 | 排行榜 + 缓存系统 | 托盘 + 网速 |
| W9 | 集成测试 + 性能优化 | Widget/Golden 测试 | 单元测试 + 文档 |
| W10 | MCP 回归 + 发布门禁 | 视觉还原审查 | 视觉还原审查 |
