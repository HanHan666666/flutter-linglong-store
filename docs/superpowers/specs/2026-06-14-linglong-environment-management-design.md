# 玲珑环境管理完整功能设计

本设计落地到 `docs/21-linglong-environment-management.md`。该功能在设置页新增「玲珑环境管理」入口，统一承载仓库管理、环境分析/修复、保存位置迁移三个能力。

## 设计结论

采用完整集中式实现：

1. 新增 `LinglongRepositoryManagementRepository`，由 `LinglongCliRepositoryImpl` 实现正式 `ll-cli repo` 管理命令。
2. 新增 `LinglongEnvironmentManagementService` 负责非 `ll-cli` 系统诊断与受控 `pkexec` 修复。
3. 新增 Riverpod Provider 管理仓库状态和环境分析状态。
4. 新增统一对话框，使用三个 Tab 承载所有管理功能。
5. 保存位置迁移严格采用 upstream issue 建议的 systemd bind mount 方案。

## 关键约束

- 不在页面散写 shell 命令。
- 不直接修改玲珑内部数据库。
- 不把仓库源重新变成业务设置。
- 不静默执行 `ostree fsck --delete`。
- 不在运行中应用或安装队列活跃时迁移 `/var/lib/linglong`。

## 远程分析依据

远程 UOS 25 / Loong64 环境只读分析确认：

- `ll-cli --version` 为 `linyaps CLI version 1.12.2`。
- `ll-cli --json repo show` 可稳定返回 JSON。
- `/var/lib/linglong/repo` 是 OSTree 仓库。
- `ostree fsck --repo=/var/lib/linglong/repo --quiet` 能发现 corrupted file object。
- `systemd-escape --path --suffix=mount /var/lib/linglong` 返回 `var-lib-linglong.mount`。
- `/var/lib/linglong` 属主为 `deepin-linglong:deepin-linglong`。

## 文档

完整业务细节、流程、校验和测试要求见：

- `docs/21-linglong-environment-management.md`
