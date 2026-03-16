# 测试与性能规范

> 文档版本: 1.0 | 创建日期: 2026-03-15  
> 目标：以**极限高性能、极低内存占用、可自动化验收**为硬性门禁，确保 Flutter 迁移后的桌面应用不仅功能一致，而且运行质量明显优于原实现。

---

## 一、质量目标总纲

本项目质量目标不是“差不多能跑”，而是**必须以硬指标约束交付**。

### 1.1 总体要求

1. **功能正确性**：所有原有功能必须有测试覆盖，禁止无验证合并。
2. **UI 一致性**：核心页面必须有自动化 UI 校验，不接受“肉眼差不多”。
3. **交互可驱动**：必须接入 **Flutter 官方测试栈 + 官方/推荐 MCP UI 控制能力**，可自动执行点击、输入、滚动、截图、语义树读取。
4. **性能极限化**：把性能预算当成编译门禁，而不是发布前临时看一眼。
5. **内存预算刚性执行**：页面缓存、图片缓存、列表缓存、Provider 生命周期全部必须可审计。

### 1.2 发布门禁

任何版本要进入可发布状态，必须同时满足：

- [ ] `flutter analyze` 零错误、零 warning
- [ ] 单元测试通过
- [ ] Widget/UI 测试通过
- [ ] MCP 驱动的关键流程测试通过
- [ ] Golden 截图差异在阈值内
- [ ] 性能指标全部达标
- [ ] 内存指标全部达标
- [ ] 无 P0 / P1 缺陷未关闭

---

## 二、测试分层模型

采用 **Testing Pyramid + UI Driver + Performance Gate** 五层模型：

```
                 ┌──────────────────────┐
                 │  L5 发布验收/性能门禁 │
                 ├──────────────────────┤
                 │  L4 MCP 驱动 UI 流程  │
                 ├──────────────────────┤
                 │  L3 Integration/E2E  │
                 ├──────────────────────┤
                 │  L2 Widget/Golden    │
                 ├──────────────────────┤
                 │  L1 Unit Tests       │
                 └──────────────────────┘
```

### 2.1 覆盖率目标

| 测试层级 | 最低覆盖目标 | 强制说明 |
|---------|-------------|---------|
| 单元测试 | **行覆盖率 ≥ 90%** | Provider / Service / Parser / Utils 必须达到 |
| Widget 测试 | **核心组件覆盖率 100%** | 所有共享组件必须有渲染与交互测试 |
| 页面测试 | **核心页面 100%** | 推荐、全部应用、详情、更新、设置、我的应用 |
| 集成测试 | **关键用户路径 100%** | 搜索→详情→安装→更新→卸载→设置 |
| MCP 测试 | **发布关键链路 100%** | 作为最终 UI 验收与回归套件 |

> 说明：这里的“100%”是**场景覆盖**，不是代码覆盖率数字游戏。

---

## 三、单元测试规范

### 3.1 适用范围

单元测试必须覆盖以下模块：

1. **Domain Models**
   - Freezed 模型 `fromJson/toJson`
   - `copyWith` 行为
   - 等值比较
2. **Core Utils**
   - 版本比较
   - 文件大小格式化
   - debounce / throttle
   - appDisplay 名称/描述回退
3. **CLI Parsers**
   - `ll-cli list --json`
   - `ll-cli ps`
   - 安装进度 JSON line parser
   - 环境检测输出解析
4. **Repositories / Services**
   - HTTP repository 映射
   - CLI repository 容错
   - cache service 命中/失效
   - analytics payload 构造
5. **Providers / Controllers**
   - install queue 状态机
   - launch 初始化流程
   - updates 检查流程
   - process 轮询退避逻辑
   - keepAlive LRU 淘汰逻辑

### 3.2 命名规范

```dart
void main() {
  group('InstallQueueNotifier', () {
    test('enqueueInstall should append task and start processing when idle', () async {
      // ...
    });

    test('markFailed should move current task to history with failed status', () async {
      // ...
    });
  });
}
```

命名要求：
- `should + 结果 + when + 条件`
- 不允许 `test('test xxx')`
- 不允许中文混乱命名，测试名使用英文，注释可中文

### 3.3 结构规范

目录建议：

```
test/
├── unit/
│   ├── core/
│   ├── domain/
│   ├── data/
│   └── application/
```

每个测试文件只测一个主对象：
- `version_compare_test.dart`
- `install_queue_notifier_test.dart`
- `cli_output_parser_test.dart`

### 3.4 强制测试清单

#### A. Install Queue 状态机

必须验证：
- [ ] 空队列不触发处理
- [ ] 入队后自动开始处理
- [ ] 同时只允许 1 个安装任务执行
- [ ] 成功后自动执行下一个
- [ ] 失败后写入 history 且不阻塞下一个
- [ ] cancel 后状态正确回滚
- [ ] 崩溃恢复后 currentTask 能被恢复或清理

#### B. 缓存系统

必须验证：
- [ ] seed 数据优先级低于 runtime cache
- [ ] runtime cache key 计算稳定
- [ ] 页数裁剪逻辑正确
- [ ] 安装/卸载后缓存失效
- [ ] locale 进入 cache key（防止多语言串缓存）

#### C. 环境检测

必须验证：
- [ ] `ll-cli` 不存在
- [ ] `ll-cli` 存在但版本低
- [ ] repo show 为 JSON 输出
- [ ] repo show 为文本输出
- [ ] 容器环境检测结果

### 3.5 Mock 规范

优先级：
1. **Fake 实现** > 纯 Mock
2. **固定样本输出** > 动态拼凑字符串
3. **真实 ll-cli 输出快照** > 手写猜测

推荐：
- 对 HTTP 用 `dio adapter mock`
- 对 CLI 用 `FakeCliExecutor`
- 对时间与定时器用 `fake_async`

### 3.6 单元测试门禁

- 单元测试必须在 PR 阶段执行
- 任意 Provider / Service / Parser 新文件，没有对应 test 文件禁止合并
- 覆盖率低于 90% 的模块必须在 PR 描述里说明原因

---

## 四、Widget 测试与 UI 测试规范

### 4.1 Widget 测试范围

必须覆盖：

| 类型 | 组件 |
|------|------|
| 布局组件 | `TitleBar`, `Sidebar`, `LaunchPage` |
| 核心组件 | `ApplicationCard`, `ApplicationCardSkeleton`, `ApplicationCarousel`, `DownloadProgressDialog`, `SpeedTool` |
| 页面容器 | `RecommendPage`, `AllAppsPage`, `AppDetailPage`, `MyAppsPage`, `UpdateAppPage`, `SettingPage` |

### 4.2 Widget 测试要求

每个核心组件至少要覆盖：
- [ ] 正常渲染
- [ ] 空数据渲染
- [ ] loading 态
- [ ] error 态（如果有）
- [ ] 关键交互（点击、滚动、展开、关闭）
- [ ] 文案与图标可见性
- [ ] 关键尺寸约束（尤其标题栏、卡片、弹窗）

### 4.3 Golden 测试规范

必须建立 Golden 基线的页面：
- 推荐页
- 全部应用页
- 应用详情页
- 我的应用页
- 更新页
- 设置页
- 启动页
- 环境检测弹窗
- 下载管理弹窗

Golden 维度：

| 维度 | 必测值 |
|------|-------|
| 窗口尺寸 | `1200x800`, `600x400` |
| 语言 | `zh-CN`, `en-US` |
| 主题 | Light（当前项目仅亮色） |
| 状态 | normal / loading / empty / error（按需） |

#### Golden 命名规范

```text
goldens/
  recommend_page.zh-CN.1200x800.normal.png
  recommend_page.zh-CN.1200x800.loading.png
  app_detail_page.en-US.1200x800.normal.png
```

### 4.4 Widget 测试硬规则

1. 禁止在 Widget 测试里依赖真实网络
2. 禁止依赖真实 `ll-cli`
3. 必须注入 fake provider / fake repository
4. 所有页面测试必须固定窗口尺寸
5. 所有截图测试必须固定字体、文本缩放比、设备像素比

---

## 五、MCP 驱动 UI 测试规范

### 5.1 定位

本项目必须引入 **Flutter 官方测试栈 + 官方/推荐 MCP UI 控制能力**，用于：
- 驱动桌面 UI 操作
- 读取 widget tree / semantics tree
- 执行点击、输入、滚动、等待
- 截图并与 Golden / 参考图对比
- 回归验证复杂交互链路

> 这里的 MCP 角色不是替代 `flutter_test`，而是补足**黑盒交互验证**，相当于“可编排的 UI 自动驾驶员”。

### 5.2 MCP 必须支持的动作集

- [ ] 查找 Widget（按文本、Key、Type、Semantics）
- [ ] 点击 `tap`
- [ ] 双击 `doubleTap`
- [ ] 输入文本 `enterText`
- [ ] 清空输入框
- [ ] 拖动/滚动 `drag`, `scrollUntilVisible`
- [ ] 等待动画/异步结束 `waitForIdle`
- [ ] 读取语义树/可见树
- [ ] 截图 `screenshot`
- [ ] 导出当前页面可交互元素清单

### 5.3 MCP 场景目录建议

```
test/
├── mcp/
│   ├── smoke/
│   │   ├── launch_and_home.yaml
│   │   └── search_and_open.yaml
│   ├── regression/
│   │   ├── install_flow.yaml
│   │   ├── uninstall_flow.yaml
│   │   ├── keep_alive_restore.yaml
│   │   └── language_switch.yaml
│   └── performance/
│       ├── home_scroll_benchmark.yaml
│       └── update_list_benchmark.yaml
```

### 5.4 MCP 核心回归场景

#### 场景 A：启动与首页
- [ ] 启动应用
- [ ] 等待启动页结束
- [ ] 校验推荐页轮播可见
- [ ] 校验侧边栏菜单渲染
- [ ] 截图保存

#### 场景 B：搜索 → 详情
- [ ] 在标题栏输入关键词
- [ ] 按回车
- [ ] 等待搜索结果页出现
- [ ] 点击第一个卡片
- [ ] 校验详情页头部、截图区、版本区可见

#### 场景 C：安装流程
- [ ] 进入详情页
- [ ] 点击安装
- [ ] 打开下载管理弹窗
- [ ] 校验队列状态变化
- [ ] 校验进度更新
- [ ] 完成后校验按钮变为“打开”

#### 场景 D：卸载流程
- [ ] 已安装应用进入详情页
- [ ] 点击卸载
- [ ] 确认弹窗出现
- [ ] 点击确认
- [ ] 校验状态回到“安装”

#### 场景 E：KeepAlive 行为
- [ ] 推荐页滚动到第 N 页
- [ ] 切换到全部应用页
- [ ] 再切回推荐页
- [ ] 校验滚动位置保留
- [ ] 校验未触发重复首屏骨架闪烁

### 5.5 MCP 测试门禁

- 每次发布前至少跑一遍 smoke + regression
- 每个高风险修复（安装、卸载、KeepAlive、搜索、更新）必须补充对应 MCP 场景
- MCP 场景失败时，禁止以“本地偶现”为由跳过合并

---

## 六、集成测试规范

### 6.1 集成测试范围

采用 Flutter 官方 `integration_test`：

| 场景 | 是否强制 |
|------|---------|
| 启动 → 推荐页加载 | 强制 |
| 搜索 → 详情 | 强制 |
| 详情 → 安装 | 强制 |
| 更新页 → 全部更新 | 强制 |
| 设置页 → 语言切换 | 强制 |
| 进程页 → 停止进程 | 强制 |

### 6.2 环境分层

集成测试分两套：

#### A. Fake 环境（CI 默认）
- fake HTTP API
- fake CLI executor
- 固定返回数据
- 目标：稳定、快速、无外部依赖

#### B. Real 环境（夜间或发布前）
- 真正调用测试环境 API
- 真正执行 `ll-cli`
- 目标：验证平台联动真实可用

---

## 七、性能要求（硬性指标）

> 这里不写“尽量优化”，写**必须达标**的硬门槛。

### 7.1 启动性能

| 指标 | 目标值 | 备注 |
|------|--------|------|
| 冷启动到首帧 | **≤ 900ms** | 不含环境检测弹窗阻塞 |
| 冷启动到首页可交互 | **≤ 1.8s** | 推荐页可滚动、可点击 |
| Warm start 到首页可交互 | **≤ 700ms** | 二次启动 |
| 路由切换响应 | **≤ 120ms** | 页面间切换主观无感 |

### 7.2 渲染性能

| 指标 | 目标值 |
|------|--------|
| 普通滚动页平均帧率 | **≥ 60 FPS** |
| 99% 帧耗时 | **≤ 16.6ms** |
| 慢帧占比 | **< 1%** |
| 卡顿帧（>50ms） | **0 容忍** |
| 推荐页首屏渲染完成 | **≤ 500ms**（有 seed） |
| 应用详情页切入完成 | **≤ 350ms**（已有数据场景） |

### 7.3 内存要求（硬性上限）

| 场景 | RSS 目标上限 |
|------|-------------|
| 应用空闲首页稳定后 | **≤ 180 MB** |
| 推荐/分类/搜索列表页滚动后稳定 | **≤ 220 MB** |
| 详情页（含截图）稳定后 | **≤ 260 MB** |
| 多 KeepAlive 页共存稳定后 | **≤ 320 MB** |
| 下载管理弹窗 + 安装中 | **≤ 300 MB** |

> 若任一指标超出上限，必须提供原因分析和修复方案，不能默认接受。

### 7.4 CPU 要求

| 场景 | CPU 目标 |
|------|---------|
| 应用空闲静止 | **≤ 2% 单核占用** |
| 普通滚动中 | **≤ 25% 单核占用** |
| 后台隐藏页 | **接近 0% 持续占用** |
| 进程页轮询 | **≤ 5% 单核平均占用** |

### 7.5 网络与 IO 要求

- 列表页禁止重复请求首屏数据
- KeepAlive 页面从隐藏切回可见，只允许**必要的后台 refresh**
- 图片必须使用缓存，禁止每次重刷图标/截图
- 日志写入必须限频，禁止 UI 高频操作同步落盘

---

## 八、性能实现规范

### 8.1 Widget 层性能规则

- [ ] 所有纯展示组件优先 `const`
- [ ] 列表必须使用 `ListView.builder` / `GridView.builder`
- [ ] 禁止在 `build` 内执行 JSON 解析、排序、大 Map 构建
- [ ] Provider 选择器必须最小化订阅范围
- [ ] 卡片组件不能直接 watch 多个全局 Provider
- [ ] 页面级先构建索引 Map，再把布尔状态下发给卡片

### 8.2 KeepAlive 与副作用规则

- [ ] 仅白名单页面允许 KeepAlive
- [ ] 默认缓存上限建议 **6**，硬上限 **10**
- [ ] 隐藏页必须暂停：定时器、自动补页、滚动监听、网络轮询、Resize/Visibility 观察
- [ ] 页面恢复可见时，只触发一次轻量 refresh

### 8.3 图片与缓存规则

- [ ] 图标缓存单图上限：`128x128`
- [ ] 截图缓存按需加载，详情页外禁止预解码全量大图
- [ ] Flutter `ImageCache.maximumSizeBytes` 建议限制到 **48MB ~ 64MB**
- [ ] 运行时列表缓存必须有 TTL 与页数裁剪

### 8.4 数据结构规则

- [ ] 列表页严禁全量深拷贝大对象
- [ ] 统一保存轻量 ViewModel，而不是重复存整份 DTO
- [ ] 高频路径使用 `Map<String, T>` 做 O(1) 查询
- [ ] 禁止在滚动回调里做重运算

---

## 九、性能测试与基准规范

### 9.1 基准场景

必须建立以下 benchmark：

1. **首页启动 benchmark**
2. **推荐页滚动 benchmark**
3. **全部应用页切分类 benchmark**
4. **搜索结果页切关键字 benchmark**
5. **详情页打开 benchmark**
6. **更新页批量更新 benchmark**
7. **KeepAlive 切页 benchmark**

### 9.2 基准采集工具

- Flutter DevTools（CPU、Timeline、Memory）
- `integration_test` + profile mode
- MCP 驱动统一执行操作路径
- Linux 进程指标采集（RSS / CPU / fd 数 / IO）

### 9.3 基准报告模板

每次大版本必须输出：

| 项目 | 指标 | 本次 | 上次 | 结果 |
|------|------|------|------|------|
| 首页首帧 | ms |  |  | Pass/Fail |
| 首页可交互 | ms |  |  | Pass/Fail |
| 推荐页 60s 滚动慢帧数 | count |  |  | Pass/Fail |
| 空闲 RSS | MB |  |  | Pass/Fail |
| KeepAlive 5 页 RSS | MB |  |  | Pass/Fail |

---

## 十、CI / 发布流水线要求

### 10.1 PR 阶段

必须跑：
- `flutter analyze`
- 单元测试
- Widget 测试
- 关键 Golden 测试

### 10.2 develop 分支阶段

必须跑：
- 全量单元测试
- 全量 Widget 测试
- integration_test（fake 环境）
- MCP smoke 场景

### 10.3 发布前阶段

必须跑：
- MCP regression 全量
- profile 模式 benchmark
- 内存与帧率审计
- Golden 回归
- 真 CLI / 真 API 联调

---

## 十一、禁止事项

以下行为一律禁止：

- [ ] 只做手工点点点，不补自动化测试
- [ ] 用 `pumpAndSettle` 无限等待掩盖异步问题
- [ ] 用大面积截图测试替代精确断言
- [ ] 没有性能数据就宣称“性能很好”
- [ ] 出现明显内存上涨却归因给 Flutter 默认行为不处理
- [ ] 为了通过测试把动画、缓存、KeepAlive 全关掉

---

## 十二、落地建议

迁移初期建议立即建立以下脚手架：

1. `test/helpers/`：Provider 注入、fake repository、fake CLI 输出
2. `test/goldens/`：统一截图基线目录
3. `test/mcp/`：MCP 场景用例目录
4. `tool/benchmarks/`：性能采集脚本
5. `docs/perf-reports/`：性能审计报告目录

这样后面每迁一个页面，就不是“写完再看”，而是“写完就能验”。这会少掉大量后期返工——也少掉很多经典桌面端玄学事故。