# 启动期仓库读取失败与服务重启提示

> 文档版本：1.0
> 更新日期：2026-06-29
> 适用范围：启动期玲珑环境检测对话框、`ll-cli --json repo show` 仓库读取失败诊断、系统服务重启动作

## 背景

启动期环境检测需要通过 `ll-cli --json repo show` 读取玲珑仓库配置。实测问题中，`ll-cli` 已经安装，但系统 D-Bus 服务 `org.deepin.linglong.PackageManager.service` 未运行，导致 `ll-cli --json repo show` 返回非零退出码，应用只能得到空仓库结果，并展示“未检测到玲珑仓库配置，请检查环境”。

该场景与“用户确实没有配置仓库”不同：仓库配置可能存在，只是读取命令失败。UI 必须明确告诉用户失败的是 `ll-cli --json repo show` 命令，并提供受控的服务重启入口，避免用户误以为需要重新安装整个应用环境。

## 目标

1. 区分“仓库未配置”和“仓库读取命令失败”。
2. 在 `ll-cli --json repo show` 失败时展示结构化诊断信息：
   - 失败命令；
   - 命令失败原因摘要；
   - 推荐重启的系统服务名称。
3. 在环境检测对话框中展示“已经安装好了应用环境？”提示，并提供 link 样式按钮“尝试重启 org.deepin.linglong.PackageManager.service”。
4. 按现有架构约定执行服务重启：UI 只触发 Provider，Provider 调用环境服务，命令由服务层集中封装。

## 非目标

- 不把仓库源重新变成商店业务配置。
- 不在 Widget 或页面中直接拼接 `systemctl` 命令。
- 不自动静默重启系统服务；必须由用户点击按钮触发，并通过 `pkexec` 获取授权。
- 不把用户级 `linglong-session-helper.service` 暴露为独立 UI 操作；它只作为“尝试重启”恢复动作的一部分顺序执行。

## 行为设计

环境检测仍按现有顺序执行：

1. 检测 `ll-cli --help`，确认命令存在。
2. 执行 `ll-cli --json repo show`。
3. 命令失败时直接返回 `RepoStatus.unavailable`，并记录失败命令为 `ll-cli --json repo show`。
4. 命令成功但 JSON 输出不可解析时返回 `RepoStatus.misconfigured`，不再追加执行文本格式 `ll-cli repo show`。

当 `RepoStatus.unavailable` 且诊断动作是重启包管理器服务时，弹窗展示：

- 错误信息：`无法通过 ll-cli --json repo show 读取玲珑仓库配置`
- 诊断说明：`执行 ll-cli --json repo show 读取玲珑仓库配置失败。该命令需要通过系统服务 org.deepin.linglong.PackageManager.service 读取仓库配置；服务未运行时会返回失败。`
- 推荐动作：
  - 标题：`已经安装好了应用环境？`
  - 说明：`如果已经安装 ll-cli 和应用环境，可以尝试重启该系统服务后重新检测。`
  - link 按钮：`尝试重启 org.deepin.linglong.PackageManager.service`

用户点击按钮后，Provider 调用环境服务执行：

```bash
systemctl --user enable linglong-session-helper.service
systemctl --user start linglong-session-helper.service
pkexec systemctl restart org.deepin.linglong.PackageManager.service
```

三条命令按顺序执行，任一步失败都把该命令输出作为恢复动作错误返回给 UI。全部成功后立即重新执行环境检测；检测通过则关闭环境检测对话框，检测仍失败则保留错误信息，允许用户继续查看命令输出摘要或执行手动安装。

## 分层契约

### Domain

`LinglongEnvCheckResult` 增加结构化诊断字段：

- `failedCommand`：用户可读失败命令，例如 `ll-cli --json repo show`。
- `failedCommandExitCode`：失败命令退出码，便于日志和测试定位。
- `recoveryAction`：推荐修复动作，本场景为 `restartPackageManagerService`。

这些字段只描述检测结果，不直接执行副作用。

### Application / Service

`LinglongEnvironmentService` 负责：

- 保留仓库读取失败命令和错误摘要；
- 封装 `org.deepin.linglong.PackageManager.service` 重启动作；
- 继续通过 `ShellCommandExecutor` 执行系统命令，便于测试替换。

`LinglongEnv` Provider 负责：

- 标记服务重启中的 UI 状态；
- 调用环境服务重启系统服务；
- 重启成功后触发 `checkEnvironment()` 复检；
- 失败时把错误摘要留在状态里供 UI 展示。

### Presentation

`LinglongEnvDialog` 只负责渲染结构化诊断和调用 Provider 方法：

- 不拼接 `systemctl` 命令；
- 不直接处理 `pkexec`；
- link 样式按钮必须明确显示服务名，避免用户不知道将要重启什么。

## 测试与验证

需要覆盖：

1. `ll-cli --help` 成功，但 `ll-cli --json repo show` 失败时，环境检测结果包含失败命令、退出码、错误摘要和 `restartPackageManagerService` 推荐动作。
2. Provider 调用服务重启动作后重新执行环境检测。
3. 环境检测对话框在该诊断场景下展示“已经安装好了应用环境？”和“尝试重启 org.deepin.linglong.PackageManager.service”按钮。
4. i18n 生成文件与 Riverpod/Freezed 生成文件同步更新。

建议验证命令：

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter test test/unit/application/services/linglong_environment_service_test.dart
flutter test test/unit/application/providers/linglong_env_provider_test.dart
flutter test test/widget/presentation/widgets/linglong_env_dialog_test.dart
flutter analyze
```
