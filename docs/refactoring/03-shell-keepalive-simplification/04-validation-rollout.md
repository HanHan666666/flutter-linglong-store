# KeepAlive Simplification Validation and Rollout Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐项执行。步骤使用 `- [ ]` 复选框语法。

**Goal:** 为本次 KeepAlive 重构与附带清理提供统一的验证、回归、内存检查、提交拆分与回滚策略，避免“代码看起来变简单了，但行为悄悄坏了”。

**Architecture:** 验证分为 4 层：静态分析、Widget 测试、流程级人工回归、Profile 模式内存观察。提交按“壳层重构 / 页面迁移 / 清理收尾 / 后续边界整改”分批进行，任何一批失败都可以独立回滚。

**Tech Stack:** flutter analyze, flutter test, integration_test, Flutter DevTools, Conventional Commits

---

## 验证顺序

### 第一层：编译与静态分析

- `flutter analyze`

### 第二层：定向自动化测试

- 新增 / 替换的 widget tests
- 已有的 sidebar tests
- 受影响 provider/page 的相关 tests

### 第三层：人工流程回归

- 主页面切换
- 二级页面覆盖层
- 恢复状态
- 进程轮询暂停/恢复

### 第四层：内存与驻留验证

- Profile 模式运行
- DevTools Memory 观察
- 对比“首次访问前 / 访问 4 个主页面后 / 进入二级页面后”的驻留对象变化

---

## Task 17：执行静态分析与定向测试

**Files:**
- Verify all modified files
- Test focus:
  - `test/widget/core/config/shell_branch_visibility_test.dart`
  - `test/widget/presentation/widgets/app_shell_primary_stack_test.dart`
  - `test/widget/presentation/widgets/sidebar_test.dart`

### 推荐执行命令

一条一条跑，不要上来全量乱轰。

- [ ] `flutter analyze`
- [ ] `flutter test test/widget/core/config/shell_branch_visibility_test.dart`
- [ ] `flutter test test/widget/presentation/widgets/app_shell_primary_stack_test.dart`
- [ ] `flutter test test/widget/presentation/widgets/sidebar_test.dart`

如果这些都过了，再补一轮更大范围：

- [ ] `flutter test test/widget/`
- [ ] `flutter test test/unit/`

### 对执行方的要求

- 不要在第一轮就跑全量集成测试
- 先用最小测试闭环确定壳层和页面切换没坏
- 如果 `flutter analyze` 有 warning，先处理与本次改动直接相关的 warning

---

## Task 18：做主流程人工回归

### 回归清单 A：4 个主页面

- [ ] 启动后默认进入推荐页
- [ ] 切到全部应用页后，列表正常显示
- [ ] 切到排行榜页后，当前 tab 正常显示
- [ ] 切到我的应用页后，应用列表正常显示

### 回归清单 B：主页面状态保留

#### 推荐页

- [ ] 下拉滚动一段距离
- [ ] 切到其他主页面
- [ ] 再切回推荐页
- [ ] 滚动位置仍保留
- [ ] 轮播没有在隐藏期间继续跑飞

#### 全部应用页

- [ ] 展开分类栏
- [ ] 切到其他主页面
- [ ] 切回全部应用页
- [ ] 分类展开状态仍保留

#### 排行榜页

- [ ] 切到非默认 tab
- [ ] 切到其他主页面
- [ ] 切回排行榜页
- [ ] 当前 tab 仍保留

#### 我的应用页

- [ ] 输入搜索关键词
- [ ] 切换到“玲珑进程” tab
- [ ] 切到其他主页面
- [ ] 切回我的应用页
- [ ] 当前 tab 与搜索关键词仍保留

### 回归清单 C：二级页面覆盖层

- [ ] 从任一主页面进入设置页
- [ ] 设置页显示正常，侧边栏 / 标题栏仍在
- [ ] 返回后主页面状态还在
- [ ] 从任一主页面进入应用详情页
- [ ] 详情页返回后主页面状态还在
- [ ] 搜索页 / 更新页 / 自定义分类页行为同理

### 回归清单 D：进程轮询

- [ ] 我的应用页切到“玲珑进程”
- [ ] 确认轮询正常
- [ ] 切到推荐 / 全部 / 排行
- [ ] 确认轮询停止
- [ ] 切回我的应用
- [ ] 确认轮询恢复

---

## Task 19：做内存占用验证

### 为什么这一步必须做

用户明确要求：

> 唯一的要求就是内存占用不能过高。

所以不能只说“`IndexedStack` 看起来简单”，必须做一次最基本的运行时观察。

### 运行方式

- [ ] `flutter run -d linux --profile`

### DevTools 观察步骤

#### 观察点 1：刚进入首页

记录：

- 当前总内存趋势
- Widget / Element / RenderObject 的数量级
- 是否只创建了推荐页，而不是 4 个主页面一起创建

#### 观察点 2：把 4 个主页面都访问一遍

记录：

- 是否只在首次访问对应页面时出现明显增长
- 再切回已访问页面时，内存是否基本稳定

#### 观察点 3：进入设置 / 搜索 / 详情等二级页面

记录：

- 进入二级页面时，主页面栈是否没有继续新增额外实例
- 返回后内存是否回到稳定平台，而不是持续线性增长

### 这一步要看什么，不要看什么

#### 要看

- “首次访问某主页面时增长，之后稳定” 这一趋势
- “二级页面退出后没有新增额外常驻页” 这一趋势
- “主页面常驻数量固定为 4” 这一事实

#### 不要看

- 不要臆造一个具体 MB 数字当门槛
- 不要因为 Profile 模式瞬时抖动就判定泄漏
- 不要只看 RSS 一项就得出全部结论

### 通过标准（定性）

以下 3 条同时满足，视为通过：

- [ ] 首次启动时未出现 4 个主页面同时抢首屏加载
- [ ] 访问过 4 个主页面后，内存进入稳定平台，不再持续增长
- [ ] 多次进入 / 退出详情、设置、搜索后，没有出现主页面实例数继续增加

---

## Task 20：提交拆分与推荐 commit 信息

### 提交 1：KeepAlive 核心结构改造

建议提交信息：

- `refactor: 用 IndexedStack 替换自定义 KeepAlive 架构`

包含：

- `routes.dart`
- `app_shell.dart`
- `shell_primary_route.dart`
- `shell_branch_visibility.dart`

### 提交 2：页面迁移与旧 KeepAlive 清理

建议提交信息：

- `refactor: 迁移主页面可见性逻辑并移除旧 KeepAlive 基础设施`

包含：

- 4 个主页面
- `custom_category_page.dart`
- 删除旧 keepalive 文件

### 提交 3：测试补齐

建议提交信息：

- `test: 补充主页面保活与可见性切换测试`

包含：

- 新测试文件
- 删除旧测试文件

### 提交 4：附带低风险清理

建议提交信息：

- `refactor: 删除遗留 ProcessManager 并收敛侧边栏 hover 逻辑`

### 后续独立提交

- `refactor: 拆分 GlobalApp 全局状态`
- `refactor: 上移安装文案本地化边界`

---

## Task 21：回滚策略

### 如果 KeepAlive 主重构失败，优先回滚哪一层

#### 第一优先级回滚：`routes.dart + app_shell.dart`

如果出现：

- 主页面状态不保留
- 二级页面覆盖层异常
- 页面切换白屏 / 空白

直接回滚：

- `routes.dart`
- `app_shell.dart`
- `shell_primary_route.dart`
- `shell_branch_visibility.dart`

并恢复旧 KeepAlive 文件。

#### 第二优先级回滚：页面迁移层

如果壳层正常，但个别页面副作用暂停/恢复不对：

- 只回滚受影响页面
- 不要先回滚整个 KeepAlive 主结构

例如：

- 推荐页轮播异常，只回滚 `recommend_page.dart`
- 我的应用轮询异常，只回滚 `my_apps_page.dart`

#### 第三优先级回滚：附带清理

- `ProcessManager` 删除失败：单独回滚这一提交
- sidebar hover 抽象失败：单独回滚这一提交
- `GlobalApp` / `InstallMessages` 后续整改失败：绝对不能影响已稳定的 KeepAlive 主线

---

## Task 22：文档与约定同步

**Files:**
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Optional: `docs/08-architecture-improvement-analysis.md`

### 必须补充的新约定

主重构完成后，建议在 `AGENTS.md` / `CLAUDE.md` 增加一条新约定，避免后续再把旧逻辑加回来。

建议写成类似下面这条：

```markdown
- 2026-04-xx：侧边栏主页面保活统一由 `AppShell` 内部懒加载 `IndexedStack` 承担；固定只保活 `推荐 / 全部 / 排行 / 我的应用` 4 个主页面。搜索、设置、更新、自定义分类、应用详情均为普通二级路由，不得重新引入全局 KeepAlive 注册表、页面可见性管理器或 LRU 页面缓存。
```

### 可选同步

如果你希望保留完整设计记录，可以在：

- `docs/08-architecture-improvement-analysis.md`

末尾追加一个“整改落地结果”小节，说明：

- 哪些判断被采纳
- 为什么最终方案选 `IndexedStack` 而不是 `StatefulShellRoute`

---

## 最终验收清单

全部打勾后，才允许说“这次 KeepAlive 重构完成”：

- [ ] `flutter analyze` 通过
- [ ] 新 widget tests 通过
- [ ] 旧 keepalive tests 已删除
- [ ] 4 个主页面状态切换保留正常
- [ ] 二级页面覆盖层行为正常
- [ ] 进程轮询暂停 / 恢复正常
- [ ] Profile 模式下内存趋势稳定
- [ ] 提交已按功能拆分
- [ ] `AGENTS.md` / `CLAUDE.md` 新约定已补充

---

## 执行完这份文档后

如果只是交付方案，到这里就结束。

如果要继续实施，按这个顺序走：

1. `01-core-router-and-shell.md`
2. `02-page-migration.md`
3. `03-secondary-cleanups.md`
4. 本文档的验证与回滚步骤
