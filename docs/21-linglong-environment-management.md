# 玲珑环境管理、修复与保存位置迁移

> 文档版本：1.3
> 更新日期：2026-06-19
> 适用范围：设置页「玲珑环境管理」入口、仓库管理、环境分析与修复、保存位置迁移

## 背景

项目已有启动期玲珑环境检测、自动安装、安装队列和废弃 base 清理能力，但运行期缺少集中诊断入口。用户遇到仓库配置错误、OSTree 本地仓库损坏、`/var/lib/linglong` 空间不足时，过去只能从安装失败日志里看到零散错误。

本功能在设置页新增「玲珑环境管理」入口，打开统一对话框，包含：

- 「环境分析」：展示 ll-cli、仓库、数据目录权限、磁盘、OSTree、运行中应用等诊断结果。
- 「仓库管理」：查看、添加、修改、删除仓库，设置默认仓库、优先级和镜像开关。
- 「保存位置」：按上游建议通过 systemd bind mount 迁移 `/var/lib/linglong`。

## 参考依据

1. 远程 UOS 25 / Loong64 环境实测 `ll-cli 1.12.2` 支持 `repo add/remove/update/set-default/show/set-priority/enable-mirror/disable-mirror`。
2. `ll-cli --json repo show` 返回 `defaultRepo`、`repos`、`version`，可作为仓库列表首选解析来源；文本表格输出作为兜底。
3. 玲珑本地根目录为 `/var/lib/linglong`，OSTree 仓库位于 `/var/lib/linglong/repo`。
4. OpenAtom-Linyaps/linyaps#1411 中上游维护者说明当前不支持直接自定义安装位置，推荐通过 systemd `.mount` 将目标目录 bind 到 `/var/lib/linglong`。
5. linyaps 1.13.0 源码中仓库运行路径主要通过 `OSTreeRepo::init/loadFromPath/create` 打开仓库、读取 refs/cache/states，并通过 `/var/lib/linglong/layers/<commit>` checkout 目录支撑运行；源码未把 `ostree fsck` 作为启动或运行前置条件。
6. 远程环境实测 `ostree fsck --repo=/var/lib/linglong/repo --quiet` 可发现 corrupted file object，但 `ll-cli --json repo show`、`ll-cli --json list`、`ll-cli --json ps` 和 `ostree refs --repo=/var/lib/linglong/repo` 仍可正常执行。UI 必须区分“仓库不可读”和“深度对象完整性风险”，不能仅凭 `fsck` 非零码展示笼统的运行异常。
7. 远程 Loong64 环境实测 `ll-package-manager` 以 `deepin-linglong:deepin-linglong` 运行；当 `/var/lib/linglong/.version`、`states.json`、`repo`、`layers`、`entries`、`merged` 被 root 接管时，会出现 `couldn't open "/var/lib/linglong/.version"`、`ostree_repo_pull_with_options [code 14]: mkdirat: 权限不够`、`failed to create layer dir ... 权限不够` 等错误。环境管理必须把这类问题识别为“玲珑数据目录权限异常”，不能混同为 OSTree 仓库完整性异常。

## 实现边界

- 不新增“任意配置玲珑安装目录”的业务语义。
- 不把仓库源重新变成商店业务配置；后端接口仍使用 `AppConfig.defaultStoreRepoName`。
- 不直接修改玲珑内部数据库。
- 不在页面或 Provider 中散写 `ll-cli repo`、`ostree fsck`、`pkexec`、`rsync`、`systemctl` 命令。
- 不静默执行数据目录权限修复、`ostree fsck --delete` 或保存位置迁移，所有副作用操作必须由用户确认。
- 不在安装/更新队列仍有活跃任务或玲珑应用仍在运行时迁移保存位置。

## 分层契约

### Domain

- `LinglongRepositoryConfig`：仓库配置版本、默认仓库、仓库列表。
- `LinglongRepoInfo`：单个仓库的 `name/url/alias/priority/isDefault/isMirrorEnabled`。
- `LinglongEnvironmentAnalysis`：环境检测结果、数据目录权限、存储信息、OSTree 检查、问题列表、运行中应用数量。
- `LinglongDataPermissionCheckResult`：`/var/lib/linglong` 关键目录和状态文件是否由玲珑服务用户持有，并具备 owner 写权限。
- `LinglongEnvironmentIssue`：问题 code、严重级别、标题、说明、诊断详情和可执行修复动作。
- `LinglongStorageInfo`：根目录、文件系统、挂载源、容量、已用、可用、使用率、bind mount 状态。
- `LinglongEnvironmentRepairResult`：修复动作、成功状态、展示消息、日志路径和截断输出。

### Data / Platform

`LinglongRepositoryManagementRepository` 是仓库管理唯一抽象，当前由 `LinglongCliRepositoryImpl` 实现。所有 `ll-cli repo ...` 调用必须收敛到这一层：

- `getRepositoryConfig()`
- `addRepository(name, url, alias)`
- `updateRepository(aliasOrName, url)`
- `removeRepository(aliasOrName)`
- `setDefaultRepository(aliasOrName)`
- `setRepositoryPriority(aliasOrName, priority)`
- `setRepositoryMirror(aliasOrName, enabled)`

解析策略：

- 优先执行 `ll-cli --json repo show`。
- JSON 失败时执行 `ll-cli repo show`，去除 ANSI 控制符后解析 `Default:` 与表格行。
- 命令失败文案优先使用 `stderr`，为空时回退 `stdout`。

`LinglongEnvironmentManagementService` 负责非仓库管理的系统诊断和受控特权修复：

- 聚合现有 `LinglongEnvironmentService.checkEnvironment()`。
- 执行 `ll-cli --json ps` 统计运行中玲珑应用。
- 执行 `stat -c %U:%G:%a:%n` 检查 `/var/lib/linglong`、`.version`、`config.yaml`、`states.json`、`repo`、`layers`、`entries`、`merged` 的属主和 owner 写权限。
- 执行 `df -PB1 /var/lib/linglong` 读取空间。
- 执行 `findmnt --json /var/lib/linglong` 读取挂载状态。
- 先执行 `ostree refs --repo=/var/lib/linglong/repo` 做轻量只读可用性检查。
- 仅在 refs 可读时执行 `ostree fsck --repo=/var/lib/linglong/repo --quiet` 做深度对象完整性审计。
- 通过 `pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete` 执行 OSTree 修复。
- 通过 `pkexec bash <temp-script>` 执行数据目录权限修复脚本。
- 通过 `pkexec bash <temp-script>` 执行保存位置迁移脚本。
- 修复与迁移日志写入 XDG logs 目录；UI 只展示截断摘要。

### Application

`linglongEnvironmentManagementProvider` 是 UI 唯一状态编排入口：

- `load()` 同时加载环境分析和仓库配置。
- 仓库写操作成功后刷新仓库配置。
- 数据目录权限修复后重新执行完整分析。
- OSTree 修复后重新执行完整分析。
- 保存位置迁移前读取 `installQueueProvider`，只要当前任务或等待队列仍存在，就直接返回失败结果，不进入特权脚本。

### Presentation

`LinglongEnvironmentManagementDialog` 是统一对话框：

- Tab 1：环境分析。
- Tab 2：仓库管理。
- Tab 3：保存位置。

设置页入口位于「商店选项」卡片：

- 标题：`玲珑环境管理`
- 副标题：`分析环境、管理仓库、修复基础环境和移动保存位置`
- 图标：`Icons.health_and_safety_outlined`

## 环境分析规则

当前分析项：

1. `ll-cli` 可用性、版本、仓库状态。
2. 仓库是否已配置。
3. `/var/lib/linglong` 所在文件系统容量、已用、可用和使用率。
4. `/var/lib/linglong` 是否处于 bind mount。
5. `/var/lib/linglong` 关键目录和状态文件是否由 `deepin-linglong:deepin-linglong` 持有，并具备 owner 写权限。
6. `ostree` 命令是否可用。
7. `/var/lib/linglong/repo` refs 是否可读取。
8. `/var/lib/linglong/repo` 深度对象完整性审计是否存在风险。
9. `ll-cli --json ps` 是否存在运行中应用。

数据目录权限状态模型：

- `isAvailable=false`：无法执行 `stat` 或读取权限信息，展示“玲珑数据目录权限异常”错误，并保留原始输出。
- `isOk=false`：关键路径不是 `deepin-linglong:deepin-linglong`，或 owner 不具备写权限，展示“玲珑数据目录权限异常”错误，并列出异常路径。
- `isOk=true`：关键路径属主和 owner 写权限符合玲珑服务运行要求。

OSTree 状态模型：

- `isAvailable=false`：`ostree` 命令不可用或无法执行基础检查，展示“OSTree 工具不可用”警告。
- `isOk=false`：`ostree refs --repo=/var/lib/linglong/repo` 无法读取本地仓库，展示“OSTree 仓库不可用”错误，可引导尝试修复。
- `isOk=true && hasIntegrityWarning=true`：refs 可读但 `ostree fsck --quiet` 发现对象损坏，展示“OSTree 对象完整性风险”警告，并保留修复入口。
- `isOk=true && hasIntegrityWarning=false`：仓库可读且深度审计未发现风险，展示“正常”。

问题 code：

- `llCliUnavailable`
- `repositoryNotConfigured`
- `linglongDataPermissionAbnormal`
- `ostreeToolUnavailable`
- `ostreeRepositoryCorrupted`
- `storageNearlyFull`
- `runningAppsBlockStorageMove`

严重级别：

- `error`：缺少可用 ll-cli、仓库未配置、玲珑数据目录权限异常、OSTree 仓库 refs 不可读、空间严重不足。
- `warning`：ostree 工具不可用、OSTree 深度对象完整性风险、空间偏高、有运行中应用阻断迁移。
- `info`：保留给后续状态说明。

## 修复动作

### 刷新仓库配置

仓库配置异常时，环境分析页提供跳转或刷新入口；真实仓库增删改在「仓库管理」页完成。

### 修复玲珑数据目录权限

默认只分析，不自动修复。用户点击修复并确认后执行受控脚本：

```bash
pkexec bash <linglong-permission-repair-temp-script>
```

检查范围：

- `/var/lib/linglong`
- `/var/lib/linglong/.version`
- `/var/lib/linglong/config.yaml`
- `/var/lib/linglong/states.json`
- `/var/lib/linglong/repo`
- `/var/lib/linglong/layers`
- `/var/lib/linglong/entries`
- `/var/lib/linglong/merged`

修复规则：

- 修复目标属主固定为 `deepin-linglong:deepin-linglong`，与 `ll-package-manager` 服务运行身份一致。
- `.version`、`config.yaml`、`states.json` 只处理文件属主并确保 owner 可读写。
- `repo`、`layers`、`entries`、`merged` 递归恢复属主，并确保目录 owner 可进入和写入。
- 修复前停止 `org.deepin.linglong.PackageManager.service`，修复后执行 `systemctl reset-failed` 与 `systemctl restart`。
- 修复后执行 `ll-cli --json repo show` 验证 package-manager 能正常读取仓库配置。
- 脚本必须写完整日志；UI 只展示截断输出。
- 修复后自动重新执行环境分析。

该动作不能替代 OSTree 对象修复，也不能删除损坏对象；它只处理服务用户无法读写本地数据树导致的权限类故障。

### 修复 OSTree 仓库

默认只分析，不自动修复。用户点击修复并确认后执行：

```bash
pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete
```

要求：

- 必须显示风险说明。
- 必须写完整日志。
- UI 只展示截断输出。
- 修复后自动重新执行环境分析。

`--delete` 会删除损坏对象，后续安装或更新可重新拉取缺失内容。这个动作不能静默执行。

OSTree 版本兼容规则：

- 优先执行 `pkexec ostree fsck --repo=/var/lib/linglong/repo --all --delete`。
- 如果输出明确表示当前 OSTree 不支持 `--all`，降级重试 `pkexec ostree fsck --repo=/var/lib/linglong/repo --delete`，并继续写入同一个日志文件。
- 如果输出明确表示当前 OSTree 不支持 `--delete`，不能退化成只检查命令，也不能提示修复成功；必须告知用户该版本无法自动删除损坏对象，需要升级 ostree 或使用发行版工具手动修复。
- 新版 OSTree 可能在删除损坏对象后输出 `partial commits from fsck-detected corruption` 并以非零码退出。这类结果表示可自动清理的损坏对象已处理，但仍有受影响 commit 被标记为 partial；UI 应提示用户重新安装或更新受影响应用/基础环境后再次执行环境分析，而不是展示普通“修复失败”。
- partial commit 数量优先从 OSTree 输出中提取，例如 `32 partial commits not verified` 展示为“32 个 partial commits”。完整输出仍以日志文件为准。

## 保存位置迁移

### 上游方案

遵循 OpenAtom-Linyaps/linyaps#1411 的 systemd bind mount 方案：

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

本项目固定使用 `var-lib-linglong.mount`，目标是把目标目录挂载到 `/var/lib/linglong`，而不是创建新的玲珑安装目录配置。

### 前置校验

执行迁移前必须满足：

- 目标路径必须是绝对路径。
- 目标路径不能是 `/`、`/var`、`/var/lib`、`/var/lib/linglong`。
- 目标路径不能位于 `/var/lib/linglong` 内部。
- 目标路径不能包含换行。
- `ll-cli --json ps` 没有运行中应用。
- `installQueueProvider` 没有当前任务或等待任务。
- 当前 `/var/lib/linglong` 不是已存在的 bind mount。
- 目标所在文件系统可用空间必须大于当前已用空间，并额外保留安全余量。

### 执行脚本

通过 `pkexec bash <temp-script>` 执行受控脚本：

1. `set -euo pipefail`。
2. 再次检查 `ll-cli --json ps`，避免确认后有新应用启动。
3. 创建源目录和目标目录。
4. 优先使用 `rsync -aHAX --numeric-ids "$SRC"/ "$DST"/` 复制数据，缺少 `rsync` 时回退 `cp -a`。
5. 校验目标目录存在 `repo/config`。
6. 复制源目录属主和权限到目标目录。
7. 写入 `/etc/systemd/system/var-lib-linglong.mount`。
8. 将旧 `/var/lib/linglong` 移动为 `/var/lib/linglong.backup-YYYYmmdd-HHMMSS`。
9. 重新创建空的 `/var/lib/linglong` 挂载点。
10. `systemctl daemon-reload`。
11. `systemctl enable --now var-lib-linglong.mount`。
12. `findmnt /var/lib/linglong` 验证挂载。
13. 若存在 `ostree`，执行 `ostree fsck --repo=/var/lib/linglong/repo --quiet` 做迁移后校验。
14. 输出旧目录备份路径。

脚本带 `ERR` trap：如果挂载前失败，会尝试把备份目录恢复回 `/var/lib/linglong`。挂载成功后的 fsck 失败会保留挂载状态和备份路径，便于用户查看日志后人工处理。

### 备份清理

迁移不会自动删除 `/var/lib/linglong.backup-*`。这是为了避免迁移后立即丢失回滚数据。UI 会展示执行输出和日志路径，用户确认新挂载可用后，再手动清理旧备份释放原分区空间。

## UI 行为

### 环境分析

- 顶部展示 ll-cli 版本、运行中应用数量、空间使用率、OSTree 状态；OSTree 必须区分“正常”“可用，有风险”“不可用”“工具不可用”。
- 数据目录权限异常必须在环境分析问题列表中展示，修复入口和 OSTree 修复入口同级，不进入保存位置 Tab。
- 问题按严重程度排序展示。
- 每个问题展示标题、描述、原始诊断详情和可执行动作。
- 修复按钮必须先弹出确认对话框。

### 仓库管理

- 顶部展示默认仓库。
- 仓库列表展示名称、别名、URL、优先级、默认/镜像状态。
- 每行支持修改地址、设为默认、设置优先级、启用/禁用镜像、删除。
- 添加/修改表单校验仓库名称、URL 和优先级。

### 保存位置

- 展示当前根目录、挂载源、容量、已用、可用和使用率。
- 展示运行中应用数量和迁移风险说明。
- 目标路径默认填 `/data/linglong`。
- 执行迁移前二次确认。
- 执行后展示结果、截断输出和日志目录入口。

## 性能与响应

- 权限修复、`ostree fsck` 和保存位置迁移都可能耗时较长，必须异步执行。
- UI 操作期间只显示轻量进度状态，不阻塞主线程。
- 命令输出截断到 4000 字符，避免大量 corrupted object 输出导致 UI 卡顿。
- 仓库列表只在打开对话框、刷新或写操作成功后重新加载。

## 测试覆盖

已覆盖：

- 仓库 JSON 解析、ANSI 文本兜底解析、仓库命令参数。
- 环境分析中的数据目录权限异常、OSTree refs 不可读、OSTree 深度对象完整性风险、空间不足和运行中应用阻断。
- 数据目录权限修复脚本、修复命令和日志参数。
- OSTree 修复命令和日志参数。
- 保存位置迁移脚本内容、危险目标路径拒绝、目标空间不足拒绝。
- Provider 状态加载、修复后刷新、仓库写操作刷新、安装队列活跃时阻断迁移。
- 设置页入口和三 Tab 对话框基础展示。

最终变更必须至少运行：

```bash
/home/hao/Flutter/flutter-stable/bin/flutter analyze
/home/hao/Flutter/flutter-stable/bin/flutter test test/unit/data/repositories/linglong_cli_repository_impl_command_test.dart
/home/hao/Flutter/flutter-stable/bin/flutter test test/unit/application/services/linglong_environment_management_service_test.dart
/home/hao/Flutter/flutter-stable/bin/flutter test test/unit/application/providers/linglong_environment_management_provider_test.dart
/home/hao/Flutter/flutter-stable/bin/flutter test test/widget/presentation/widgets/linglong_environment_management_dialog_test.dart
/home/hao/Flutter/flutter-stable/bin/flutter test test/widget/presentation/pages/setting_page_test.dart
```
