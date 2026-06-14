# 玲珑环境管理、修复与保存位置迁移设计

> 文档版本：1.0  
> 创建日期：2026-06-14  
> 适用范围：设置页玲珑环境管理入口、仓库管理、环境分析与修复、保存位置迁移

## 背景

当前项目已经具备启动期玲珑环境检测、自动安装、安装队列和清理废弃基础服务能力，但缺少运行期的集中环境管理入口。用户遇到仓库配置错误、OSTree 本地仓库损坏、玲珑根目录空间不足时，只能从安装失败日志里看到零散错误，无法在商店内主动诊断和修复。

本功能新增一个集中入口，放在设置页「商店选项」附近，命名为「玲珑环境管理」。入口打开统一对话框，对话框内分为「环境分析」「仓库管理」「保存位置」三个页签。

## 参考结论

1. 官方 `ll-cli repo` 在 1.10.x 文档中支持 `add/remove/update/set-default/show/set-priority/enable-mirror/disable-mirror`。
2. 远程 UOS 25 / Loong64 机器实测 `ll-cli 1.12.2` 的 `ll-cli --json repo show` 返回：
   - `defaultRepo`
   - `repos`
   - `version`
3. 玲珑本地根目录为 `/var/lib/linglong`，OSTree 仓库为 `/var/lib/linglong/repo`。
4. 官方 issue OpenAtom-Linyaps/linyaps#1411 明确说明当前不支持直接自定义安装位置，推荐通过 systemd `.mount` 把目标目录 bind 到 `/var/lib/linglong`。
5. OSTree 完整性检查使用 `ostree fsck --repo=/var/lib/linglong/repo --quiet`。远程实测可发现 corrupted file object。

## 目标

- 在设置页新增「玲珑环境管理」入口。
- 支持查看、添加、编辑、删除玲珑仓库。
- 支持设置默认仓库、调整仓库优先级、启用/禁用镜像。
- 支持主动环境分析，展示发现的问题和诊断详情。
- 支持对可修复问题执行用户确认后的修复操作。
- 支持按 systemd bind mount 方案迁移玲珑保存位置。
- 所有命令集中在 Repository / Service 层，页面不直接拼命令。
- 所有有副作用操作必须二次确认，并保留执行日志。

## 非目标

- 不新增“任意配置玲珑安装目录”的业务语义。
- 不绕过 Linyaps 上游机制直接修改内部数据库。
- 不在安装队列执行中、玲珑应用运行中迁移保存位置。
- 不静默执行 `ostree fsck --delete`。
- 不把仓库源选择重新变成商店业务配置。后端接口仍使用 `AppConfig.defaultStoreRepoName`。

## 架构

### Domain

新增轻量模型：

- `LinglongRepositoryConfig`：默认仓库、仓库列表、配置版本。
- `LinglongEnvironmentAnalysis`：环境检测结果、存储信息、OSTree 完整性结果、问题列表。
- `LinglongEnvironmentIssue`：问题类型、严重级别、展示摘要、诊断详情、可用修复动作。
- `LinglongStorageInfo`：根目录、repo 路径、挂载状态、磁盘空间、运行中应用数量。
- `LinglongActionResult`：命令执行结果、输出摘要、日志路径。

### Data / Platform

`LinglongCliRepository` 继续作为所有 `ll-cli` 操作入口，新增仓库管理方法：

- `getRepositoryConfig()`
- `addRepository(name, url, alias)`
- `updateRepository(aliasOrName, url)`
- `removeRepository(aliasOrName)`
- `setDefaultRepository(aliasOrName)`
- `setRepositoryPriority(aliasOrName, priority)`
- `setRepositoryMirror(aliasOrName, enabled)`

非 `ll-cli` 系统操作集中到 `LinglongEnvironmentManagementService`：

- 读取 `/var/lib/linglong`、`/var/lib/linglong/repo` 状态。
- 运行 `df`、`findmnt`、`systemd-escape`、`systemctl cat` 等只读诊断命令。
- 运行 `ostree fsck --repo=/var/lib/linglong/repo --quiet` 做完整性检查。
- 通过 `pkexec bash <temp-script>` 执行受控修复脚本。

### Application

新增两个 Provider：

- `linglongRepositoryManagementProvider`
  - 缓存仓库列表。
  - 负责仓库增删改、默认仓库、优先级、镜像开关。
  - 每次写操作成功后重新加载仓库配置。

- `linglongEnvironmentManagementProvider`
  - 执行环境分析。
  - 汇总 `LinglongEnvCheckResult`、仓库配置、磁盘空间、OSTree fsck、运行中应用。
  - 执行修复动作并保留状态。

### Presentation

新增对话框：

- `LinglongEnvironmentManagementDialog`
  - Tab 1：环境分析
  - Tab 2：仓库管理
  - Tab 3：保存位置

新增表单：

- `LinglongRepositoryFormDialog`：添加/编辑仓库。
- `LinglongStorageMigrationDialog`：输入目标目录并展示迁移风险。

## 环境分析规则

分析项：

1. `ll-cli` 可用性和版本。
2. 玲珑仓库配置是否存在。
3. `/var/lib/linglong` 是否存在。
4. `/var/lib/linglong/repo` 是否存在。
5. 根目录所在分区剩余空间。
6. `ostree fsck --repo=/var/lib/linglong/repo --quiet` 完整性。
7. `ll-cli --json ps` 是否存在运行中应用。
8. `var-lib-linglong.mount` 是否已配置。

严重级别：

- `fatal`：`ll-cli` 缺失、玲珑根目录缺失、迁移目标不可用。
- `error`：仓库未配置、OSTree 损坏、空间不足。
- `warning`：版本过低、有运行中应用、空间偏低、已有手工挂载但缺少 systemd 持久化配置。
- `info`：当前状态说明。

## 修复动作

### 自动安装/修复基础环境

沿用现有 `LinglongEnvProvider.performAutoInstall()`，脚本来源仍为后端 `/app/findShellString`，执行方式仍为 `pkexec bash <temp-script>`。

### 修复 OSTree 仓库

默认只分析，不修复。

用户点击修复后：

1. 显示风险说明。
2. 确认无安装任务运行。
3. 确认无玲珑应用运行。
4. 执行 `pkexec ostree fsck --repo=/var/lib/linglong/repo --delete`。
5. 修复后重新执行环境分析。

说明：`--delete` 会删除损坏对象，后续安装/更新可重新拉取缺失内容。该操作不是静默自愈，必须显式确认。

### 清理废弃基础服务

复用现有 `Setting.pruneBaseService()` / `LinglongCliRepository.pruneApps()`。

## 保存位置迁移

### 方案

遵循 OpenAtom-Linyaps/linyaps#1411 的建议，不创造新的“安装目录配置”语义。迁移通过 systemd bind mount 完成：

```ini
[Unit]
Description=Bind for linglong root dir

[Mount]
What=/data/linglong
Where=/var/lib/linglong
Options=bind

[Install]
WantedBy=multi-user.target
```

真实 unit 名通过：

```bash
systemd-escape --path --suffix=mount /var/lib/linglong
```

得到 `var-lib-linglong.mount`。

### 前置校验

迁移前必须满足：

- 目标路径为绝对路径。
- 目标路径不是 `/`、`/var`、`/var/lib`、`/var/lib/linglong`。
- 目标路径不在 `/var/lib/linglong` 内部。
- 目标所在文件系统可写。
- 目标可用空间大于当前 `/var/lib/linglong` 已用空间，并保留安全余量。
- `ll-cli --json ps` 没有运行中应用。
- 安装/更新队列没有正在处理的任务。
- 当前没有活跃的 `/var/lib/linglong` bind mount。

### 执行脚本

通过 `pkexec bash <temp-script>` 执行受控脚本：

1. `set -euo pipefail`
2. 创建目标目录。
3. 使用 `rsync -aHAX --numeric-ids /var/lib/linglong/ <target>/` 复制数据。
4. 校验复制后的 `repo/config`、`states.json`、`.version`。
5. 设置目标目录属主和权限，与原目录保持一致。
6. 将原目录移动为带时间戳的备份目录。
7. 重新创建 `/var/lib/linglong` 挂载点。
8. 写入 `/etc/systemd/system/var-lib-linglong.mount`。
9. `systemctl daemon-reload`
10. `systemctl enable --now var-lib-linglong.mount`
11. 运行 `findmnt /var/lib/linglong` 验证挂载生效。
12. 运行 `ostree fsck --repo=/var/lib/linglong/repo --quiet` 做迁移后校验。

### 备份清理

迁移默认保留旧目录备份，例如 `/var/lib/linglong.backup-20260614-235959`。UI 显示备份路径，后续由用户确认后再清理。第一版提供“复制清理命令”与“打开日志目录”，不自动删除备份。

## UI 行为

### 设置页入口

在「商店选项」卡片中新增 ListTile：

- 标题：玲珑环境管理
- 副标题：仓库、完整性检查、保存位置迁移
- 图标：`Icons.health_and_safety_outlined`

### 环境分析页签

- 顶部显示总状态。
- 问题按 `fatal/error/warning/info` 排序。
- 每个问题显示摘要、详情、建议动作。
- 详情可复制。
- 可执行动作必须弹确认。

### 仓库管理页签

- 显示默认仓库。
- 列表显示名称、URL、别名、优先级。
- 每行支持编辑、设为默认、调整优先级、启用/禁用镜像、删除。
- 添加/编辑使用表单校验 URL 和名称。

### 保存位置页签

- 显示当前根目录、repo 路径、分区空间、挂载状态、运行中应用数量。
- 提供目标路径输入。
- 展示 systemd bind mount 方案和风险。
- 执行前二次确认。
- 执行后展示日志路径、备份路径和重新分析按钮。

## 性能与响应

- `ostree fsck` 可能耗时较长，必须异步执行，UI 显示进度文案。
- fsck 输出必须截断保存摘要，避免大量 corrupt object 输出导致 UI 卡顿。
- 完整日志写入 XDG 日志目录，UI 仅展示前若干行和路径。
- 仓库列表刷新只在打开对话框或写操作后触发。

## 测试要求

单元测试：

- repo JSON 解析。
- ANSI 文本 repo 输出兜底解析。
- 仓库管理命令参数。
- OSTree fsck 成功/失败解析。
- 保存位置迁移脚本生成前置校验。
- 分析结果问题排序和修复动作映射。

Widget 测试：

- 设置页出现「玲珑环境管理」入口。
- 环境管理对话框显示三个页签。
- 仓库表单校验空名称和非法 URL。
- 环境分析问题展示和修复确认按钮存在。
- 保存位置迁移在有运行中应用时禁用执行。

验证：

- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test test/unit/`
- `flutter test test/widget/`
- `flutter analyze`

## 后续维护约定

- 新增玲珑环境类命令必须优先走 `LinglongEnvironmentManagementService` 或 `LinglongCliRepository`。
- 页面层禁止直接写 `ll-cli`、`ostree`、`systemctl`、`pkexec` 命令。
- OSTree 修复和保存位置迁移必须保留二次确认。
- 保存位置迁移只能实现 bind mount 方案，禁止伪造“ll-cli 安装目录配置”。
- 修改 Riverpod 注解或 Freezed 模型后必须重新生成代码。
