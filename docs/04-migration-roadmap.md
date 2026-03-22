# 迁移路线图与进度跟踪

> 文档版本: 1.0 | 创建日期: 2026-03-15

---

## 总体规划

迁移分为 **5 个阶段**，采用渐进式策略——先搭基础骨架，再逐模块迁移，最后联调收尾。

```
Phase 0        Phase 1        Phase 2        Phase 3        Phase 4
基础搭建  ───→  核心框架  ───→  页面迁移  ───→  高级特性  ───→  测试收尾
                                                              & 发布
```

---

## Phase 0: 项目初始化与基础搭建

> 依赖：无 | 可并行：是（多人各自搭建不同模块骨架）

### 0.1 Flutter 项目初始化

- [ ] 创建 Flutter 项目 `flutter create linglong_store`
- [ ] 配置 `pubspec.yaml`（全部依赖声明）
- [ ] 配置 `analysis_options.yaml`（lint 规则）
- [ ] 配置 `.vscode/launch.json`（调试配置）
- [ ] 初始化 Git 仓库 & `.gitignore`

### 0.2 目录结构搭建

- [ ] 按 02-flutter-architecture.md 创建完整目录树
- [ ] 创建 `lib/core/` 基础模块骨架
- [ ] 创建 `lib/features/` 领域模块骨架
- [ ] 创建 `lib/shared/` 共享模块骨架
- [ ] 创建 `assets/` 静态资源目录并迁移图标/SVG

### 0.3 构建环境

- [ ] 配置 Linux 桌面构建 (`linux/`)
- [ ] 集成 `window_manager` 并配置窗口参数 (1200×800, 600×400 min)
- [ ] 配置无边框窗口 + 自定义拖拽
- [ ] 集成 `build_runner` + `freezed` 代码生成流水线
- [ ] 编写 `Makefile` 或 `justfile` 统一构建命令

### 0.4 CI/CD 基础

- [ ] GitHub Actions: Flutter lint + build on push
- [ ] 配置 `flutter analyze` 零警告策略
- [ ] 配置 deb/rpm 打包脚本
- [ ] 建立 `test/golden/`、`test/mcp/`、`tool/benchmarks/` 目录
- [ ] 建立基线性能采集模板（启动、滚动、内存）

---

## Phase 1: 核心框架层

> 依赖：Phase 0 完成 | 并行度：高（各子模块独立）

### 1.1 主题系统 (Theme)

- [ ] 实现 `AppTheme`：颜色、字体、间距（对照 03a-ui-design-tokens.md）
- [ ] 配置 `ThemeData` 完整映射（含 Material 组件覆盖）
- [ ] 实现 `ThemeExtension` 自定义 token
- [ ] 验证所有颜色值与原项目一致

### 1.2 路由系统 (Router)

- [ ] 实现 `go_router` 路由表（10 个页面路由）
- [ ] 实现 KeepAlive 机制（`KeepAliveShell` + `AutomaticKeepAliveClientMixin`）
- [ ] 实现 `KeepAliveVisibilityNotifier`（页面可见性通知）
- [ ] URL query 保持（搜索关键字、分页参数）

### 1.3 网络层 (Network)

- [ ] 实现 `ApiClient`（dio 封装 + 拦截器 + baseURL + 超时）
- [ ] 实现 retrofit 接口定义（20 个 API 端口）
- [ ] 实现分页请求辅助 `paginate()`
- [ ] 响应数据 JSON 解析 + freezed 模型映射

### 1.4 本地命令层 (CLI Executor)

- [ ] 实现 `CliExecutor`（`dart:io Process` 封装）
- [ ] 实现 `ll-cli list --json` 解析
- [ ] 实现 `ll-cli ps` 解析
- [ ] 实现 `ll-cli run` / `ll-cli kill`
- [ ] 实现安装/卸载/更新命令（流式进度解析）
- [ ] 输入参数校验 & 超时控制（30s 默认）
- [ ] ✅ 验证：在真实 Linux 环境运行全部命令

### 1.5 数据模型 (Models)

- [ ] freezed 模型：`AppInfo`, `InstalledApp`, `RunningProcess`, `UpdateInfo`
- [ ] freezed 模型：`CategoryInfo`, `BannerInfo`, `AppDetail`
- [ ] freezed 模型：`InstallTask`, `InstallProgress`, `InstallResult`
- [ ] API 响应模型：`PaginatedResponse<T>`, `ApiResponse<T>`
- [ ] JSON 序列化/反序列化 + 工厂方法
- [ ] 运行 `build_runner` 生成代码并验证

### 1.6 状态管理 (Riverpod Providers)

- [ ] `installedAppsProvider` — 已安装应用列表 + CRUD
- [ ] `updateAppsProvider` — 可更新应用列表 + 检查逻辑
- [ ] `installQueueProvider` — 安装队列状态机
- [ ] `globalConfigProvider` — 全局配置（语言、仓库源等）
- [ ] `runningProcessProvider` — 运行中进程列表
- [ ] `menuBadgeProvider` — 侧边栏红点计数

### 1.7 i18n 国际化

- [ ] 配置 `flutter_localizations` + ARB 文件
- [ ] 创建 `intl_zh.arb` 中文资源（从原项目 i18n 迁移）
- [ ] 创建 `intl_en.arb` 英文资源
- [ ] 语言切换逻辑 + 持久化

### 1.8 错误处理

- [ ] 定义 `AppException` 层级（NetworkException, CliException, etc.）
- [ ] 全局错误边界 Widget
- [ ] SnackBar / Dialog 错误反馈统一封装

### 1.9 测试基建

- [ ] 建立 fake repository / fake cli executor 测试基座
- [ ] 建立 Golden 基线生成规范（1200×800, 600×400, zh/en）
- [ ] 建立 MCP 场景目录（smoke / regression / performance）
- [ ] 建立 profile 模式性能采集流程

---

## Phase 2: 页面迁移（核心 UI）

> 依赖：Phase 1.1~1.6 完成 | 并行度：高（每页独立开发）

### 2.1 布局壳 (AppShell)

- [ ] 实现 `AppShell`（Titlebar + Sidebar + Content 三分布局）
- [ ] 实现 `CustomTitleBar`（搜索框 + 窗口控制）
- [ ] 实现 `Sidebar`（静态菜单 + 动态菜单 + 底部图标）
- [ ] 实现响应式折叠（≤768px）
- [ ] 实现下载管理弹窗触发

### 2.2 共享组件

- [ ] `ApplicationCard` + `ConnectedApplicationCard`
- [ ] `ApplicationCardSkeleton`（带 shimmer）
- [ ] `ApplicationCarousel`（带自定义背景）
- [ ] `DownloadProgressDialog`（三 Tab + 列表项）
- [ ] `SpeedTool`（网速显示）
- [ ] `AppConfirmDialog`（统一确认弹窗）
- [ ] `EmptyState`（空数据）
- [ ] `PaginatedGridView`（无限滚动网格）
- [ ] 所有共享组件补齐 Widget 测试 + Golden 测试

### 2.3 推荐页 (RecommendPage)

- [ ] 页面骨架 + 轮播区 + 筛选栏 + 卡片网格
- [ ] 接入 `usePaginatedList` 等效逻辑
- [ ] Seed 缓存首屏
- [ ] KeepAlive 可见性治理
- [ ] ✅ 视觉还原验证

### 2.4 全部应用页 (AllAppsPage)

- [ ] 分类标签 + 卡片网格
- [ ] 分类切换重置分页
- [ ] Seed 缓存首屏
- [ ] KeepAlive 可见性治理
- [ ] ✅ 视觉还原验证

### 2.5 应用详情页 (AppDetailPage)

- [ ] 头部信息 + 截图轮播 + 描述展开/收起
- [ ] 应用信息表格 + 版本列表
- [ ] 安装/更新/打开/卸载操作
- [ ] ✅ 视觉还原验证

### 2.6 我的应用页 (MyAppsPage)

- [ ] 已安装列表 + 搜索过滤
- [ ] 打开/卸载操作
- [ ] ✅ 视觉还原验证

### 2.7 更新页 (UpdateAppPage)

- [ ] 可更新列表 + 全部更新
- [ ] 单项更新进度
- [ ] ✅ 视觉还原验证

### 2.8 搜索列表页 (SearchListPage)

- [ ] URL keyword → 加载结果
- [ ] 无限滚动
- [ ] KeepAlive
- [ ] ✅ 视觉还原验证

### 2.9 自定义分类页 (CustomCategoryPage)

- [ ] 动态路由 `:code` 解析
- [ ] 卡片网格 + 分页
- [ ] KeepAlive
- [ ] ✅ 视觉还原验证

### 2.10 设置页 (SettingPage)

- [ ] 语言切换
- [ ] 仓库源配置
- [ ] 关于信息
- [ ] ✅ 视觉还原验证

### 2.11 进程管理页 (ProcessPage)

- [ ] 运行中应用列表 + 停止
- [ ] 自动刷新
- [ ] ✅ 视觉还原验证

### 2.12 排行榜页 (RankingPage)

- [ ] Tab 切换 + 卡片网格
- [ ] pageSize=100
- [ ] KeepAlive
- [ ] ✅ 视觉还原验证

---

## Phase 3: 高级特性 & 系统集成

> 依赖：Phase 2 核心页面完成 | 并行度：中

### 3.1 安装队列状态机

- [ ] 实现完整安装队列：排队 → 执行中 → 完成/失败
- [ ] 并行安装控制（最多 1 个并行）
- [ ] 进度流解析（ll-cli 输出 → 百分比）
- [ ] 取消安装支持（kill process）
- [ ] 失败重试
- [ ] 应用关闭时队列持久化/恢复
- [ ] ✅ 全流程验证

### 3.2 启动序列

- [ ] LaunchPage（logo + 进度条 + 步骤文案）
- [ ] 环境检测 `checkLinglongEnv()`
- [ ] `LinglongEnvDialog`（4 按钮交互）
- [ ] 自动安装脚本执行
- [ ] 系统信息获取（arch）
- [ ] 已安装应用初始化
- [ ] 更新检查
- [ ] 安装恢复
- [ ] ✅ 冷启动流程完整验证

### 3.3 系统托盘

- [ ] `tray_manager` 集成
- [ ] 托盘图标 + 右键菜单
- [ ] 最小化到托盘 / 恢复

### 3.4 网络速度监控

- [ ] Dart `Process` 定时读取 `/proc/net/dev`
- [ ] 解析收发字节差值 → 速率
- [ ] 1s 刷新周期
- [ ] 单位自动转换

### 3.6 单实例控制

- [ ] 实现应用单实例锁（文件锁 / DBus）
- [ ] 重复打开时激活已有窗口

### 3.7 缓存系统

- [ ] Seed 数据集成（构建期 JSON）
- [ ] 运行时缓存读写（`shared_preferences` 或 `hive`）
- [ ] 缓存失效策略（安装/卸载后刷新）
- [ ] 保活页可见时后台刷新

---

## Phase 4: 测试、优化与发布

> 依赖：Phase 3 完成 | 并行度：高

### 4.1 单元测试

- [ ] Provider 测试：所有 Riverpod provider 覆盖核心状态流转
- [ ] Model 测试：freezed JSON 序列化/反序列化
- [ ] CLI 解析器测试：mock ll-cli 输出
- [ ] 工具函数测试：格式化、校验等
- [ ] 覆盖率 ≥ 90%

### 4.2 Widget 测试

- [ ] 核心组件测试：ApplicationCard, Skeleton, Carousel
- [ ] 布局组件测试：Titlebar, Sidebar
- [ ] 页面级快照测试
- [ ] Golden 截图回归：1200×800 / 600×400 / zh-CN / en-US

### 4.3 集成测试

- [ ] 启动→首页渲染→搜索→详情→安装 全流程
- [ ] 设置页语言切换
- [ ] 窗口操作（最小化/最大化/关闭）
- [ ] MCP smoke：启动、导航、截图、关键控件可见性
- [ ] MCP regression：安装、卸载、KeepAlive、搜索、更新

### 4.4 性能优化

- [ ] 列表滚动帧率检测（≥60fps，99%帧耗时 ≤16.6ms）
- [ ] 启动时间优化（首帧 ≤900ms，可交互 ≤1.8s）
- [ ] 内存占用监控（首页 ≤180MB，列表页 ≤220MB，详情页 ≤260MB）
- [ ] CPU 占用监控（空闲 ≤2% 单核，滚动 ≤25% 单核）
- [ ] 减少不必要的 rebuild

### 4.5 视觉还原审查

- [ ] 逐页截图与原项目对比
- [ ] 字号/颜色/间距精确度检查
- [ ] 动画效果对比
- [ ] 响应式断点行为验证

### 4.6 打包与分发

- [ ] deb 包构建 & 测试安装
- [ ] rpm 包构建 & 测试安装
- [ ] AppImage 构建（可选）
- [ ] 自动更新机制（可选）
- [ ] 版本号与 CHANGELOG.md

### 4.7 发布准备

- [ ] README.md 更新（Flutter 版本说明）
- [ ] 安装文档更新
- [ ] 贡献指南更新
- [ ] License 文件确认

---

## 关键里程碑

| 里程碑 | 完成标准 | 依赖 |
|--------|---------|------|
| M0: 项目可运行 | Flutter 空壳窗口启动，无边框 + 自定义标题栏 | Phase 0 |
| M1: 骨架跑通 | 路由切换、主题渲染、API 调用成功 | Phase 1.1~1.3 |
| M2: 首页可用 | 推荐页完整渲染（轮播+列表+分页） | Phase 2.1~2.3 |
| M3: 核心流程 | 安装/卸载/运行全链路通 | Phase 2.5, 3.1 |
| M4: 功能完整 | 所有页面迁移完成 | Phase 2 全部 |
| M5: 系统集成 | 启动序列+托盘+单实例+缓存 | Phase 3 |
| M6: 发布就绪 | 测试通过 + 打包 + 文档 + 性能门禁全部达标 | Phase 4 |

---

## 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| Flutter Linux 桌面成熟度不如 Web | 某些 API 缺失 | 早期验证关键功能（窗口管理、系统托盘、进程执行） |
| ll-cli 输出格式变化 | 解析失败 | 单元测试覆盖多种输出格式 + 容错解析 |
| KeepAlive 实现复杂度 | 性能/内存问题 | 参考 `IndexedStack` / `Offstage`，限制缓存数 |
| Ant Design → Material 视觉差异 | UI 不一致 | 通过 ThemeData 深度定制 + 必要时自定义 Widget |
| 团队 Flutter 经验 | 开发效率 | Phase 0 安排学习 & 原型练手 |
